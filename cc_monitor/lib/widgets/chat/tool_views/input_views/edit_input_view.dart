// Edit/MultiEdit 工具 Input 视图
// 对标 web: 显示 old_string -> new_string 的差异

import 'package:flutter/material.dart';

/// Edit Input 视图
/// 显示文件路径和编辑内容
class EditInputView {
  EditInputView._();

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
    final oldString = input['old_string'] as String? ?? '';
    final newString = input['new_string'] as String? ?? '';

    // MultiEdit 的情况
    final edits = input['edits'] as List?;

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
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_document,
                    size: isCompact ? 12 : 14,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(width: 6),
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

          // MultiEdit: 显示多个编辑
          if (edits != null && edits.isNotEmpty)
            _buildMultiEdits(context, edits, isCompact)
          // 单个编辑
          else if (oldString.isNotEmpty || newString.isNotEmpty)
            _buildSingleEdit(context, oldString, newString, isCompact),
        ],
      ),
    );
  }

  static Widget _buildSingleEdit(
    BuildContext context,
    String oldString,
    String newString,
    bool isCompact,
  ) {
    return Padding(
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 删除的内容
          if (oldString.isNotEmpty) ...[
            _buildDiffBlock(
              context,
              oldString,
              isDelete: true,
              isCompact: isCompact,
            ),
            const SizedBox(height: 8),
          ],
          // 添加的内容
          if (newString.isNotEmpty)
            _buildDiffBlock(
              context,
              newString,
              isDelete: false,
              isCompact: isCompact,
            ),
        ],
      ),
    );
  }

  static Widget _buildMultiEdits(
    BuildContext context,
    List edits,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 最多显示 3 个编辑
    final visibleEdits = edits.length > 3 ? edits.sublist(0, 3) : edits;
    final remaining = edits.length > 3 ? edits.length - 3 : 0;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < visibleEdits.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildEditItem(context, visibleEdits[i], i + 1, isCompact),
          ],
          if (remaining > 0) ...[
            const SizedBox(height: 8),
            Text(
              '(+$remaining more edits)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
                fontSize: isCompact ? 10 : 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildEditItem(
    BuildContext context,
    dynamic edit,
    int index,
    bool isCompact,
  ) {
    if (edit is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }

    final oldString = edit['old_string'] as String? ?? '';
    final newString = edit['new_string'] as String? ?? '';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit #$index',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.outline,
            fontSize: isCompact ? 9 : 10,
          ),
        ),
        const SizedBox(height: 4),
        if (oldString.isNotEmpty)
          _buildDiffBlock(
            context,
            oldString,
            isDelete: true,
            isCompact: isCompact,
          ),
        if (oldString.isNotEmpty && newString.isNotEmpty)
          const SizedBox(height: 4),
        if (newString.isNotEmpty)
          _buildDiffBlock(
            context,
            newString,
            isDelete: false,
            isCompact: isCompact,
          ),
      ],
    );
  }

  static Widget _buildDiffBlock(
    BuildContext context,
    String content, {
    required bool isDelete,
    required bool isCompact,
  }) {
    final theme = Theme.of(context);
    final color = isDelete ? Colors.red : Colors.green;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: color.shade600, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDelete ? '- ' : '+ ',
            style: TextStyle(
              color: color.shade600,
              fontSize: isCompact ? 10 : 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: SelectableText(
              _truncateContent(content, 500),
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.shade700,
                fontSize: isCompact ? 10 : 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _truncateContent(String content, int maxLen) {
    if (content.length <= maxLen) return content;
    return '${content.substring(0, maxLen)}...';
  }
}
