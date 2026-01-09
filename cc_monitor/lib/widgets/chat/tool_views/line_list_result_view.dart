import 'package:flutter/material.dart';

import '../../../models/task.dart';

/// LineList 工具结果视图 (Glob/Grep/LS)
///
/// 特性：
/// - 按行分割输出
/// - 列表显示
/// - 支持 Markdown 列表检测
class LineListResultView extends StatelessWidget {
  const LineListResultView({
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
      return _buildPlaceholder(context, '(no output)', isCompact);
    }

    final output = task.outputSummary!;

    // 检测是否为 Markdown 列表
    if (_isProbablyMarkdownList(output)) {
      return _buildMarkdownList(context, output, isCompact);
    }

    // 提取行列表
    final lines = _extractLineList(output);
    if (lines.isEmpty) {
      return _buildPlaceholder(context, '(no output)', isCompact);
    }

    return _buildLineList(context, lines, isCompact);
  }

  bool _isProbablyMarkdownList(String text) {
    final trimmed = text.trimLeft();
    return trimmed.startsWith('- ') ||
        trimmed.startsWith('* ') ||
        trimmed.startsWith('1. ');
  }

  List<String> _extractLineList(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Widget _buildLineList(
    BuildContext context,
    List<String> lines,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            lines.map((line) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: isCompact ? 1 : 2),
                child: Text(
                  line,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: isCompact ? 10 : 11,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildMarkdownList(
    BuildContext context,
    String content,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 简化版 Markdown 渲染
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            lines.map((line) {
              final trimmed = line.trimLeft();
              String displayText = trimmed;
              IconData? icon;

              // 解析列表标记
              if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
                displayText = trimmed.substring(2);
                icon = Icons.circle;
              } else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
                final match = RegExp(r'^\d+\.\s').firstMatch(trimmed);
                displayText = trimmed.substring(match!.end);
              }

              return Padding(
                padding: EdgeInsets.symmetric(vertical: isCompact ? 2 : 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: isCompact ? 4 : 5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        displayText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: isCompact ? 10 : 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
