// Glob/Grep/LS 工具 Input 视图
// 显示搜索模式和路径

import 'package:flutter/material.dart';

/// Glob/Grep/LS Input 视图
class GlobGrepInputView {
  GlobGrepInputView._();

  /// Glob 视图
  static Widget buildGlob({
    required Map<String, dynamic>? input,
    required bool isCompact,
    required BuildContext context,
  }) {
    return _build(
      input: input,
      isCompact: isCompact,
      context: context,
      icon: Icons.search,
      iconColor: Colors.blue.shade600,
      label: 'Pattern',
      patternKey: 'pattern',
    );
  }

  /// Grep 视图
  static Widget buildGrep({
    required Map<String, dynamic>? input,
    required bool isCompact,
    required BuildContext context,
  }) {
    return _build(
      input: input,
      isCompact: isCompact,
      context: context,
      icon: Icons.find_in_page_outlined,
      iconColor: Colors.blue.shade600,
      label: 'Search',
      patternKey: 'pattern',
    );
  }

  /// LS 视图
  static Widget buildLS({
    required Map<String, dynamic>? input,
    required bool isCompact,
    required BuildContext context,
  }) {
    return _build(
      input: input,
      isCompact: isCompact,
      context: context,
      icon: Icons.folder_outlined,
      iconColor: Colors.amber.shade700,
      label: 'Directory',
      patternKey: 'path',
    );
  }

  static Widget _build({
    required Map<String, dynamic>? input,
    required bool isCompact,
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String patternKey,
  }) {
    if (input == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 提取字段
    final pattern = input[patternKey] as String? ?? '';
    final path = input['path'] as String? ?? input['directory'] as String?;

    if (pattern.isEmpty && path == null) {
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
          // 搜索模式/路径
          Row(
            children: [
              Icon(icon, size: isCompact ? 12 : 14, color: iconColor),
              const SizedBox(width: 6),
              Text(
                '$label: ',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                  fontSize: isCompact ? 10 : 11,
                ),
              ),
              Expanded(
                child: SelectableText(
                  pattern.isNotEmpty ? pattern : (path ?? ''),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: isCompact ? 11 : 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          // 路径（如果和 pattern 不同）
          if (path != null && pattern.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(width: isCompact ? 18 : 20), // 对齐图标
                Text(
                  'in: ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                    fontSize: isCompact ? 10 : 11,
                  ),
                ),
                Expanded(
                  child: Text(
                    path,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                      fontSize: isCompact ? 10 : 11,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
