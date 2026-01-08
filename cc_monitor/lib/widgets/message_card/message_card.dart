import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/message.dart';
import '../../models/payload/payload.dart';
import 'base_card.dart';
import 'progress_card.dart';
import 'complete_card.dart';
import 'code_card.dart';
import 'interactive_card.dart';

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
        duration: payload.duration,
        toolCount: payload.toolCount,
        onTap: onTap,
        isRead: message.isRead,
      ),
      ErrorPayload payload => BaseMessageCard(
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
      WarningPayload payload => BaseMessageCard(
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
      MarkdownPayload payload => BaseMessageCard(
        type: 'markdown',
        title: payload.title,
        timestamp: message.createdAt,
        subtitle:
            payload.content.length > 100
                ? '${payload.content.substring(0, 100)}...'
                : payload.content,
        onTap: onTap,
        isRead: message.isRead,
      ),
      ImagePayload payload => BaseMessageCard(
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
        requestId: payload.requestId,
        interactiveType: payload.interactiveType,
        metadata: payload.metadata,
        onApprove: onApprove,
        onDeny: onDeny,
        onTap: onTap,
        isRead: message.isRead,
      ),
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
}
