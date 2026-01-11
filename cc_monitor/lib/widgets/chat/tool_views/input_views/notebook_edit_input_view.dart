import 'package:flutter/material.dart';

import '../../../../utils/path_utils.dart';

/// Input view for NotebookEdit tool
///
/// Displays the notebook path and edit mode.
class NotebookEditInputView {
  NotebookEditInputView._();

  /// Build the NotebookEdit input view
  static Widget build({
    required Map<String, dynamic>? input,
    required bool isCompact,
    required BuildContext context,
    String? sessionRoot,
  }) {
    if (input == null) return const SizedBox.shrink();

    final notebookPath = input['notebook_path'] as String?;
    if (notebookPath == null || notebookPath.isEmpty) {
      return const SizedBox.shrink();
    }

    final editMode = input['edit_mode'] as String?;
    final cellType = input['cell_type'] as String?;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displayPath = resolveDisplayPath(notebookPath, sessionRoot);
    final fileName = basename(displayPath);

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
          // File name
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: isCompact ? 14 : 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Edit mode and cell type
          if (editMode != null || cellType != null) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (editMode != null)
                  _buildTag(context, 'mode: $editMode', colorScheme),
                if (cellType != null)
                  _buildTag(context, 'type: $cellType', colorScheme),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildTag(
    BuildContext context,
    String text,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: colorScheme.onPrimaryContainer),
      ),
    );
  }
}
