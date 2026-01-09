import 'package:freezed_annotation/freezed_annotation.dart';
import '../task.dart';

part 'payload.freezed.dart';
part 'payload.g.dart';

/// 消息负载类型 - 使用 Freezed 的 union 类型实现
@freezed
sealed class Payload with _$Payload {
  const Payload._();

  /// 进度类型 - 任务进度更新
  const factory Payload.progress({
    required String title,
    String? description,
    @Default(0) int current,
    @Default(0) int total,
    String? currentStep,
  }) = ProgressPayload;

  /// 完成类型 - 任务完成
  const factory Payload.complete({
    required String title,
    String? summary,
    int? duration,
    int? toolCount,
  }) = CompletePayload;

  /// 错误类型 - 错误信息
  const factory Payload.error({
    required String title,
    required String message,
    String? stackTrace,
    String? suggestion,
  }) = ErrorPayload;

  /// 警告类型 - 警告信息
  const factory Payload.warning({
    required String title,
    required String message,
    String? action,
  }) = WarningPayload;

  /// 代码类型 - 代码片段
  const factory Payload.code({
    required String title,
    required String code,
    String? language,
    String? filename,
    int? startLine,
    List<CodeChange>? changes,
    @Default(StreamingStatus.complete) StreamingStatus streamingStatus,
  }) = CodePayload;

  /// Markdown 类型 - 富文本内容
  const factory Payload.markdown({
    required String title,
    required String content,
    @Default(StreamingStatus.complete) StreamingStatus streamingStatus,
    String? streamingId,
  }) = MarkdownPayload;

  /// 思维链类型 - AI 的推理过程（可折叠显示）
  const factory Payload.thinking({
    required String content,
    @Default(StreamingStatus.complete) StreamingStatus streamingStatus,
    String? streamingId,
  }) = ThinkingPayload;

  /// 图片类型 - 图片/截图
  const factory Payload.image({
    required String title,
    required String url,
    String? caption,
    int? width,
    int? height,
  }) = ImagePayload;

  /// 交互类型 - 需要用户响应
  const factory Payload.interactive({
    required String title,
    required String message,
    required String requestId,
    required InteractiveType interactiveType,

    /// 权限状态 (pending/approved/denied/canceled)
    @Default(PermissionStatus.pending) PermissionStatus status,
    Map<String, dynamic>? metadata,
  }) = InteractivePayload;

  /// 用户消息类型 - 用户输入的消息
  const factory Payload.userMessage({
    required String content,
    @Default(false) bool isPending,
    @Default(false) bool isFailed,
    String? failureReason,
  }) = UserMessagePayload;

  /// 任务执行类型 - 显示工具执行列表 (可折叠)
  const factory Payload.taskExecution({
    required String title,
    required List<TaskItem> tasks,
    required TaskStatus overallStatus,
    String? summary,
    String? prompt,
    int? durationMs,
    @Default(false) bool isExpanded,
  }) = TaskExecutionPayload;

  /// 隐藏类型 - 不显示在聊天界面，但用于消息链追踪
  /// 主要用于 tool_result 等内部消息
  const factory Payload.hidden({required String reason, String? toolUseId}) =
      HiddenPayload;

  /// 从 JSON 解析
  factory Payload.fromJson(Map<String, dynamic> json) =>
      _$PayloadFromJson(json);

  /// 获取消息类型字符串
  String get type => switch (this) {
    ProgressPayload() => 'progress',
    CompletePayload() => 'complete',
    ErrorPayload() => 'error',
    WarningPayload() => 'warning',
    CodePayload() => 'code',
    MarkdownPayload() => 'markdown',
    ThinkingPayload() => 'thinking',
    ImagePayload() => 'image',
    InteractivePayload() => 'interactive',
    UserMessagePayload() => 'userMessage',
    TaskExecutionPayload() => 'taskExecution',
    HiddenPayload() => 'hidden',
  };
}

/// 代码变更
@freezed
class CodeChange with _$CodeChange {
  const factory CodeChange({
    required int line,
    required ChangeType changeType,
    required String content,
  }) = _CodeChange;

  factory CodeChange.fromJson(Map<String, dynamic> json) =>
      _$CodeChangeFromJson(json);
}

/// 变更类型
enum ChangeType {
  @JsonValue('add')
  add,
  @JsonValue('remove')
  remove,
  @JsonValue('modify')
  modify,
}

/// 流式状态
enum StreamingStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('streaming')
  streaming,
  @JsonValue('complete')
  complete,
  @JsonValue('error')
  error,
}

/// 交互类型
enum InteractiveType {
  @JsonValue('permission')
  permission,
  @JsonValue('confirm')
  confirm,
  @JsonValue('input')
  input,
  @JsonValue('choice')
  choice,
}

/// 权限状态 (对应 hapi ToolPermission.status)
enum PermissionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('denied')
  denied,
  @JsonValue('canceled')
  canceled,
}
