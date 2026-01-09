import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/payload/payload.dart';
import '../../providers/streaming_provider.dart';
import 'typing_indicator.dart';

/// 紧凑型流式 Markdown 渲染组件
///
/// 设计原则（Vibe Coding）：
/// - 无边距浪费，内容区域最大化
/// - 内联状态指示，不占用额外行
/// - 信息密集，同屏展示更多内容
class StreamingMarkdown extends ConsumerWidget {
  const StreamingMarkdown({
    super.key,
    required this.content,
    required this.streamingStatus,
    this.messageId,
    this.selectable = true,
    this.shrinkWrap = true,
    this.onTapLink,
    this.textColor,
  });

  final String content;
  final StreamingStatus streamingStatus;
  final String? messageId;
  final bool selectable;
  final bool shrinkWrap;
  final void Function(String text, String? href, String title)? onTapLink;
  final Color? textColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 如果有 messageId，监听实时流式内容
    final displayContent =
        messageId != null
            ? ref.watch(streamingContentProvider(messageId!))
            : content;

    final isStreaming =
        messageId != null
            ? ref.watch(isMessageStreamingProvider(messageId!))
            : streamingStatus == StreamingStatus.streaming;

    final effectiveContent =
        displayContent.isNotEmpty ? displayContent : content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Markdown 内容
        MarkdownBody(
          data: effectiveContent,
          selectable: selectable,
          shrinkWrap: shrinkWrap,
          styleSheet: _compactStyleSheet(context, textColor),
          onTapLink: onTapLink ?? _defaultOnTapLink,
        ),
        // 内联指示器（streaming 时）
        if (isStreaming)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TypingIndicator(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  /// 紧凑型样式表
  MarkdownStyleSheet _compactStyleSheet(
    BuildContext context,
    Color? textColor,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return MarkdownStyleSheet(
      // 段落 - 紧凑行高
      p: textTheme.bodyMedium?.copyWith(height: 1.4, color: textColor),
      pPadding: EdgeInsets.zero,

      // 标题 - 减少间距
      h1: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      h1Padding: const EdgeInsets.only(top: 8, bottom: 4),
      h2: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      h2Padding: const EdgeInsets.only(top: 6, bottom: 3),
      h3: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      h3Padding: const EdgeInsets.only(top: 4, bottom: 2),

      // 块间距 - 紧凑
      blockSpacing: 8,

      // 代码 - 紧凑
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        color: colorScheme.primary,
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      ),
      codeblockDecoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      codeblockPadding: const EdgeInsets.all(10),

      // 引用 - 紧凑
      blockquote: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),

      // 列表 - 紧凑
      listBullet: textTheme.bodyMedium,
      listBulletPadding: const EdgeInsets.only(right: 6),
      listIndent: 16,

      // 链接
      a: TextStyle(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: colorScheme.primary.withValues(alpha: 0.5),
      ),

      // 表格 - 紧凑
      tableHead: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      tableBody: textTheme.bodyMedium,
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      tableBorder: TableBorder.all(
        color: colorScheme.outline.withValues(alpha: 0.3),
        width: 1,
      ),

      // 分隔线
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
    );
  }

  void _defaultOnTapLink(String text, String? href, String title) {
    // TODO: 实现链接点击处理
    // 'Link tapped: $href');
  }
}

/// 带状态容器的流式 Markdown
class StreamingMarkdownContainer extends ConsumerWidget {
  const StreamingMarkdownContainer({
    super.key,
    required this.content,
    required this.streamingStatus,
    this.messageId,
    this.showStatusHeader = false,
  });

  final String content;
  final StreamingStatus streamingStatus;
  final String? messageId;
  final bool showStatusHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isStreaming =
        messageId != null
            ? ref.watch(isMessageStreamingProvider(messageId!))
            : streamingStatus == StreamingStatus.streaming;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 状态头部（可选）
        if (showStatusHeader && isStreaming)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '正在生成...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

        // Markdown 内容
        StreamingMarkdown(
          content: content,
          streamingStatus: streamingStatus,
          messageId: messageId,
        ),

        // 完成状态（可选）
        if (showStatusHeader && streamingStatus == StreamingStatus.complete)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 12,
                  color: theme.colorScheme.outline.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  '生成完成',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
