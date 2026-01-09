import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/logger.dart';
import '../models/message.dart';
import '../models/session.dart';

/// 事件类型枚举
enum EventType {
  messageReceived,
  messageUpdated,
  sessionCreated,
  sessionUpdated,
  sessionEnded,
  permissionRequested,
  todoUpdated,
  connectionChanged,
  error,
}

/// 事件基类
abstract class AppEvent {
  const AppEvent(this.type);

  final EventType type;
}

/// 消息事件
class MessageEvent extends AppEvent {
  const MessageEvent(this.message, {this.isUpdate = false})
    : super(isUpdate ? EventType.messageUpdated : EventType.messageReceived);

  final Message message;
  final bool isUpdate;
}

/// 会话事件
class SessionEvent extends AppEvent {
  const SessionEvent(this.session, EventType type) : super(type);

  final Session session;

  factory SessionEvent.created(Session session) =>
      SessionEvent(session, EventType.sessionCreated);

  factory SessionEvent.updated(Session session) =>
      SessionEvent(session, EventType.sessionUpdated);

  factory SessionEvent.ended(Session session) =>
      SessionEvent(session, EventType.sessionEnded);
}

/// 连接状态事件
class ConnectionEvent extends AppEvent {
  const ConnectionEvent({required this.isConnected, this.errorMessage})
    : super(EventType.connectionChanged);

  final bool isConnected;
  final String? errorMessage;
}

/// 错误事件
class ErrorEvent extends AppEvent {
  const ErrorEvent(this.error, [this.stackTrace]) : super(EventType.error);

  final Object error;
  final StackTrace? stackTrace;
}

/// 事件总线 (Mediator 模式)
/// 解耦事件生产者和消费者，提供集中的事件分发机制
class EventBus {
  EventBus._();

  static final EventBus instance = EventBus._();

  final _controller = StreamController<AppEvent>.broadcast();

  /// 事件流
  Stream<AppEvent> get stream => _controller.stream;

  /// 发送事件
  void emit(AppEvent event) {
    if (_controller.isClosed) return;
    Log.d('EventBus', 'Emit: ${event.type}');
    _controller.add(event);
  }

  /// 发送消息事件
  void emitMessage(Message message, {bool isUpdate = false}) {
    emit(MessageEvent(message, isUpdate: isUpdate));
  }

  /// 发送会话创建事件
  void emitSessionCreated(Session session) {
    emit(SessionEvent.created(session));
  }

  /// 发送会话更新事件
  void emitSessionUpdated(Session session) {
    emit(SessionEvent.updated(session));
  }

  /// 发送会话结束事件
  void emitSessionEnded(Session session) {
    emit(SessionEvent.ended(session));
  }

  /// 发送连接状态事件
  void emitConnectionChanged({required bool isConnected, String? error}) {
    emit(ConnectionEvent(isConnected: isConnected, errorMessage: error));
  }

  /// 发送错误事件
  void emitError(Object error, [StackTrace? stackTrace]) {
    emit(ErrorEvent(error, stackTrace));
  }

  /// 监听特定类型的事件
  Stream<T> on<T extends AppEvent>() {
    return stream.where((event) => event is T).cast<T>();
  }

  /// 监听消息事件
  Stream<MessageEvent> get onMessage => on<MessageEvent>();

  /// 监听会话事件
  Stream<SessionEvent> get onSession => on<SessionEvent>();

  /// 监听连接事件
  Stream<ConnectionEvent> get onConnection => on<ConnectionEvent>();

  /// 监听错误事件
  Stream<ErrorEvent> get onError => on<ErrorEvent>();

  /// 释放资源
  void dispose() {
    _controller.close();
    Log.i('EventBus', 'Disposed');
  }
}

/// EventBus Provider
final eventBusProvider = Provider<EventBus>((ref) {
  final eventBus = EventBus.instance;
  ref.onDispose(() => eventBus.dispose());
  return eventBus;
});
