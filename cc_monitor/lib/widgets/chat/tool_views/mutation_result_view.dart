import 'package:flutter/material.dart';

import '../../../models/task.dart';

/// Mutation 工具结果视图 (Edit/Write/NotebookEdit)
///
/// 特性：
/// - 成功时显示 "Done"
/// - 失败时显示错误信息
/// - 简洁样式
class MutationResultView extends StatelessWidget {
  const MutationResultView({
    super.key,
    required this.task,
    required this.isCompact,
  });

  final TaskItem task;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 有错误：显示错误信息
    if (task.hasError &&
        task.outputSummary != null &&
        task.outputSummary!.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 8 : 10),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          task.outputSummary!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onErrorContainer,
            fontSize: isCompact ? 10 : 11,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    // 完成状态：显示 "Done"
    if (task.status == TaskItemStatus.completed) {
      return _buildSuccessIndicator(context, isCompact);
    }

    // 其他状态：显示占位符
    return _buildPlaceholder(
      context,
      _getPlaceholderText(task.status),
      isCompact,
    );
  }

  Widget _buildSuccessIndicator(BuildContext context, bool isCompact) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: isCompact ? 14 : 16,
          color: Colors.green.shade600,
        ),
        const SizedBox(width: 6),
        Text(
          'Done',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.outline,
            fontSize: isCompact ? 11 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context, String text, bool isCompact) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.outline,
        fontSize: isCompact ? 10 : 11,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  String _getPlaceholderText(TaskItemStatus status) {
    return switch (status) {
      TaskItemStatus.pending => 'Waiting for permission…',
      TaskItemStatus.running => 'Running…',
      TaskItemStatus.completed => 'Done',
      TaskItemStatus.error => '(error)',
    };
  }
}
