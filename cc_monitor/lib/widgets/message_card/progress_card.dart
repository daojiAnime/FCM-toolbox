import 'package:flutter/material.dart';
import '../../common/colors.dart';
import '../../common/constants.dart';
import 'base_card.dart';

/// 进度消息卡片
class ProgressMessageCard extends StatelessWidget {
  const ProgressMessageCard({
    super.key,
    required this.title,
    required this.timestamp,
    this.description,
    this.current = 0,
    this.total = 0,
    this.currentStep,
    this.onTap,
    this.isRead = false,
  });

  final String title;
  final DateTime timestamp;
  final String? description;
  final int current;
  final int total;
  final String? currentStep;
  final VoidCallback? onTap;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasProgress = total > 0;
    final progress = hasProgress ? current / total : 0.0;

    return BaseMessageCard(
      type: AppConstants.messageProgress,
      title: title,
      timestamp: timestamp,
      subtitle: description,
      onTap: onTap,
      isRead: isRead,
      child:
          hasProgress
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 进度条
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: MessageColors.progress.withValues(
                        alpha: 0.2,
                      ),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        MessageColors.progress,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 进度文本
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentStep != null)
                        Expanded(
                          child: Text(
                            currentStep!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
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
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : null,
    );
  }
}
