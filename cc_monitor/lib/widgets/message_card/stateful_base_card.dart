import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../base/responsive_builder.dart';

/// Stateful 消息卡片基类 (Template Method 模式)
/// 用于需要动画或状态管理的卡片（如可折叠卡片）
abstract class StatefulBaseMessageCard extends StatefulWidget {
  const StatefulBaseMessageCard({
    super.key,
    required this.timestamp,
    this.isRead = false,
  });

  final DateTime timestamp;
  final bool isRead;

  @override
  State<StatefulBaseMessageCard> createState();
}

/// Stateful 消息卡片状态基类
abstract class StatefulBaseMessageCardState<T extends StatefulBaseMessageCard>
    extends State<T> {
  // ==================== Template Method (模板方法) ====================

  /// 主构建方法 - 定义算法骨架
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return buildContainer(context, r, child: buildCardContent(context, r))
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

  /// Hook: 构建卡片内容（包含头部、内容、底部）
  Widget buildCardContent(BuildContext context, ResponsiveValues r) {
    return Padding(
      padding: r.cardPaddingGeometry,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(context, r),
          SizedBox(height: r.contentGap),
          buildContent(context, r),
          if (shouldShowFooter(context, r)) ...[
            SizedBox(height: r.timestampTopGap),
            buildFooter(context, r),
          ],
        ],
      ),
    );
  }

  /// Hook: 构建头部
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
                  widget.isRead
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.55)
                      : theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          formatTimestamp(widget.timestamp),
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
          formatTimestamp(widget.timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: r.isCompact ? 9 : 10,
          ),
        ),
      ],
    );
  }

  /// Hook: 是否显示底部
  bool shouldShowFooter(BuildContext context, ResponsiveValues r) => false;

  // ==================== 子类必须实现的属性 ====================

  IconData getHeaderIcon();
  String getHeaderTitle();
  Color getHeaderColor(BuildContext context);

  // ==================== 共享工具方法 ====================

  /// 时间戳格式化
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

  /// 构建状态标签
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

  /// 动画时长
  Duration getAnimationDuration() => const Duration(milliseconds: 200);
}
