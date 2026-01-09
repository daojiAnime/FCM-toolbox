import '../../../common/logger.dart';
import '../hapi_sse_service.dart';
import 'event_handler.dart';

/// 权限请求事件处理器
/// 处理 permissionRequest 事件
class PermissionEventHandler extends EventHandler {
  PermissionEventHandler(this._onPermission);

  final void Function(HapiSseEvent event) _onPermission;

  @override
  bool canHandle(HapiSseEvent event) {
    return event.type == HapiSseEventType.permissionRequest;
  }

  @override
  void doHandle(HapiSseEvent event) {
    Log.d('PermHandler', 'Handling permission request');
    _onPermission(event);
  }
}

/// Todo 更新事件处理器
/// 处理 todoUpdate 事件
class TodoEventHandler extends EventHandler {
  TodoEventHandler(this._onTodo);

  final void Function(HapiSseEvent event) _onTodo;

  @override
  bool canHandle(HapiSseEvent event) {
    return event.type == HapiSseEventType.todoUpdate;
  }

  @override
  void doHandle(HapiSseEvent event) {
    Log.d('TodoHandler', 'Handling todo update');
    _onTodo(event);
  }
}
