import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../common/colors.dart';
import '../../common/constants.dart';

/// 消息卡片基类
class BaseMessageCard extends StatelessWidget {
  const BaseMessageCard({
    super.key,
    required this.type,
    required this.title,
    required this.timestamp,
    this.subtitle,
    this.child,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.isRead = false,
  });

  final String type;
  final String title;
  final DateTime timestamp;
  final String? subtitle;
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final color = MessageColors.fromType(type);
    final icon = MessageColors.iconFromType(type);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isDark ? MessageColors.cardBackgroundDark : MessageColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Row(
          children: [
            // 左侧彩色指示条
            Container(
              width: AppConstants.cardIndicatorWidth,
              height: 80,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.cardBorderRadius),
                  bottomLeft: Radius.circular(AppConstants.cardBorderRadius),
                ),
              ),
            ),
            // 内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行
                    Row(
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isRead
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                                  : theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    ),
                    // 副标题
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // 自定义内容
                    if (child != null) ...[
                      const SizedBox(height: 8),
                      child!,
                    ],
                    // 时间戳
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppConstants.animationNormal).slideX(
          begin: 0.1,
          end: 0,
          duration: AppConstants.animationNormal,
          curve: Curves.easeOutCubic,
        );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}
