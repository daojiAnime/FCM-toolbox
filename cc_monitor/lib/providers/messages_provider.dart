import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message.dart';

/// 消息列表状态
class MessagesNotifier extends StateNotifier<List<Message>> {
  MessagesNotifier() : super([]);

  /// 消息列表最大长度限制
  static const int maxMessages = 500;

  /// 添加新消息
  void addMessage(Message message) {
    state = [message, ...state];
    trimMessages();
  }

  /// 批量添加消息
  void addMessages(List<Message> messages) {
    state = [...messages, ...state];
    trimMessages();
  }

  /// 设置指定会话的消息（替换该会话的所有消息）
  /// 用于加载历史消息，会自动按时间正序排序
  void setSessionMessages(String sessionId, List<Message> messages) {
    // 移除该会话的现有消息
    final otherMessages = state.where((m) => m.sessionId != sessionId).toList();

    // 按时间正序排序新消息
    final sortedMessages = List<Message>.from(messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // 合并（其他会话消息在前，当前会话消息在后）
    state = [...otherMessages, ...sortedMessages];
    trimMessages();
  }

  /// 添加或更新消息（如果消息已存在则跳过）
  void addMessageIfNotExists(Message message) {
    if (state.any((m) => m.id == message.id)) return;
    addMessage(message);
  }

  /// 清理超出限制的消息（保留最新的 maxMessages 条）
  void trimMessages() {
    if (state.length > maxMessages) {
      state = state.sublist(0, maxMessages);
    }
  }

  /// 标记消息为已读
  void markAsRead(String id) {
    state =
        state.map((msg) {
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
    state =
        state.map((msg) {
          if (msg.id == id) {
            return update(msg);
          }
          return msg;
        }).toList();
  }

  /// 替换消息（用于流式消息完成时更新）
  void replaceMessage(Message message) {
    state =
        state.map((msg) {
          if (msg.id == message.id) {
            return message;
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

/// 按会话 ID 过滤消息的 Provider（按时间正序排序）
final sessionMessagesProvider = Provider.family<List<Message>, String>((
  ref,
  sessionId,
) {
  final messages = ref.watch(messagesProvider);
  final filtered = messages.where((msg) => msg.sessionId == sessionId).toList();
  // 确保按时间正序排序（最旧在前，最新在后）
  // 这对 MessageTracer 和 UI 都是必要的
  filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return filtered;
});
