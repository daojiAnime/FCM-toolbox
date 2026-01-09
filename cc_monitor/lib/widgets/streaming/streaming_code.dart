import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/payload/payload.dart';
import '../../providers/streaming_provider.dart';
import 'typing_indicator.dart';

/// 紧凑型流式代码渲染组件
///
/// 设计原则（Vibe Coding）：
/// - 紧凑的文件头
/// - 流式光标指示
/// - 一键复制
class StreamingCode extends ConsumerWidget {
  const StreamingCode({
    super.key,
    required this.code,
    required this.streamingStatus,
    this.messageId,
    this.language,
    this.filename,
    this.startLine,
    this.maxHeight,
  });

  final String code;
  final StreamingStatus streamingStatus;
  final String? messageId;
  final String? language;
  final String? filename;
  final int? startLine;
  final double? maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final highlightTheme = isDark ? atomOneDarkTheme : atomOneLightTheme;

    // 如果有 messageId，监听实时流式内容
    final displayCode =
        messageId != null
            ? ref.watch(streamingContentProvider(messageId!))
            : code;

    final isStreaming =
        messageId != null
            ? ref.watch(isMessageStreamingProvider(messageId!))
            : streamingStatus == StreamingStatus.streaming;

    final effectiveCode = displayCode.isNotEmpty ? displayCode : code;
    final effectiveLanguage = _detectLanguage(language, filename);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 文件头（紧凑版）
        _buildCompactHeader(context, isStreaming),

        // 代码内容
        _buildCodeBlock(
          context,
          effectiveCode,
          effectiveLanguage,
          highlightTheme,
          isStreaming,
        ),
      ],
    );
  }

  /// 紧凑的文件头
  Widget _buildCompactHeader(BuildContext context, bool isStreaming) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
      child: Row(
        children: [
          // 语言/文件名
          Expanded(
            child: Row(
              children: [
                Icon(Icons.code, size: 14, color: colorScheme.outline),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    filename ?? language ?? 'code',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 流式状态指示
          if (isStreaming) ...[
            TypingIndicator(size: 3, spacing: 2, color: colorScheme.primary),
            const SizedBox(width: 8),
          ],

          // 复制按钮
          _CopyButton(code: code),
        ],
      ),
    );
  }

  /// 代码块
  Widget _buildCodeBlock(
    BuildContext context,
    String code,
    String language,
    Map<String, TextStyle> theme,
    bool isStreaming,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget codeWidget = ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
      child: HighlightView(
        code,
        language: language,
        theme: theme,
        padding: const EdgeInsets.all(10),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );

    // 添加最大高度限制
    if (maxHeight != null) {
      codeWidget = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: SingleChildScrollView(child: codeWidget),
      );
    }

    // 流式状态：添加闪烁光标
    if (isStreaming) {
      return Stack(
        children: [
          codeWidget,
          // 右下角闪烁光标
          Positioned(
            right: 12,
            bottom: 12,
            child: BlinkingCursor(
              color: colorScheme.primary,
              width: 2,
              height: 14,
            ),
          ),
        ],
      );
    }

    return codeWidget;
  }

  /// 检测语言
  String _detectLanguage(String? language, String? filename) {
    if (language != null && language.isNotEmpty) {
      return language.toLowerCase();
    }

    if (filename != null) {
      final ext = filename.split('.').last.toLowerCase();
      return _extensionToLanguage[ext] ?? 'plaintext';
    }

    return 'plaintext';
  }

  static const _extensionToLanguage = {
    'dart': 'dart',
    'js': 'javascript',
    'ts': 'typescript',
    'tsx': 'typescript',
    'jsx': 'javascript',
    'py': 'python',
    'rb': 'ruby',
    'go': 'go',
    'rs': 'rust',
    'java': 'java',
    'kt': 'kotlin',
    'swift': 'swift',
    'c': 'c',
    'cpp': 'cpp',
    'h': 'c',
    'hpp': 'cpp',
    'cs': 'csharp',
    'php': 'php',
    'html': 'html',
    'css': 'css',
    'scss': 'scss',
    'less': 'less',
    'json': 'json',
    'yaml': 'yaml',
    'yml': 'yaml',
    'xml': 'xml',
    'md': 'markdown',
    'sql': 'sql',
    'sh': 'bash',
    'bash': 'bash',
    'zsh': 'bash',
    'dockerfile': 'dockerfile',
    'toml': 'toml',
    'ini': 'ini',
    'env': 'bash',
  };
}

/// 复制按钮
class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.code});

  final String code;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: _copyCode,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          _copied ? Icons.check : Icons.copy,
          size: 14,
          color: _copied ? colorScheme.primary : colorScheme.outline,
        ),
      ),
    );
  }
}

/// 带 Diff 高亮的代码块
class StreamingCodeWithDiff extends StatelessWidget {
  const StreamingCodeWithDiff({
    super.key,
    required this.code,
    required this.streamingStatus,
    this.changes,
    this.language,
    this.filename,
  });

  final String code;
  final StreamingStatus streamingStatus;
  final List<dynamic>? changes; // CodeChange list
  final String? language;
  final String? filename;

  @override
  Widget build(BuildContext context) {
    // TODO: 实现 diff 高亮
    return StreamingCode(
      code: code,
      streamingStatus: streamingStatus,
      language: language,
      filename: filename,
    );
  }
}
