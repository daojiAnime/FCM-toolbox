import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../models/task.dart';

/// Result view for TodoWrite tool
///
/// Displays the todo list with status indicators.
/// Supports both input.todos and result.newTodos as data sources.
/// Mirrors web/src/components/ToolCard/views/TodoWriteView.tsx
class TodoWriteResultView extends StatelessWidget {
  final TaskItem task;
  final bool isCompact;

  const TodoWriteResultView({
    super.key,
    required this.task,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final todos = _extractTodos();
    if (todos.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.checklist,
                size: isCompact ? 14 : 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '${todos.length} item${todos.length > 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Todo items
          ..._buildTodoItems(context, todos),
        ],
      ),
    );
  }

  /// Extract todos from input or result
  List<Map<String, dynamic>> _extractTodos() {
    // Try input.todos first
    final input = task.input;
    if (input != null) {
      final inputTodos = input['todos'];
      if (inputTodos is List && inputTodos.isNotEmpty) {
        return List<Map<String, dynamic>>.from(
          inputTodos.map((e) => e as Map<String, dynamic>),
        );
      }
    }

    // Fall back to result.newTodos (outputSummary might be JSON string)
    final result = task.outputSummary;
    if (result != null && result.isNotEmpty) {
      try {
        final parsed = jsonDecode(result);
        if (parsed is Map<String, dynamic>) {
          final resultTodos = parsed['newTodos'];
          if (resultTodos is List && resultTodos.isNotEmpty) {
            return List<Map<String, dynamic>>.from(
              resultTodos.map((e) => e as Map<String, dynamic>),
            );
          }
        }
      } catch (_) {
        // Not valid JSON, ignore
      }
    }

    return [];
  }

  List<Widget> _buildTodoItems(
    BuildContext context,
    List<Map<String, dynamic>> todos,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxItems = isCompact ? 5 : todos.length;
    final displayTodos = todos.take(maxItems).toList();
    final remaining = todos.length - maxItems;

    final items =
        displayTodos.map((todo) {
          final content = todo['content'] as String? ?? '';
          final status = todo['status'] as String? ?? 'pending';

          final (icon, color) = switch (status) {
            'completed' => (Icons.check_circle_outline, Colors.green.shade600),
            'in_progress' => (
              Icons.radio_button_checked,
              Colors.amber.shade600,
            ),
            _ => (Icons.radio_button_unchecked, colorScheme.outline),
          };

          final textStyle = TextStyle(
            fontSize: isCompact ? 12 : 13,
            color:
                status == 'completed'
                    ? colorScheme.outline
                    : colorScheme.onSurface,
            decoration:
                status == 'completed' ? TextDecoration.lineThrough : null,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: isCompact ? 14 : 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    content,
                    style: textStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList();

    if (remaining > 0) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '+$remaining more',
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              color: colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return items;
  }
}
