import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../common/constants.dart';
import '../../models/message.dart';
import '../../models/payload/payload.dart';
import '../../models/task.dart';
import 'task_components/child_tasks_summary.dart';
import 'task_components/task_expanded_content.dart';
import 'task_components/task_header.dart';
import 'task_components/task_item_row.dart';
import 'task_components/task_status_icons.dart';
import 'task_components/task_summary.dart';

/// 可折叠任务卡片 - 类似 HAPI web 风格
///
/// UI 结构：
/// ┌─────────────────────────────────┐
/// │ ● 探索 CC Monitor 项目结构        │
/// ├─────────────────────────────────┤
/// │ ✓ cc_monitor/lib/services/...   │
/// │ ✓ grep -r "class.*Provider"     │
/// │ ● cc_monitor/scripts/cc_push.py │
/// │ (+20 more)                      │
/// ├─────────────────────────────────┤
/// │ ▶ Task details (25)             │
/// └─────────────────────────────────┘
class TaskCard extends StatefulWidget {
  const TaskCard({
    super.key,
    required this.message,
    this.children,
    this.maxVisibleTasks = 3,
    this.initialExpanded = false,
  });

  final Message message;
  final List<Message>? children;
  final int maxVisibleTasks;
  final bool initialExpanded;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 响应式布局
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < AppConstants.compactBreakpoint;

    // 获取任务数据
    final payload = widget.message.payload;
    if (payload is! TaskExecutionPayload) {
      return const SizedBox.shrink();
    }

    final tasks = payload.tasks;

    // 单任务优化：直接显示任务卡片，不需要外层包装
    if (tasks.length == 1) {
      return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 4 : 6,
            ),
            child: TaskItemRow(task: tasks.first, isCompact: isCompact),
          )
          .animate()
          .fadeIn(duration: const Duration(milliseconds: 200))
          .slideY(
            begin: 0.02,
            end: 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
    }

    // 摘要：只显示最近 3 个任务
    final summaryTasks =
        tasks.length > 3 ? tasks.sublist(tasks.length - 3) : tasks;
    final remainingCount = tasks.length > 3 ? tasks.length - 3 : 0;

    return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 4 : 6,
          ),
          child: Card(
            margin: EdgeInsets.zero,
            color: colorScheme.surfaceContainerHigh,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: _toggleExpand,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 卡片头部
                  TaskHeader(
                    payload: payload,
                    isCompact: isCompact,
                    expandAnimation: _expandAnimation,
                  ),

                  // 分隔线
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),

                  // 内容区域：折叠时显示摘要，展开时显示完整列表
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child:
                        _isExpanded
                            ? TaskExpandedContent(
                              payload: payload,
                              tasks: tasks,
                              isCompact: isCompact,
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TaskSummary(
                                  tasks: summaryTasks,
                                  isCompact: isCompact,
                                ),
                                if (remainingCount > 0)
                                  MoreTasksIndicator(
                                    remainingCount: remainingCount,
                                    isCompact: isCompact,
                                  ),
                                // 子任务摘要（如果有）
                                if (widget.children != null &&
                                    widget.children!.isNotEmpty)
                                  ChildTasksSummary(
                                    children: widget.children!,
                                    isCompact: isCompact,
                                  ),
                              ],
                            ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 200))
        .slideY(
          begin: 0.02,
          end: 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
  }
}

/// 简化版任务卡片 - 用于静态显示
class SimpleTaskCard extends StatelessWidget {
  const SimpleTaskCard({
    super.key,
    required this.title,
    required this.tasks,
    required this.status,
    this.maxVisible = 3,
  });

  final String title;
  final List<TaskItem> tasks;
  final TaskStatus status;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visibleTasks = tasks.take(maxVisible).toList();
    final remaining = tasks.length - maxVisible;

    return Card(
      color: colorScheme.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          ListTile(
            leading: OverallStatusIcon(status: status),
            title: Text(title),
            dense: true,
          ),
          const Divider(height: 1),

          // 任务列表
          ...visibleTasks.map(
            (task) => ListTile(
              leading: Icon(
                task.status == TaskItemStatus.completed
                    ? Icons.check
                    : task.status == TaskItemStatus.error
                    ? Icons.close
                    : Icons.circle,
                size: 14,
                color:
                    task.status == TaskItemStatus.completed
                        ? Colors.green
                        : task.status == TaskItemStatus.error
                        ? colorScheme.error
                        : Colors.amber,
              ),
              title: Text(
                task.displayName,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              dense: true,
              visualDensity: VisualDensity.compact,
            ),
          ),

          // 剩余数量
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(left: 56, bottom: 8),
              child: Text(
                '(+$remaining more)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
