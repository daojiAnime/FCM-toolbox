import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../common/constants.dart';
import '../../models/message.dart';
import '../../models/payload/payload.dart';
import '../../models/task.dart';
import '../../utils/tool_presentation.dart';
import 'tool_views/tool_view_registry.dart';
import 'tool_views/input_views/input_view_registry.dart';

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
            child: _TaskItemRow(task: tasks.first, isCompact: isCompact),
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
                  _buildHeader(context, payload, isCompact),

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
                            ? _buildExpandedContent(
                              context,
                              payload,
                              tasks,
                              isCompact,
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTaskSummary(
                                  context,
                                  summaryTasks,
                                  isCompact,
                                ),
                                if (remainingCount > 0)
                                  _buildMoreIndicator(
                                    context,
                                    remainingCount,
                                    isCompact,
                                  ),
                                // 子任务摘要（如果有）
                                if (widget.children != null &&
                                    widget.children!.isNotEmpty)
                                  _buildChildTasksSummary(
                                    context,
                                    widget.children!,
                                    isCompact,
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

  /// 构建卡片头部
  Widget _buildHeader(
    BuildContext context,
    TaskExecutionPayload payload,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = payload.overallStatus;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      child: Row(
        children: [
          // 状态图标
          _StatusIcon(status: status, size: isCompact ? 16 : 18),
          SizedBox(width: isCompact ? 8 : 10),

          // 标题
          Expanded(
            child: Text(
              payload.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 13 : 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 耗时
          if (payload.durationMs != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _formatDuration(payload.durationMs!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                  fontSize: isCompact ? 10 : 11,
                ),
              ),
            ),

          // 展开箭头 - 带旋转动画
          RotationTransition(
            turns: Tween(
              begin: 0.0,
              end: 0.5,
            ).animate(_expandAnimation), // 0 to 180 degrees
            child: Icon(
              Icons.keyboard_arrow_down,
              size: isCompact ? 20 : 24,
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建展开内容 (prompt + 任务列表)
  Widget _buildExpandedContent(
    BuildContext context,
    TaskExecutionPayload payload,
    List<TaskItem> tasks,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasPrompt = payload.prompt != null && payload.prompt!.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 8 : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input 区域 (类似 hapi web Dialog 中的 Input)
          if (hasPrompt) ...[
            Text(
              'Input',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 10 : 11,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isCompact ? 10 : 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                payload.prompt!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: isCompact ? 12 : 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 任务列表
          if (tasks.isNotEmpty) ...[
            Text(
              'Tasks (${tasks.length})',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 10 : 11,
              ),
            ),
            const SizedBox(height: 6),
            ...tasks.map(
              (task) => _TaskItemRow(task: task, isCompact: isCompact),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建任务摘要（简洁模式，只显示状态图标和标题）
  Widget _buildTaskSummary(
    BuildContext context,
    List<TaskItem> tasks,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 6 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            tasks.map((task) {
              final presentation = getToolPresentation(
                toolName: task.toolName,
                description: task.description,
                filePath: task.filePath,
                input: task.input, // 传递完整 input 以支持工具专用字段提取
              );
              return Padding(
                padding: EdgeInsets.symmetric(vertical: isCompact ? 2 : 3),
                child: Row(
                  children: [
                    // 状态图标
                    SizedBox(
                      width: isCompact ? 16 : 18,
                      child: Center(
                        child: _buildStatusText(task.status, isCompact),
                      ),
                    ),
                    SizedBox(width: isCompact ? 6 : 8),
                    // 任务名称
                    Expanded(
                      child: Text(
                        task.displayName.isNotEmpty
                            ? task.displayName
                            : presentation.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              task.hasError
                                  ? colorScheme.error
                                  : colorScheme.onSurfaceVariant,
                          fontSize: isCompact ? 11 : 12,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  /// 构建状态文字
  Widget _buildStatusText(TaskItemStatus status, bool isCompact) {
    final (text, color) = switch (status) {
      TaskItemStatus.completed => ('✓', Colors.green.shade600),
      TaskItemStatus.error => ('✕', Colors.red.shade600),
      TaskItemStatus.running => ('●', Colors.amber.shade600),
      TaskItemStatus.pending => ('🔐', Colors.amber.shade700),
    };

    if (status == TaskItemStatus.running) {
      return SizedBox(
        width: isCompact ? 10 : 12,
        height: isCompact ? 10 : 12,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
      );
    }

    return Text(
      text,
      style: TextStyle(fontSize: isCompact ? 10 : 12, color: color),
    );
  }

  /// 构建 "(+N more)" 提示
  Widget _buildMoreIndicator(
    BuildContext context,
    int remainingCount,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: isCompact ? 34 : 38,
        bottom: isCompact ? 6 : 8,
      ),
      child: Text(
        '(+$remainingCount more)',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.outline,
          fontSize: isCompact ? 11 : 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  /// 构建子任务摘要 (参考 web 实现的 renderTaskSummary)
  /// 显示最后 3 个子任务的状态和名称
  Widget _buildChildTasksSummary(
    BuildContext context,
    List<Message> children,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 过滤出有效的子任务消息（TaskExecutionPayload）
    final childTasks =
        children
            .where((child) => child.payload is TaskExecutionPayload)
            .toList();

    if (childTasks.isEmpty) return const SizedBox.shrink();

    // 显示最后 3 个子任务
    final visibleTasks =
        childTasks.length > 3
            ? childTasks.sublist(childTasks.length - 3)
            : childTasks;
    final remaining = childTasks.length > 3 ? childTasks.length - 3 : 0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 6 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分隔线
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
          const SizedBox(height: 6),
          // 子任务列表
          ...visibleTasks.map((msg) {
            final payload = msg.payload as TaskExecutionPayload;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: isCompact ? 2 : 3),
              child: Row(
                children: [
                  // 状态图标
                  SizedBox(
                    width: isCompact ? 16 : 18,
                    child: Center(
                      child: _buildChildTaskStatusIcon(
                        payload.overallStatus,
                        isCompact,
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? 6 : 8),
                  // 任务标题
                  Expanded(
                    child: Text(
                      payload.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            payload.overallStatus == TaskStatus.error
                                ? colorScheme.error
                                : colorScheme.onSurfaceVariant,
                        fontSize: isCompact ? 11 : 12,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          // 剩余数量提示
          if (remaining > 0)
            Padding(
              padding: EdgeInsets.only(
                left: isCompact ? 24 : 26,
                top: isCompact ? 2 : 3,
              ),
              child: Text(
                '(+$remaining more)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                  fontSize: isCompact ? 11 : 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建子任务状态图标 (参考 web 的 TaskStateIcon)
  Widget _buildChildTaskStatusIcon(TaskStatus status, bool isCompact) {
    final (text, color) = switch (status) {
      TaskStatus.completed => ('✓', Colors.green.shade600),
      TaskStatus.error => ('✕', Colors.red.shade600),
      TaskStatus.pending => ('🔐', Colors.amber.shade700),
      TaskStatus.running => ('●', Colors.amber.shade600),
      TaskStatus.partial => ('⚠', Colors.orange.shade600),
    };

    if (status == TaskStatus.running) {
      return SizedBox(
        width: isCompact ? 10 : 12,
        height: isCompact ? 10 : 12,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
      );
    }

    return Text(
      text,
      style: TextStyle(fontSize: isCompact ? 10 : 12, color: color),
    );
  }

  /// 格式化耗时
  String _formatDuration(int ms) {
    if (ms < 1000) return '${ms}ms';
    final seconds = ms / 1000;
    if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';
    final minutes = seconds / 60;
    return '${minutes.toStringAsFixed(1)}m';
  }
}

/// 任务项行 - 可展开显示详情
class _TaskItemRow extends StatefulWidget {
  const _TaskItemRow({required this.task, required this.isCompact});

  final TaskItem task;
  final bool isCompact;

  @override
  State<_TaskItemRow> createState() => _TaskItemRowState();
}

class _TaskItemRowState extends State<_TaskItemRow>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  // 运行时间实时更新
  Timer? _runningTimer;
  int? _elapsedMs;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // 如果任务正在运行，启动计时器
    _startTimerIfRunning();
  }

  @override
  void didUpdateWidget(_TaskItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 状态变化时更新计时器
    if (oldWidget.task.status != widget.task.status) {
      _startTimerIfRunning();
    }
  }

  @override
  void dispose() {
    _runningTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// 如果任务正在运行，启动计时器；否则取消计时器
  void _startTimerIfRunning() {
    _runningTimer?.cancel();
    _runningTimer = null;
    _elapsedMs = null;

    if (widget.task.status == TaskItemStatus.running) {
      // 初始化已用时间
      _elapsedMs = widget.task.durationMs ?? 0;

      // 每秒更新一次
      _runningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _elapsedMs = (_elapsedMs ?? 0) + 1000;
          });
        }
      });
    }
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
    final task = widget.task;
    final isCompact = widget.isCompact;

    // 获取工具展示信息
    final presentation = getToolPresentation(
      toolName: task.toolName,
      description: task.description,
      filePath: task.filePath,
      command: task.inputSummary,
      pattern: task.inputSummary,
      input: task.input, // 传递完整 input 以支持工具专用字段提取
    );
    final iconColor = getToolIconColor(context, task.toolName);

    return Container(
      margin: EdgeInsets.symmetric(vertical: isCompact ? 3 : 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 头部 - 可点击
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 12,
                vertical: isCompact ? 8 : 10,
              ),
              child: Row(
                children: [
                  // 工具图标
                  Container(
                    width: isCompact ? 24 : 28,
                    height: isCompact ? 24 : 28,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      presentation.icon,
                      size: isCompact ? 14 : 16,
                      color: iconColor,
                    ),
                  ),
                  SizedBox(width: isCompact ? 10 : 12),

                  // 标题和副标题
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题
                        Text(
                          _getDisplayTitle(presentation, task),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: isCompact ? 12 : 13,
                            color:
                                task.hasError
                                    ? colorScheme.error
                                    : colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // 副标题 (命令/路径)
                        if (_getSubtitle(presentation, task) != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _getSubtitle(presentation, task)!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: isCompact ? 10 : 11,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        // Result 预览（未展开时也显示）
                        if (!_isExpanded &&
                            task.outputSummary != null &&
                            task.outputSummary!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  task.hasError
                                      ? colorScheme.errorContainer.withValues(
                                        alpha: 0.3,
                                      )
                                      : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _truncateResult(task.outputSummary!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    task.hasError
                                        ? colorScheme.error
                                        : colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.8),
                                fontSize: isCompact ? 9 : 10,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 状态图标
                  _TaskStatusIcon(
                    status: _convertStatus(task.status),
                    size: isCompact ? 14 : 16,
                  ),
                  SizedBox(width: isCompact ? 6 : 8),

                  // 展开箭头 - 带旋转动画
                  RotationTransition(
                    turns: Tween(
                      begin: 0.0,
                      end: 0.25,
                    ).animate(_expandAnimation),
                    child: Icon(
                      Icons.chevron_right,
                      size: isCompact ? 16 : 18,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 展开内容
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildExpandedContent(context, task, isCompact),
          ),
        ],
      ),
    );
  }

  /// 构建展开的详情内容
  Widget _buildExpandedContent(
    BuildContext context,
    TaskItem task,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: isCompact ? 10 : 12,
        right: isCompact ? 10 : 12,
        bottom: isCompact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // 输入参数 - 使用工具专用视图
          if (task.input != null && task.input!.isNotEmpty) ...[
            _buildInputSection(context, task, isCompact),
            const SizedBox(height: 8),
          ],

          // 输出结果 - 使用工具专用视图
          if (task.outputSummary != null && task.outputSummary!.isNotEmpty) ...[
            _buildResultSection(context, task, isCompact),
            const SizedBox(height: 8),
          ],

          // 错误信息
          if (task.hasError && task.errorMessage != null) ...[
            _buildDetailSection(
              context,
              'Error',
              task.errorMessage!,
              isCompact,
              isError: true,
            ),
            const SizedBox(height: 8),
          ],

          // 耗时 - 运行时显示实时计时，否则显示最终耗时
          if (_elapsedMs != null || task.durationMs != null)
            Text(
              'Duration: ${_formatDuration(_elapsedMs ?? task.durationMs!)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
                fontSize: isCompact ? 10 : 11,
              ),
            ),
        ],
      ),
    );
  }

  /// 构建 Input 区块 - 使用工具专用视图
  Widget _buildInputSection(
    BuildContext context,
    TaskItem task,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Input',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.outline,
            fontWeight: FontWeight.w600,
            fontSize: isCompact ? 10 : 11,
          ),
        ),
        const SizedBox(height: 4),
        // 使用 Input 视图注册表渲染
        InputViewRegistry.buildInputView(
          toolName: task.toolName,
          input: task.input,
          isCompact: isCompact,
          context: context,
        ),
      ],
    );
  }

  /// 构建 Result 区块 - 使用工具专用视图
  Widget _buildResultSection(
    BuildContext context,
    TaskItem task,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Result',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.outline,
            fontWeight: FontWeight.w600,
            fontSize: isCompact ? 10 : 11,
          ),
        ),
        const SizedBox(height: 4),
        // 使用工具视图注册表渲染
        ToolViewRegistry.buildResultView(
          toolName: task.toolName,
          task: task,
          isCompact: isCompact,
          context: context,
        ),
      ],
    );
  }

  /// 构建详情区块
  Widget _buildDetailSection(
    BuildContext context,
    String label,
    String content,
    bool isCompact, {
    bool isError = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isError ? colorScheme.error : colorScheme.outline,
            fontWeight: FontWeight.w600,
            fontSize: isCompact ? 10 : 11,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isCompact ? 8 : 10),
          decoration: BoxDecoration(
            color:
                isError
                    ? colorScheme.errorContainer.withValues(alpha: 0.3)
                    : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            content,
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  isError
                      ? colorScheme.onErrorContainer
                      : colorScheme.onSurfaceVariant,
              fontSize: isCompact ? 10 : 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  String _getDisplayTitle(ToolPresentation presentation, TaskItem task) {
    if (task.name.isNotEmpty && task.name != task.toolName) {
      return task.displayName;
    }
    return presentation.title;
  }

  String? _getSubtitle(ToolPresentation presentation, TaskItem task) {
    if (task.inputSummary != null && task.inputSummary!.isNotEmpty) {
      return task.inputSummary;
    }
    return presentation.subtitle;
  }

  String _formatDuration(int ms) {
    if (ms < 1000) return '${ms}ms';
    final seconds = ms / 1000;
    if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';
    final minutes = seconds / 60;
    return '${minutes.toStringAsFixed(1)}m';
  }

  /// 截断 Result 预览文本（用于未展开状态）
  String _truncateResult(String result) {
    // 移除首尾空白
    final trimmed = result.trim();
    // 取第一行（最多 100 字符）
    final firstLine = trimmed.split('\n').first;
    if (firstLine.length > 100) {
      return '${firstLine.substring(0, 100)}...';
    }
    return firstLine;
  }

  TaskStatus _convertStatus(TaskItemStatus status) {
    return switch (status) {
      TaskItemStatus.pending => TaskStatus.pending,
      TaskItemStatus.running => TaskStatus.running,
      TaskItemStatus.completed => TaskStatus.completed,
      TaskItemStatus.error => TaskStatus.error,
    };
  }
}

/// 任务状态图标 - 圆形样式，类似 hapi web
class _TaskStatusIcon extends StatelessWidget {
  const _TaskStatusIcon({required this.status, this.size = 14});

  final TaskStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (status == TaskStatus.running) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.amber.shade600,
        ),
      );
    }

    final (icon, color) = _getIconAndColor();

    return Icon(icon, size: size, color: color);
  }

  (IconData, Color) _getIconAndColor() {
    return switch (status) {
      TaskStatus.completed => (
        Icons.check_circle_outline,
        Colors.green.shade600,
      ),
      TaskStatus.error => (Icons.cancel_outlined, Colors.red.shade600),
      TaskStatus.pending => (Icons.lock_outline, Colors.amber.shade700),
      TaskStatus.running => (Icons.circle, Colors.amber.shade600),
      TaskStatus.partial => (Icons.warning_amber, Colors.orange.shade600),
    };
  }
}

/// 状态图标
class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, this.size = 14});

  final TaskStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getIconAndColor(context);

    if (status == TaskStatus.running) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }

    return Icon(icon, size: size, color: color);
  }

  (IconData, Color) _getIconAndColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (status) {
      TaskStatus.completed => (Icons.check_circle, Colors.green.shade600),
      TaskStatus.error => (Icons.cancel, colorScheme.error),
      TaskStatus.pending => (Icons.lock_outline, Colors.amber.shade700),
      TaskStatus.running => (Icons.circle, Colors.amber.shade600),
      TaskStatus.partial => (Icons.warning_amber, Colors.orange.shade600),
    };
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
            leading: _StatusIcon(status: status),
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
