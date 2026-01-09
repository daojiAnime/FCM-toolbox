// Task 工具 Input 视图
// 对标 web: Task 只显示 prompt，用 Markdown 渲染

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Task Input 视图
/// 只显示 prompt 字段，用 Markdown 渲染
/// description 和 subagent_type 不在 Input 区域显示（它们用于标题/副标题）
class TaskInputView {
  TaskInputView._();

  static Widget build({
    required Map<String, dynamic>? input,
    required bool isCompact,
    required BuildContext context,
  }) {
    if (input == null) {
      return const SizedBox.shrink();
    }

    final prompt = input['prompt'] as String?;
    if (prompt == null || prompt.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: MarkdownBody(
        data: prompt,
        selectable: true,
        shrinkWrap: true,
        styleSheet: MarkdownStyleSheet(
          p: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: isCompact ? 11 : 12,
            height: 1.5,
          ),
          code: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
            fontSize: isCompact ? 10 : 11,
            fontFamily: 'monospace',
            backgroundColor: colorScheme.primaryContainer.withValues(
              alpha: 0.3,
            ),
          ),
          codeblockDecoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          listBullet: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: isCompact ? 11 : 12,
          ),
        ),
      ),
    );
  }
}
