import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';

/// 消息列表状态
class MessagesNotifier extends StateNotifier<List<Message>> {
  MessagesNotifier() : super([]);

  /// 添加新消息
  void addMessage(Message message) {
    state = [message, ...state];
  }

  /// 批量添加消息
  void addMessages(List<Message> messages) {
    state = [...messages, ...state];
  }

  /// 标记消息为已读
  void markAsRead(String id) {
    state = state.map((msg) {
      if (msg.id == id) {
        return msg.copyWith(isRead: true);
      }
      return msg;
    }).toList();
  }

  /// 标记所有消息为已读
  void markAllAsRead() {
    state = state.map((msg) => msg.copyWith(isRead: true)).toList();
  }

  /// 删除消息
  void removeMessage(String id) {
    state = state.where((msg) => msg.id != id).toList();
  }

  /// 更新消息（用于交互消息状态更新）
  void updateMessage(String id, Message Function(Message) update) {
    state = state.map((msg) {
      if (msg.id == id) {
        return update(msg);
      }
      return msg;
    }).toList();
  }

  /// 清空所有消息
  void clearAll() {
    state = [];
  }

  /// 按会话 ID 过滤消息
  List<Message> getBySessionId(String sessionId) {
    return state.where((msg) => msg.sessionId == sessionId).toList();
  }

  /// 获取未读消息数量
  int get unreadCount => state.where((msg) => !msg.isRead).length;
}

/// 消息列表 Provider
final messagesProvider = StateNotifierProvider<MessagesNotifier, List<Message>>(
  (ref) {
    return MessagesNotifier();
  },
);

/// 未读消息数量 Provider
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(messagesProvider).where((msg) => !msg.isRead).length;
});
