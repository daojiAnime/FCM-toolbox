// Input 视图注册表
// 对标 web/src/components/ToolCard/views/_all.tsx

import 'package:flutter/material.dart';

import 'task_input_view.dart';
import 'bash_input_view.dart';
import 'edit_input_view.dart';
import 'write_input_view.dart';
import 'read_input_view.dart';
import 'glob_grep_input_view.dart';
import 'todo_write_input_view.dart';
import 'ask_question_input_view.dart';
import 'exit_plan_input_view.dart';
import 'generic_input_view.dart';
import 'codex_diff_input_view.dart';
import 'codex_patch_input_view.dart';
import 'web_fetch_input_view.dart';
import 'web_search_input_view.dart';
import 'notebook_edit_input_view.dart';

/// Input 视图构建器类型
typedef InputViewBuilder =
    Widget Function({
      required Map<String, dynamic>? input,
      required bool isCompact,
      required BuildContext context,
    });

/// Input 视图注册表
class InputViewRegistry {
  InputViewRegistry._();

  /// 工具到 Input 视图的映射
  static final Map<String, InputViewBuilder> _registry = {
    'Task': TaskInputView.build,
    'Bash': BashInputView.build,
    'CodexBash': BashInputView.build,
    'Edit': EditInputView.build,
    'MultiEdit': EditInputView.build,
    'Write': WriteInputView.build,
    'Read': ReadInputView.build,
    'NotebookRead': ReadInputView.build,
    'Glob': GlobGrepInputView.buildGlob,
    'Grep': GlobGrepInputView.buildGrep,
    'LS': GlobGrepInputView.buildLS,
    'TodoWrite': TodoWriteInputView.build,
    'AskUserQuestion': AskQuestionInputView.build,
    'ask_user_question': AskQuestionInputView.build,
    'ExitPlanMode': ExitPlanInputView.build,
    'exit_plan_mode': ExitPlanInputView.build,
    'CodexDiff': CodexDiffInputView.build,
    'CodexPatch': CodexPatchInputView.build,
    'WebFetch': WebFetchInputView.build,
    'WebSearch': WebSearchInputView.build,
    'NotebookEdit': NotebookEditInputView.build,
  };

  /// 构建 Input 视图
  static Widget buildInputView({
    required String? toolName,
    required Map<String, dynamic>? input,
    required bool isCompact,
    required BuildContext context,
  }) {
    if (toolName == null || input == null) {
      return GenericInputView.build(
        input: input,
        isCompact: isCompact,
        context: context,
      );
    }

    final builder = _registry[toolName];
    if (builder != null) {
      return builder(input: input, isCompact: isCompact, context: context);
    }

    // MCP 工具使用通用视图
    if (toolName.startsWith('mcp__')) {
      return GenericInputView.build(
        input: input,
        isCompact: isCompact,
        context: context,
      );
    }

    // 默认回退到通用视图
    return GenericInputView.build(
      input: input,
      isCompact: isCompact,
      context: context,
    );
  }
}
