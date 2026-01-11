import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/logger.dart';
import '../../../models/session.dart';
import '../../../providers/messages_provider.dart';
import '../../../providers/session_provider.dart';
import '../../interaction_service.dart';
import '../hapi_sse_service.dart';
import 'event_handler.dart';
import 'message_parser.dart';

/// 权限和 Todo 事件处理器
/// 处理 permissionRequest 和 todoUpdate 事件
class PermissionEventHandler extends EventHandler {
  PermissionEventHandler(this._ref, this._parser);

  final Ref _ref;
  final HapiMessageParser _parser;

  static final _handledTypes = {
    HapiSseEventType.permissionRequest,
    HapiSseEventType.todoUpdate,
  };

  @override
  bool canHandle(HapiSseEvent event) {
    return _handledTypes.contains(event.type);
  }

  @override
  void doHandle(HapiSseEvent event) {
    Log.d('PermHandler', 'Handling ${event.type}');

    switch (event.type) {
      case HapiSseEventType.permissionRequest:
        _handlePermissionRequest(event);
      case HapiSseEventType.todoUpdate:
        _handleTodoUpdate(event);
      default:
        Log.w('PermHandler', 'Unhandled event type: ${event.type}');
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
      final message = _parser.parsePermissionRequest(data, sessionId);
      if (message != null) {
        _ref.read(messagesProvider.notifier).addMessage(message);
      }
    } catch (e) {
      Log.e('PermHandler', 'Failed to handle permission request', e);
    }
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
      Log.e('PermHandler', 'Failed to update todos', e);
    }
  }
}
