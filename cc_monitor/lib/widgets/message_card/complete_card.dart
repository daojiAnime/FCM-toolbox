import 'package:flutter/material.dart';
import '../../common/constants.dart';
import '../../common/colors.dart';
import 'base_card.dart';

/// 完成消息卡片
class CompleteMessageCard extends StatelessWidget {
  const CompleteMessageCard({
    super.key,
    required this.title,
    required this.timestamp,
    this.summary,
    this.executionSummary,
    this.duration,
    this.toolCount,
    this.onTap,
    this.isRead = false,
  });

  final String title;
  final DateTime timestamp;
  final String? summary;
  final String? executionSummary;
  final int? duration;
  final int? toolCount;
  final VoidCallback? onTap;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    // 构建统计信息
    final stats = <String>[];
    if (duration != null && duration! > 0) {
      stats.add('耗时 ${_formatDuration(duration!)}');
    }
    if (toolCount != null && toolCount! > 0) {
      stats.add('$toolCount 次工具调用');
    }

    return LegacyMessageCard(
      type: AppConstants.messageComplete,
      title: title,
      timestamp: timestamp,
      subtitle: summary,
      summary: executionSummary,
      onTap: onTap,
      isRead: isRead,
      // trailing 已移除：状态标签"已完成"已提供足够信息
      child:
          stats.isNotEmpty
              ? Wrap(
                spacing: 12,
                children:
                    stats.map((stat) => _buildStatChip(context, stat)).toList(),
              )
              : null,
    );
  }

  Widget _buildStatChip(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MessageColors.complete.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: MessageColors.complete,
          fontWeight: FontWeight.w500,
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
