// ExitPlanMode 工具 Input 视图
// 显示计划内容（通常无 input，只是一个信号）

import 'package:flutter/material.dart';

/// ExitPlanMode Input 视图
/// 通常 ExitPlanMode 没有实际 input 内容
class ExitPlanInputView {
  ExitPlanInputView._();

  static Widget build({
    required Map<String, dynamic>? input,
    required bool isCompact,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ExitPlanMode 通常没有 input，显示一个简单的提示
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
