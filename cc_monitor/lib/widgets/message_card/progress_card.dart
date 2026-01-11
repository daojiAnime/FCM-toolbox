import 'package:flutter/material.dart';
import '../../common/colors.dart';
import '../base/responsive_builder.dart';
import 'base_card.dart';

/// 进度消息卡片 - 继承 BaseMessageCard，使用 Template Method 模式
class ProgressMessageCard extends BaseMessageCard {
  const ProgressMessageCard({
    super.key,
    required this.title,
    required super.timestamp,
    this.description,
    this.summary,
    this.current = 0,
    this.total = 0,
    this.currentStep,
    super.isRead,
  });

  final String title;
  final String? description;
  final String? summary;
  final int current;
  final int total;
  final String? currentStep;

  // ==================== 实现抽象方法 ====================

  @override
  IconData getHeaderIcon() => Icons.hourglass_empty;

  @override
  String getHeaderTitle() => title;

  @override
  Color getHeaderColor(BuildContext context) => MessageColors.progress;

  // ==================== 实现钩子方法 ====================

  @override
  Widget buildContent(BuildContext context, ResponsiveValues r) {
    final theme = Theme.of(context);
    final hasProgress = total > 0;
    final progress = hasProgress ? current / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 描述或摘要
        if (description != null && description!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: r.contentGap),
            child: Text(
              description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: r.isCompact ? 12 : 14,
              ),
            ),
          ),
        if (summary != null && summary != description && summary!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: r.contentGap),
            child: Text(
              summary!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: r.isCompact ? 11 : 12,
              ),
            ),
          ),
        // 进度条区域
        if (hasProgress) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: MessageColors.progress.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                MessageColors.progress,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentStep != null)
                Expanded(
                  child: Text(
                    currentStep!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontSize: r.isCompact ? 11 : 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Text(
                '$current / $total',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: MessageColors.progress,
                  fontSize: r.isCompact ? 11 : 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
