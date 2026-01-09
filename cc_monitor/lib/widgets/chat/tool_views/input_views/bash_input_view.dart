// Bash 工具 Input 视图
// 对标 web: 用 CodeBlock 渲染 command

import 'package:flutter/material.dart';

/// Bash Input 视图
/// 显示 command 字段，代码块样式
class BashInputView {
  BashInputView._();

  static Widget build({
    required Map<String, dynamic>? input,
    required bool isCompact,
    required BuildContext context,
  }) {
    if (input == null) {
      return const SizedBox.shrink();
    }

    // 尝试获取 command
    final command =
        input['command'] as String? ?? input['cmd'] as String? ?? '';

    if (command.isEmpty) {
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
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 终端提示符
          Text(
            '\$ ',
            style: TextStyle(
              color: Colors.green.shade600,
              fontSize: isCompact ? 11 : 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          // 命令内容
          Expanded(
            child: SelectableText(
              command,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: isCompact ? 11 : 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
