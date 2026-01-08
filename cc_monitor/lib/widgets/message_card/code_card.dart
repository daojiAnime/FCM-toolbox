import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import '../../common/constants.dart';
import 'base_card.dart';

/// 代码消息卡片
class CodeMessageCard extends StatelessWidget {
  const CodeMessageCard({
    super.key,
    required this.title,
    required this.timestamp,
    required this.code,
    this.language,
    this.filename,
    this.startLine,
    this.onTap,
    this.isRead = false,
  });

  final String title;
  final DateTime timestamp;
  final String code;
  final String? language;
  final String? filename;
  final int? startLine;
  final VoidCallback? onTap;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BaseMessageCard(
      type: AppConstants.messageCode,
      title: title,
      timestamp: timestamp,
      subtitle: filename,
      onTap: onTap,
      isRead: isRead,
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 18),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: code));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('代码已复制')));
        },
        tooltip: '复制代码',
        visualDensity: VisualDensity.compact,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: HighlightView(
              code,
              language: _detectLanguage(language, filename),
              theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
              padding: const EdgeInsets.all(12),
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _detectLanguage(String? language, String? filename) {
    if (language != null && language.isNotEmpty) {
      return language;
    }

    if (filename != null) {
      final ext = filename.split('.').last.toLowerCase();
      return switch (ext) {
        'dart' => 'dart',
        'ts' || 'tsx' => 'typescript',
        'js' || 'jsx' => 'javascript',
        'py' => 'python',
        'rs' => 'rust',
        'go' => 'go',
        'java' => 'java',
        'kt' || 'kts' => 'kotlin',
        'swift' => 'swift',
        'rb' => 'ruby',
        'php' => 'php',
        'c' || 'h' => 'c',
        'cpp' || 'cc' || 'hpp' => 'cpp',
        'cs' => 'csharp',
        'json' => 'json',
        'yaml' || 'yml' => 'yaml',
        'xml' => 'xml',
        'html' || 'htm' => 'html',
        'css' => 'css',
        'scss' || 'sass' => 'scss',
        'sql' => 'sql',
        'sh' || 'bash' || 'zsh' => 'bash',
        'md' => 'markdown',
        _ => 'plaintext',
      };
    }

    return 'plaintext';
  }
}
