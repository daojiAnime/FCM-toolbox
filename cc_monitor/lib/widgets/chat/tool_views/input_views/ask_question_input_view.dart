// AskUserQuestion 工具 Input 视图
// 对标 web/src/components/ToolCard/views/AskUserQuestionView.tsx

import 'package:flutter/material.dart';

/// AskUserQuestion Input 视图
/// 显示问题和选项
class AskQuestionInputView {
  AskQuestionInputView._();

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

    // 提取问题列表
    final questions = input['questions'] as List? ?? [];

    if (questions.isEmpty) {
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
          for (var i = 0; i < questions.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildQuestion(context, questions[i], i + 1, isCompact),
          ],
        ],
      ),
    );
  }

  static Widget _buildQuestion(
    BuildContext context,
    dynamic question,
    int index,
    bool isCompact,
  ) {
    if (question is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final questionText = question['question'] as String? ?? '';
    final header = question['header'] as String?;
    final options = question['options'] as List? ?? [];
    final multiSelect = question['multiSelect'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 问题标题
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.help_outline,
              size: isCompact ? 14 : 16,
              color: Colors.amber.shade700,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (header != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        header,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontSize: isCompact ? 9 : 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    questionText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 选项列表
        if (options.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(left: isCompact ? 20 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final option in options)
                  _buildOption(context, option, multiSelect, isCompact),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static Widget _buildOption(
    BuildContext context,
    dynamic option,
    bool multiSelect,
    bool isCompact,
  ) {
    if (option is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final label = option['label'] as String? ?? '';
    final description = option['description'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            multiSelect
                ? Icons.check_box_outline_blank
                : Icons.radio_button_unchecked,
            size: isCompact ? 12 : 14,
            color: colorScheme.outline,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: isCompact ? 10 : 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                      fontSize: isCompact ? 9 : 10,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
