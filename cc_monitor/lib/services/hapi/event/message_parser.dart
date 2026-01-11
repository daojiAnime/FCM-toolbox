import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../common/logger.dart';
import '../../../models/message.dart';
import '../../../models/payload/payload.dart';
import '../../../models/session.dart';
import '../../../models/task.dart';
import '../buffer_manager.dart';

const _uuid = Uuid();

/// hapi 消息解析器 - 将 hapi API 返回的数据解析为应用模型
///
/// 这个类封装了所有与消息解析相关的逻辑,被多个事件处理器共享使用
/// 包含:
/// - Message 解析 (SSE 事件和历史记录)
/// - Session 解析
/// - 工具结果关联
/// - 时间戳解析等辅助方法
class HapiMessageParser {
  HapiMessageParser(this._ref, this._bufferManager);

  // ignore: unused_field
  final Ref _ref;
  final BufferManager _bufferManager;

  // ============ 时间戳和工具格式化辅助方法 ============

  /// 解析时间戳
  DateTime parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is int) {
      // 毫秒时间戳
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }

    return DateTime.now();
  }

  /// 根据消息类型获取默认标题
  String getTitleFromType(String type) {
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

  /// 格式化工具输入参数（简短版）
  String? formatToolInputBrief(Map<String, dynamic>? input) {
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

  /// 格式化工具输入参数（详细版）
  String? formatToolInputDetailed(Map<String, dynamic>? input) {
    if (input == null) return null;
    final buffer = StringBuffer();
    int count = 0;

    for (final entry in input.entries) {
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

  /// 提取工具结果内容
  String extractToolResultContent(dynamic content) {
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

  /// 计算任务的整体状态
  TaskStatus calculateOverallStatus(List<TaskItem> tasks) {
    if (tasks.isEmpty) return TaskStatus.completed;

    final hasError = tasks.any((t) => t.hasError);
    if (hasError) return TaskStatus.error;

    final allCompleted = tasks.every(
      (t) =>
          t.status == TaskItemStatus.completed ||
          t.status == TaskItemStatus.error,
    );
    return allCompleted ? TaskStatus.completed : TaskStatus.running;
  }

  // ============ Session 解析 ============

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
  Session? parseHapiSession(Map<String, dynamic> data) {
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

  // ============ Permission 解析 ============

  /// 解析权限请求为 Message 对象
  Message? parsePermissionRequest(
    Map<String, dynamic> data,
    String? sessionId,
  ) {
    if (sessionId == null) {
      Log.d('MessageParser', 'sessionId is null for permission request');
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

  // ============ 工具结果关联 ============

  /// 阶段2: 关联 tool_result 到对应的 TaskItem
  /// 参考 hapi web reducerTimeline.ts:168-219
  /// 在所有消息解析完成后，遍历消息列表将收集的 tool_result 关联到 tool_use
  void associateToolResults(List<Message> messages) {
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
              overallStatus: calculateOverallStatus(updatedTasks),
            ),
          );
        }
      }
    }

    // 清理剩余未匹配的 tool_result
    _bufferManager.clearPendingToolResults();
  }

  // NOTE: 由于消息解析方法非常多(约1500行),在实际实施中需要将剩余的解析方法从
  // HapiEventHandler 迁移到这里,包括:
  // - parseHapiMessage (主解析器)
  // - parseHistoryMessage
  // - parseUserHistoryMessage
  // - parseAssistantHistoryMessage
  // - parseHapiUserMessage
  // - parseUserMessage
  // - parseProgressMessage, parseCompleteMessage, parseErrorMessage 等
  //
  // 这些方法的完整实现见 HapiEventHandler.dart,待后续步骤迁移
}
