import 'package:flutter/material.dart';

import '../../../models/task.dart';

/// Markdown 工具结果视图 (Task/WebFetch/WebSearch)
///
/// 特性：
/// - Markdown 渲染（目前使用简化版）
/// - 自动检测 JSON/HTML，使用代码块显示
/// - 通用回退视图
class MarkdownResultView extends StatelessWidget {
  const MarkdownResultView({
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

    // 检测 JSON/HTML，使用代码块显示
    if (_looksLikeJson(output) || _looksLikeHtml(output)) {
      final language = _looksLikeJson(output) ? 'json' : 'html';
      return _buildCodeBlock(context, output, isCompact, language: language);
    }

    // 普通文本（简化版 Markdown 渲染）
    return _buildTextBlock(context, output, isCompact);
  }

  bool _looksLikeJson(String text) {
    final trimmed = text.trim();
    return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'));
  }

  bool _looksLikeHtml(String text) {
    final trimmed = text.trimLeft();
    return trimmed.startsWith('<!DOCTYPE') ||
        trimmed.startsWith('<html') ||
        trimmed.startsWith('<div') ||
        trimmed.startsWith('<span');
  }

  Widget _buildCodeBlock(
    BuildContext context,
    String content,
    bool isCompact, {
    String language = 'text',
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 语言标签
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 6 : 8,
            vertical: isCompact ? 2 : 3,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            language,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontSize: isCompact ? 9 : 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // 代码内容
        Container(
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
        ),
      ],
    );
  }

  Widget _buildTextBlock(BuildContext context, String content, bool isCompact) {
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
