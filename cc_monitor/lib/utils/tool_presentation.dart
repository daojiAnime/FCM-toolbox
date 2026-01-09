import 'package:flutter/material.dart';

/// 工具展示信息 - 类似 hapi web 的 ToolPresentation
class ToolPresentation {
  const ToolPresentation({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isMinimal = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isMinimal;
}

/// 获取工具展示信息
/// 对标 web/src/components/ToolCard/knownTools.tsx
ToolPresentation getToolPresentation({
  required String? toolName,
  String? description,
  String? filePath,
  String? command,
  String? pattern,
  Map<String, dynamic>? input, // 添加 input 参数以支持工具专用字段提取
}) {
  if (toolName == null || toolName.isEmpty) {
    return ToolPresentation(
      icon: Icons.build_outlined,
      title: description ?? 'Unknown Tool',
    );
  }

  // MCP 工具
  if (toolName.startsWith('mcp__')) {
    return ToolPresentation(
      icon: Icons.extension,
      title: _formatMCPTitle(toolName),
    );
  }

  // 已知工具映射
  return switch (toolName) {
    // 任务工具 - 对标 web: title=description, subtitle=prompt(truncated)
    'Task' => ToolPresentation(
      icon: Icons.rocket_launch_outlined,
      title: _getInputString(input, 'description') ?? description ?? 'Task',
      subtitle: _truncate(_getInputString(input, 'prompt') ?? '', 120),
    ),

    // 终端/Bash
    'Bash' || 'CodexBash' => ToolPresentation(
      icon: Icons.terminal,
      title: () {
        final cmd =
            _getInputString(input, 'command') ??
            _getInputString(input, 'cmd') ??
            command;
        return cmd != null
            ? 'Bash(${_truncate(cmd, 40)})'
            : (description ?? 'Terminal');
      }(),
      subtitle: () {
        final cmd =
            _getInputString(input, 'command') ??
            _getInputString(input, 'cmd') ??
            command;
        return cmd != null && cmd.length > 40 ? cmd : null;
      }(),
    ),

    // 文件搜索
    'Glob' => ToolPresentation(
      icon: Icons.search,
      title: () {
        final p = _getInputString(input, 'pattern') ?? pattern;
        return p != null ? 'Glob($p)' : 'Search files';
      }(),
    ),

    // 内容搜索
    'Grep' => ToolPresentation(
      icon: Icons.find_in_page_outlined,
      title: () {
        final p = _getInputString(input, 'pattern') ?? pattern;
        return p != null ? 'Grep($p)' : 'Search content';
      }(),
    ),

    // 列出目录
    'LS' => ToolPresentation(
      icon: Icons.folder_outlined,
      title: () {
        final path =
            _getInputString(input, 'path') ??
            _getInputString(input, 'directory') ??
            filePath;
        return path != null ? 'LS(${_truncatePath(path)})' : 'List files';
      }(),
    ),

    // 读取文件
    'Read' || 'NotebookRead' => ToolPresentation(
      icon: Icons.visibility_outlined,
      title: () {
        final path =
            _getInputString(input, 'file_path') ??
            _getInputString(input, 'path') ??
            filePath;
        return path != null ? 'Read(${_truncatePath(path)})' : 'Read file';
      }(),
    ),

    // 编辑文件
    'Edit' ||
    'MultiEdit' ||
    'NotebookEdit' ||
    'CodexDiff' ||
    'CodexPatch' => ToolPresentation(
      icon: Icons.edit_document,
      title: () {
        final path =
            _getInputString(input, 'file_path') ??
            _getInputString(input, 'path') ??
            filePath;
        return path != null ? 'Edit(${_truncatePath(path)})' : 'Edit file';
      }(),
    ),

    // 写入文件
    'Write' => ToolPresentation(
      icon: Icons.add_box_outlined,
      title: () {
        final path =
            _getInputString(input, 'file_path') ??
            _getInputString(input, 'path') ??
            filePath;
        return path != null ? 'Write(${_truncatePath(path)})' : 'Write file';
      }(),
    ),

    // Web 操作
    'WebFetch' => ToolPresentation(
      icon: Icons.language,
      title: () {
        final url = _getInputString(input, 'url');
        return url != null ? 'Fetch(${_truncate(url, 40)})' : 'Web fetch';
      }(),
    ),
    'WebSearch' => ToolPresentation(
      icon: Icons.travel_explore,
      title: () {
        final query = _getInputString(input, 'query') ?? pattern;
        return query ?? 'Web search';
      }(),
    ),

    // Todo 列表
    'TodoWrite' => ToolPresentation(icon: Icons.checklist, title: 'Todo list'),

    // 推理
    'CodexReasoning' => ToolPresentation(
      icon: Icons.lightbulb_outline,
      title: description ?? 'Reasoning',
    ),

    // 计划模式
    'ExitPlanMode' || 'exit_plan_mode' => ToolPresentation(
      icon: Icons.assignment_outlined,
      title: 'Plan proposal',
      isMinimal: false,
    ),

    // 提问 - 对标 web: title=第一个问题的header或question
    'AskUserQuestion' || 'ask_user_question' => ToolPresentation(
      icon: Icons.help_outline,
      title: () {
        final questions = input?['questions'] as List?;
        if (questions != null && questions.isNotEmpty) {
          final first = questions.first as Map<String, dynamic>?;
          return first?['header'] as String? ??
              first?['question'] as String? ??
              description ??
              'Question';
        }
        return description ?? 'Question';
      }(),
    ),

    // 默认
    _ => ToolPresentation(
      icon: Icons.build_outlined,
      title: toolName,
      subtitle: description,
    ),
  };
}

/// 从 input Map 中提取字符串
String? _getInputString(Map<String, dynamic>? input, String key) {
  if (input == null) return null;
  final value = input[key];
  if (value is String) return value;
  return null;
}

/// 格式化 MCP 工具标题
String _formatMCPTitle(String toolName) {
  final withoutPrefix = toolName.replaceFirst('mcp__', '');
  final parts = withoutPrefix.split('__');
  if (parts.length >= 2) {
    final serverName = _snakeToTitle(parts[0]);
    final toolPart = _snakeToTitle(parts.sublist(1).join('_'));
    return 'MCP: $serverName $toolPart';
  }
  return 'MCP: ${_snakeToTitle(withoutPrefix)}';
}

/// Snake case 转 Title case
String _snakeToTitle(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

/// 截断长路径
String _truncatePath(String path) {
  if (path.length <= 50) return path;
  final parts = path.split('/');
  if (parts.length <= 2) return path;
  // 保留最后两级目录
  return '.../${parts.sublist(parts.length - 2).join('/')}';
}

/// 截断长文本
String _truncate(String text, int maxLen) {
  if (text.length <= maxLen) return text;
  return '${text.substring(0, maxLen - 3)}...';
}

/// 获取工具图标颜色
Color getToolIconColor(BuildContext context, String? toolName) {
  final colorScheme = Theme.of(context).colorScheme;

  if (toolName == null) return colorScheme.onSurfaceVariant;

  return switch (toolName) {
    'Task' => colorScheme.primary,
    'Bash' || 'CodexBash' => Colors.green.shade600,
    'Glob' || 'Grep' || 'LS' => Colors.blue.shade600,
    'Read' || 'NotebookRead' => colorScheme.onSurfaceVariant,
    'Edit' ||
    'MultiEdit' ||
    'Write' ||
    'NotebookEdit' => Colors.orange.shade600,
    'WebFetch' || 'WebSearch' => Colors.purple.shade600,
    'TodoWrite' => Colors.teal.shade600,
    'AskUserQuestion' || 'ask_user_question' => Colors.amber.shade700,
    _ => colorScheme.onSurfaceVariant,
  };
}
