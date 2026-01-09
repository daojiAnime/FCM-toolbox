import '../../../common/logger.dart';
import '../hapi_sse_service.dart';
import 'event_handler.dart';

/// 连接事件处理器
/// 处理 connectionChanged、connected、error 等连接相关事件
class ConnectionEventHandler extends EventHandler {
  ConnectionEventHandler(this._onConnection);

  final void Function(HapiSseEvent event) _onConnection;

  static final _handledTypes = {
    HapiSseEventType.connectionChanged,
    HapiSseEventType.connected,
    HapiSseEventType.error,
  };

  @override
  bool canHandle(HapiSseEvent event) {
    return _handledTypes.contains(event.type);
  }

  @override
  void doHandle(HapiSseEvent event) {
    Log.d('ConnHandler', 'Handling ${event.type}');
    _onConnection(event);
  }
}
