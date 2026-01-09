import '../hapi_sse_service.dart';

/// 事件处理器基类 (Chain of Responsibility 模式)
/// 每个处理器负责处理特定类型的 SSE 事件
abstract class EventHandler {
  EventHandler? _next;

  /// 设置下一个处理器
  void setNext(EventHandler handler) {
    _next = handler;
  }

  /// 处理事件
  /// 如果当前处理器能处理该事件，则处理；否则传递给下一个处理器
  void handle(HapiSseEvent event) {
    if (canHandle(event)) {
      doHandle(event);
    } else {
      _next?.handle(event);
    }
  }

  /// 判断是否能处理该事件
  bool canHandle(HapiSseEvent event);

  /// 实际处理逻辑
  void doHandle(HapiSseEvent event);
}

/// 事件处理链构建器
class EventHandlerChain {
  EventHandler? _head;
  EventHandler? _tail;

  /// 添加处理器到链末尾
  EventHandlerChain add(EventHandler handler) {
    if (_head == null) {
      _head = handler;
      _tail = handler;
    } else {
      _tail!.setNext(handler);
      _tail = handler;
    }
    return this;
  }

  /// 处理事件
  void handle(HapiSseEvent event) {
    _head?.handle(event);
  }

  /// 获取链头
  EventHandler? get head => _head;
}
