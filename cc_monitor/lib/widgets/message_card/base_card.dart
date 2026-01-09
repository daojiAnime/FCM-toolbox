import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../common/colors.dart';
import '../base/responsive_builder.dart';

/// 消息卡片基类 (Template Method 模式)
/// 定义卡片构建的算法骨架，子类实现具体内容
abstract class BaseMessageCard extends StatelessWidget {
  const BaseMessageCard({
    super.key,
    required this.timestamp,
    this.isRead = false,
  });

  final DateTime timestamp;
  final bool isRead;

  // ==================== Template Method (模板方法) ====================

  /// 主构建方法 - 定义算法骨架
  /// 子类不应覆盖此方法，而是实现具体的钩子方法
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return buildContainer(
          context,
          r,
          child: Padding(
            padding: r.cardPaddingGeometry,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hook 1: 头部（可覆盖）
                buildHeader(context, r),
                // Hook 2: 内容（必须实现）
                SizedBox(height: r.contentGap),
                buildContent(context, r),
                // Hook 3: 底部（可覆盖）
                if (shouldShowFooter(context, r)) ...[
                  SizedBox(height: r.timestampTopGap),
                  buildFooter(context, r),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: getAnimationDuration(), curve: Curves.easeOut)
        .slideY(
          begin: 0.03,
          end: 0,
          duration: getAnimationDuration(),
          curve: Curves.easeOut,
        );
  }

  // ==================== 钩子方法 (Hook Methods) ====================

  /// Hook: 构建外层容器
  /// 子类可以覆盖以自定义容器样式（如 ThinkingCard 使用左边框而非卡片）
  Widget buildContainer(
    BuildContext context,
    ResponsiveValues r, {
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: r.cardMarginGeometry,
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: r.cardBorderRadiusGeometry,
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  /// Hook: 构建头部
  /// 默认实现：图标 + 标题 + 时间戳
  Widget buildHeader(BuildContext context, ResponsiveValues r) {
    final theme = Theme.of(context);
    final color = getHeaderColor(context);
    final icon = getHeaderIcon();
    final title = getHeaderTitle();
    final iconSize = r.isCompact ? 14.0 : 16.0;

    return Row(
      children: [
        Icon(icon, size: iconSize, color: color),
        SizedBox(width: r.titleIconGap),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: r.isCompact ? 13 : null,
              color:
                  isRead
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.55)
                      : theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          formatTimestamp(timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: r.isCompact ? 9 : 10,
          ),
        ),
      ],
    );
  }

  /// Hook: 构建内容（抽象方法，子类必须实现）
  Widget buildContent(BuildContext context, ResponsiveValues r);

  /// Hook: 构建底部
  /// 默认实现：时间戳（完整版）
  Widget buildFooter(BuildContext context, ResponsiveValues r) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.schedule_outlined,
          size: r.isCompact ? 10 : 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 3),
        Text(
          formatTimestamp(timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: r.isCompact ? 9 : 10,
          ),
        ),
      ],
    );
  }

  /// Hook: 是否显示底部
  /// 子类可覆盖以控制底部显示逻辑
  bool shouldShowFooter(BuildContext context, ResponsiveValues r) => false;

  // ==================== 子类必须实现的属性 ====================

  /// 获取头部图标
  IconData getHeaderIcon();

  /// 获取头部标题
  String getHeaderTitle();

  /// 获取头部颜色
  Color getHeaderColor(BuildContext context);

  // ==================== 共享工具方法 ====================

  /// 时间戳格式化（共享方法）
  String formatTimestamp(DateTime timestamp) {
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

  /// 构建状态标签（共享方法）
  Widget buildStatusLabel(
    BuildContext context,
    String label,
    Color color,
    ResponsiveValues r,
  ) {
    return Container(
      padding: r.statusLabelPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: r.statusLabelBorderRadiusGeometry,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: r.isCompact ? 9 : 10,
        ),
      ),
    );
  }

  /// 动画时长（可覆盖）
  Duration getAnimationDuration() => const Duration(milliseconds: 250);
}

// ==================== 具体实现类保留兼容性 ====================

/// 传统消息卡片（保留向后兼容）
/// 使用组合而非模板方法，适用于动态内容场景
class LegacyMessageCard extends StatelessWidget {
  const LegacyMessageCard({
    super.key,
    required this.type,
    required this.title,
    required this.timestamp,
    this.subtitle,
    this.summary,
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
  final String? summary;
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
    final r = context.responsive;
    final iconSize = r.isCompact ? 16.0 : 18.0;

    return Card(
          margin: r.cardMarginGeometry,
          color: theme.colorScheme.surfaceContainerHigh,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: r.cardBorderRadiusGeometry,
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: r.cardBorderRadiusGeometry,
            child: Padding(
              padding: r.cardPaddingGeometry,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: iconSize, color: color),
                      SizedBox(width: r.titleIconGap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: r.isCompact ? 13 : null,
                                color:
                                    isRead
                                        ? theme.colorScheme.onSurface
                                            .withValues(alpha: 0.55)
                                        : theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (summary != null && summary!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Text(
                                  summary!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                    fontSize: r.isCompact ? 10 : 11,
                                    fontFamily: 'monospace',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildStatusLabel(context, label, color, r),
                      if (trailing != null) ...[
                        SizedBox(width: r.isCompact ? 4 : 6),
                        trailing!,
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: r.contentGap),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: r.isCompact ? 12 : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (child != null) ...[
                    SizedBox(height: r.contentGap + 2),
                    child!,
                  ],
                  SizedBox(height: r.timestampTopGap),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: r.isCompact ? 10 : 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatTimestamp(timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: r.isCompact ? 9 : 10,
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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.03,
          end: 0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
  }

  Widget _buildStatusLabel(
    BuildContext context,
    String label,
    Color color,
    ResponsiveValues r,
  ) {
    return Container(
      padding: r.statusLabelPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: r.statusLabelBorderRadiusGeometry,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: r.isCompact ? 9 : 10,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${timestamp.month}/${timestamp.day}';
  }
}
