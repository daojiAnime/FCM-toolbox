import 'package:flutter/material.dart';

import '../../../models/task.dart';

/// Read 工具结果视图
///
/// 特性：
/// - 显示文件路径（从 filePath 或 inputSummary 提取）
/// - 显示文件内容
/// - 代码块样式
class ReadResultView extends StatelessWidget {
  const ReadResultView({
    super.key,
    required this.task,
    required this.isCompact,
  });

  final TaskItem task;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 没有输出
    if (task.outputSummary == null || task.outputSummary!.isEmpty) {
      return _buildPlaceholder(context, '(no content)', isCompact);
    }

    // 提取文件路径
    final filePath = task.filePath ?? task.inputSummary;
    final fileName = filePath != null ? _extractFileName(filePath) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 文件名标签
        if (fileName != null) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 6 : 8,
              vertical: isCompact ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              fileName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontSize: isCompact ? 9 : 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
        ],

        // 文件内容
        _buildCodeBlock(context, task.outputSummary!, isCompact),
      ],
    );
  }

  String _extractFileName(String path) {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  Widget _buildCodeBlock(BuildContext context, String content, bool isCompact) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        content,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: isCompact ? 10 : 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, String text, bool isCompact) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.outline,
        fontSize: isCompact ? 10 : 11,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
