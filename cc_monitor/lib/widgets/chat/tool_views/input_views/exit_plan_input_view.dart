// ExitPlanMode 工具 Input 视图
// 显示计划内容或简单提示

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// ExitPlanMode Input 视图
///
/// Displays plan content if available, otherwise shows a status indicator.
/// Mirrors web/src/components/ToolCard/views/ExitPlanModeView.tsx
class ExitPlanInputView {
  ExitPlanInputView._();

  static Widget build({
    required Map<String, dynamic>? input,
    required bool isCompact,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check for plan content in input
    final plan = input?['plan'] as String?;

    // If we have plan content, show it as markdown
    if (plan != null && plan.isNotEmpty && !isCompact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Plan Proposal',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Plan content as markdown
            MarkdownBody(
              data: plan,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
                code: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  backgroundColor: colorScheme.surfaceContainerLowest,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default: simple status indicator
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: isCompact ? 14 : 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Plan proposal ready for review',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: isCompact ? 11 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
