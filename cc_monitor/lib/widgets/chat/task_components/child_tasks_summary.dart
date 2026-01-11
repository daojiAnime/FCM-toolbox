import 'package:flutter/material.dart';

import '../../../models/message.dart';
import '../../../models/payload/payload.dart';
import '../../../models/task.dart';

/// 子任务摘要组件
/// 显示最后 3 个子任务的状态和名称
class ChildTasksSummary extends StatelessWidget {
  const ChildTasksSummary({
    super.key,
    required this.children,
    required this.isCompact,
  });

  final List<Message> children;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
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
}
