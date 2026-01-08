import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/message.dart';
import '../../models/payload/payload.dart';
import '../../models/session.dart';
import '../../providers/messages_provider.dart';
import '../../providers/session_provider.dart';
import '../interaction_service.dart';
import '../cache_service.dart';
import 'hapi_api_service.dart';
import 'hapi_config_service.dart';
import 'hapi_sse_service.dart';

/// hapi 事件处理器 - 监听 SSE 事件并更新应用状态
class HapiEventHandler {
  HapiEventHandler(this._ref);

  final Ref _ref;
  StreamSubscription<HapiSseEvent>? _subscription;

  // 会话更新防抖器 - 防止频繁的会话更新导致 UI 抖动
  final _sessionUpdateDebouncer = Debouncer(
    delay: const Duration(milliseconds: 150),
  );

  // 待更新的会话缓存
  final _pendingSessionUpdates = <String, Map<String, dynamic>>{};

  /// 开始监听 SSE 事件
  void startListening() {
    final sseService = _ref.read(hapiSseServiceProvider);
    if (sseService == null) {
      debugPrint('[HapiEventHandler] SSE service not available');
      return;
    }

    _subscription?.cancel();
    _subscription = sseService.events.listen(_handleEvent);
    debugPrint('[HapiEventHandler] Started listening to SSE events');

    // 连接后加载初始会话
    loadSessions();
  }

  /// 停止监听
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('[HapiEventHandler] Stopped listening');
  }

  /// 处理 SSE 事件
  void _handleEvent(HapiSseEvent event) {
    debugPrint('[HapiEventHandler] Received event: ${event.type}');

    switch (event.type) {
      case HapiSseEventType.message:
        _handleMessageEvent(event);
        break;
      case HapiSseEventType.permissionRequest:
        _handlePermissionRequest(event);
        break;
      case HapiSseEventType.sessionUpdate:
        _handleSessionUpdate(event);
        break;
      case HapiSseEventType.sessionCreated:
        _handleSessionCreated(event);
        break;
      case HapiSseEventType.sessionEnded:
        _handleSessionEnded(event);
        break;
      case HapiSseEventType.todoUpdate:
        _handleTodoUpdate(event);
        break;
      case HapiSseEventType.connected:
        debugPrint('[HapiEventHandler] SSE connected');
        break;
      case HapiSseEventType.error:
        debugPrint('[HapiEventHandler] SSE error: ${event.data}');
        break;
      default:
        debugPrint('[HapiEventHandler] Unknown event type: ${event.type}');
    }
  }

  /// 处理消息事件
  void _handleMessageEvent(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    try {
      final message = _parseHapiMessage(data, event.sessionId);
      if (message != null) {
        _ref.read(messagesProvider.notifier).addMessage(message);
        debugPrint('[HapiEventHandler] Added message: ${message.id}');
      }
    } catch (e) {
      debugPrint('[HapiEventHandler] Failed to parse message: $e');
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
        debugPrint(
          '[HapiEventHandler] Added permission request: ${message.id}',
        );
      }
    } catch (e) {
      debugPrint('[HapiEventHandler] Failed to handle permission request: $e');
    }
  }

  /// 处理会话更新事件（带防抖）
  void _handleSessionUpdate(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    final sessionId = data['id'] as String?;
    if (sessionId == null) return;

    // 累积更新
    _pendingSessionUpdates[sessionId] = data;

    // 使用防抖批量处理
    _sessionUpdateDebouncer.run(_flushSessionUpdates);
  }

  /// 批量刷新会话更新
  void _flushSessionUpdates() {
    if (_pendingSessionUpdates.isEmpty) return;

    final updates = Map<String, Map<String, dynamic>>.from(
      _pendingSessionUpdates,
    );
    _pendingSessionUpdates.clear();

    debugPrint('[HapiEventHandler] Flushing ${updates.length} session updates');

    for (final entry in updates.entries) {
      try {
        final session = _parseHapiSession(entry.value);
        if (session != null) {
          _ref.read(sessionsProvider.notifier).upsertSession(session);
        }
      } catch (e) {
        debugPrint(
          '[HapiEventHandler] Failed to update session ${entry.key}: $e',
        );
      }
    }
  }

  /// 处理会话创建事件
  void _handleSessionCreated(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    try {
      final session = _parseHapiSession(data);
      if (session != null) {
        _ref.read(sessionsProvider.notifier).upsertSession(session);
        debugPrint('[HapiEventHandler] Session created: ${session.id}');
      }
    } catch (e) {
      debugPrint('[HapiEventHandler] Failed to create session: $e');
    }
  }

  /// 处理会话结束事件
  void _handleSessionEnded(HapiSseEvent event) {
    final sessionId = event.sessionId ?? event.data?['id'] as String?;
    if (sessionId == null) return;

    _ref
        .read(sessionsProvider.notifier)
        .updateStatus(sessionId, SessionStatus.completed);
    debugPrint('[HapiEventHandler] Session ended: $sessionId');
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
      debugPrint('[HapiEventHandler] Todo updated for session: $sessionId');
    } catch (e) {
      debugPrint('[HapiEventHandler] Failed to update todos: $e');
    }
  }

  /// 解析 hapi 会话数据
  Session? _parseHapiSession(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    if (id == null) return null;

    final statusStr = data['status'] as String? ?? 'running';
    final status = switch (statusStr) {
      'running' || 'active' => SessionStatus.running,
      'waiting' || 'pending' => SessionStatus.waiting,
      'completed' || 'ended' => SessionStatus.completed,
      _ => SessionStatus.running,
    };

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

    return Session(
      id: id,
      projectName:
          data['projectName'] as String? ??
          data['project'] as String? ??
          'Unknown',
      projectPath: data['projectPath'] as String? ?? data['cwd'] as String?,
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
      debugPrint('[HapiEventHandler] Loaded ${sessionsData.length} sessions');
    } catch (e) {
      debugPrint('[HapiEventHandler] Failed to load sessions: $e');
    }
  }

  /// 解析 hapi 消息为 Message 对象
  Message? _parseHapiMessage(Map<String, dynamic> data, String? sessionId) {
    if (sessionId == null) {
      debugPrint('[HapiEventHandler] sessionId is null, skipping message');
      return null;
    }

    final id =
        data['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final type = data['type'] as String? ?? 'markdown';
    final content =
        data['content'] as String? ?? data['message'] as String? ?? '';
    final title = data['title'] as String? ?? _getTitleFromType(type);
    final projectName = data['projectName'] as String? ?? 'hapi';

    // 解析 payload
    Payload payload;
    switch (type) {
      case 'progress':
        payload = ProgressPayload(
          title: title,
          description: content,
          current: data['current'] as int? ?? 0,
          total: data['total'] as int? ?? 0,
          currentStep: data['currentStep'] as String?,
        );
        break;
      case 'complete':
        payload = CompletePayload(
          title: title,
          summary: content.isNotEmpty ? content : data['summary'] as String?,
          duration: data['duration'] as int?,
          toolCount: data['toolCount'] as int?,
        );
        break;
      case 'error':
        payload = ErrorPayload(
          title: title,
          message: content,
          stackTrace: data['stackTrace'] as String?,
          suggestion: data['suggestion'] as String?,
        );
        break;
      case 'warning':
        payload = WarningPayload(
          title: title,
          message: content,
          action: data['action'] as String?,
        );
        break;
      case 'code':
        payload = CodePayload(
          title: title,
          code: content,
          language: data['language'] as String?,
          filename: data['filename'] as String?,
          startLine: data['startLine'] as int?,
        );
        break;
      default:
        payload = MarkdownPayload(title: title, content: content);
    }

    return Message(
      id: id,
      sessionId: sessionId,
      payload: payload,
      projectName: projectName,
      projectPath: data['projectPath'] as String?,
      hookEvent: data['hookEvent'] as String?,
      toolName: data['toolName'] as String?,
      createdAt: DateTime.now(),
    );
  }

  /// 解析权限请求为 Message 对象
  Message? _parsePermissionRequest(
    Map<String, dynamic> data,
    String? sessionId,
  ) {
    if (sessionId == null) {
      debugPrint('[HapiEventHandler] sessionId is null for permission request');
      return null;
    }

    final requestId = data['id'] as String? ?? data['requestId'] as String?;
    if (requestId == null) return null;

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
