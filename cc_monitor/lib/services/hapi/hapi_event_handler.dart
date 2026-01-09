import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/logger.dart';
import 'package:uuid/uuid.dart';
import '../../models/message.dart';
import '../../models/payload/payload.dart';
import '../../models/session.dart';
import '../../models/task.dart';
import '../../providers/messages_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/streaming_provider.dart';
import '../interaction_service.dart';
import '../cache_service.dart';
import '../toast_service.dart';
import 'buffer_manager.dart';
import 'hapi_api_service.dart';
import 'hapi_config_service.dart';
import 'hapi_sse_service.dart';

const _uuid = Uuid();

/// hapi 事件处理器 - 监听 SSE 事件并更新应用状态
class HapiEventHandler {
  HapiEventHandler(this._ref);

  final Ref _ref;
  StreamSubscription<HapiSseEvent>? _subscription;

  // 会话更新防抖器 - 防止频繁的会话更新导致 UI 抖动
  final _sessionUpdateDebouncer = Debouncer(
    delay: const Duration(milliseconds: 150),
  );

  // 使用 BufferManager 单例管理所有缓冲区 (Singleton 模式)
  BufferManager get _bufferManager => BufferManager.instance;

  /// 开始监听 SSE 事件
  void startListening() {
    final sseService = _ref.read(hapiSseServiceProvider);
    if (sseService == null) {
      Log.w('HapiEvent', 'SSE service not available');
      return;
    }

    _subscription?.cancel();
    _subscription = sseService.events.listen(_handleEvent);
    Log.i('HapiEvent', 'Started listening');

    // 连接后加载初始会话
    loadSessions();
  }

  /// 停止监听
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;

    // 清理流式状态 (使用 BufferManager)
    _bufferManager.clearAll();
    _ref.read(streamingMessagesProvider.notifier).clear();

    Log.i('HapiEvent', 'Stopped listening');
  }

  /// 处理 SSE 事件
  void _handleEvent(HapiSseEvent event) {
    switch (event.type) {
      // 消息事件
      case HapiSseEventType.message:
        _handleMessageEvent(event);
      case HapiSseEventType.permissionRequest:
        _handlePermissionRequest(event);
      case HapiSseEventType.todoUpdate:
        _handleTodoUpdate(event);

      // 会话事件
      case HapiSseEventType.sessionUpdate:
        _handleSessionUpdate(event);
      case HapiSseEventType.sessionCreated:
        _handleSessionCreated(event);
      case HapiSseEventType.sessionEnded:
        _handleSessionEnded(event);
      case HapiSseEventType.sessionAdded:
      case HapiSseEventType.sessionUpdated:
      case HapiSseEventType.sessionRemoved:
        loadSessions();

      // 连接事件
      case HapiSseEventType.connectionChanged:
      case HapiSseEventType.connected:
        break; // 已在 SSE 服务中处理

      // 流式内容
      case HapiSseEventType.streamingContent:
        _handleStreamingContent(event);
      case HapiSseEventType.streamingComplete:
        _handleStreamingComplete(event);

      // 机器事件
      case HapiSseEventType.machineUpdate:
      case HapiSseEventType.machineUpdated:
        break; // 暂不处理

      // 其他
      case HapiSseEventType.toast:
        _handleToast(event);
      case HapiSseEventType.error:
        Log.w('HapiEvent', 'SSE error: ${event.data}');
      case HapiSseEventType.unknown:
        Log.w('HapiEvent', 'Unknown event: ${event.type}');
    }
  }

  /// 处理 toast 通知
  void _handleToast(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    final message = data['message'] as String? ?? data['text'] as String?;
    if (message != null) {
      final type = data['type'] as String?;
      final toastType = switch (type) {
        'error' => ToastType.error,
        'warning' => ToastType.warning,
        'success' => ToastType.success,
        _ => ToastType.info,
      };
      ToastService().show(message, type: toastType);
    }
  }

  /// 处理消息事件
  /// hapi SSE 事件结构: { type: 'message-received', sessionId: 'xxx', message: {...} }
  void _handleMessageEvent(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    try {
      // hapi message-received 事件: sessionId 和 message 都在顶层
      final sessionId = event.sessionId ?? data['sessionId'] as String?;
      final messageData = data['message'] as Map<String, dynamic>?;

      if (sessionId == null || messageData == null) return;

      final message = _parseHapiMessage(messageData, sessionId);
      if (message != null) {
        _ref.read(messagesProvider.notifier).addMessage(message);
      }

      // 从消息中提取 usage 并更新 session 的 contextSize
      _updateSessionContextSize(sessionId, messageData);
    } catch (e) {
      Log.e('HapiEvent', 'Failed to parse message', e);
    }
  }

  /// 处理权限请求事件
  void _handlePermissionRequest(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    try {
      // 注册 requestId -> sessionId 映射
      final requestId = data['id'] as String? ?? data['requestId'] as String?;
      final sessionId = event.sessionId ?? data['sessionId'] as String?;

      if (requestId != null && sessionId != null) {
        final interactionService = _ref.read(interactionServiceProvider);
        if (interactionService is HapiInteractionService) {
          interactionService.registerRequestSession(requestId, sessionId);
        }
      }

      // 创建交互消息
      final message = _parsePermissionRequest(data, sessionId);
      if (message != null) {
        _ref.read(messagesProvider.notifier).addMessage(message);
      }
    } catch (e) {
      Log.e('HapiEvent', 'Failed to handle permission request', e);
    }
  }

  /// 处理会话更新事件（带防抖）
  void _handleSessionUpdate(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    final sessionId = data['id'] as String?;
    if (sessionId == null) return;

    // 累积更新 (使用 BufferManager)
    _bufferManager.addPendingSessionUpdate(sessionId, data);

    // 使用防抖批量处理
    _sessionUpdateDebouncer.run(_flushSessionUpdates);
  }

  /// 从消息中提取 usage 并更新 session 的 contextSize
  void _updateSessionContextSize(
    String sessionId,
    Map<String, dynamic> messageData,
  ) {
    // 尝试从多个位置获取 usage
    Map<String, dynamic>? usage;

    // 1. 直接在消息顶层
    usage = messageData['usage'] as Map<String, dynamic>?;

    // 2. 在 content 中
    if (usage == null) {
      final content = messageData['content'];
      if (content is Map<String, dynamic>) {
        usage = content['usage'] as Map<String, dynamic>?;
      }
    }

    if (usage == null) {
      Log.v(
        'HapiEvent',
        'No usage data found in message for session $sessionId',
      );
      return;
    }

    // 计算 contextSize
    final inputTokens =
        usage['input_tokens'] as int? ?? usage['inputTokens'] as int? ?? 0;
    final cacheCreation =
        usage['cache_creation_input_tokens'] as int? ??
        usage['cacheCreationInputTokens'] as int? ??
        0;
    final cacheRead =
        usage['cache_read_input_tokens'] as int? ??
        usage['cacheReadInputTokens'] as int? ??
        0;
    final contextSize = inputTokens + cacheCreation + cacheRead;

    Log.d(
      'HapiEvent',
      'Context size calculated: $contextSize (input=$inputTokens, cache_creation=$cacheCreation, cache_read=$cacheRead)',
    );

    if (contextSize > 0) {
      final sessions = _ref.read(sessionsProvider);
      final session = sessions.firstWhereOrNull((s) => s.id == sessionId);
      if (session != null) {
        _ref
            .read(sessionsProvider.notifier)
            .upsertSession(session.copyWith(contextSize: contextSize));
        Log.i(
          'HapiEvent',
          'Updated context size for session $sessionId: $contextSize',
        );
      } else {
        Log.w(
          'HapiEvent',
          'Session $sessionId not found, cannot update context size',
        );
      }
    } else {
      Log.v('HapiEvent', 'Context size is 0, skipping update');
    }
  }

  /// 批量刷新会话更新
  void _flushSessionUpdates() {
    // 使用 BufferManager 获取并清空待处理更新
    final updates = _bufferManager.consumePendingSessionUpdates();
    if (updates.isEmpty) return;

    final sessions = _ref.read(sessionsProvider);

    for (final entry in updates.entries) {
      try {
        final newSession = _parseHapiSession(entry.value);
        if (newSession != null) {
          // 保留现有 session 的 contextSize（如果新数据中为 null）
          // 因为 contextSize 通常来自消息的 usage 数据，而不是 session update 事件
          final existingSession = sessions.firstWhereOrNull(
            (s) => s.id == newSession.id,
          );
          final mergedSession =
              existingSession != null && newSession.contextSize == null
                  ? newSession.copyWith(
                    contextSize: existingSession.contextSize,
                  )
                  : newSession;
          _ref.read(sessionsProvider.notifier).upsertSession(mergedSession);
        }
      } catch (e) {
        Log.e('HapiEvent', 'Failed to update session ${entry.key}', e);
      }
    }
  }

  /// 处理会话创建事件
  void _handleSessionCreated(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    try {
      final newSession = _parseHapiSession(data);
      if (newSession != null) {
        // 保留现有 session 的 contextSize（如果新数据中为 null）
        final sessions = _ref.read(sessionsProvider);
        final existingSession = sessions.firstWhereOrNull(
          (s) => s.id == newSession.id,
        );
        final mergedSession =
            existingSession != null && newSession.contextSize == null
                ? newSession.copyWith(contextSize: existingSession.contextSize)
                : newSession;
        _ref.read(sessionsProvider.notifier).upsertSession(mergedSession);
      }
    } catch (e) {
      Log.e('HapiEvent', 'Failed to create session', e);
    }
  }

  /// 处理会话结束事件
  void _handleSessionEnded(HapiSseEvent event) {
    final sessionId = event.sessionId ?? event.data?['id'] as String?;
    if (sessionId == null) return;

    _ref
        .read(sessionsProvider.notifier)
        .updateStatus(sessionId, SessionStatus.completed);
  }

  /// 处理流式内容事件
  void _handleStreamingContent(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    try {
      final messageId = data['messageId'] as String? ?? data['id'] as String?;
      final chunk = data['chunk'] as String? ?? data['content'] as String?;
      final sessionId = event.sessionId ?? data['sessionId'] as String?;

      if (messageId == null) return;

      // 初始化缓冲区和元数据 (使用 BufferManager)
      if (!_bufferManager.hasStreamingBuffer(messageId)) {
        _bufferManager.initStreamingBuffer(messageId, {
          'sessionId': sessionId,
          'type': data['type'] as String? ?? 'markdown',
          'title': data['title'] as String?,
          'language': data['language'] as String?,
          'filename': data['filename'] as String?,
          'projectName': data['projectName'] as String? ?? 'hapi',
          'parentUuid':
              data['parentUuid'] as String? ?? data['parentId'] as String?,
          'contentUuid': data['uuid'] as String?,
        });

        // 开始流式传输
        _ref
            .read(streamingMessagesProvider.notifier)
            .startStreaming(messageId, initialContent: chunk ?? '');

        // 创建初始消息（状态为 streaming）
        final message = _createStreamingMessage(messageId, chunk ?? '');
        if (message != null) {
          _ref.read(messagesProvider.notifier).addMessage(message);
        }
      } else if (chunk != null) {
        // 追加内容 (使用 BufferManager)
        _bufferManager.appendStreamingContent(messageId, chunk);

        // 更新流式内容（使用 provider 内置的节流）
        _ref
            .read(streamingMessagesProvider.notifier)
            .updateContent(
              messageId,
              _bufferManager.getStreamingContent(messageId) ?? '',
            );
      }
    } catch (e) {
      Log.e('HapiEvent', 'Failed to handle streaming content', e);
    }
  }

  /// 处理流式完成事件
  void _handleStreamingComplete(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    try {
      final messageId = data['messageId'] as String? ?? data['id'] as String?;
      if (messageId == null) return;

      // 标记完成
      final notifier = _ref.read(streamingMessagesProvider.notifier);
      notifier.complete(messageId);

      // 更新消息为完成状态 (使用 BufferManager)
      final finalContent = _bufferManager.getStreamingContent(messageId) ?? '';
      final metadata = _bufferManager.getStreamingMetadata(messageId);

      if (metadata != null) {
        final message = _createFinalMessage(messageId, finalContent, metadata);
        if (message != null) {
          _ref.read(messagesProvider.notifier).replaceMessage(message);
        }
      }

      // 清理缓冲区 (使用 BufferManager)
      _bufferManager.removeStreamingBuffer(messageId);

      // 延迟清理流式状态（让 UI 有时间显示最终状态）
      Future.delayed(const Duration(milliseconds: 500), () {
        notifier.remove(messageId);
      });
    } catch (e) {
      Log.e('HapiEvent', 'Failed to handle streaming complete', e);
    }
  }

  /// 创建流式消息（初始状态）
  Message? _createStreamingMessage(String messageId, String initialContent) {
    final metadata = _bufferManager.getStreamingMetadata(messageId);
    if (metadata == null) return null;

    final sessionId = metadata['sessionId'] as String?;
    if (sessionId == null) return null;

    final type = metadata['type'] as String? ?? 'markdown';
    final title = metadata['title'] as String? ?? _getTitleFromType(type);
    final projectName = metadata['projectName'] as String? ?? 'hapi';
    final parentId = metadata['parentUuid'] as String?;
    final contentUuid = metadata['contentUuid'] as String?;

    Payload payload;
    if (type == 'code') {
      payload = CodePayload(
        title: title,
        code: initialContent,
        language: metadata['language'] as String?,
        filename: metadata['filename'] as String?,
        streamingStatus: StreamingStatus.streaming,
      );
    } else {
      payload = MarkdownPayload(
        title: title,
        content: initialContent,
        streamingStatus: StreamingStatus.streaming,
        streamingId: messageId,
      );
    }

    return Message(
      id: messageId,
      sessionId: sessionId,
      payload: payload,
      projectName: projectName,
      createdAt: DateTime.now(),
      parentId: parentId,
      contentUuid: contentUuid,
    );
  }

  /// 创建最终消息（完成状态）
  Message? _createFinalMessage(
    String messageId,
    String content,
    Map<String, dynamic> metadata,
  ) {
    final sessionId = metadata['sessionId'] as String?;
    if (sessionId == null) return null;

    final type = metadata['type'] as String? ?? 'markdown';
    final title = metadata['title'] as String? ?? _getTitleFromType(type);
    final projectName = metadata['projectName'] as String? ?? 'hapi';
    final parentId = metadata['parentUuid'] as String?;
    final contentUuid = metadata['contentUuid'] as String?;

    Payload payload;
    if (type == 'code') {
      payload = CodePayload(
        title: title,
        code: content,
        language: metadata['language'] as String?,
        filename: metadata['filename'] as String?,
        streamingStatus: StreamingStatus.complete,
      );
    } else {
      payload = MarkdownPayload(
        title: title,
        content: content,
        streamingStatus: StreamingStatus.complete,
      );
    }

    return Message(
      id: messageId,
      sessionId: sessionId,
      payload: payload,
      projectName: projectName,
      createdAt: DateTime.now(),
      parentId: parentId,
      contentUuid: contentUuid,
    );
  }

  /// 处理 Todo 更新事件
  void _handleTodoUpdate(HapiSseEvent event) {
    final data = event.data;
    final sessionId = event.sessionId ?? data?['sessionId'] as String?;
    if (data == null || sessionId == null) return;

    try {
      final todos =
          (data['todos'] as List?)
              ?.map(
                (e) => TodoItem(
                  content: e['content'] as String? ?? '',
                  status: e['status'] as String? ?? 'pending',
                  activeForm: e['activeForm'] as String?,
                ),
              )
              .toList();

      if (todos != null) {
        // 更新会话的 todos
        final sessions = _ref.read(sessionsProvider);
        final session = sessions.where((s) => s.id == sessionId).firstOrNull;
        if (session != null) {
          _ref
              .read(sessionsProvider.notifier)
              .upsertSession(session.copyWith(todos: todos));
        }
      }
    } catch (e) {
      Log.e('HapiEvent', 'Failed to update todos', e);
    }
  }

  /// 解析 hapi 会话数据
  /// hapi API 返回的数据结构示例:
  /// {
  ///   "id": "session_xxx",
  ///   "active": true,
  ///   "metadata": {
  ///     "path": "/home/user/project",
  ///     "summary": {"text": "项目描述"},
  ///     "machineId": "machine_xxx"
  ///   }
  /// }
  Session? _parseHapiSession(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    if (id == null) return null;

    // 解析 metadata 中的路径和名称
    final metadata = data['metadata'] as Map<String, dynamic>?;
    String? projectPath;
    String projectName = 'Unknown';

    if (metadata != null) {
      // 从 metadata.path 获取路径
      projectPath = metadata['path'] as String?;

      // 从 metadata.summary.text 获取名称，如果没有则从路径提取
      final summary = metadata['summary'] as Map<String, dynamic>?;
      final summaryText = summary?['text'];
      if (summaryText is String && summaryText.isNotEmpty) {
        projectName = summaryText;
      } else if (projectPath != null && projectPath.isNotEmpty) {
        // 从路径提取项目名称（取最后一部分）
        projectName = projectPath.split('/').last;
      }
    }

    // 如果 metadata 为空，尝试旧版字段
    projectPath ??= data['projectPath'] as String? ?? data['cwd'] as String?;
    if (projectName == 'Unknown') {
      projectName =
          data['projectName'] as String? ??
          data['project'] as String? ??
          'Unknown';
    }

    // 从 active 字段或 status 字段确定状态
    SessionStatus status;
    if (data.containsKey('active')) {
      // hapi 使用 active 布尔值
      final isActive = data['active'] as bool? ?? false;
      status = isActive ? SessionStatus.running : SessionStatus.completed;
    } else {
      // 回退到旧版 status 字符串
      final statusStr = data['status'] as String? ?? 'running';
      status = switch (statusStr) {
        'running' || 'active' => SessionStatus.running,
        'waiting' || 'pending' => SessionStatus.waiting,
        'completed' || 'ended' => SessionStatus.completed,
        _ => SessionStatus.running,
      };
    }

    SessionProgress? progress;
    if (data['progress'] != null) {
      final p = data['progress'] as Map<String, dynamic>;
      progress = SessionProgress(
        current: p['current'] as int? ?? 0,
        total: p['total'] as int? ?? 0,
        currentStep: p['currentStep'] as String?,
      );
    }

    List<TodoItem> todos = [];
    if (data['todos'] != null) {
      todos =
          (data['todos'] as List)
              .map(
                (e) => TodoItem(
                  content: e['content'] as String? ?? '',
                  status: e['status'] as String? ?? 'pending',
                  activeForm: e['activeForm'] as String?,
                ),
              )
              .toList();
    }

    // 解析 agentState
    AgentState? agentState;
    final agentData = data['agentState'] as Map<String, dynamic>?;
    if (agentData != null) {
      agentState = AgentState(
        controlledByUser: agentData['controlledByUser'] as bool? ?? false,
        requests: agentData['requests'] as Map<String, dynamic>? ?? {},
      );
    }

    // 解析 permissionMode 和 modelMode
    final permissionMode = data['permissionMode'] as String? ?? 'default';
    final modelMode = data['modelMode'] as String? ?? 'default';

    // 解析 contextSize (从多个位置尝试)
    int? contextSize;
    // 1. 直接从 data 获取
    contextSize = data['contextSize'] as int?;
    // 2. 从 latestUsage 获取
    if (contextSize == null) {
      final latestUsage = data['latestUsage'] as Map<String, dynamic>?;
      contextSize = latestUsage?['contextSize'] as int?;
    }
    // 3. 从 usage 计算
    if (contextSize == null) {
      final usage = data['usage'] as Map<String, dynamic>?;
      if (usage != null) {
        final inputTokens =
            usage['input_tokens'] as int? ?? usage['inputTokens'] as int? ?? 0;
        final cacheCreation =
            usage['cache_creation_input_tokens'] as int? ??
            usage['cacheCreationInputTokens'] as int? ??
            0;
        final cacheRead =
            usage['cache_read_input_tokens'] as int? ??
            usage['cacheReadInputTokens'] as int? ??
            0;
        contextSize = inputTokens + cacheCreation + cacheRead;
      }
    }

    return Session(
      id: id,
      projectName: projectName,
      projectPath: projectPath,
      status: status,
      progress: progress,
      todos: todos,
      currentTask: data['currentTask'] as String? ?? data['task'] as String?,
      startedAt:
          data['startedAt'] != null
              ? DateTime.tryParse(data['startedAt'] as String) ?? DateTime.now()
              : DateTime.now(),
      lastUpdatedAt: DateTime.now(),
      endedAt:
          data['endedAt'] != null
              ? DateTime.tryParse(data['endedAt'] as String)
              : null,
      toolCallCount:
          data['toolCallCount'] as int? ?? data['toolCalls'] as int? ?? 0,
      agentState: agentState,
      permissionMode: permissionMode,
      modelMode: modelMode,
      contextSize: contextSize,
    );
  }

  /// 初始加载所有会话
  Future<void> loadSessions() async {
    final apiService = _ref.read(hapiApiServiceProvider);
    if (apiService == null) return;

    try {
      final sessionsData = await apiService.getSessions();
      for (final data in sessionsData) {
        final session = _parseHapiSession(data);
        if (session != null) {
          _ref.read(sessionsProvider.notifier).upsertSession(session);
        }
      }
      Log.i('HapiEvent', 'Loaded ${sessionsData.length} sessions');
    } catch (e) {
      Log.e('HapiEvent', 'Failed to load sessions', e);
    }
  }

  /// 加载单个会话的详情（包含 permissionMode 等完整字段）
  Future<void> loadSessionDetail(String sessionId) async {
    final apiService = _ref.read(hapiApiServiceProvider);
    if (apiService == null) return;

    try {
      final data = await apiService.getSession(sessionId);
      if (data != null) {
        final newSession = _parseHapiSession(data);
        if (newSession != null) {
          // 保留现有 session 的 contextSize（如果新数据中为 null）
          final sessions = _ref.read(sessionsProvider);
          final existingSession = sessions.firstWhereOrNull(
            (s) => s.id == newSession.id,
          );
          final mergedSession =
              existingSession != null && newSession.contextSize == null
                  ? newSession.copyWith(
                    contextSize: existingSession.contextSize,
                  )
                  : newSession;
          _ref.read(sessionsProvider.notifier).upsertSession(mergedSession);
        }
      }
    } catch (e) {
      Log.e('HapiEvent', 'Failed to load session detail', e);
    }
  }

  /// 加载会话的消息历史（支持分页获取完整历史）
  Future<void> loadSessionMessages(String sessionId) async {
    final apiService = _ref.read(hapiApiServiceProvider);
    if (apiService == null) return;

    try {
      final allMessages = <Message>[];
      final allRawMessages = <Map<String, dynamic>>[]; // 保存原始数据用于提取 usage
      int? beforeSeq;
      bool hasMore = true;
      int pageCount = 0;
      const int limit = 50;
      const int maxPages = 20;

      while (hasMore && pageCount < maxPages) {
        pageCount++;
        final result = await apiService.getMessages(
          sessionId,
          limit: limit,
          beforeSeq: beforeSeq,
        );

        final messagesList = result['messages'] as List<dynamic>? ?? [];
        final pageInfo = result['page'] as Map<String, dynamic>?;
        hasMore =
            pageInfo?['hasMore'] as bool? ??
            result['hasMore'] as bool? ??
            false;

        if (messagesList.isEmpty) break;

        int? minSeq;

        for (final msgData in messagesList) {
          final msgMap = msgData as Map<String, dynamic>;
          final seq = msgMap['seq'] as int?;
          if (seq != null && (minSeq == null || seq < minSeq)) {
            minSeq = seq;
          }

          // 保存原始消息数据
          allRawMessages.add(msgMap);

          final message = _parseHistoryMessage(msgMap, sessionId);
          if (message != null) {
            allMessages.add(message);
          }
        }

        if (hasMore && minSeq != null) {
          if (beforeSeq != null && beforeSeq == minSeq) break;
          beforeSeq = minSeq;
        } else {
          break;
        }
      }

      _associateToolResults(allMessages);

      if (allMessages.isNotEmpty) {
        _ref
            .read(messagesProvider.notifier)
            .setSessionMessages(sessionId, allMessages);

        // 从原始消息数据中提取 contextSize（从后往前找第一个包含 usage 的消息）
        _extractAndUpdateContextSize(sessionId, allRawMessages);
      }

      Log.i('HapiEvent', 'Loaded $sessionId: ${allMessages.length} msgs');
    } catch (e) {
      Log.e('HapiEvent', 'Failed to load session messages', e);
    }
  }

  /// 从原始消息列表中提取 contextSize 并更新 session
  /// 从后往前遍历，找到第一个包含 usage 数据的消息
  void _extractAndUpdateContextSize(
    String sessionId,
    List<Map<String, dynamic>> rawMessages,
  ) {
    for (var i = rawMessages.length - 1; i >= 0; i--) {
      final msgData = rawMessages[i];

      // 尝试提取 usage 数据（参考 _updateSessionContextSize 的逻辑）
      Map<String, dynamic>? usage;

      // 1. 直接在消息顶层
      usage = msgData['usage'] as Map<String, dynamic>?;

      // 2. 在 content 中
      if (usage == null) {
        final content = msgData['content'];
        if (content is Map<String, dynamic>) {
          usage = content['usage'] as Map<String, dynamic>?;

          // 3. 在 content.content.data 中（output 消息）
          if (usage == null) {
            final innerContent = content['content'];
            if (innerContent is Map<String, dynamic>) {
              final data = innerContent['data'];
              if (data is Map<String, dynamic>) {
                final message = data['message'];
                if (message is Map<String, dynamic>) {
                  usage = message['usage'] as Map<String, dynamic>?;
                }
              }
            }
          }
        }
      }

      if (usage != null) {
        final inputTokens =
            usage['input_tokens'] as int? ?? usage['inputTokens'] as int? ?? 0;
        final cacheCreation =
            usage['cache_creation_input_tokens'] as int? ??
            usage['cacheCreationInputTokens'] as int? ??
            0;
        final cacheRead =
            usage['cache_read_input_tokens'] as int? ??
            usage['cacheReadInputTokens'] as int? ??
            0;
        final contextSize = inputTokens + cacheCreation + cacheRead;

        if (contextSize > 0) {
          final sessions = _ref.read(sessionsProvider);
          final session = sessions.firstWhereOrNull((s) => s.id == sessionId);
          if (session != null) {
            _ref
                .read(sessionsProvider.notifier)
                .upsertSession(session.copyWith(contextSize: contextSize));
            Log.i(
              'HapiEvent',
              'Extracted context size from history: $contextSize (msg #${i + 1}/${rawMessages.length})',
            );
          }
        }
        return; // 找到第一个就返回
      }
    }

    Log.v(
      'HapiEvent',
      'No usage data found in ${rawMessages.length} history messages',
    );
  }

  /// 解析历史消息（从 /api/sessions/{id}/messages API）
  ///
  /// hapi 返回的消息格式有两种类型：
  ///
  /// 1. Output 消息 (content.content.type = "output"):
  /// {
  ///   "id": "xxx",
  ///   "content": {
  ///     "role": "agent",
  ///     "content": {
  ///       "type": "output",
  ///       "data": {
  ///         "type": "assistant" | "user",
  ///         "parentUuid": "xxx",
  ///         "uuid": "xxx",
  ///         "isSidechain": true | false,
  ///         "message": { "role": "...", "content": [...] }
  ///       }
  ///     }
  ///   },
  ///   "createdAt": 1767844596809
  /// }
  ///
  /// 2. Event 消息 (content.content.type = "event"):
  /// {
  ///   "id": "xxx",
  ///   "content": {
  ///     "role": "agent",
  ///     "content": {
  ///       "id": "xxx",
  ///       "type": "event",
  ///       "data": { "type": "ready" | "switch" | "message", ... }
  ///     }
  ///   }
  /// }
  Message? _parseHistoryMessage(Map<String, dynamic> data, String sessionId) {
    try {
      final id = data['id'] as String?;
      if (id == null) return null;

      final createdAtMs = data['createdAt'] as int?;
      final createdAt =
          createdAtMs != null
              ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
              : DateTime.now();

      // content 可能是 String 或 Map
      final contentField = data['content'];
      if (contentField == null) return null;

      // 如果 content 是简单字符串，直接作为 Markdown 消息
      if (contentField is String) {
        if (contentField.isEmpty) return null;
        return Message(
          id: id,
          sessionId: sessionId,
          payload: MarkdownPayload(title: 'Claude', content: contentField),
          projectName: 'hapi',
          createdAt: createdAt,
          role: 'assistant',
        );
      }

      // 解析嵌套的 content 结构
      final contentWrapper = contentField as Map<String, dynamic>?;
      if (contentWrapper == null) return null;

      // ========== 关键修复：首先检查 content.role ==========
      // hapi API 消息格式：
      // 用户: { content: { role: 'user', content: { type: 'text', text: '...' } } }
      // Agent: { content: { role: 'agent', content: { type: 'output'|'event', data: {...} } } }
      final role = contentWrapper['role'] as String?;
      if (role == 'user') {
        // 用户消息：从 content.content 中提取文本
        return _parseHistoryUserMessage(
          data,
          contentWrapper,
          id,
          sessionId,
          createdAt,
        );
      }

      // innerContent 也可能是 String
      final innerContentField = contentWrapper['content'];
      if (innerContentField == null) return null;

      if (innerContentField is String) {
        if (innerContentField.isEmpty) return null;
        return Message(
          id: id,
          sessionId: sessionId,
          payload: MarkdownPayload(title: 'Claude', content: innerContentField),
          projectName: 'hapi',
          createdAt: createdAt,
          role: 'assistant',
        );
      }

      final innerContent = innerContentField as Map<String, dynamic>?;
      if (innerContent == null) return null;

      // ========== 检查消息类型是 "output" 还是 "event" ==========
      final contentType = innerContent['type'] as String?;

      // Event 消息：ready, switch, message 等系统事件
      if (contentType == 'event') {
        final eventData = innerContent['data'] as Map<String, dynamic>?;
        if (eventData == null) return null;

        final eventType = eventData['type'] as String?;
        // 跳过系统事件消息（ready, switch 等不需要显示在聊天中）
        if (eventType == 'ready' || eventType == 'switch') {
          return null;
        }

        // 其他事件类型（如 message）可以创建系统消息
        final eventMessage = eventData['message'] as String?;
        if (eventMessage != null && eventMessage.isNotEmpty) {
          return Message(
            id: id,
            sessionId: sessionId,
            payload: MarkdownPayload(title: '系统消息', content: eventMessage),
            projectName: 'hapi',
            createdAt: createdAt,
            role: 'system',
          );
        }
        return null;
      }

      // Output 消息：正常的聊天消息
      if (contentType != 'output') {
        return null;
      }

      // 解析 output 消息的 data 字段
      final innerDataField = innerContent['data'];
      if (innerDataField == null) return null;

      if (innerDataField is String) {
        if (innerDataField.isEmpty) return null;
        return Message(
          id: id,
          sessionId: sessionId,
          payload: MarkdownPayload(title: 'Claude', content: innerDataField),
          projectName: 'hapi',
          createdAt: createdAt,
          role: 'assistant',
        );
      }

      final innerData = innerDataField as Map<String, dynamic>?;
      if (innerData == null) return null;

      final msgType = innerData['type'] as String?; // "assistant" or "user"

      // 提取 parentUuid 和 isSidechain 用于 Task 子任务折叠
      final parentUuid = innerData['parentUuid'] as String?;
      final contentUuid = innerData['uuid'] as String?;
      final isSidechain = innerData['isSidechain'] as bool? ?? false;
      // taskPrompt 用于 sidechain root 匹配 Task
      final taskPrompt =
          innerData['taskPrompt'] as String? ?? innerData['prompt'] as String?;

      // message 也可能是 String
      final messageField = innerData['message'];
      if (messageField == null) {
        // 关键修复：对于没有 message 字段但有 uuid 的 sidechain 消息，创建占位符以保留链
        if (isSidechain && contentUuid != null) {
          return Message(
            id: id,
            sessionId: sessionId,
            payload: const MarkdownPayload(title: 'Processing...', content: ''),
            projectName: 'hapi',
            createdAt: createdAt,
            role: 'assistant',
            parentId: parentUuid,
            contentUuid: contentUuid,
            isSidechain: isSidechain,
            taskPrompt: taskPrompt,
          );
        }
        return null;
      }

      if (messageField is String) {
        if (messageField.isEmpty) return null;
        return Message(
          id: id,
          sessionId: sessionId,
          payload:
              msgType == 'user'
                  ? UserMessagePayload(content: messageField)
                  : MarkdownPayload(title: 'Claude', content: messageField),
          projectName: 'hapi',
          createdAt: createdAt,
          role: msgType ?? 'assistant',
          parentId: parentUuid,
          contentUuid: contentUuid,
          isSidechain: isSidechain,
          taskPrompt: taskPrompt,
        );
      }

      final messageObj = messageField as Map<String, dynamic>?;
      if (messageObj == null) return null;

      // 根据消息类型分别处理
      if (msgType == 'user') {
        return _parseUserHistoryMessage(
          id,
          sessionId,
          messageObj,
          createdAt,
          parentUuid,
          contentUuid,
          isSidechain,
          taskPrompt,
        );
      } else {
        return _parseAssistantHistoryMessage(
          id,
          sessionId,
          messageObj,
          createdAt,
          parentUuid,
          contentUuid,
          isSidechain,
          taskPrompt,
        );
      }
    } catch (e) {
      Log.e('HapiEvent', 'Failed to parse history message', e);
      return null;
    }
  }

  /// 解析用户历史消息 → UserMessagePayload
  ///
  /// 用户消息的 content 可能包含多种类型：
  /// - type: "text" → 普通文本消息
  /// - type: "tool_result" → 工具执行结果（最常见）
  ///
  /// tool_result 结构：
  /// {
  ///   "tool_use_id": "toolu_xxx",
  ///   "type": "tool_result",
  ///   "content": "工具执行结果文本..."
  /// }
  Message? _parseUserHistoryMessage(
    String id,
    String sessionId,
    Map<String, dynamic> messageObj,
    DateTime createdAt,
    String? parentId,
    String? contentUuid,
    bool isSidechain,
    String? taskPrompt,
  ) {
    final contentList = messageObj['content'];

    // ========== 关键修复：处理 sidechain root 消息 ==========
    // 参考 hapi web normalizeAgent.ts:111-119
    // 如果 isSidechain=true 且 content 是字符串，这是 sidechain root
    // 它应该被渲染为用户气泡样式（类似 user-text），但 role 是 assistant
    // 这样它会被 tracer 正确关联到 Task，并显示在 Task 的 children 中
    if (isSidechain && contentList is String && contentList.isNotEmpty) {
      return Message(
        id: id,
        sessionId: sessionId,
        // 使用 UserMessagePayload 但 role 保持 user，这样渲染时显示为用户气泡
        payload: UserMessagePayload(content: contentList),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'user',
        parentId: parentId,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: contentList, // 设置 taskPrompt 用于后续去重
      );
    }

    final contentParts = <String>[];
    final toolResults = <Map<String, dynamic>>[];

    if (contentList is List) {
      for (final item in contentList) {
        if (item is Map<String, dynamic>) {
          final itemType = item['type'] as String?;

          if (itemType == 'text') {
            // 普通文本消息
            final text = item['text'] as String? ?? '';
            if (text.isNotEmpty) {
              contentParts.add(text);
            }
          } else if (itemType == 'tool_result') {
            // ========== tool_result 附加到对应的 tool 块中 ==========
            // 参考 hapi web normalizeAgent.ts:143-158
            final toolUseId = item['tool_use_id'] as String?;
            final isError = item['is_error'] as bool? ?? false;
            final resultContent = _extractToolResultContent(item['content']);
            toolResults.add({
              'tool_use_id': toolUseId,
              'content': resultContent,
              'is_error': isError,
            });
          }
        } else if (item is String) {
          contentParts.add(item);
        }
      }
    } else if (contentList is String) {
      contentParts.add(contentList);
    }

    // 如果有文本内容，创建用户消息
    if (contentParts.isNotEmpty) {
      final content = contentParts.join('\n');

      // ========== sidechain 消息样式区分 ==========
      // 参考 hapi web normalizeAgent.ts 和 reducerTimeline.ts:
      // - sidechain root (content 是字符串): 渲染为 user-text (用户气泡)
      // - sidechain child (content 是数组): 渲染为 agent-text (assistant 样式)
      // seq=4 在上面已处理为 UserMessagePayload
      // seq=7 这里处理：isSidechain=true 且 content 来自数组，转为 MarkdownPayload
      if (isSidechain) {
        return Message(
          id: id,
          sessionId: sessionId,
          payload: MarkdownPayload(title: '', content: content),
          projectName: 'hapi',
          createdAt: createdAt,
          role: 'assistant', // 转为 assistant 角色
          parentId: parentId,
          contentUuid: contentUuid,
          isSidechain: isSidechain,
          taskPrompt: taskPrompt,
        );
      }

      return Message(
        id: id,
        sessionId: sessionId,
        payload: UserMessagePayload(content: content),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'user',
        parentId: parentId,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    }

    // 只有 tool_result（无文本）：收集到 _pendingToolResults，稍后关联
    // 参考 hapi web reducerTimeline.ts:168-219
    if (toolResults.isNotEmpty) {
      // 收集 tool_result 到待处理缓存（阶段1）
      // 阶段2 在 _associateToolResults 中执行
      for (final result in toolResults) {
        final toolUseId = result['tool_use_id'] as String?;
        final content = result['content'] as String?;
        final isError = result['is_error'] as bool? ?? false;
        if (toolUseId != null && content != null && content.isNotEmpty) {
          _bufferManager.addPendingToolResult(toolUseId, {
            'content': content,
            'isError': isError,
          });
        }
      }

      // 返回 HiddenPayload（tool_result 不单独显示在聊天界面）
      final toolUseId = toolResults.first['tool_use_id'] as String?;
      return Message(
        id: id,
        sessionId: sessionId,
        payload: HiddenPayload(reason: 'tool_result', toolUseId: toolUseId),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'user',
        parentId: parentId,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    }

    // 对于 sidechain 消息，即使没有内容也要保留以维持链的完整性
    if (isSidechain && contentUuid != null) {
      return Message(
        id: id,
        sessionId: sessionId,
        payload: const HiddenPayload(reason: 'empty_sidechain'),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'user',
        parentId: parentId,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    }

    return null;
  }

  /// 解析历史记录中的用户消息
  /// hapi 格式: { content: { role: 'user', content: { type: 'text', text: '...' }, meta: {...} } }
  Message _parseHistoryUserMessage(
    Map<String, dynamic> data,
    Map<String, dynamic> contentWrapper,
    String id,
    String sessionId,
    DateTime createdAt,
  ) {
    // 从 content.content 中提取文本
    String textContent = '';
    final innerContent = contentWrapper['content'];

    if (innerContent is String) {
      textContent = innerContent;
    } else if (innerContent is Map<String, dynamic>) {
      // { type: 'text', text: '...' } 格式
      if (innerContent['type'] == 'text') {
        textContent = innerContent['text'] as String? ?? '';
      } else {
        // 其他格式，尝试提取 text 字段
        textContent = innerContent['text'] as String? ?? '';
      }
    } else if (innerContent is List) {
      // 数组格式，提取所有文本
      for (final item in innerContent) {
        if (item is String) {
          textContent += item;
        } else if (item is Map && item['type'] == 'text') {
          textContent += item['text'] as String? ?? '';
        }
      }
    }

    // 解析 meta 信息
    final meta = contentWrapper['meta'] as Map<String, dynamic>?;
    final sentFrom = meta?['sentFrom'] as String?;

    return Message(
      id: id,
      sessionId: sessionId,
      payload: UserMessagePayload(
        content: textContent,
        isPending: false,
        isFailed: false,
      ),
      projectName: 'hapi',
      createdAt: createdAt,
      role: 'user',
    );
  }

  /// 解析 AI 助手历史消息 → MarkdownPayload 或 TaskExecutionPayload
  Message? _parseAssistantHistoryMessage(
    String id,
    String sessionId,
    Map<String, dynamic> messageObj,
    DateTime createdAt,
    String? parentId,
    String? contentUuid,
    bool isSidechain,
    String? taskPrompt,
  ) {
    final contentList = messageObj['content'];
    if (contentList is! List) {
      // 简单字符串内容
      if (contentList is String && contentList.isNotEmpty) {
        return Message(
          id: id,
          sessionId: sessionId,
          payload: MarkdownPayload(title: 'Claude', content: contentList),
          projectName: 'hapi',
          createdAt: createdAt,
          role: 'assistant',
          parentId: parentId,
          contentUuid: contentUuid,
          isSidechain: isSidechain,
          taskPrompt: taskPrompt,
        );
      }
      // 关键修复：contentList 不是 List 也不是非空 String，但是 sidechain 消息需要保留
      if (isSidechain && contentUuid != null) {
        return Message(
          id: id,
          sessionId: sessionId,
          payload: const MarkdownPayload(title: 'Processing...', content: ''),
          projectName: 'hapi',
          createdAt: createdAt,
          role: 'assistant',
          parentId: parentId,
          contentUuid: contentUuid,
          isSidechain: isSidechain,
          taskPrompt: taskPrompt,
        );
      }
      return null;
    }

    // contentList 是 List 但可能为空
    if (contentList.isEmpty) {
      if (isSidechain && contentUuid != null) {
        return Message(
          id: id,
          sessionId: sessionId,
          payload: const MarkdownPayload(title: 'Processing...', content: ''),
          projectName: 'hapi',
          createdAt: createdAt,
          role: 'assistant',
          parentId: parentId,
          contentUuid: contentUuid,
          isSidechain: isSidechain,
          taskPrompt: taskPrompt,
        );
      }
      return null;
    }

    // 收集文本内容、思维链内容和工具调用
    final textParts = <String>[];
    final thinkingParts = <String>[]; // 思维链内容
    final toolCalls = <TaskItem>[];
    String? firstToolName;
    String? extractedTaskPrompt; // 从 Task 工具调用中提取的 prompt

    for (final item in contentList) {
      if (item is! Map<String, dynamic>) continue;

      final itemType = item['type'] as String?;

      if (itemType == 'text') {
        final text = item['text'] as String? ?? '';
        if (text.isNotEmpty) {
          textParts.add(text);
        }
      } else if (itemType == 'thinking') {
        // 思维链内容 - hapi 格式: { type: 'thinking', thinking: '...', signature: '...' }
        final thinking = item['thinking'] as String? ?? '';
        if (thinking.isNotEmpty) {
          thinkingParts.add(thinking);
        }
      } else if (itemType == 'tool_use') {
        final toolName = item['name'] as String? ?? 'unknown';
        final toolId = item['id'] as String? ?? '';
        firstToolName ??= toolName;

        // 构建任务项
        final input = item['input'] as Map<String, dynamic>?;
        String? filePath;
        String? description;

        // 尝试从输入中提取文件路径
        if (input != null) {
          filePath =
              input['file_path'] as String? ??
              input['path'] as String? ??
              input['filename'] as String?;
          // 构建描述
          description = _formatToolInputBrief(input);

          // ========== 关键修复：提取 Task 工具的 prompt ==========
          // 参考 hapi web tracer.ts: Task 工具的 input.prompt 用于 sidechain 匹配
          if (toolName == 'Task') {
            extractedTaskPrompt = input['prompt'] as String?;
            if (extractedTaskPrompt != null) {
              final shortPrompt =
                  extractedTaskPrompt.length > 50
                      ? extractedTaskPrompt.substring(0, 50)
                      : extractedTaskPrompt;
            }
          }
        }

        toolCalls.add(
          TaskItem(
            id: toolId,
            name: toolName,
            status: TaskItemStatus.completed, // 历史消息都是已完成的
            filePath: filePath,
            description: description,
            toolName: toolName,
            input: input, // 存储完整 input 用于专用视图渲染
            inputSummary: _formatToolInputBrief(input),
          ),
        );
      } else if (itemType == 'tool_result') {
        // 工具结果 - 更新对应工具的状态
        final toolUseId = item['tool_use_id'] as String?;
        final isError = item['is_error'] as bool? ?? false;
        // content 可能是字符串或数组 [{"type": "text", "text": "..."}]
        final rawContent = item['content'];
        final resultContent = _extractToolResultContent(rawContent);

        if (toolUseId != null) {
          // 查找并更新对应的 TaskItem
          final index = toolCalls.indexWhere((t) => t.id == toolUseId);
          if (index >= 0) {
            toolCalls[index] = toolCalls[index].copyWith(
              status: isError ? TaskItemStatus.error : TaskItemStatus.completed,
              hasError: isError,
              outputSummary: resultContent,
              errorMessage: isError ? resultContent : null,
            );
          }
        }
      }
    }

    // 决定返回什么类型的 Payload
    if (toolCalls.isNotEmpty) {
      // 有工具调用 → TaskExecutionPayload
      final hasError = toolCalls.any((t) => t.hasError);
      final allCompleted = toolCalls.every(
        (t) =>
            t.status == TaskItemStatus.completed ||
            t.status == TaskItemStatus.error,
      );

      // 使用提取的 Task prompt（用于 sidechain 分组匹配）
      final effectivePrompt = extractedTaskPrompt ?? taskPrompt;

      return Message(
        id: id,
        sessionId: sessionId,
        payload: TaskExecutionPayload(
          title:
              toolCalls.length == 1
                  ? '执行: ${toolCalls.first.name}'
                  : '执行 ${toolCalls.length} 个工具',
          tasks: toolCalls,
          overallStatus:
              hasError
                  ? TaskStatus.error
                  : (allCompleted ? TaskStatus.completed : TaskStatus.running),
          summary: textParts.isNotEmpty ? textParts.join('\n') : null,
          prompt: effectivePrompt, // 关键：存储 Task 的 prompt 用于 sidechain 匹配
        ),
        projectName: 'hapi',
        toolName: firstToolName,
        createdAt: createdAt,
        role: 'assistant',
        parentId: parentId,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: effectivePrompt,
      );
    } else if (textParts.isNotEmpty) {
      // 只有文本 → MarkdownPayload
      return Message(
        id: id,
        sessionId: sessionId,
        payload: MarkdownPayload(
          title: 'Claude',
          content: textParts.join('\n'),
        ),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'assistant',
        parentId: parentId,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    } else if (thinkingParts.isNotEmpty) {
      // 只有思维链 → ThinkingPayload（可折叠显示）
      return Message(
        id: id,
        sessionId: sessionId,
        payload: ThinkingPayload(
          content: thinkingParts.join('\n'),
          streamingStatus: StreamingStatus.complete,
        ),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'assistant',
        parentId: parentId,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    }

    // 没有 toolCalls、textParts 或 thinkingParts，返回空的 MarkdownPayload 保留消息链
    if (isSidechain && contentUuid != null) {
      return Message(
        id: id,
        sessionId: sessionId,
        payload: const MarkdownPayload(title: 'Processing...', content: ''),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'assistant',
        parentId: parentId,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    }

    return null;
  }

  /// 格式化工具输入参数（简短版）
  String? _formatToolInputBrief(Map<String, dynamic>? input) {
    if (input == null) return null;
    final buffer = StringBuffer();
    int count = 0;
    for (final entry in input.entries) {
      final value = entry.value;
      final valueStr = value.toString();
      if (count > 0) buffer.write(', ');
      buffer.write('${entry.key}: $valueStr');
      count++;
    }
    return buffer.toString();
  }

  /// 解析 hapi 消息为 Message 对象
  /// 支持多种消息类型：
  /// - user: 用户消息 → UserMessagePayload
  /// - assistant: AI 响应 → MarkdownPayload 或 TaskExecutionPayload
  /// - tool_use: 工具调用 → TaskExecutionPayload
  /// - progress/complete/error/warning/code: 特定类型消息
  Message? _parseHapiMessage(Map<String, dynamic> data, String? sessionId) {
    if (sessionId == null) {
      Log.w('HapiEvent', 'sessionId is null, skipping message');
      return null;
    }

    final id =
        data['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final projectName = data['projectName'] as String? ?? 'hapi';

    // 解析 parentUuid 用于 Task 子任务折叠
    // hapi 的消息结构: { content: { role: 'user'|'agent', content: { type: '...', ... } } }
    String? parentId =
        data['parentUuid'] as String? ?? data['parentId'] as String?;
    String? contentUuid = data['uuid'] as String?; // 提取 contentUuid
    bool isSidechain = data['isSidechain'] as bool? ?? false;

    // 从嵌套的 content.data 中提取 parentUuid、uuid 和 isSidechain
    final content = data['content'];
    if (content is Map<String, dynamic>) {
      final contentData = content['data'];
      if (contentData is Map<String, dynamic>) {
        parentId ??= contentData['parentUuid'] as String?;
        contentUuid ??= contentData['uuid'] as String?;
        isSidechain =
            isSidechain || (contentData['isSidechain'] as bool? ?? false);
      }
    }

    // 解析 taskPrompt（用于 sidechain root 匹配）
    // 参考 hapi web tracer.ts: sidechain root 通过 prompt 匹配到 Task
    String? taskPrompt;
    final sidechainContent = content;
    if (sidechainContent is Map<String, dynamic>) {
      // 尝试从 sidechain content 中提取 prompt
      taskPrompt = sidechainContent['prompt'] as String?;
    }

    // ========== 关键修复：首先检查 content.role ==========
    // hapi API 返回的消息结构：
    // { content: { role: 'user', content: { type: 'text', text: '...' } } }
    // { content: { role: 'agent', content: { type: 'output'|'event', data: {...} } } }
    if (content is Map<String, dynamic>) {
      final role = content['role'] as String?;
      if (role == 'user') {
        // 用户消息：从 content.content 中提取文本
        return _parseHapiUserMessage(
          data,
          content,
          id,
          sessionId,
          projectName,
          parentId,
          contentUuid,
        );
      }
      // agent 消息：继续按 type 处理
    }

    // 获取消息类型（可能在顶层或 content.content.type 中）
    String type = data['type'] as String? ?? 'markdown';
    if (content is Map<String, dynamic>) {
      final innerContent = content['content'];
      if (innerContent is Map<String, dynamic>) {
        type = innerContent['type'] as String? ?? type;
      }
    }

    // 根据消息类型分别处理（参考 hapi web 的 normalize.ts）
    Message? message;
    switch (type) {
      // 用户消息 → UserMessagePayload（兼容旧格式）
      case 'user':
      case 'userMessage':
        message = _parseUserMessage(
          data,
          id,
          sessionId,
          projectName,
          parentId,
          contentUuid,
        );
        break;

      // AI 助手输出 → MarkdownPayload 或 TaskExecutionPayload
      case 'assistant':
      case 'output':
        message = _parseAssistantOutput(
          data,
          id,
          sessionId,
          projectName,
          parentId,
          contentUuid,
        );
        break;

      // 工具调用事件 → TaskExecutionPayload
      case 'tool_use':
      case 'toolCall':
        message = _parseToolUseMessage(
          data,
          id,
          sessionId,
          projectName,
          parentId,
          contentUuid,
        );
        break;

      // 工具结果 → 更新现有工具状态
      case 'tool_result':
      case 'toolResult':
        _handleToolResult(data, sessionId);
        return null; // 不创建新消息，而是更新现有消息

      // 进度消息
      case 'progress':
        message = _parseProgressMessage(
          data,
          id,
          sessionId,
          projectName,
          parentId,
          contentUuid,
        );
        break;

      // 完成消息
      case 'complete':
        message = _parseCompleteMessage(
          data,
          id,
          sessionId,
          projectName,
          parentId,
          contentUuid,
        );
        break;

      // 错误消息
      case 'error':
        message = _parseErrorMessage(
          data,
          id,
          sessionId,
          projectName,
          parentId,
          contentUuid,
        );
        break;

      // 警告消息
      case 'warning':
        message = _parseWarningMessage(
          data,
          id,
          sessionId,
          projectName,
          parentId,
          contentUuid,
        );
        break;

      // 代码消息
      case 'code':
        message = _parseCodeMessage(
          data,
          id,
          sessionId,
          projectName,
          parentId,
          contentUuid,
        );
        break;

      // 事件消息（系统事件、状态变更等）
      case 'event':
      case 'system':
        message = _parseEventMessage(
          data,
          id,
          sessionId,
          projectName,
          parentId,
          contentUuid,
        );
        break;

      // 默认：Markdown 消息
      default:
        message = _parseDefaultMessage(
          data,
          id,
          sessionId,
          projectName,
          type,
          parentId,
          contentUuid,
        );
    }

    // 添加 isSidechain 和 taskPrompt
    if (message != null && (isSidechain || taskPrompt != null)) {
      message = message.copyWith(
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    }

    return message;
  }

  /// 解析 hapi API 格式的用户消息
  /// hapi 格式: { content: { role: 'user', content: { type: 'text', text: '...' }, meta: {...} } }
  Message _parseHapiUserMessage(
    Map<String, dynamic> data,
    Map<String, dynamic> contentWrapper,
    String id,
    String sessionId,
    String projectName,
    String? parentId,
    String? contentUuid,
  ) {
    // 从 content.content 中提取文本
    String textContent = '';
    final innerContent = contentWrapper['content'];

    if (innerContent is String) {
      textContent = innerContent;
    } else if (innerContent is Map<String, dynamic>) {
      // { type: 'text', text: '...' } 格式
      if (innerContent['type'] == 'text') {
        textContent = innerContent['text'] as String? ?? '';
      } else {
        // 其他格式，尝试提取 text 字段
        textContent = innerContent['text'] as String? ?? '';
      }
    } else if (innerContent is List) {
      // 数组格式，提取所有文本
      for (final item in innerContent) {
        if (item is String) {
          textContent += item;
        } else if (item is Map && item['type'] == 'text') {
          textContent += item['text'] as String? ?? '';
        }
      }
    }

    // 解析 meta 信息
    final meta = contentWrapper['meta'] as Map<String, dynamic>?;
    final sentFrom = meta?['sentFrom'] as String?;

    return Message(
      id: id,
      sessionId: sessionId,
      payload: UserMessagePayload(
        content: textContent,
        isPending: false, // 从服务器返回的消息已发送成功
        isFailed: false,
      ),
      projectName: projectName,
      createdAt: _parseTimestamp(data['createdAt']),
      role: 'user',
      parentId: parentId,
      contentUuid: contentUuid,
    );
  }

  /// 解析用户消息 → UserMessagePayload（兼容旧格式）
  /// 参考 hapi web: normalizeUser.ts
  Message _parseUserMessage(
    Map<String, dynamic> data,
    String id,
    String sessionId,
    String projectName,
    String? parentId,
    String? contentUuid,
  ) {
    // 提取文本内容
    String content = '';
    final contentField = data['content'] ?? data['message'] ?? data['text'];

    if (contentField is String) {
      content = contentField;
    } else if (contentField is Map) {
      // { type: 'text', text: '...' } 格式
      if (contentField['type'] == 'text') {
        content = contentField['text'] as String? ?? '';
      }
    } else if (contentField is List) {
      // 数组格式，提取所有文本
      for (final item in contentField) {
        if (item is String) {
          content += item;
        } else if (item is Map && item['type'] == 'text') {
          content += item['text'] as String? ?? '';
        }
      }
    }

    // 解析消息状态（sending/sent/failed）
    final statusStr = data['status'] as String?;
    final isPending = statusStr == 'sending';
    final isFailed = statusStr == 'failed';
    final failureReason =
        data['failureReason'] as String? ?? data['error'] as String?;

    return Message(
      id: id,
      sessionId: sessionId,
      payload: UserMessagePayload(
        content: content,
        isPending: isPending,
        isFailed: isFailed,
        failureReason: isFailed ? (failureReason ?? '发送失败') : null,
      ),
      projectName: projectName,
      createdAt: _parseTimestamp(data['createdAt']),
      role: 'user',
      parentId: parentId,
      contentUuid: contentUuid,
    );
  }

  /// 解析 AI 助手输出
  /// 参考 hapi web: normalizeAgent.ts - normalizeAssistantOutput()
  Message? _parseAssistantOutput(
    Map<String, dynamic> data,
    String id,
    String sessionId,
    String projectName,
    String? parentId,
    String? contentUuid,
  ) {
    final contentField = data['content'] ?? data['message'];

    // 简单字符串 → MarkdownPayload
    if (contentField is String) {
      if (contentField.isEmpty) return null;
      return Message(
        id: id,
        sessionId: sessionId,
        payload: MarkdownPayload(
          title: data['title'] as String? ?? 'Claude',
          content: contentField,
        ),
        projectName: projectName,
        createdAt: _parseTimestamp(data['createdAt']),
        role: 'assistant',
        parentId: parentId,
        contentUuid: contentUuid,
      );
    }

    // 数组格式 → 可能包含文本和工具调用
    if (contentField is List) {
      final textParts = <String>[];
      final toolCalls = <TaskItem>[];
      String? firstToolName;

      for (final item in contentField) {
        if (item is! Map<String, dynamic>) continue;

        final itemType = item['type'] as String?;

        switch (itemType) {
          case 'text':
            final text = item['text'] as String? ?? '';
            if (text.isNotEmpty) textParts.add(text);
            break;

          case 'thinking':
          case 'reasoning':
            // 推理内容，可以包含在文本中
            final thinking =
                item['text'] as String? ?? item['thinking'] as String? ?? '';
            if (thinking.isNotEmpty) {
              textParts.add(
                '<details><summary>思考过程</summary>\n\n$thinking\n\n</details>',
              );
            }
            break;

          case 'tool_use':
            final toolItem = _parseToolUseItem(item);
            if (toolItem != null) {
              toolCalls.add(toolItem);
              firstToolName ??= toolItem.toolName;
            }
            break;
        }
      }

      // 决定返回类型
      if (toolCalls.isNotEmpty) {
        // 有工具调用 → TaskExecutionPayload
        return Message(
          id: id,
          sessionId: sessionId,
          payload: TaskExecutionPayload(
            title: _buildToolCallTitle(toolCalls),
            tasks: toolCalls,
            overallStatus: _calculateOverallStatus(toolCalls),
            summary: textParts.isNotEmpty ? textParts.join('\n\n') : null,
          ),
          projectName: projectName,
          toolName: firstToolName,
          createdAt: _parseTimestamp(data['createdAt']),
          role: 'assistant',
          parentId: parentId,
          contentUuid: contentUuid,
        );
      } else if (textParts.isNotEmpty) {
        // 纯文本 → MarkdownPayload
        return Message(
          id: id,
          sessionId: sessionId,
          payload: MarkdownPayload(
            title: data['title'] as String? ?? 'Claude',
            content: textParts.join('\n\n'),
          ),
          projectName: projectName,
          createdAt: _parseTimestamp(data['createdAt']),
          role: 'assistant',
          parentId: parentId,
          contentUuid: contentUuid,
        );
      }
    }

    return null;
  }

  /// 解析单个工具调用项
  /// 参考 hapi web: normalizeAgent.ts L64-68
  TaskItem? _parseToolUseItem(Map<String, dynamic> item) {
    final toolId = item['id'] as String?;
    final toolName = item['name'] as String? ?? 'unknown';

    if (toolId == null) return null;

    final input = item['input'] as Map<String, dynamic>?;

    // 提取文件路径（多种可能的字段名）
    String? filePath;
    if (input != null) {
      filePath =
          input['file_path'] as String? ??
          input['path'] as String? ??
          input['filename'] as String? ??
          input['file'] as String? ??
          input['command'] as String?; // 对于 Bash 工具
    }

    // 提取描述
    final description =
        item['description'] as String? ??
        (input != null ? _formatToolInputDetailed(input) : null);

    // 解析状态
    final stateStr = item['state'] as String? ?? 'pending';
    final status = _parseToolItemStatus(stateStr);

    return TaskItem(
      id: toolId,
      name: _getToolDisplayName(toolName),
      status: status,
      filePath: filePath,
      description: description,
      toolName: toolName,
      input: input, // 存储完整 input 用于专用视图渲染
      inputSummary: input != null ? _formatToolInputBrief(input) : null,
      durationMs: item['duration'] as int?,
      hasError: item['is_error'] as bool? ?? false,
      errorMessage: item['error'] as String?,
    );
  }

  /// 解析工具调用消息（单独的 tool_use 事件）
  Message _parseToolUseMessage(
    Map<String, dynamic> data,
    String id,
    String sessionId,
    String projectName,
    String? parentId,
    String? contentUuid,
  ) {
    final toolItem = _parseToolUseItem(data);

    if (toolItem == null) {
      // 回退到基本消息
      return Message(
        id: id,
        sessionId: sessionId,
        payload: MarkdownPayload(
          title: '工具调用',
          content: data['name'] as String? ?? 'unknown',
        ),
        projectName: projectName,
        createdAt: _parseTimestamp(data['createdAt']),
        role: 'assistant',
        parentId: parentId,
        contentUuid: contentUuid,
      );
    }

    return Message(
      id: id,
      sessionId: sessionId,
      payload: TaskExecutionPayload(
        title: '执行: ${toolItem.name}',
        tasks: [toolItem],
        overallStatus: _statusToTaskStatus(toolItem.status),
      ),
      projectName: projectName,
      toolName: toolItem.toolName,
      createdAt: _parseTimestamp(data['createdAt']),
      role: 'assistant',
      parentId: parentId,
      contentUuid: contentUuid,
    );
  }

  /// 从 tool_result 的 content 提取文本
  /// content 可能是:
  /// - 字符串: "result text"
  /// - 数组: [{"type": "text", "text": "result text"}]
  String _extractToolResultContent(dynamic content) {
    if (content == null) return '';
    if (content is String) return content;
    if (content is List) {
      final texts = <String>[];
      for (final item in content) {
        if (item is Map) {
          final text = item['text'] as String?;
          if (text != null) texts.add(text);
        }
      }
      return texts.join('\n');
    }
    return content.toString();
  }

  /// 处理工具结果事件 → 更新现有 TaskExecutionPayload
  /// 参考 hapi web: reducerTools.ts
  void _handleToolResult(Map<String, dynamic> data, String sessionId) {
    final toolUseId = data['tool_use_id'] as String? ?? data['id'] as String?;
    if (toolUseId == null) return;

    final isError = data['is_error'] as bool? ?? false;
    // content 可能是字符串或数组 [{"type": "text", "text": "..."}]
    final rawContent = data['content'];
    final resultSummary = _extractToolResultContent(rawContent);

    // 查找并更新包含此工具调用的消息
    final messages = _ref.read(messagesProvider);
    for (final message in messages.where((m) => m.sessionId == sessionId)) {
      final payload = message.payload;
      if (payload is TaskExecutionPayload) {
        final taskIndex = payload.tasks.indexWhere((t) => t.id == toolUseId);
        if (taskIndex >= 0) {
          // 更新任务项
          final updatedTasks = List<TaskItem>.from(payload.tasks);
          updatedTasks[taskIndex] = updatedTasks[taskIndex].copyWith(
            status: isError ? TaskItemStatus.error : TaskItemStatus.completed,
            hasError: isError,
            outputSummary: resultSummary,
            errorMessage: isError ? resultSummary : null,
          );

          // 更新消息
          _ref
              .read(messagesProvider.notifier)
              .updateMessage(
                message.id,
                (m) => m.copyWith(
                  payload: payload.copyWith(
                    tasks: updatedTasks,
                    overallStatus: _calculateOverallStatus(updatedTasks),
                  ),
                ),
              );
          return;
        }
      }
    }
  }

  /// 阶段2: 关联 tool_result 到对应的 TaskItem
  /// 参考 hapi web reducerTimeline.ts:168-219
  /// 在所有消息解析完成后，遍历消息列表将收集的 tool_result 关联到 tool_use
  void _associateToolResults(List<Message> messages) {
    // 使用 BufferManager 检查待处理结果
    if (!_bufferManager.hasPendingToolResults()) {
      return;
    }

    for (final message in messages) {
      final payload = message.payload;
      if (payload is! TaskExecutionPayload) continue;

      var updated = false;
      final updatedTasks = List<TaskItem>.from(payload.tasks);

      for (var i = 0; i < updatedTasks.length; i++) {
        final task = updatedTasks[i];
        final result = _bufferManager.getPendingToolResult(task.id);
        if (result == null) continue;

        final content = result['content'] as String? ?? '';
        final isError = result['isError'] as bool? ?? false;

        updatedTasks[i] = task.copyWith(
          status: isError ? TaskItemStatus.error : TaskItemStatus.completed,
          outputSummary: content,
          hasError: isError,
          errorMessage: isError ? content : null,
        );
        updated = true;

        // 从待处理列表中移除
        _bufferManager.removePendingToolResult(task.id);
      }

      if (updated) {
        // 直接修改 message 的 payload（messages 列表尚未添加到 provider）
        final idx = messages.indexOf(message);
        if (idx >= 0) {
          messages[idx] = message.copyWith(
            payload: payload.copyWith(
              tasks: updatedTasks,
              overallStatus: _calculateOverallStatus(updatedTasks),
            ),
          );
        }
      }
    }

    // 清理剩余未匹配的 tool_result
    _bufferManager.clearPendingToolResults();
  }

  /// 解析进度消息
  Message _parseProgressMessage(
    Map<String, dynamic> data,
    String id,
    String sessionId,
    String projectName,
    String? parentId,
    String? contentUuid,
  ) {
    final content =
        data['content'] as String? ?? data['message'] as String? ?? '';
    final title = data['title'] as String? ?? '进度更新';

    return Message(
      id: id,
      sessionId: sessionId,
      payload: ProgressPayload(
        title: title,
        description: content.isNotEmpty ? content : null,
        current: data['current'] as int? ?? 0,
        total: data['total'] as int? ?? 0,
        currentStep: data['currentStep'] as String? ?? data['step'] as String?,
      ),
      projectName: projectName,
      createdAt: _parseTimestamp(data['createdAt']),
      role: 'assistant',
      parentId: parentId,
      contentUuid: contentUuid,
    );
  }

  /// 解析完成消息
  Message _parseCompleteMessage(
    Map<String, dynamic> data,
    String id,
    String sessionId,
    String projectName,
    String? parentId,
    String? contentUuid,
  ) {
    final content =
        data['content'] as String? ?? data['message'] as String? ?? '';
    final title = data['title'] as String? ?? '任务完成';

    return Message(
      id: id,
      sessionId: sessionId,
      payload: CompletePayload(
        title: title,
        summary: content.isNotEmpty ? content : data['summary'] as String?,
        duration: data['duration'] as int? ?? data['durationMs'] as int?,
        toolCount: data['toolCount'] as int? ?? data['toolCalls'] as int?,
      ),
      projectName: projectName,
      createdAt: _parseTimestamp(data['createdAt']),
      role: 'assistant',
      parentId: parentId,
      contentUuid: contentUuid,
    );
  }

  /// 解析错误消息
  Message _parseErrorMessage(
    Map<String, dynamic> data,
    String id,
    String sessionId,
    String projectName,
    String? parentId,
    String? contentUuid,
  ) {
    final content =
        data['content'] as String? ?? data['message'] as String? ?? '';
    final title = data['title'] as String? ?? '错误';

    return Message(
      id: id,
      sessionId: sessionId,
      payload: ErrorPayload(
        title: title,
        message: content,
        stackTrace: data['stackTrace'] as String? ?? data['stack'] as String?,
        suggestion: data['suggestion'] as String? ?? data['hint'] as String?,
      ),
      projectName: projectName,
      createdAt: _parseTimestamp(data['createdAt']),
      role: 'assistant',
      parentId: parentId,
      contentUuid: contentUuid,
    );
  }

  /// 解析警告消息
  Message _parseWarningMessage(
    Map<String, dynamic> data,
    String id,
    String sessionId,
    String projectName,
    String? parentId,
    String? contentUuid,
  ) {
    final content =
        data['content'] as String? ?? data['message'] as String? ?? '';
    final title = data['title'] as String? ?? '警告';

    return Message(
      id: id,
      sessionId: sessionId,
      payload: WarningPayload(
        title: title,
        message: content,
        action: data['action'] as String?,
      ),
      projectName: projectName,
      createdAt: _parseTimestamp(data['createdAt']),
      role: 'assistant',
      parentId: parentId,
      contentUuid: contentUuid,
    );
  }

  /// 解析代码消息
  Message _parseCodeMessage(
    Map<String, dynamic> data,
    String id,
    String sessionId,
    String projectName,
    String? parentId,
    String? contentUuid,
  ) {
    final code = data['content'] as String? ?? data['code'] as String? ?? '';
    final title = data['title'] as String? ?? '代码';

    return Message(
      id: id,
      sessionId: sessionId,
      payload: CodePayload(
        title: title,
        code: code,
        language: data['language'] as String? ?? data['lang'] as String?,
        filename: data['filename'] as String? ?? data['file'] as String?,
        startLine: data['startLine'] as int? ?? data['line'] as int?,
      ),
      projectName: projectName,
      createdAt: _parseTimestamp(data['createdAt']),
      role: 'assistant',
      parentId: parentId,
      contentUuid: contentUuid,
    );
  }

  /// 解析事件消息（系统事件、状态变更等）
  /// 参考 hapi web: presentation.ts - getEventPresentation()
  Message _parseEventMessage(
    Map<String, dynamic> data,
    String id,
    String sessionId,
    String projectName,
    String? parentId,
    String? contentUuid,
  ) {
    final eventType =
        data['eventType'] as String? ?? data['event'] as String? ?? 'unknown';
    final content =
        data['content'] as String? ?? data['message'] as String? ?? '';

    // 根据事件类型生成合适的标题和内容
    final (title, message) = _getEventPresentation(eventType, data, content);

    return Message(
      id: id,
      sessionId: sessionId,
      payload: MarkdownPayload(title: title, content: message),
      projectName: projectName,
      hookEvent: eventType,
      createdAt: _parseTimestamp(data['createdAt']),
      role: 'system',
      parentId: parentId,
      contentUuid: contentUuid,
    );
  }

  /// 解析默认消息（Markdown）
  Message _parseDefaultMessage(
    Map<String, dynamic> data,
    String id,
    String sessionId,
    String projectName,
    String type,
    String? parentId,
    String? contentUuid,
  ) {
    final content =
        data['content'] as String? ?? data['message'] as String? ?? '';
    final title = data['title'] as String? ?? _getTitleFromType(type);

    return Message(
      id: id,
      sessionId: sessionId,
      payload: MarkdownPayload(title: title, content: content),
      projectName: projectName,
      projectPath: data['projectPath'] as String?,
      hookEvent: data['hookEvent'] as String?,
      toolName: data['toolName'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      parentId: parentId,
      contentUuid: contentUuid,
      role: 'assistant',
    );
  }

  /// 获取事件展示信息
  /// 参考 hapi web: presentation.ts
  (String title, String message) _getEventPresentation(
    String eventType,
    Map<String, dynamic> data,
    String defaultContent,
  ) {
    switch (eventType) {
      case 'api-error':
        final retryCount = data['retryCount'] as int? ?? 0;
        final maxRetries = data['maxRetries'] as int? ?? 3;
        return ('API 错误', 'API 错误: 重试中 ($retryCount/$maxRetries)');

      case 'switch':
        final mode = data['mode'] as String? ?? 'unknown';
        return ('模式切换', '已切换到 $mode 模式');

      case 'limit-reached':
        final until = data['until'] as String?;
        return ('使用限制', '已达到使用限制${until != null ? '，将在 $until 后恢复' : ''}');

      case 'title-changed':
        final newTitle = data['title'] as String? ?? '';
        return ('标题更新', '会话标题已更新为: $newTitle');

      case 'session-started':
        return ('会话开始', '新会话已开始');

      case 'session-ended':
        return ('会话结束', '会话已结束');

      case 'permission-granted':
        final tool = data['tool'] as String? ?? '';
        return ('权限授予', '已授予 $tool 执行权限');

      case 'permission-denied':
        final tool = data['tool'] as String? ?? '';
        return ('权限拒绝', '已拒绝 $tool 执行权限');

      default:
        return ('系统消息', defaultContent.isNotEmpty ? defaultContent : eventType);
    }
  }

  /// 构建工具调用标题
  String _buildToolCallTitle(List<TaskItem> toolCalls) {
    if (toolCalls.isEmpty) return '工具调用';
    if (toolCalls.length == 1) return '执行: ${toolCalls.first.name}';

    // 统计工具类型
    final toolNames = toolCalls.map((t) => t.toolName ?? t.name).toSet();
    if (toolNames.length == 1) {
      return '执行 ${toolCalls.length} 次 ${toolCalls.first.name}';
    }
    return '执行 ${toolCalls.length} 个工具';
  }

  /// 计算整体任务状态
  TaskStatus _calculateOverallStatus(List<TaskItem> tasks) {
    if (tasks.isEmpty) return TaskStatus.pending;

    final hasError = tasks.any((t) => t.status == TaskItemStatus.error);
    final hasRunning = tasks.any((t) => t.status == TaskItemStatus.running);
    final hasPending = tasks.any((t) => t.status == TaskItemStatus.pending);
    final allCompleted = tasks.every(
      (t) =>
          t.status == TaskItemStatus.completed ||
          t.status == TaskItemStatus.error,
    );

    if (hasError && allCompleted) return TaskStatus.error;
    if (hasError) return TaskStatus.partial;
    if (hasRunning) return TaskStatus.running;
    if (hasPending) return TaskStatus.pending;
    if (allCompleted) return TaskStatus.completed;
    return TaskStatus.running;
  }

  /// 解析工具项状态字符串
  TaskItemStatus _parseToolItemStatus(String state) {
    return switch (state) {
      'pending' => TaskItemStatus.pending,
      'running' => TaskItemStatus.running,
      'completed' => TaskItemStatus.completed,
      'error' => TaskItemStatus.error,
      _ => TaskItemStatus.pending,
    };
  }

  /// TaskItemStatus → TaskStatus
  TaskStatus _statusToTaskStatus(TaskItemStatus status) {
    return switch (status) {
      TaskItemStatus.pending => TaskStatus.pending,
      TaskItemStatus.running => TaskStatus.running,
      TaskItemStatus.completed => TaskStatus.completed,
      TaskItemStatus.error => TaskStatus.error,
    };
  }

  /// 获取工具显示名称
  String _getToolDisplayName(String toolName) {
    // 常见工具名称的友好显示
    return switch (toolName) {
      'Read' => '读取文件',
      'Write' => '写入文件',
      'Edit' => '编辑文件',
      'Bash' => '执行命令',
      'Glob' => '文件搜索',
      'Grep' => '内容搜索',
      'Task' => '子任务',
      'WebFetch' => '网页获取',
      'WebSearch' => '网页搜索',
      'TodoWrite' => '任务列表',
      'AskUserQuestion' => '询问用户',
      'NotebookEdit' => '编辑笔记本',
      _ => toolName,
    };
  }

  /// 格式化工具输入参数（详细版）
  String _formatToolInputDetailed(Map<String, dynamic> input) {
    final buffer = StringBuffer();
    int count = 0;

    for (final entry in input.entries) {
      // 跳过一些不重要的字段
      if (['description', 'timeout', 'run_in_background'].contains(entry.key)) {
        continue;
      }

      final value = entry.value;
      String valueStr;

      if (value is String) {
        // 对于长字符串进行截断
        if (value.length > 100) {
          valueStr = '${value.substring(0, 100)}...';
        } else {
          valueStr = value;
        }
      } else if (value is Map || value is List) {
        valueStr = '[复杂数据]';
      } else {
        valueStr = value.toString();
      }

      if (count > 0) buffer.writeln();
      buffer.write('${entry.key}: $valueStr');
      count++;

      // 最多显示 5 个参数
      if (count >= 5) {
        final remaining = input.length - count;
        if (remaining > 0) {
          buffer.writeln();
          buffer.write('... 还有 $remaining 个参数');
        }
        break;
      }
    }

    return buffer.toString();
  }

  /// 解析时间戳
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is int) {
      // 毫秒时间戳
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }

    return DateTime.now();
  }

  /// 解析权限请求为 Message 对象
  Message? _parsePermissionRequest(
    Map<String, dynamic> data,
    String? sessionId,
  ) {
    if (sessionId == null) {
      Log.w('HapiEvent', 'sessionId is null for permission request');
      return null;
    }

    // 使用服务器提供的 ID，如果没有则生成唯一 UUID
    final requestId =
        data['id'] as String? ?? data['requestId'] as String? ?? _uuid.v4();

    final toolName =
        data['toolName'] as String? ?? data['tool'] as String? ?? 'unknown';
    final description = data['description'] as String? ?? '请求执行操作';
    final projectName = data['projectName'] as String? ?? 'hapi';

    return Message(
      id: 'perm_$requestId',
      sessionId: sessionId,
      payload: InteractivePayload(
        title: '权限请求: $toolName',
        message: description,
        requestId: requestId,
        interactiveType: InteractiveType.permission,
        metadata: {
          'toolName': toolName,
          if (data['args'] != null) 'args': data['args'],
        },
      ),
      projectName: projectName,
      toolName: toolName,
      createdAt: DateTime.now(),
    );
  }

  /// 根据消息类型获取默认标题
  String _getTitleFromType(String type) {
    return switch (type) {
      'progress' => '进度更新',
      'complete' => '任务完成',
      'error' => '错误',
      'warning' => '警告',
      'code' => '代码',
      'markdown' => '消息',
      _ => '通知',
    };
  }

  /// 释放资源
  void dispose() {
    stopListening();
    // 刷新剩余的会话更新
    _flushSessionUpdates();
    _sessionUpdateDebouncer.dispose();
  }
}

/// hapi 事件处理器 Provider
final hapiEventHandlerProvider = Provider<HapiEventHandler?>((ref) {
  final config = ref.watch(hapiConfigProvider);

  // 只有在 hapi 启用时才创建处理器
  if (!config.enabled || !config.isConfigured) {
    return null;
  }

  final handler = HapiEventHandler(ref);

  // 监听 SSE 连接状态，连接后开始监听事件
  ref.listen(hapiConnectionStateProvider, (previous, next) {
    next.whenData((state) {
      if (state.isConnected) {
        handler.startListening();
      } else {
        handler.stopListening();
      }
    });
  });

  ref.onDispose(() {
    handler.dispose();
  });

  return handler;
});

/// 初始化 hapi 事件监听的 Provider（在 main.dart 中使用）
final hapiEventInitProvider = Provider<void>((ref) {
  // 触发 hapiEventHandlerProvider 的创建
  ref.watch(hapiEventHandlerProvider);
});
