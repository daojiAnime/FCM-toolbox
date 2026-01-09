import '../../../common/logger.dart';
import '../hapi_sse_service.dart';
import 'event_handler.dart';

/// 会话事件处理器
/// 处理 sessionUpdate、sessionCreated、sessionEnded 等会话相关事件
class SessionEventHandler extends EventHandler {
  SessionEventHandler(this._onSession);

  final void Function(HapiSseEvent event) _onSession;

  static const _handledTypes = {
    HapiSseEventType.sessionUpdate,
    HapiSseEventType.sessionCreated,
    HapiSseEventType.sessionEnded,
    HapiSseEventType.sessionAdded,
    HapiSseEventType.sessionUpdated,
    HapiSseEventType.sessionRemoved,
  };

  @override
  bool canHandle(HapiSseEvent event) {
    return _handledTypes.contains(event.type);
  }

  @override
  void doHandle(HapiSseEvent event) {
    Log.d('SessionHandler', 'Handling ${event.type}');
    _onSession(event);
  }
}
