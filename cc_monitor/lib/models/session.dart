import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

/// 会话状态
enum SessionStatus {
  @JsonValue('running')
  running,
  @JsonValue('waiting')
  waiting,
  @JsonValue('completed')
  completed,
  @JsonValue('error')
  error,
}

/// 会话进度
@freezed
class SessionProgress with _$SessionProgress {
  const factory SessionProgress({
    @Default(0) int current,
    @Default(0) int total,
    String? currentStep,
  }) = _SessionProgress;

  factory SessionProgress.fromJson(Map<String, dynamic> json) =>
      _$SessionProgressFromJson(json);
}

/// Todo 项
@freezed
class TodoItem with _$TodoItem {
  const factory TodoItem({
    required String content,
    required String status,
    String? activeForm,
  }) = _TodoItem;

  factory TodoItem.fromJson(Map<String, dynamic> json) =>
      _$TodoItemFromJson(json);
}

/// Agent 状态 - 从 hapi API 返回
@freezed
class AgentState with _$AgentState {
  const factory AgentState({
    /// 是否由本地终端控制
    @Default(false) bool controlledByUser,

    /// 待处理的权限请求 (key: requestId)
    @Default({}) Map<String, dynamic> requests,
  }) = _AgentState;

  factory AgentState.fromJson(Map<String, dynamic> json) =>
      _$AgentStateFromJson(json);
}

/// 会话模型
@freezed
class Session with _$Session {
  const Session._();

  const factory Session({
    /// 会话 ID
    required String id,

    /// 项目名称
    required String projectName,

    /// 项目路径
    String? projectPath,

    /// 会话状态
    @Default(SessionStatus.running) SessionStatus status,

    /// 进度信息
    SessionProgress? progress,

    /// Todo 列表
    @Default([]) List<TodoItem> todos,

    /// 当前任务描述
    String? currentTask,

    /// 开始时间
    required DateTime startedAt,

    /// 最后更新时间
    required DateTime lastUpdatedAt,

    /// 结束时间
    DateTime? endedAt,

    /// 总工具调用次数
    @Default(0) int toolCallCount,

    /// Agent 状态
    AgentState? agentState,

    /// 权限模式 (default, plan, acceptEdits, bypassPermissions)
    @Default('default') String permissionMode,

    /// 模型模式 (default, sonnet, opus, haiku)
    @Default('default') String modelMode,

    /// 上下文大小 (tokens)
    int? contextSize,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);

  /// 会话持续时间
  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  /// 是否活跃
  bool get isActive => status == SessionStatus.running;

  /// 是否等待用户响应
  bool get isWaiting => status == SessionStatus.waiting;

  /// 是否已完成
  bool get isCompleted => status == SessionStatus.completed;

  /// 进度百分比 (0-100)
  int get progressPercent {
    if (progress == null || progress!.total == 0) return 0;
    return ((progress!.current / progress!.total) * 100).round();
  }
}
