import 'package:flutter/material.dart';

import '../../../models/task.dart';

/// Bash 工具结果视图
///
/// 特性：
/// - 提取 stdout/stderr
/// - 代码块显示
/// - 错误高亮
class BashResultView extends StatelessWidget {
  const BashResultView({
    super.key,
    required this.task,
    required this.isCompact,
  });

  final TaskItem task;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    // 没有输出
    if (task.outputSummary == null || task.outputSummary!.isEmpty) {
      return _buildPlaceholder(
        context,
        _getPlaceholderText(task.status),
        isCompact,
      );
    }

    final output = task.outputSummary!;

    // 尝试提取 stdout/stderr（如果是结构化输出）
    final stdio = _extractStdoutStderr(output);
    if (stdio != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stdio['stdout'] != null) ...[
            _buildSectionLabel(context, 'stdout', isCompact),
            const SizedBox(height: 4),
            _buildCodeBlock(
              context,
              stdio['stdout']!,
              isCompact,
              isError: false,
            ),
            if (stdio['stderr'] != null) const SizedBox(height: 8),
          ],
          if (stdio['stderr'] != null) ...[
            _buildSectionLabel(context, 'stderr', isCompact),
            const SizedBox(height: 4),
            _buildCodeBlock(
              context,
              stdio['stderr']!,
              isCompact,
              isError: true,
            ),
          ],
        ],
      );
    }

    // 普通文本输出
    return _buildCodeBlock(context, output, isCompact, isError: task.hasError);
  }

  /// 尝试从 JSON 格式提取 stdout/stderr
  Map<String, String>? _extractStdoutStderr(String output) {
    // 简单检测：如果包含 "stdout" 和 "stderr" 字样
    if (!output.contains('stdout') && !output.contains('stderr')) {
      return null;
    }

    try {
      // 尝试解析结构化数据（通过正则提取）
      final stdoutMatch = RegExp(
        r'"stdout"\s*:\s*"([^"]*)"',
      ).firstMatch(output);
      final stderrMatch = RegExp(
        r'"stderr"\s*:\s*"([^"]*)"',
      ).firstMatch(output);

      if (stdoutMatch != null || stderrMatch != null) {
        return {
          if (stdoutMatch != null)
            'stdout': _unescapeString(stdoutMatch.group(1)!),
          if (stderrMatch != null)
            'stderr': _unescapeString(stderrMatch.group(1)!),
        };
      }
    } catch (e) {
      // 解析失败，返回 null
    }

    return null;
  }

  String _unescapeString(String str) {
    return str
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', '\\');
  }

  Widget _buildSectionLabel(
    BuildContext context,
    String label,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: colorScheme.outline,
        fontWeight: FontWeight.w600,
        fontSize: isCompact ? 9 : 10,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildCodeBlock(
    BuildContext context,
    String content,
    bool isCompact, {
    required bool isError,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color:
            isError
                ? colorScheme.errorContainer.withValues(alpha: 0.3)
                : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        content,
        style: theme.textTheme.bodySmall?.copyWith(
          color:
              isError
                  ? colorScheme.onErrorContainer
                  : colorScheme.onSurfaceVariant,
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

  String _getPlaceholderText(TaskItemStatus status) {
    return switch (status) {
      TaskItemStatus.pending => 'Waiting for permission…',
      TaskItemStatus.running => 'Running…',
      TaskItemStatus.completed => '(no output)',
      TaskItemStatus.error => '(error)',
    };
  }
}
