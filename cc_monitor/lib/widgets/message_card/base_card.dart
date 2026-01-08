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
    final label = MessageColors.labelFromType(type);
    final theme = Theme.of(context);

    return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: theme.colorScheme.surfaceContainerHigh,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行（带状态标签）
                  Row(
                    children: [
                      Icon(icon, size: 20, color: color),
                      SizedBox(width: AppConstants.titleIconGap),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isRead
                                ? theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  )
                                : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusLabel(context, label, color),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
                      ],
                    ],
                  ),
                  // 副标题
                  if (subtitle != null) ...[
                    SizedBox(height: AppConstants.contentGap),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // 自定义内容
                  if (child != null) ...[const SizedBox(height: 10), child!],
                  // 时间戳
                  SizedBox(height: AppConstants.timestampTopGap),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.05,
          end: 0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1.0, 1.0),
          duration: const Duration(milliseconds: 350),
        );
  }

  /// 构建状态标签
  Widget _buildStatusLabel(BuildContext context, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.statusLabelPaddingH,
        vertical: AppConstants.statusLabelPaddingV,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(
          AppConstants.statusLabelBorderRadius,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
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
