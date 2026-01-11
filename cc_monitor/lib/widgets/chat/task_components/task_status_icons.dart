import 'package:flutter/material.dart';

import '../../../models/task.dart';

/// 任务状态图标 - 圆形样式，类似 hapi web
class TaskStatusIcon extends StatelessWidget {
  const TaskStatusIcon({super.key, required this.status, this.size = 14});

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

/// 总体状态图标
class OverallStatusIcon extends StatelessWidget {
  const OverallStatusIcon({super.key, required this.status, this.size = 14});

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

/// 构建任务项状态文字图标
Widget buildTaskItemStatusText(TaskItemStatus status, bool isCompact) {
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
