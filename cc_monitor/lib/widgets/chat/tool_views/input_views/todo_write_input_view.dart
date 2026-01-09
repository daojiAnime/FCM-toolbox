// TodoWrite 工具 Input 视图
// 显示任务列表

import 'package:flutter/material.dart';

/// TodoWrite Input 视图
/// 显示要写入的任务列表
class TodoWriteInputView {
  TodoWriteInputView._();

  static Widget build({
    required Map<String, dynamic>? input,
    required bool isCompact,
    required BuildContext context,
  }) {
    if (input == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 提取 todos 列表
    final todos = input['todos'] as List? ?? [];

    if (todos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.checklist,
                size: isCompact ? 12 : 14,
                color: Colors.teal.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                '${todos.length} tasks',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                  fontSize: isCompact ? 10 : 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 任务列表
          ...todos
              .take(5)
              .map((todo) => _buildTodoItem(context, todo, isCompact)),
          // 更多提示
          if (todos.length > 5) ...[
            const SizedBox(height: 4),
            Text(
              '(+${todos.length - 5} more)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
                fontSize: isCompact ? 9 : 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildTodoItem(
    BuildContext context,
    dynamic todo,
    bool isCompact,
  ) {
    if (todo is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = todo['content'] as String? ?? '';
    final status = todo['status'] as String? ?? 'pending';

    final (icon, color) = switch (status) {
      'completed' => (Icons.check_circle_outline, Colors.green.shade600),
      'in_progress' => (Icons.radio_button_checked, Colors.amber.shade600),
      _ => (Icons.radio_button_unchecked, colorScheme.outline),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isCompact ? 12 : 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              content,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    status == 'completed'
                        ? colorScheme.outline
                        : colorScheme.onSurfaceVariant,
                fontSize: isCompact ? 10 : 11,
                decoration:
                    status == 'completed' ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
