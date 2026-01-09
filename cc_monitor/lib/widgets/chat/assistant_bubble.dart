import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/constants.dart';
import '../../models/message.dart';
import '../../models/payload/payload.dart';
import '../streaming/streaming_markdown.dart';

/// AI 助手消息气泡 - 左对齐显示
class AssistantBubble extends ConsumerWidget {
  const AssistantBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
  });

  final Message message;
  final bool showAvatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 响应式布局
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < AppConstants.compactBreakpoint;
    final maxBubbleWidth = screenWidth * 0.85;

    // 获取消息内容和流式状态
    final payload = message.payload;
    final (content, streamingStatus, streamingId) = _extractContent(payload);

    return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 4 : 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI 头像
              if (showAvatar) ...[
                _buildAvatar(context, isCompact),
                SizedBox(width: isCompact ? 8 : 10),
              ],

              // 消息气泡
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 12 : 14,
                    vertical: isCompact ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(4),
                      topRight: const Radius.circular(16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 消息标题 (可选)
                      if (_shouldShowTitle(payload)) ...[
                        _buildTitle(context, payload),
                        const SizedBox(height: 8),
                      ],

                      // Markdown 内容
                      StreamingMarkdown(
                        content: content,
                        streamingStatus: streamingStatus,
                        messageId: streamingId,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 200))
        .slideX(
          begin: -0.05,
          end: 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
  }

  /// 构建 AI 头像
  Widget _buildAvatar(BuildContext context, bool isCompact) {
    final theme = Theme.of(context);
    final size = isCompact ? 28.0 : 32.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          'AI',
          style: TextStyle(
            fontSize: isCompact ? 10 : 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  /// 提取消息内容
  (String, StreamingStatus, String?) _extractContent(Payload payload) {
    return switch (payload) {
      MarkdownPayload(
        :final content,
        :final streamingStatus,
        :final streamingId,
      ) =>
        (content, streamingStatus, streamingId),
      CodePayload(:final code, :final streamingStatus) => (
        '```${payload.language ?? ''}\n$code\n```',
        streamingStatus,
        null,
      ),
      ProgressPayload(:final title, :final description) => (
        '**$title**\n\n${description ?? ''}',
        StreamingStatus.complete,
        null,
      ),
      CompletePayload(:final title, :final summary) => (
        '✅ **$title**\n\n${summary ?? '任务完成'}',
        StreamingStatus.complete,
        null,
      ),
      ErrorPayload(:final title, :final message) => (
        '❌ **$title**\n\n$message',
        StreamingStatus.complete,
        null,
      ),
      WarningPayload(:final title, :final message) => (
        '⚠️ **$title**\n\n$message',
        StreamingStatus.complete,
        null,
      ),
      _ => (message.title, StreamingStatus.complete, null),
    };
  }

  /// 是否显示标题
  bool _shouldShowTitle(Payload payload) {
    return switch (payload) {
      MarkdownPayload(:final title) => title.isNotEmpty && title != 'Claude 响应',
      CodePayload(:final title) => title.isNotEmpty,
      _ => false,
    };
  }

  /// 构建标题
  Widget _buildTitle(BuildContext context, Payload payload) {
    final theme = Theme.of(context);
    final title = switch (payload) {
      MarkdownPayload(:final title) => title,
      CodePayload(:final title) => title,
      _ => '',
    };

    return Row(
      children: [
        Icon(Icons.auto_awesome, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// 简化版 AI 气泡 - 直接显示 Markdown 内容
class SimpleAssistantBubble extends StatelessWidget {
  const SimpleAssistantBubble({
    super.key,
    required this.content,
    this.isStreaming = false,
  });

  final String content;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * 0.85;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 头像
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'AI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 气泡内容
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: StreamingMarkdown(
                content: content,
                streamingStatus:
                    isStreaming
                        ? StreamingStatus.streaming
                        : StreamingStatus.complete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
