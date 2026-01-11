import 'package:flutter/material.dart';
import '../../common/colors.dart';
import '../base/responsive_builder.dart';
import 'base_card.dart';

/// 完成消息卡片 - 继承 BaseMessageCard，使用 Template Method 模式
class CompleteMessageCard extends BaseMessageCard {
  const CompleteMessageCard({
    super.key,
    required this.title,
    required super.timestamp,
    this.summary,
    this.executionSummary,
    this.duration,
    this.toolCount,
    super.isRead,
  });

  final String title;
  final String? summary;
  final String? executionSummary;
  final int? duration;
  final int? toolCount;

  // ==================== 实现抽象方法 ====================

  @override
  IconData getHeaderIcon() => Icons.check_circle;

  @override
  String getHeaderTitle() => title;

  @override
  Color getHeaderColor(BuildContext context) => MessageColors.complete;

  // ==================== 实现钩子方法 ====================

  @override
  Widget buildContent(BuildContext context, ResponsiveValues r) {
    final theme = Theme.of(context);

    // 构建统计信息
    final stats = <String>[];
    if (duration != null && duration! > 0) {
      stats.add('耗时 ${_formatDuration(duration!)}');
    }
    if (toolCount != null && toolCount! > 0) {
      stats.add('$toolCount 次工具调用');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 摘要
        if (summary != null && summary!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: r.contentGap),
            child: Text(
              summary!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: r.isCompact ? 12 : 14,
              ),
            ),
          ),
        // 执行摘要（高亮显示）
        if (executionSummary != null &&
            executionSummary!.isNotEmpty &&
            executionSummary != summary)
          Padding(
            padding: EdgeInsets.only(bottom: r.contentGap),
            child: Container(
              padding: EdgeInsets.all(r.contentGap),
              decoration: BoxDecoration(
                color: MessageColors.complete.withValues(alpha: 0.1),
                borderRadius: r.cardBorderRadiusGeometry,
              ),
              child: Text(
                executionSummary!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MessageColors.complete.withValues(alpha: 0.9),
                  fontSize: r.isCompact ? 11 : 12,
                ),
              ),
            ),
          ),
        // 统计信息
        if (stats.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children:
                stats.map((stat) => _buildStatChip(context, stat, r)).toList(),
          ),
      ],
    );
  }

  // ==================== 私有辅助方法 ====================

  Widget _buildStatChip(BuildContext context, String text, ResponsiveValues r) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.isCompact ? 6 : 8,
        vertical: r.isCompact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: MessageColors.complete.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: MessageColors.complete,
          fontWeight: FontWeight.w500,
          fontSize: r.isCompact ? 10 : 11,
        ),
      ),
    );
  }

  String _formatDuration(int ms) {
    final seconds = ms ~/ 1000;
    if (seconds < 60) return '$seconds秒';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return remainingSeconds > 0 ? '$minutes分$remainingSeconds秒' : '$minutes分钟';
  }
}
