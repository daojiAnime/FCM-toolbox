import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/task.dart';
import '../../../utils/tool_presentation.dart';
import '../tool_views/input_views/input_view_registry.dart';
import '../tool_views/tool_view_registry.dart';
import 'task_status_icons.dart';

/// 任务项行 - 可展开显示详情
class TaskItemRow extends StatefulWidget {
  const TaskItemRow({super.key, required this.task, required this.isCompact});

  final TaskItem task;
  final bool isCompact;

  @override
  State<TaskItemRow> createState() => _TaskItemRowState();
}

class _TaskItemRowState extends State<TaskItemRow>
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
  void didUpdateWidget(TaskItemRow oldWidget) {
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
                  TaskStatusIcon(
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
