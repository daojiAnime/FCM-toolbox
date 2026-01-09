import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/message.dart';
import '../../models/payload/payload.dart';
import '../chat/task_card.dart';
import 'base_card.dart';
import 'progress_card.dart';
import 'complete_card.dart';
import 'code_card.dart';
import 'interactive_card.dart';
import 'markdown_card.dart';
import 'thinking_card.dart';

/// 统一消息卡片工厂
class MessageCard extends StatelessWidget {
  const MessageCard({
    super.key,
    required this.message,
    this.onTap,
    this.onApprove,
    this.onDeny,
  });

  final Message message;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onDeny;

  @override
  Widget build(BuildContext context) {
    return switch (message.payload) {
      ProgressPayload payload => ProgressMessageCard(
        title: payload.title,
        timestamp: message.createdAt,
        description: payload.description,
        summary: _getToolSummary(payload.description, payload.currentStep),
        current: payload.current,
        total: payload.total,
        currentStep: payload.currentStep,
        onTap: onTap,
        isRead: message.isRead,
      ),
      CompletePayload payload => CompleteMessageCard(
        title: payload.title,
        timestamp: message.createdAt,
        summary: payload.summary,
        executionSummary: _getToolSummary(payload.summary, null),
        duration: payload.duration,
        toolCount: payload.toolCount,
        onTap: onTap,
        isRead: message.isRead,
      ),
      ErrorPayload payload => LegacyMessageCard(
        type: 'error',
        title: payload.title,
        timestamp: message.createdAt,
        subtitle: payload.message,
        onTap: onTap,
        isRead: message.isRead,
        child:
            payload.suggestion != null
                ? _buildSuggestion(context, payload.suggestion!)
                : null,
      ),
      WarningPayload payload => LegacyMessageCard(
        type: 'warning',
        title: payload.title,
        timestamp: message.createdAt,
        subtitle: payload.message,
        onTap: onTap,
        isRead: message.isRead,
      ),
      CodePayload payload => CodeMessageCard(
        title: payload.title,
        timestamp: message.createdAt,
        code: payload.code,
        language: payload.language,
        filename: payload.filename,
        startLine: payload.startLine,
        onTap: onTap,
        isRead: message.isRead,
      ),
      MarkdownPayload payload => MarkdownMessageCard(
        title: payload.title,
        content: payload.content,
        timestamp: message.createdAt,
        messageId: payload.streamingId ?? message.id,
        streamingStatus: payload.streamingStatus,
        isRead: message.isRead,
      ),
      // 思维链 - 可折叠显示 AI 推理过程
      ThinkingPayload payload => ThinkingCard(
        content: payload.content,
        timestamp: message.createdAt,
        messageId: payload.streamingId ?? message.id,
        streamingStatus: payload.streamingStatus,
        isRead: message.isRead,
      ),
      ImagePayload payload => LegacyMessageCard(
        type: 'image',
        title: payload.title,
        timestamp: message.createdAt,
        subtitle: payload.caption,
        onTap: onTap,
        isRead: message.isRead,
        child: _buildImagePreview(payload),
      ),
      InteractivePayload payload => InteractiveMessageCard(
        title: payload.title,
        timestamp: message.createdAt,
        message: payload.message,
        summary: _getInteractiveSummary(payload),
        requestId: payload.requestId,
        interactiveType: payload.interactiveType,
        metadata: payload.metadata,
        onApprove: onApprove,
        onDeny: onDeny,
        onTap: onTap,
        isRead: message.isRead,
      ),
      // 用户消息 - 简单文本显示
      UserMessagePayload payload => LegacyMessageCard(
        type: 'userMessage',
        title: '用户消息',
        timestamp: message.createdAt,
        subtitle: payload.content,
        onTap: onTap,
        isRead: message.isRead,
      ),
      // 任务执行 - 使用折叠任务卡片
      TaskExecutionPayload() => TaskCard(message: message),
      // 隐藏消息 - 不渲染
      HiddenPayload() => const SizedBox.shrink(),
    };
  }

  /// 构建图片预览
  Widget _buildImagePreview(ImagePayload payload) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 150,
          maxWidth: double.infinity,
        ),
        child: CachedNetworkImage(
          imageUrl: payload.url,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => Container(
                height: 100,
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          errorWidget:
              (context, url, error) => Container(
                height: 100,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 32, color: Colors.grey),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildSuggestion(BuildContext context, String suggestion) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              suggestion,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取工具执行摘要
  String? _getToolSummary(String? description, String? currentStep) {
    if (description != null && description.isNotEmpty) {
      // 截取前 100 个字符
      return description.length > 100
          ? '${description.substring(0, 100)}...'
          : description;
    }
    if (currentStep != null && currentStep.isNotEmpty) {
      return currentStep.length > 100
          ? '${currentStep.substring(0, 100)}...'
          : currentStep;
    }
    return null;
  }

  /// 获取交互消息摘要
  String? _getInteractiveSummary(InteractivePayload payload) {
    if (payload.metadata != null) {
      final metadata = payload.metadata!;
      if (metadata.containsKey('command')) return metadata['command'] as String;
      if (metadata.containsKey('args')) return metadata['args'].toString();
      if (metadata.containsKey('path')) return metadata['path'] as String;
    }
    // 如果 message 比较短且包含路径或空格，可能包含命令信息
    if (payload.message.length < 100 &&
        (payload.message.contains('/') || payload.message.contains(' '))) {
      return payload.message;
    }
    return null;
  }
}
