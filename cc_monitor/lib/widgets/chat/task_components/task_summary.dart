import 'package:flutter/material.dart';

import '../../../models/task.dart';
import '../../../utils/tool_presentation.dart';
import 'task_status_icons.dart';

/// 任务摘要组件（简洁模式，只显示状态图标和标题）
class TaskSummary extends StatelessWidget {
  const TaskSummary({super.key, required this.tasks, required this.isCompact});

  final List<TaskItem> tasks;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 6 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            tasks.map((task) {
              final presentation = getToolPresentation(
                toolName: task.toolName,
                description: task.description,
                filePath: task.filePath,
                input: task.input, // 传递完整 input 以支持工具专用字段提取
              );
              return Padding(
                padding: EdgeInsets.symmetric(vertical: isCompact ? 2 : 3),
                child: Row(
                  children: [
                    // 状态图标
                    SizedBox(
                      width: isCompact ? 16 : 18,
                      child: Center(
                        child: buildTaskItemStatusText(task.status, isCompact),
                      ),
                    ),
                    SizedBox(width: isCompact ? 6 : 8),
                    // 任务名称
                    Expanded(
                      child: Text(
                        task.displayName.isNotEmpty
                            ? task.displayName
                            : presentation.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              task.hasError
                                  ? colorScheme.error
                                  : colorScheme.onSurfaceVariant,
                          fontSize: isCompact ? 11 : 12,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}

/// "(+N more)" 提示组件
class MoreTasksIndicator extends StatelessWidget {
  const MoreTasksIndicator({
    super.key,
    required this.remainingCount,
    required this.isCompact,
  });

  final int remainingCount;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: isCompact ? 34 : 38,
        bottom: isCompact ? 6 : 8,
      ),
      child: Text(
        '(+$remainingCount more)',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.outline,
          fontSize: isCompact ? 11 : 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
