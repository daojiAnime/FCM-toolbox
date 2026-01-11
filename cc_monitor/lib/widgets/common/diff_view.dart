import 'package:flutter/material.dart';

/// Diff view variant
enum DiffVariant {
  /// Preview mode: shows summary, click to expand
  preview,

  /// Inline mode: shows full diff content directly
  inline,
}

/// A single diff part (added, removed, or unchanged)
class DiffPart {
  final String value;
  final bool added;
  final bool removed;

  const DiffPart({
    required this.value,
    this.added = false,
    this.removed = false,
  });

  bool get unchanged => !added && !removed;
}

/// Parse a unified diff into old and new text
class ParsedDiff {
  final String oldText;
  final String newText;
  final String? fileName;

  const ParsedDiff({
    required this.oldText,
    required this.newText,
    this.fileName,
  });
}

/// Parse unified diff format into old/new text and filename
ParsedDiff parseUnifiedDiff(String unifiedDiff) {
  final lines = unifiedDiff.split('\n');
  final oldLines = <String>[];
  final newLines = <String>[];
  String? fileName;
  bool inHunk = false;

  for (final line in lines) {
    // Extract filename from +++ line
    if (line.startsWith('+++ b/') || line.startsWith('+++ ')) {
      fileName = line.replaceFirst(RegExp(r'^\+\+\+ (b/)?'), '');
      continue;
    }

    // Skip header lines
    if (line.startsWith('diff --git') ||
        line.startsWith('index ') ||
        line.startsWith('--- ') ||
        line.startsWith('new file mode') ||
        line.startsWith('deleted file mode')) {
      continue;
    }

    // Hunk marker
    if (line.startsWith('@@')) {
      inHunk = true;
      continue;
    }

    if (!inHunk) continue;

    // Content lines
    if (line.startsWith('+')) {
      newLines.add(line.substring(1));
    } else if (line.startsWith('-')) {
      oldLines.add(line.substring(1));
    } else if (line.startsWith(' ')) {
      oldLines.add(line.substring(1));
      newLines.add(line.substring(1));
    } else if (line.isEmpty) {
      // Empty line in diff (context)
      oldLines.add('');
      newLines.add('');
    }
  }

  return ParsedDiff(
    oldText: oldLines.join('\n'),
    newText: newLines.join('\n'),
    fileName: fileName,
  );
}

/// Compute line-by-line diff between two strings
List<DiffPart> diffLines(String oldText, String newText) {
  final oldLines = oldText.split('\n');
  final newLines = newText.split('\n');
  final result = <DiffPart>[];

  // Simple LCS-based diff algorithm
  final lcs = _computeLCS(oldLines, newLines);
  var oldIdx = 0;
  var newIdx = 0;

  for (final (oldLine, newLine) in lcs) {
    // Add removed lines before this common line
    while (oldIdx < oldLine) {
      result.add(DiffPart(value: '${oldLines[oldIdx]}\n', removed: true));
      oldIdx++;
    }
    // Add added lines before this common line
    while (newIdx < newLine) {
      result.add(DiffPart(value: '${newLines[newIdx]}\n', added: true));
      newIdx++;
    }
    // Add the common line
    result.add(DiffPart(value: '${oldLines[oldIdx]}\n'));
    oldIdx++;
    newIdx++;
  }

  // Add remaining removed lines
  while (oldIdx < oldLines.length) {
    result.add(DiffPart(value: '${oldLines[oldIdx]}\n', removed: true));
    oldIdx++;
  }
  // Add remaining added lines
  while (newIdx < newLines.length) {
    result.add(DiffPart(value: '${newLines[newIdx]}\n', added: true));
    newIdx++;
  }

  return result;
}

/// Compute LCS (Longest Common Subsequence) indices
List<(int, int)> _computeLCS(List<String> a, List<String> b) {
  final m = a.length;
  final n = b.length;

  // DP table
  final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      if (a[i - 1] == b[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1] + 1;
      } else {
        dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
      }
    }
  }

  // Backtrack to find LCS indices
  final result = <(int, int)>[];
  var i = m;
  var j = n;
  while (i > 0 && j > 0) {
    if (a[i - 1] == b[j - 1]) {
      result.add((i - 1, j - 1));
      i--;
      j--;
    } else if (dp[i - 1][j] > dp[i][j - 1]) {
      i--;
    } else {
      j--;
    }
  }

  return result.reversed.toList();
}

/// DiffView widget for displaying code differences
class DiffView extends StatelessWidget {
  final String oldString;
  final String newString;
  final String? filePath;
  final DiffVariant variant;

  const DiffView({
    super.key,
    required this.oldString,
    required this.newString,
    this.filePath,
    this.variant = DiffVariant.preview,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == DiffVariant.inline) {
      return _DiffInlineView(
        oldString: oldString,
        newString: newString,
        filePath: filePath,
      );
    }

    return _DiffPreviewView(
      oldString: oldString,
      newString: newString,
      filePath: filePath,
    );
  }
}

/// Preview variant: shows summary card
class _DiffPreviewView extends StatelessWidget {
  final String oldString;
  final String newString;
  final String? filePath;

  const _DiffPreviewView({
    required this.oldString,
    required this.newString,
    this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final oldChars = oldString.length;
    final newChars = newString.length;

    return GestureDetector(
      onTap: () => _showFullDiff(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filePath != null)
                    Text(
                      filePath!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '$oldChars chars → $newChars chars',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 16, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  void _showFullDiff(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        child: _DiffInlineView(
                          oldString: oldString,
                          newString: newString,
                          filePath: filePath,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }
}

/// Inline variant: shows full diff content
class _DiffInlineView extends StatelessWidget {
  final String oldString;
  final String newString;
  final String? filePath;

  const _DiffInlineView({
    required this.oldString,
    required this.newString,
    this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final diff = diffLines(oldString, newString);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // File header
          if (filePath != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Text(
                filePath!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          // Diff content
          Container(
            color: colorScheme.surfaceContainerLowest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children:
                  diff.map((part) => _buildDiffLine(context, part)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffLine(BuildContext context, DiffPart part) {
    final colorScheme = Theme.of(context).colorScheme;

    Color? bgColor;
    Color textColor = colorScheme.onSurface;
    String prefix = ' ';

    if (part.added) {
      bgColor = Colors.green.withValues(alpha: 0.15);
      textColor = Colors.green.shade700;
      prefix = '+';
    } else if (part.removed) {
      bgColor = Colors.red.withValues(alpha: 0.15);
      textColor = Colors.red.shade700;
      prefix = '-';
    }

    final lines = part.value.split('\n');
    // Remove trailing empty line from split
    if (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children:
          lines.map((line) {
            return Container(
              color: bgColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              child: Text(
                '$prefix $line',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: textColor,
                ),
              ),
            );
          }).toList(),
    );
  }
}
