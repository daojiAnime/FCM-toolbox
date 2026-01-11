import 'package:flutter/material.dart';

import '../../../models/payload/payload.dart';
import 'task_status_icons.dart';

/// 任务卡片头部组件
class TaskHeader extends StatelessWidget {
  const TaskHeader({
    super.key,
    required this.payload,
    required this.isCompact,
    required this.expandAnimation,
  });

  final TaskExecutionPayload payload;
  final bool isCompact;
  final Animation<double> expandAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = payload.overallStatus;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      child: Row(
        children: [
          // 状态图标
          OverallStatusIcon(status: status, size: isCompact ? 16 : 18),
          SizedBox(width: isCompact ? 8 : 10),

          // 标题
          Expanded(
            child: Text(
              payload.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 13 : 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 耗时
          if (payload.durationMs != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _formatDuration(payload.durationMs!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                  fontSize: isCompact ? 10 : 11,
                ),
              ),
            ),

          // 展开箭头 - 带旋转动画
          RotationTransition(
            turns: Tween(
              begin: 0.0,
              end: 0.5,
            ).animate(expandAnimation), // 0 to 180 degrees
            child: Icon(
              Icons.keyboard_arrow_down,
              size: isCompact ? 20 : 24,
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化耗时
  String _formatDuration(int ms) {
    if (ms < 1000) return '${ms}ms';
    final seconds = ms / 1000;
    if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';
    final minutes = seconds / 60;
    return '${minutes.toStringAsFixed(1)}m';
  }
}
