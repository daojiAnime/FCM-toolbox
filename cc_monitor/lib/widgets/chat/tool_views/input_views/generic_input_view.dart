// 通用 Input 视图
// 用于没有专用视图的工具，显示 JSON 格式

import 'dart:convert';

import 'package:flutter/material.dart';

/// 通用 Input 视图
/// 将 input 格式化为 JSON 显示
class GenericInputView {
  GenericInputView._();

  static Widget build({
    required Map<String, dynamic>? input,
    required bool isCompact,
    required BuildContext context,
  }) {
    if (input == null || input.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 格式化 JSON
    String formattedJson;
    try {
      final encoder = const JsonEncoder.withIndent('  ');
      formattedJson = encoder.convert(input);
    } catch (e) {
      formattedJson = input.toString();
    }

    // 截断过长内容
    if (formattedJson.length > 1000) {
      formattedJson = '${formattedJson.substring(0, 1000)}...\n(truncated)';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SelectableText(
        formattedJson,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: isCompact ? 10 : 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
