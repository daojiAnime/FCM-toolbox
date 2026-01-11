# Task Card Components

## 架构说明

本目录包含 TaskCard 组件的所有子组件，采用 **Composite 设计模式** 实现。

### 组件职责

#### 1. 状态组件 (`task_status_icons.dart`)
- `TaskStatusIcon`: 单个任务的状态图标
- `OverallStatusIcon`: 整体任务状态图标
- `buildTaskItemStatusText`: 任务项状态文字图标

#### 2. 布局组件
- `TaskHeader` (`task_header.dart`): 卡片头部（标题、状态、耗时、展开按钮）
- `TaskSummary` (`task_summary.dart`): 任务摘要列表
- `MoreTasksIndicator` (`task_summary.dart`): "(+N more)" 提示

#### 3. 内容组件
- `TaskItemRow` (`task_item_row.dart`): 单个任务项（Leaf 节点）
  - 支持展开/折叠
  - 实时运行时间计时
  - Input/Result 视图集成
- `TaskExpandedContent` (`task_expanded_content.dart`): 展开后的完整任务列表

#### 4. 复合组件
- `ChildTasksSummary` (`child_tasks_summary.dart`): 子任务摘要（Composite 节点）

### Composite 模式应用

```
TaskCard (Root Container)
├── TaskHeader
├── TaskSummary
│   └── TaskItem[] (Leaf)
├── MoreTasksIndicator
└── TaskExpandedContent
    └── TaskItemRow[] (Leaf)
        ├── Input Views
        └── Result Views
```

### 使用方式

```dart
// 方式 1: 使用主入口
import 'package:cc_monitor/widgets/chat/task_card.dart';

TaskCard(message: message);

// 方式 2: 使用子组件（如果需要自定义布局）
import 'package:cc_monitor/widgets/chat/task_components/task_components.dart';

TaskItemRow(task: task, isCompact: false);
```

### 代码行数统计

| 文件 | 行数 | 职责 |
|------|------|------|
| `task_card.dart` | 287 | 主卡片组件（原 1206 行） |
| `task_status_icons.dart` | 100 | 状态图标组件 |
| `task_header.dart` | 84 | 头部组件 |
| `task_summary.dart` | 106 | 摘要列表 |
| `task_item_row.dart` | 477 | 单个任务项 |
| `task_expanded_content.dart` | 84 | 展开内容 |
| `child_tasks_summary.dart` | 127 | 子任务摘要 |
| **总计** | **1265** | **拆分后总行数** |

### 设计优势

1. **单一职责**: 每个组件专注于单一功能
2. **可复用性**: 组件可独立使用（如 TaskItemRow）
3. **可测试性**: 组件粒度小，易于单元测试
4. **可维护性**: 修改某个组件不影响其他组件
5. **扩展性**: 易于添加新的任务类型或视图

### 向后兼容

重构保持了 `TaskCard` 的公共 API，现有代码无需修改：

```dart
// 现有代码无需改变
TaskCard(
  message: message,
  children: childMessages,
  maxVisibleTasks: 3,
  initialExpanded: false,
)
```
