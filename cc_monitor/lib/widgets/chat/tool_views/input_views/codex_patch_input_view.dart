import 'package:flutter/material.dart';

import '../../../../utils/path_utils.dart';

/// Input view for CodexPatch tool
///
/// Displays the list of files that will be changed.
/// Mirrors web/src/components/ToolCard/views/CodexPatchView.tsx
class CodexPatchInputView {
  CodexPatchInputView._();

  /// Build the CodexPatch input view
  static Widget build({
    required Map<String, dynamic>? input,
    required bool isCompact,
    required BuildContext context,
    String? sessionRoot,
  }) {
    if (input == null) return const SizedBox.shrink();

    final changes = input['changes'];
    if (changes is! Map) return const SizedBox.shrink();

    final files = changes.keys.toList();
    if (files.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.drive_file_move_outline,
                size: isCompact ? 14 : 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '${files.length} file${files.length > 1 ? 's' : ''} to change',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // File list
          ...files.map((file) {
            final display = resolveDisplayPath(file.toString(), sessionRoot);
            final fileName = basename(display);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                fileName,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ],
      ),
    );
  }
}
