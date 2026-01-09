# 工具视图库 (Tool Views)

## 概述

工具专用视图注册表，让不同工具有定制化的 Result 显示。设计参考自 web 端的 `_results.tsx`。

## 架构

```
tool_views/
├── tool_view_registry.dart    # 核心注册表
├── bash_result_view.dart       # Bash 工具视图
├── read_result_view.dart       # Read 工具视图
├── mutation_result_view.dart   # Edit/Write 工具视图
├── line_list_result_view.dart  # Glob/Grep 工具视图
├── markdown_result_view.dart   # Task/WebFetch 工具视图
├── result_view_helpers.dart    # 辅助工具
└── all.dart                    # 导出文件
```

## 工具视图列表

| 工具 | 视图类型 | 说明 |
|------|---------|-----|
| Bash, CodexBash | BashResultView | 提取 stdout/stderr，代码块显示 |
| Read, NotebookRead | ReadResultView | 显示文件路径 + 内容 |
| Edit, Write, MultiEdit, NotebookEdit | MutationResultView | 成功显示 "Done"，失败显示错误 |
| Glob, Grep, LS | LineListResultView | 按行分割，列表显示 |
| Task, WebFetch, WebSearch | MarkdownResultView | Markdown 渲染 |

## 使用方法

### 1. 在 TaskCard 中使用

```dart
// 导入注册表
import 'tool_views/tool_view_registry.dart';

// 使用工具视图渲染结果
ToolViewRegistry.buildResultView(
  toolName: task.toolName,
  task: task,
  isCompact: isCompact,
  context: context,
);
```

### 2. 注册新工具视图

在 `tool_view_registry.dart` 中添加：

```dart
static final Map<String, ToolViewBuilder> _registry = {
  // ... 现有工具
  'NewTool': ({required task, required isCompact, required context}) =>
      NewToolResultView(task: task, isCompact: isCompact),
};
```

### 3. 创建自定义视图

```dart
import 'package:flutter/material.dart';
import '../../../models/task.dart';

class NewToolResultView extends StatelessWidget {
  const NewToolResultView({
    super.key,
    required this.task,
    required this.isCompact,
  });

  final TaskItem task;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    // 自定义渲染逻辑
    return Text(task.outputSummary ?? '(no output)');
  }
}
```

## 设计原则

1. **专用性**：每个工具有自己的视图组件
2. **一致性**：遵循统一的视觉样式和交互模式
3. **回退性**：未注册的工具使用通用 Markdown 视图
4. **扩展性**：易于添加新工具视图

## 参考

- Web 端实现：`web/src/components/ToolCard/views/_results.tsx`
- TaskCard 集成：`lib/widgets/chat/task_card.dart:874-903`
