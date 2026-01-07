import 'package:freezed_annotation/freezed_annotation.dart';

part 'command.freezed.dart';
part 'command.g.dart';

/// 指令状态
enum CommandStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('denied')
  denied,
  @JsonValue('expired')
  expired,
}

/// 指令类型
enum CommandType {
  @JsonValue('permission_response')
  permissionResponse,
  @JsonValue('task_control')
  taskControl,
  @JsonValue('user_input')
  userInput,
  @JsonValue('todo_update')
  todoUpdate,
}

/// 上行指令模型
@freezed
class Command with _$Command {
  const Command._();

  const factory Command({
    /// 指令 ID
    required String id,

    /// 会话 ID
    required String sessionId,

    /// 指令类型
    required CommandType type,

    /// 指令状态
    @Default(CommandStatus.pending) CommandStatus status,

    /// 指令负载
    required Map<String, dynamic> payload,

    /// 创建时间
    required DateTime createdAt,

    /// 响应时间
    DateTime? respondedAt,

    /// 过期时间
    DateTime? expiresAt,
  }) = _Command;

  factory Command.fromJson(Map<String, dynamic> json) =>
      _$CommandFromJson(json);

  /// 是否已过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 是否待处理
  bool get isPending => status == CommandStatus.pending && !isExpired;
}

/// 权限响应指令
@freezed
class PermissionResponsePayload with _$PermissionResponsePayload {
  const factory PermissionResponsePayload({
    required String requestId,
    required bool approved,
    String? reason,
  }) = _PermissionResponsePayload;

  factory PermissionResponsePayload.fromJson(Map<String, dynamic> json) =>
      _$PermissionResponsePayloadFromJson(json);
}

/// 任务控制指令
@freezed
class TaskControlPayload with _$TaskControlPayload {
  const factory TaskControlPayload({
    required TaskControlAction action,
    String? reason,
  }) = _TaskControlPayload;

  factory TaskControlPayload.fromJson(Map<String, dynamic> json) =>
      _$TaskControlPayloadFromJson(json);
}

/// 任务控制动作
enum TaskControlAction {
  @JsonValue('pause')
  pause,
  @JsonValue('resume')
  resume,
  @JsonValue('stop')
  stop,
}

/// 用户输入指令
@freezed
class UserInputPayload with _$UserInputPayload {
  const factory UserInputPayload({
    required String requestId,
    required String input,
  }) = _UserInputPayload;

  factory UserInputPayload.fromJson(Map<String, dynamic> json) =>
      _$UserInputPayloadFromJson(json);
}
