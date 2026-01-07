import 'package:freezed_annotation/freezed_annotation.dart';

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
  }) = CodePayload;

  /// Markdown 类型 - 富文本内容
  const factory Payload.markdown({
    required String title,
    required String content,
  }) = MarkdownPayload;

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
    Map<String, dynamic>? metadata,
  }) = InteractivePayload;

  /// 从 JSON 解析
  factory Payload.fromJson(Map<String, dynamic> json) => _$PayloadFromJson(json);

  /// 获取消息类型字符串
  String get type => switch (this) {
    ProgressPayload() => 'progress',
    CompletePayload() => 'complete',
    ErrorPayload() => 'error',
    WarningPayload() => 'warning',
    CodePayload() => 'code',
    MarkdownPayload() => 'markdown',
    ImagePayload() => 'image',
    InteractivePayload() => 'interactive',
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
