import 'package:flutter/material.dart';

import '../../../models/task.dart';
import '../../common/diff_view.dart';

/// Result view for CodexDiff tool
///
/// Displays the parsed diff result.
/// Mirrors web/src/components/ToolCard/views/CodexDiffView.tsx
class CodexDiffResultView extends StatelessWidget {
  final TaskItem task;
  final bool isCompact;

  const CodexDiffResultView({
    super.key,
    required this.task,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final input = task.input;
    if (input == null) return const SizedBox.shrink();

    final unifiedDiff = input['unified_diff'];
    if (unifiedDiff is! String || unifiedDiff.isEmpty) {
      return const SizedBox.shrink();
    }

    final parsed = parseUnifiedDiff(unifiedDiff);

    return DiffView(
      oldString: parsed.oldText,
      newString: parsed.newText,
      filePath: isCompact ? null : parsed.fileName,
      variant: isCompact ? DiffVariant.preview : DiffVariant.inline,
    );
  }
}
