// Write 工具 Input 视图
// 对标 web: 显示新建文件内容（空 -> content）

import 'package:flutter/material.dart';

/// Write Input 视图
/// 显示要写入的文件路径和内容
class WriteInputView {
  WriteInputView._();

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

    // 提取字段
    final filePath =
        input['file_path'] as String? ?? input['path'] as String? ?? '';
    final content = input['content'] as String? ?? '';

    if (filePath.isEmpty && content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文件路径
          if (filePath.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 10,
                vertical: isCompact ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_box_outlined,
                    size: isCompact ? 12 : 14,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'New file: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                      fontSize: isCompact ? 10 : 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      filePath,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: isCompact ? 10 : 11,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // 文件内容预览
          if (content.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isCompact ? 8 : 10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                border: Border(
                  left: BorderSide(color: Colors.green.shade600, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '+ ',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: isCompact ? 10 : 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_countLines(content)} lines',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.green.shade700,
                          fontSize: isCompact ? 9 : 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    _truncateContent(content, 500),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                      fontSize: isCompact ? 10 : 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static int _countLines(String content) {
    return content.split('\n').length;
  }

  static String _truncateContent(String content, int maxLen) {
    if (content.length <= maxLen) return content;
    return '${content.substring(0, maxLen)}...\n(truncated)';
  }
}
