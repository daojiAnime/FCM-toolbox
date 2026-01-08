import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../common/colors.dart';
import '../common/constants.dart';
import '../models/session.dart';

/// 会话卡片
class SessionCard extends StatelessWidget {
  const SessionCard({super.key, required this.session, this.onTap});

  final Session session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final statusColor = switch (session.status) {
      SessionStatus.running => MessageColors.progress,
      SessionStatus.waiting => MessageColors.warning,
      SessionStatus.completed => MessageColors.complete,
    };

    final statusText = switch (session.status) {
      SessionStatus.running => '运行中',
      SessionStatus.waiting => '等待响应',
      SessionStatus.completed => '已完成',
    };

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
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行
                  Row(
                    children: [
                      // 状态指示点
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 项目名称
                      Expanded(
                        child: Text(
                          session.projectName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 状态标签
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.statusLabelPaddingH,
                          vertical: AppConstants.statusLabelPaddingV,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            AppConstants.statusLabelBorderRadius,
                          ),
                        ),
                        child: Text(
                          statusText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 进度条 (如果有)
                  if (session.progress != null &&
                      session.progress!.total > 0) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: session.progressPercent / 100,
                        minHeight: 6,
                        backgroundColor: statusColor.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (session.progress!.currentStep != null)
                          Expanded(
                            child: Text(
                              session.progress!.currentStep!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Text(
                          '${session.progressPercent}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // 底部信息
                  SizedBox(height: AppConstants.timestampTopGap),
                  Row(
                    children: [
                      // 工具调用次数
                      if (session.toolCallCount > 0) ...[
                        Icon(
                          Icons.build_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.45,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${session.toolCallCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      // 持续时间
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(session.duration),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // 箭头
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
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

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}秒';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}分钟';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return minutes > 0 ? '$hours小时$minutes分钟' : '$hours小时';
    }
  }
}
