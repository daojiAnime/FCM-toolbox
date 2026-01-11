import 'package:flutter/material.dart';

import '../../../models/payload/payload.dart';
import '../../../models/task.dart';
import 'task_item_row.dart';

/// 任务卡片展开内容组件
/// 显示 Input 提示词 + 完整任务列表
class TaskExpandedContent extends StatelessWidget {
  const TaskExpandedContent({
    super.key,
    required this.payload,
    required this.tasks,
    required this.isCompact,
  });

  final TaskExecutionPayload payload;
  final List<TaskItem> tasks;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasPrompt = payload.prompt != null && payload.prompt!.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 8 : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input 区域 (类似 hapi web Dialog 中的 Input)
          if (hasPrompt) ...[
            Text(
              'Input',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 10 : 11,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isCompact ? 10 : 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                payload.prompt!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: isCompact ? 12 : 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 任务列表
          if (tasks.isNotEmpty) ...[
            Text(
              'Tasks (${tasks.length})',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 10 : 11,
              ),
            ),
            const SizedBox(height: 6),
            ...tasks.map(
              (task) => TaskItemRow(task: task, isCompact: isCompact),
            ),
          ],
        ],
      ),
    );
  }
}
