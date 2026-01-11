import 'package:flutter/material.dart';

import '../../../common/diff_view.dart';

/// Input view for CodexDiff tool
///
/// Displays the unified diff content in compact or inline mode.
/// Mirrors web/src/components/ToolCard/views/CodexDiffView.tsx
class CodexDiffInputView {
  CodexDiffInputView._();

  /// Build the CodexDiff input view
  static Widget build({
    required Map<String, dynamic>? input,
    required bool isCompact,
    required BuildContext context,
  }) {
    if (input == null) return const SizedBox.shrink();

    final unifiedDiff = input['unified_diff'];
    if (unifiedDiff is! String || unifiedDiff.isEmpty) {
      return const SizedBox.shrink();
    }

    final parsed = parseUnifiedDiff(unifiedDiff);

    // For compact mode, use preview variant (shows summary)
    // For full mode, use inline variant (shows full diff)
    return DiffView(
      oldString: parsed.oldText,
      newString: parsed.newText,
      filePath: isCompact ? null : parsed.fileName,
      variant: isCompact ? DiffVariant.preview : DiffVariant.inline,
    );
  }

  /// Build compact view (for tool card inline display)
  static Widget buildCompact({
    required Map<String, dynamic>? input,
    required BuildContext context,
  }) {
    return build(input: input, isCompact: true, context: context);
  }

  /// Build full view (for dialog/expanded display)
  static Widget buildFull({
    required Map<String, dynamic>? input,
    required BuildContext context,
  }) {
    return build(input: input, isCompact: false, context: context);
  }
}
