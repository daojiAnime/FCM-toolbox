import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import '../../common/colors.dart';
import '../base/responsive_builder.dart';
import 'base_card.dart';

/// 代码消息卡片 - 继承 BaseMessageCard，使用 Template Method 模式
class CodeMessageCard extends BaseMessageCard {
  const CodeMessageCard({
    super.key,
    required this.title,
    required super.timestamp,
    required this.code,
    this.language,
    this.filename,
    this.startLine,
    super.isRead,
  });

  final String title;
  final String code;
  final String? language;
  final String? filename;
  final int? startLine;

  // ==================== 实现抽象方法 ====================

  @override
  IconData getHeaderIcon() => Icons.code;

  @override
  String getHeaderTitle() => title;

  @override
  Color getHeaderColor(BuildContext context) => MessageColors.code;

  // ==================== 实现钩子方法 ====================

  @override
  Widget buildContent(BuildContext context, ResponsiveValues r) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 文件名和起始行号
        if (filename != null)
          Padding(
            padding: EdgeInsets.only(bottom: r.contentGap / 2),
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: r.isCompact ? 12 : 14,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    filename!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontFamily: 'monospace',
                      fontSize: r.isCompact ? 10 : 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (startLine != null)
                  Text(
                    ':$startLine',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline.withValues(alpha: 0.7),
                      fontFamily: 'monospace',
                      fontSize: r.isCompact ? 10 : 11,
                    ),
                  ),
              ],
            ),
          ),
        // 代码高亮区域
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(maxHeight: r.isCompact ? 160 : 200),
            child: SingleChildScrollView(
              child: HighlightView(
                code,
                language: _detectLanguage(language, filename),
                theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
                padding: EdgeInsets.all(r.isCompact ? 10 : 12),
                textStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: r.isCompact ? 11 : 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildFooter(BuildContext context, ResponsiveValues r) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 时间戳
        Row(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: r.isCompact ? 10 : 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 3),
            Text(
              formatTimestamp(timestamp),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: r.isCompact ? 9 : 10,
              ),
            ),
          ],
        ),
        // 复制按钮
        IconButton(
          icon: Icon(Icons.copy, size: r.isCompact ? 16 : 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('代码已复制')));
          },
          tooltip: '复制代码',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  @override
  bool shouldShowFooter(BuildContext context, ResponsiveValues r) => true;

  // ==================== 私有辅助方法 ====================

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
