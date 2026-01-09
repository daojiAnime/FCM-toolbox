import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// 任务项 - 代表单个工具调用或文件操作
@freezed
class TaskItem with _$TaskItem {
  const TaskItem._();

  const factory TaskItem({
    /// 任务 ID
    required String id,

    /// 任务名称 (文件路径或命令)
    required String name,

    /// 任务状态
    required TaskItemStatus status,

    /// 详细描述
    String? description,

    /// 文件路径 (如果是文件操作)
    String? filePath,

    /// 执行耗时
    int? durationMs,

    /// 工具名称
    String? toolName,

    /// 完整的输入参数 (Map) - 用于专用视图渲染
    Map<String, dynamic>? input,

    /// 输入参数摘要 (用于快速展示)
    String? inputSummary,

    /// 输出结果摘要
    String? outputSummary,

    /// 是否有错误
    @Default(false) bool hasError,

    /// 错误信息
    String? errorMessage,
  }) = _TaskItem;

  factory TaskItem.fromJson(Map<String, dynamic> json) =>
      _$TaskItemFromJson(json);

  /// 状态图标
  String get statusIcon => switch (status) {
    TaskItemStatus.completed => '✓',
    TaskItemStatus.error => '✕',
    TaskItemStatus.running => '●',
    TaskItemStatus.pending => '🔐',
  };

  /// 显示名称 (截断长路径)
  String get displayName {
    if (name.length <= 40) return name;
    // 保留文件名和部分路径
    final parts = name.split('/');
    if (parts.length <= 2) return name;
    return '.../${parts.sublist(parts.length - 2).join('/')}';
  }
}

/// 任务项状态
enum TaskItemStatus {
  @JsonValue('pending')
  pending, // 🔐 待权限/等待中
  @JsonValue('running')
  running, // ● 运行中
  @JsonValue('completed')
  completed, // ✓ 完成
  @JsonValue('error')
  error, // ✕ 错误
}

/// 任务整体状态
enum TaskStatus {
  @JsonValue('pending')
  pending, // 等待开始
  @JsonValue('running')
  running, // 执行中
  @JsonValue('completed')
  completed, // 全部完成
  @JsonValue('partial')
  partial, // 部分完成
  @JsonValue('error')
  error, // 执行失败
}

/// TaskStatus 扩展
extension TaskStatusExtension on TaskStatus {
  /// 状态图标
  String get icon => switch (this) {
    TaskStatus.pending => '⏳',
    TaskStatus.running => '●',
    TaskStatus.completed => '✓',
    TaskStatus.partial => '⚠',
    TaskStatus.error => '✕',
  };

  /// 是否为活跃状态
  bool get isActive => this == TaskStatus.running || this == TaskStatus.pending;

  /// 是否已结束
  bool get isDone =>
      this == TaskStatus.completed ||
      this == TaskStatus.error ||
      this == TaskStatus.partial;
}
