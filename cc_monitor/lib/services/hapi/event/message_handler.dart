import '../../../common/logger.dart';
import '../hapi_sse_service.dart';
import 'event_handler.dart';

/// 消息事件处理器
/// 处理 message、streamingContent、streamingComplete 等消息相关事件
class MessageEventHandler extends EventHandler {
  MessageEventHandler(this._onMessage);

  final void Function(HapiSseEvent event) _onMessage;

  static const _handledTypes = {
    HapiSseEventType.message,
    HapiSseEventType.streamingContent,
    HapiSseEventType.streamingComplete,
  };

  @override
  bool canHandle(HapiSseEvent event) {
    return _handledTypes.contains(event.type);
  }

  @override
  void doHandle(HapiSseEvent event) {
    Log.d('MsgHandler', 'Handling ${event.type}');
    _onMessage(event);
  }
}
