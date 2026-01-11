import 'package:flutter/material.dart';

import '../../common/design_tokens.dart';
import '../../models/message.dart';
import '../../models/payload/payload.dart';
import '../message_card/interactive_card.dart';
import '../message_card/thinking_card.dart';
import 'assistant_bubble.dart';
import 'task_card.dart';
import 'user_bubble.dart';

/// 消息项 Widget（性能优化：提取为独立 StatelessWidget）
/// 避免在列表滚动时重建整个页面
class MessageItemWidget extends StatelessWidget {
  const MessageItemWidget({super.key, required this.message, this.children});

  final Message message;
  final List<Message>? children;

  @override
  Widget build(BuildContext context) {
    final payload = message.payload;

    // 隐藏消息 - 不渲染（用于链追踪但不显示）
    if (payload is HiddenPayload) {
      return const SizedBox.shrink();
    }

    // 用户消息
    if (message.role == 'user') {
      if (payload is UserMessagePayload) {
        return SimpleUserBubble(
          content: payload.content,
          isPending: payload.isPending,
        );
      }
      return const SizedBox.shrink();
    }

    // AI 消息 / 系统消息
    // 任务执行卡片
    if (payload is TaskExecutionPayload) {
      return Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
        child: TaskCard(message: message, children: children),
      );
    }

    // Markdown 消息
    if (payload is MarkdownPayload) {
      return SimpleAssistantBubble(
        content: payload.content,
        isStreaming: payload.streamingStatus == StreamingStatus.streaming,
      );
    }

    // 思维链消息（可折叠显示）
    if (payload is ThinkingPayload) {
      return Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
        child: ThinkingCard(
          content: payload.content,
          timestamp: message.createdAt,
          messageId: payload.streamingId ?? message.id,
          streamingStatus: payload.streamingStatus,
          isRead: message.isRead,
        ),
      );
    }

    // 交互式卡片
    if (payload is InteractivePayload) {
      return Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
        child: InteractiveMessageCard(
          title: payload.title,
          timestamp: message.createdAt,
          message: payload.message,
          requestId: payload.requestId,
          interactiveType: payload.interactiveType,
          metadata: payload.metadata,
          isRead: message.isRead,
          isPending: payload.status == PermissionStatus.pending,
        ),
      );
    }

    // 其他 payload 类型暂不支持，返回空
    // 这些类型在原始代码中使用更复杂的卡片组件

    // 未知类型 - 不显示
    return const SizedBox.shrink();
  }
}
