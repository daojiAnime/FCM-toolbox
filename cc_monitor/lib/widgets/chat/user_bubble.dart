import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../common/constants.dart';
import '../../models/message.dart';
import '../../models/payload/payload.dart';
import 'bubble_styles.dart';
import 'rainbow_text.dart';

/// 用户消息气泡 - 右对齐显示
class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.message, this.onRetry});

  final Message message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // 获取消息内容和状态
    final payload = message.payload;
    final content =
        payload is UserMessagePayload ? payload.content : message.title;
    final isPending = payload is UserMessagePayload && payload.isPending;
    final isFailed = payload is UserMessagePayload && payload.isFailed;

    return _UserBubbleContent(
          content: content,
          isPending: isPending,
          isFailed: isFailed,
          onRetry: onRetry,
          useRainbow: true,
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 200))
        .slideX(
          begin: 0.05,
          end: 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
  }
}

/// 简化版用户气泡 - 显示文本和发送状态
class SimpleUserBubble extends StatelessWidget {
  const SimpleUserBubble({
    super.key,
    required this.content,
    this.isPending = false,
    this.isFailed = false,
    this.onRetry,
  });

  final String content;
  final bool isPending;
  final bool isFailed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _UserBubbleContent(
      content: content,
      isPending: isPending,
      isFailed: isFailed,
      onRetry: onRetry,
      useRainbow: true,
    );
  }
}

/// 公共气泡内容组件
class _UserBubbleContent extends StatelessWidget {
  const _UserBubbleContent({
    required this.content,
    this.isPending = false,
    this.isFailed = false,
    this.onRetry,
    this.useRainbow = true,
  });

  final String content;
  final bool isPending;
  final bool isFailed;
  final VoidCallback? onRetry;
  final bool useRainbow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 响应式布局
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < AppConstants.compactBreakpoint;
    final maxBubbleWidth = BubbleStyles.getMaxBubbleWidth(screenWidth);

    // 文本样式
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color:
          isFailed
              ? colorScheme.onErrorContainer
              : colorScheme.onPrimaryContainer,
      height: 1.4,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 4 : 6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 重试按钮 (失败时显示)
          if (isFailed && onRetry != null)
            IconButton(
              icon: Icon(Icons.refresh, size: 18, color: colorScheme.error),
              onPressed: onRetry,
              tooltip: '重试发送',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),

          // 消息气泡
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              padding: BubbleStyles.getPadding(isCompact),
              decoration: BoxDecoration(
                color:
                    isFailed
                        ? colorScheme.errorContainer
                        : colorScheme.primaryContainer,
                borderRadius: BubbleStyles.userBubbleBorderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 消息内容 - 支持彩虹效果
                  if (useRainbow && hasRainbowWord(content))
                    RainbowText(text: content, style: textStyle)
                  else
                    SelectableText(content, style: textStyle),

                  // 状态指示
                  if (isPending || isFailed) _buildStatusIndicator(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPending) ...[
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '发送中...',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
          if (isFailed) ...[
            Icon(Icons.error_outline, size: 12, color: colorScheme.error),
            const SizedBox(width: 4),
            Text(
              '发送失败',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.error,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
