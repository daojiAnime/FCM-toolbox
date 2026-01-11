import 'package:flutter/widgets.dart';

import '../../../models/task.dart';
import 'bash_result_view.dart';
import 'line_list_result_view.dart';
import 'markdown_result_view.dart';
import 'mutation_result_view.dart';
import 'read_result_view.dart';
import 'codex_diff_result_view.dart';
import 'todo_write_result_view.dart';

/// 工具视图组件类型
typedef ToolViewBuilder =
    Widget Function({
      required TaskItem task,
      required bool isCompact,
      required BuildContext context,
    });

/// 工具结果视图注册表
///
/// 类似 web 端的 toolResultViewRegistry
/// 根据工具名称返回对应的渲染 Widget
class ToolViewRegistry {
  static final Map<String, ToolViewBuilder> _registry = {
    // Bash 工具：提取 stdout/stderr，代码块显示
    'Bash':
        ({required task, required isCompact, required context}) =>
            BashResultView(task: task, isCompact: isCompact),
    'CodexBash':
        ({required task, required isCompact, required context}) =>
            BashResultView(task: task, isCompact: isCompact),

    // Read 工具：显示文件路径 + 内容
    'Read':
        ({required task, required isCompact, required context}) =>
            ReadResultView(task: task, isCompact: isCompact),
    'NotebookRead':
        ({required task, required isCompact, required context}) =>
            ReadResultView(task: task, isCompact: isCompact),

    // Mutation 工具：成功显示 "Done"，失败显示错误
    'Edit':
        ({required task, required isCompact, required context}) =>
            MutationResultView(task: task, isCompact: isCompact),
    'MultiEdit':
        ({required task, required isCompact, required context}) =>
            MutationResultView(task: task, isCompact: isCompact),
    'Write':
        ({required task, required isCompact, required context}) =>
            MutationResultView(task: task, isCompact: isCompact),
    'NotebookEdit':
        ({required task, required isCompact, required context}) =>
            MutationResultView(task: task, isCompact: isCompact),

    // LineList 工具：按行分割，列表显示
    'Glob':
        ({required task, required isCompact, required context}) =>
            LineListResultView(task: task, isCompact: isCompact),
    'Grep':
        ({required task, required isCompact, required context}) =>
            LineListResultView(task: task, isCompact: isCompact),
    'LS':
        ({required task, required isCompact, required context}) =>
            LineListResultView(task: task, isCompact: isCompact),

    // Markdown 工具：Markdown 渲染
    'Task':
        ({required task, required isCompact, required context}) =>
            MarkdownResultView(task: task, isCompact: isCompact),
    'WebFetch':
        ({required task, required isCompact, required context}) =>
            MarkdownResultView(task: task, isCompact: isCompact),
    'WebSearch':
        ({required task, required isCompact, required context}) =>
            MarkdownResultView(task: task, isCompact: isCompact),

    // CodexDiff：显示 Unified Diff
    'CodexDiff':
        ({required task, required isCompact, required context}) =>
            CodexDiffResultView(task: task, isCompact: isCompact),

    // TodoWrite：显示 Todo 列表
    'TodoWrite':
        ({required task, required isCompact, required context}) =>
            TodoWriteResultView(task: task, isCompact: isCompact),
  };

  /// 获取工具对应的视图构建器
  ///
  /// 如果没有注册，返回通用的 Markdown 视图
  static ToolViewBuilder getViewBuilder(String? toolName) {
    if (toolName == null || toolName.isEmpty) {
      return ({required task, required isCompact, required context}) =>
          MarkdownResultView(task: task, isCompact: isCompact);
    }

    // MCP 工具使用通用视图
    if (toolName.startsWith('mcp__')) {
      return ({required task, required isCompact, required context}) =>
          MarkdownResultView(task: task, isCompact: isCompact);
    }

    // 返回注册的视图或默认视图
    return _registry[toolName] ??
        ({required task, required isCompact, required context}) =>
            MarkdownResultView(task: task, isCompact: isCompact);
  }

  /// 构建工具结果视图
  static Widget buildResultView({
    required String? toolName,
    required TaskItem task,
    required bool isCompact,
    required BuildContext context,
  }) {
    final builder = getViewBuilder(toolName);
    return builder(task: task, isCompact: isCompact, context: context);
  }
}
