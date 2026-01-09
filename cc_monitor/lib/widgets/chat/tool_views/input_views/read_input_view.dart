// Read 工具 Input 视图
// 显示要读取的文件路径

import 'package:flutter/material.dart';

/// Read Input 视图
/// 显示要读取的文件路径和可选的行范围
class ReadInputView {
  ReadInputView._();

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
    final offset = input['offset'] as int?;
    final limit = input['limit'] as int?;

    if (filePath.isEmpty) {
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
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: isCompact ? 12 : 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SelectableText(
                  filePath,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: isCompact ? 11 : 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          // 行范围信息
          if (offset != null || limit != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatLineRange(offset, limit),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
                fontSize: isCompact ? 9 : 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatLineRange(int? offset, int? limit) {
    if (offset != null && limit != null) {
      return 'Lines ${offset + 1}-${offset + limit}';
    } else if (offset != null) {
      return 'From line ${offset + 1}';
    } else if (limit != null) {
      return 'First $limit lines';
    }
    return '';
  }
}
