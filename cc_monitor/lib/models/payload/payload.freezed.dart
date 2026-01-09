// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Payload _$PayloadFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'progress':
      return ProgressPayload.fromJson(json);
    case 'complete':
      return CompletePayload.fromJson(json);
    case 'error':
      return ErrorPayload.fromJson(json);
    case 'warning':
      return WarningPayload.fromJson(json);
    case 'code':
      return CodePayload.fromJson(json);
    case 'markdown':
      return MarkdownPayload.fromJson(json);
    case 'thinking':
      return ThinkingPayload.fromJson(json);
    case 'image':
      return ImagePayload.fromJson(json);
    case 'interactive':
      return InteractivePayload.fromJson(json);
    case 'userMessage':
      return UserMessagePayload.fromJson(json);
    case 'taskExecution':
      return TaskExecutionPayload.fromJson(json);
    case 'hidden':
      return HiddenPayload.fromJson(json);

    default:
      throw CheckedFromJsonException(
        json,
        'runtimeType',
        'Payload',
        'Invalid union type "${json['runtimeType']}"!',
      );
  }
}

/// @nodoc
mixin _$Payload {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )
    progress,
    required TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )
    complete,
    required TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )
    error,
    required TResult Function(String title, String message, String? action)
    warning,
    required TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )
    code,
    required TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    markdown,
    required TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    thinking,
    required TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )
    image,
    required TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )
    interactive,
    required TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )
    userMessage,
    required TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )
    taskExecution,
    required TResult Function(String reason, String? toolUseId) hidden,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult? Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult? Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult? Function(String title, String message, String? action)? warning,
    TResult? Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult? Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult? Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult? Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult? Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult? Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult? Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult? Function(String reason, String? toolUseId)? hidden,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult Function(String title, String message, String? action)? warning,
    TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult Function(String reason, String? toolUseId)? hidden,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ProgressPayload value) progress,
    required TResult Function(CompletePayload value) complete,
    required TResult Function(ErrorPayload value) error,
    required TResult Function(WarningPayload value) warning,
    required TResult Function(CodePayload value) code,
    required TResult Function(MarkdownPayload value) markdown,
    required TResult Function(ThinkingPayload value) thinking,
    required TResult Function(ImagePayload value) image,
    required TResult Function(InteractivePayload value) interactive,
    required TResult Function(UserMessagePayload value) userMessage,
    required TResult Function(TaskExecutionPayload value) taskExecution,
    required TResult Function(HiddenPayload value) hidden,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ProgressPayload value)? progress,
    TResult? Function(CompletePayload value)? complete,
    TResult? Function(ErrorPayload value)? error,
    TResult? Function(WarningPayload value)? warning,
    TResult? Function(CodePayload value)? code,
    TResult? Function(MarkdownPayload value)? markdown,
    TResult? Function(ThinkingPayload value)? thinking,
    TResult? Function(ImagePayload value)? image,
    TResult? Function(InteractivePayload value)? interactive,
    TResult? Function(UserMessagePayload value)? userMessage,
    TResult? Function(TaskExecutionPayload value)? taskExecution,
    TResult? Function(HiddenPayload value)? hidden,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ProgressPayload value)? progress,
    TResult Function(CompletePayload value)? complete,
    TResult Function(ErrorPayload value)? error,
    TResult Function(WarningPayload value)? warning,
    TResult Function(CodePayload value)? code,
    TResult Function(MarkdownPayload value)? markdown,
    TResult Function(ThinkingPayload value)? thinking,
    TResult Function(ImagePayload value)? image,
    TResult Function(InteractivePayload value)? interactive,
    TResult Function(UserMessagePayload value)? userMessage,
    TResult Function(TaskExecutionPayload value)? taskExecution,
    TResult Function(HiddenPayload value)? hidden,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Serializes this Payload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayloadCopyWith<$Res> {
  factory $PayloadCopyWith(Payload value, $Res Function(Payload) then) =
      _$PayloadCopyWithImpl<$Res, Payload>;
}

/// @nodoc
class _$PayloadCopyWithImpl<$Res, $Val extends Payload>
    implements $PayloadCopyWith<$Res> {
  _$PayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$ProgressPayloadImplCopyWith<$Res> {
  factory _$$ProgressPayloadImplCopyWith(
    _$ProgressPayloadImpl value,
    $Res Function(_$ProgressPayloadImpl) then,
  ) = __$$ProgressPayloadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String title,
    String? description,
    int current,
    int total,
    String? currentStep,
  });
}

/// @nodoc
class __$$ProgressPayloadImplCopyWithImpl<$Res>
    extends _$PayloadCopyWithImpl<$Res, _$ProgressPayloadImpl>
    implements _$$ProgressPayloadImplCopyWith<$Res> {
  __$$ProgressPayloadImplCopyWithImpl(
    _$ProgressPayloadImpl _value,
    $Res Function(_$ProgressPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = freezed,
    Object? current = null,
    Object? total = null,
    Object? currentStep = freezed,
  }) {
    return _then(
      _$ProgressPayloadImpl(
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        description:
            freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String?,
        current:
            null == current
                ? _value.current
                : current // ignore: cast_nullable_to_non_nullable
                    as int,
        total:
            null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                    as int,
        currentStep:
            freezed == currentStep
                ? _value.currentStep
                : currentStep // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProgressPayloadImpl extends ProgressPayload {
  const _$ProgressPayloadImpl({
    required this.title,
    this.description,
    this.current = 0,
    this.total = 0,
    this.currentStep,
    final String? $type,
  }) : $type = $type ?? 'progress',
       super._();

  factory _$ProgressPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProgressPayloadImplFromJson(json);

  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey()
  final int current;
  @override
  @JsonKey()
  final int total;
  @override
  final String? currentStep;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Payload.progress(title: $title, description: $description, current: $current, total: $total, currentStep: $currentStep)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProgressPayloadImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.current, current) || other.current == current) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, title, description, current, total, currentStep);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProgressPayloadImplCopyWith<_$ProgressPayloadImpl> get copyWith =>
      __$$ProgressPayloadImplCopyWithImpl<_$ProgressPayloadImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )
    progress,
    required TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )
    complete,
    required TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )
    error,
    required TResult Function(String title, String message, String? action)
    warning,
    required TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )
    code,
    required TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    markdown,
    required TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    thinking,
    required TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )
    image,
    required TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )
    interactive,
    required TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )
    userMessage,
    required TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )
    taskExecution,
    required TResult Function(String reason, String? toolUseId) hidden,
  }) {
    return progress(title, description, current, total, currentStep);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult? Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult? Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult? Function(String title, String message, String? action)? warning,
    TResult? Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult? Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult? Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult? Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult? Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult? Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult? Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult? Function(String reason, String? toolUseId)? hidden,
  }) {
    return progress?.call(title, description, current, total, currentStep);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult Function(String title, String message, String? action)? warning,
    TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult Function(String reason, String? toolUseId)? hidden,
    required TResult orElse(),
  }) {
    if (progress != null) {
      return progress(title, description, current, total, currentStep);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ProgressPayload value) progress,
    required TResult Function(CompletePayload value) complete,
    required TResult Function(ErrorPayload value) error,
    required TResult Function(WarningPayload value) warning,
    required TResult Function(CodePayload value) code,
    required TResult Function(MarkdownPayload value) markdown,
    required TResult Function(ThinkingPayload value) thinking,
    required TResult Function(ImagePayload value) image,
    required TResult Function(InteractivePayload value) interactive,
    required TResult Function(UserMessagePayload value) userMessage,
    required TResult Function(TaskExecutionPayload value) taskExecution,
    required TResult Function(HiddenPayload value) hidden,
  }) {
    return progress(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ProgressPayload value)? progress,
    TResult? Function(CompletePayload value)? complete,
    TResult? Function(ErrorPayload value)? error,
    TResult? Function(WarningPayload value)? warning,
    TResult? Function(CodePayload value)? code,
    TResult? Function(MarkdownPayload value)? markdown,
    TResult? Function(ThinkingPayload value)? thinking,
    TResult? Function(ImagePayload value)? image,
    TResult? Function(InteractivePayload value)? interactive,
    TResult? Function(UserMessagePayload value)? userMessage,
    TResult? Function(TaskExecutionPayload value)? taskExecution,
    TResult? Function(HiddenPayload value)? hidden,
  }) {
    return progress?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ProgressPayload value)? progress,
    TResult Function(CompletePayload value)? complete,
    TResult Function(ErrorPayload value)? error,
    TResult Function(WarningPayload value)? warning,
    TResult Function(CodePayload value)? code,
    TResult Function(MarkdownPayload value)? markdown,
    TResult Function(ThinkingPayload value)? thinking,
    TResult Function(ImagePayload value)? image,
    TResult Function(InteractivePayload value)? interactive,
    TResult Function(UserMessagePayload value)? userMessage,
    TResult Function(TaskExecutionPayload value)? taskExecution,
    TResult Function(HiddenPayload value)? hidden,
    required TResult orElse(),
  }) {
    if (progress != null) {
      return progress(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ProgressPayloadImplToJson(this);
  }
}

abstract class ProgressPayload extends Payload {
  const factory ProgressPayload({
    required final String title,
    final String? description,
    final int current,
    final int total,
    final String? currentStep,
  }) = _$ProgressPayloadImpl;
  const ProgressPayload._() : super._();

  factory ProgressPayload.fromJson(Map<String, dynamic> json) =
      _$ProgressPayloadImpl.fromJson;

  String get title;
  String? get description;
  int get current;
  int get total;
  String? get currentStep;

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProgressPayloadImplCopyWith<_$ProgressPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CompletePayloadImplCopyWith<$Res> {
  factory _$$CompletePayloadImplCopyWith(
    _$CompletePayloadImpl value,
    $Res Function(_$CompletePayloadImpl) then,
  ) = __$$CompletePayloadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String title, String? summary, int? duration, int? toolCount});
}

/// @nodoc
class __$$CompletePayloadImplCopyWithImpl<$Res>
    extends _$PayloadCopyWithImpl<$Res, _$CompletePayloadImpl>
    implements _$$CompletePayloadImplCopyWith<$Res> {
  __$$CompletePayloadImplCopyWithImpl(
    _$CompletePayloadImpl _value,
    $Res Function(_$CompletePayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? summary = freezed,
    Object? duration = freezed,
    Object? toolCount = freezed,
  }) {
    return _then(
      _$CompletePayloadImpl(
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        summary:
            freezed == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                    as String?,
        duration:
            freezed == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                    as int?,
        toolCount:
            freezed == toolCount
                ? _value.toolCount
                : toolCount // ignore: cast_nullable_to_non_nullable
                    as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CompletePayloadImpl extends CompletePayload {
  const _$CompletePayloadImpl({
    required this.title,
    this.summary,
    this.duration,
    this.toolCount,
    final String? $type,
  }) : $type = $type ?? 'complete',
       super._();

  factory _$CompletePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompletePayloadImplFromJson(json);

  @override
  final String title;
  @override
  final String? summary;
  @override
  final int? duration;
  @override
  final int? toolCount;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Payload.complete(title: $title, summary: $summary, duration: $duration, toolCount: $toolCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompletePayloadImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.toolCount, toolCount) ||
                other.toolCount == toolCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, title, summary, duration, toolCount);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompletePayloadImplCopyWith<_$CompletePayloadImpl> get copyWith =>
      __$$CompletePayloadImplCopyWithImpl<_$CompletePayloadImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )
    progress,
    required TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )
    complete,
    required TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )
    error,
    required TResult Function(String title, String message, String? action)
    warning,
    required TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )
    code,
    required TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    markdown,
    required TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    thinking,
    required TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )
    image,
    required TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )
    interactive,
    required TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )
    userMessage,
    required TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )
    taskExecution,
    required TResult Function(String reason, String? toolUseId) hidden,
  }) {
    return complete(title, summary, duration, toolCount);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult? Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult? Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult? Function(String title, String message, String? action)? warning,
    TResult? Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult? Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult? Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult? Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult? Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult? Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult? Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult? Function(String reason, String? toolUseId)? hidden,
  }) {
    return complete?.call(title, summary, duration, toolCount);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult Function(String title, String message, String? action)? warning,
    TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult Function(String reason, String? toolUseId)? hidden,
    required TResult orElse(),
  }) {
    if (complete != null) {
      return complete(title, summary, duration, toolCount);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ProgressPayload value) progress,
    required TResult Function(CompletePayload value) complete,
    required TResult Function(ErrorPayload value) error,
    required TResult Function(WarningPayload value) warning,
    required TResult Function(CodePayload value) code,
    required TResult Function(MarkdownPayload value) markdown,
    required TResult Function(ThinkingPayload value) thinking,
    required TResult Function(ImagePayload value) image,
    required TResult Function(InteractivePayload value) interactive,
    required TResult Function(UserMessagePayload value) userMessage,
    required TResult Function(TaskExecutionPayload value) taskExecution,
    required TResult Function(HiddenPayload value) hidden,
  }) {
    return complete(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ProgressPayload value)? progress,
    TResult? Function(CompletePayload value)? complete,
    TResult? Function(ErrorPayload value)? error,
    TResult? Function(WarningPayload value)? warning,
    TResult? Function(CodePayload value)? code,
    TResult? Function(MarkdownPayload value)? markdown,
    TResult? Function(ThinkingPayload value)? thinking,
    TResult? Function(ImagePayload value)? image,
    TResult? Function(InteractivePayload value)? interactive,
    TResult? Function(UserMessagePayload value)? userMessage,
    TResult? Function(TaskExecutionPayload value)? taskExecution,
    TResult? Function(HiddenPayload value)? hidden,
  }) {
    return complete?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ProgressPayload value)? progress,
    TResult Function(CompletePayload value)? complete,
    TResult Function(ErrorPayload value)? error,
    TResult Function(WarningPayload value)? warning,
    TResult Function(CodePayload value)? code,
    TResult Function(MarkdownPayload value)? markdown,
    TResult Function(ThinkingPayload value)? thinking,
    TResult Function(ImagePayload value)? image,
    TResult Function(InteractivePayload value)? interactive,
    TResult Function(UserMessagePayload value)? userMessage,
    TResult Function(TaskExecutionPayload value)? taskExecution,
    TResult Function(HiddenPayload value)? hidden,
    required TResult orElse(),
  }) {
    if (complete != null) {
      return complete(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CompletePayloadImplToJson(this);
  }
}

abstract class CompletePayload extends Payload {
  const factory CompletePayload({
    required final String title,
    final String? summary,
    final int? duration,
    final int? toolCount,
  }) = _$CompletePayloadImpl;
  const CompletePayload._() : super._();

  factory CompletePayload.fromJson(Map<String, dynamic> json) =
      _$CompletePayloadImpl.fromJson;

  String get title;
  String? get summary;
  int? get duration;
  int? get toolCount;

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompletePayloadImplCopyWith<_$CompletePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorPayloadImplCopyWith<$Res> {
  factory _$$ErrorPayloadImplCopyWith(
    _$ErrorPayloadImpl value,
    $Res Function(_$ErrorPayloadImpl) then,
  ) = __$$ErrorPayloadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String title,
    String message,
    String? stackTrace,
    String? suggestion,
  });
}

/// @nodoc
class __$$ErrorPayloadImplCopyWithImpl<$Res>
    extends _$PayloadCopyWithImpl<$Res, _$ErrorPayloadImpl>
    implements _$$ErrorPayloadImplCopyWith<$Res> {
  __$$ErrorPayloadImplCopyWithImpl(
    _$ErrorPayloadImpl _value,
    $Res Function(_$ErrorPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? message = null,
    Object? stackTrace = freezed,
    Object? suggestion = freezed,
  }) {
    return _then(
      _$ErrorPayloadImpl(
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        message:
            null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                    as String,
        stackTrace:
            freezed == stackTrace
                ? _value.stackTrace
                : stackTrace // ignore: cast_nullable_to_non_nullable
                    as String?,
        suggestion:
            freezed == suggestion
                ? _value.suggestion
                : suggestion // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ErrorPayloadImpl extends ErrorPayload {
  const _$ErrorPayloadImpl({
    required this.title,
    required this.message,
    this.stackTrace,
    this.suggestion,
    final String? $type,
  }) : $type = $type ?? 'error',
       super._();

  factory _$ErrorPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$ErrorPayloadImplFromJson(json);

  @override
  final String title;
  @override
  final String message;
  @override
  final String? stackTrace;
  @override
  final String? suggestion;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Payload.error(title: $title, message: $message, stackTrace: $stackTrace, suggestion: $suggestion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorPayloadImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.stackTrace, stackTrace) ||
                other.stackTrace == stackTrace) &&
            (identical(other.suggestion, suggestion) ||
                other.suggestion == suggestion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, title, message, stackTrace, suggestion);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorPayloadImplCopyWith<_$ErrorPayloadImpl> get copyWith =>
      __$$ErrorPayloadImplCopyWithImpl<_$ErrorPayloadImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )
    progress,
    required TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )
    complete,
    required TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )
    error,
    required TResult Function(String title, String message, String? action)
    warning,
    required TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )
    code,
    required TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    markdown,
    required TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    thinking,
    required TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )
    image,
    required TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )
    interactive,
    required TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )
    userMessage,
    required TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )
    taskExecution,
    required TResult Function(String reason, String? toolUseId) hidden,
  }) {
    return error(title, message, stackTrace, suggestion);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult? Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult? Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult? Function(String title, String message, String? action)? warning,
    TResult? Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult? Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult? Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult? Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult? Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult? Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult? Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult? Function(String reason, String? toolUseId)? hidden,
  }) {
    return error?.call(title, message, stackTrace, suggestion);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult Function(String title, String message, String? action)? warning,
    TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult Function(String reason, String? toolUseId)? hidden,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(title, message, stackTrace, suggestion);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ProgressPayload value) progress,
    required TResult Function(CompletePayload value) complete,
    required TResult Function(ErrorPayload value) error,
    required TResult Function(WarningPayload value) warning,
    required TResult Function(CodePayload value) code,
    required TResult Function(MarkdownPayload value) markdown,
    required TResult Function(ThinkingPayload value) thinking,
    required TResult Function(ImagePayload value) image,
    required TResult Function(InteractivePayload value) interactive,
    required TResult Function(UserMessagePayload value) userMessage,
    required TResult Function(TaskExecutionPayload value) taskExecution,
    required TResult Function(HiddenPayload value) hidden,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ProgressPayload value)? progress,
    TResult? Function(CompletePayload value)? complete,
    TResult? Function(ErrorPayload value)? error,
    TResult? Function(WarningPayload value)? warning,
    TResult? Function(CodePayload value)? code,
    TResult? Function(MarkdownPayload value)? markdown,
    TResult? Function(ThinkingPayload value)? thinking,
    TResult? Function(ImagePayload value)? image,
    TResult? Function(InteractivePayload value)? interactive,
    TResult? Function(UserMessagePayload value)? userMessage,
    TResult? Function(TaskExecutionPayload value)? taskExecution,
    TResult? Function(HiddenPayload value)? hidden,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ProgressPayload value)? progress,
    TResult Function(CompletePayload value)? complete,
    TResult Function(ErrorPayload value)? error,
    TResult Function(WarningPayload value)? warning,
    TResult Function(CodePayload value)? code,
    TResult Function(MarkdownPayload value)? markdown,
    TResult Function(ThinkingPayload value)? thinking,
    TResult Function(ImagePayload value)? image,
    TResult Function(InteractivePayload value)? interactive,
    TResult Function(UserMessagePayload value)? userMessage,
    TResult Function(TaskExecutionPayload value)? taskExecution,
    TResult Function(HiddenPayload value)? hidden,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ErrorPayloadImplToJson(this);
  }
}

abstract class ErrorPayload extends Payload {
  const factory ErrorPayload({
    required final String title,
    required final String message,
    final String? stackTrace,
    final String? suggestion,
  }) = _$ErrorPayloadImpl;
  const ErrorPayload._() : super._();

  factory ErrorPayload.fromJson(Map<String, dynamic> json) =
      _$ErrorPayloadImpl.fromJson;

  String get title;
  String get message;
  String? get stackTrace;
  String? get suggestion;

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorPayloadImplCopyWith<_$ErrorPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WarningPayloadImplCopyWith<$Res> {
  factory _$$WarningPayloadImplCopyWith(
    _$WarningPayloadImpl value,
    $Res Function(_$WarningPayloadImpl) then,
  ) = __$$WarningPayloadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String title, String message, String? action});
}

/// @nodoc
class __$$WarningPayloadImplCopyWithImpl<$Res>
    extends _$PayloadCopyWithImpl<$Res, _$WarningPayloadImpl>
    implements _$$WarningPayloadImplCopyWith<$Res> {
  __$$WarningPayloadImplCopyWithImpl(
    _$WarningPayloadImpl _value,
    $Res Function(_$WarningPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? message = null,
    Object? action = freezed,
  }) {
    return _then(
      _$WarningPayloadImpl(
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        message:
            null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                    as String,
        action:
            freezed == action
                ? _value.action
                : action // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WarningPayloadImpl extends WarningPayload {
  const _$WarningPayloadImpl({
    required this.title,
    required this.message,
    this.action,
    final String? $type,
  }) : $type = $type ?? 'warning',
       super._();

  factory _$WarningPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$WarningPayloadImplFromJson(json);

  @override
  final String title;
  @override
  final String message;
  @override
  final String? action;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Payload.warning(title: $title, message: $message, action: $action)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WarningPayloadImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.action, action) || other.action == action));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, title, message, action);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WarningPayloadImplCopyWith<_$WarningPayloadImpl> get copyWith =>
      __$$WarningPayloadImplCopyWithImpl<_$WarningPayloadImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )
    progress,
    required TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )
    complete,
    required TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )
    error,
    required TResult Function(String title, String message, String? action)
    warning,
    required TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )
    code,
    required TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    markdown,
    required TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    thinking,
    required TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )
    image,
    required TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )
    interactive,
    required TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )
    userMessage,
    required TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )
    taskExecution,
    required TResult Function(String reason, String? toolUseId) hidden,
  }) {
    return warning(title, message, action);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult? Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult? Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult? Function(String title, String message, String? action)? warning,
    TResult? Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult? Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult? Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult? Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult? Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult? Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult? Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult? Function(String reason, String? toolUseId)? hidden,
  }) {
    return warning?.call(title, message, action);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult Function(String title, String message, String? action)? warning,
    TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult Function(String reason, String? toolUseId)? hidden,
    required TResult orElse(),
  }) {
    if (warning != null) {
      return warning(title, message, action);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ProgressPayload value) progress,
    required TResult Function(CompletePayload value) complete,
    required TResult Function(ErrorPayload value) error,
    required TResult Function(WarningPayload value) warning,
    required TResult Function(CodePayload value) code,
    required TResult Function(MarkdownPayload value) markdown,
    required TResult Function(ThinkingPayload value) thinking,
    required TResult Function(ImagePayload value) image,
    required TResult Function(InteractivePayload value) interactive,
    required TResult Function(UserMessagePayload value) userMessage,
    required TResult Function(TaskExecutionPayload value) taskExecution,
    required TResult Function(HiddenPayload value) hidden,
  }) {
    return warning(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ProgressPayload value)? progress,
    TResult? Function(CompletePayload value)? complete,
    TResult? Function(ErrorPayload value)? error,
    TResult? Function(WarningPayload value)? warning,
    TResult? Function(CodePayload value)? code,
    TResult? Function(MarkdownPayload value)? markdown,
    TResult? Function(ThinkingPayload value)? thinking,
    TResult? Function(ImagePayload value)? image,
    TResult? Function(InteractivePayload value)? interactive,
    TResult? Function(UserMessagePayload value)? userMessage,
    TResult? Function(TaskExecutionPayload value)? taskExecution,
    TResult? Function(HiddenPayload value)? hidden,
  }) {
    return warning?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ProgressPayload value)? progress,
    TResult Function(CompletePayload value)? complete,
    TResult Function(ErrorPayload value)? error,
    TResult Function(WarningPayload value)? warning,
    TResult Function(CodePayload value)? code,
    TResult Function(MarkdownPayload value)? markdown,
    TResult Function(ThinkingPayload value)? thinking,
    TResult Function(ImagePayload value)? image,
    TResult Function(InteractivePayload value)? interactive,
    TResult Function(UserMessagePayload value)? userMessage,
    TResult Function(TaskExecutionPayload value)? taskExecution,
    TResult Function(HiddenPayload value)? hidden,
    required TResult orElse(),
  }) {
    if (warning != null) {
      return warning(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$WarningPayloadImplToJson(this);
  }
}

abstract class WarningPayload extends Payload {
  const factory WarningPayload({
    required final String title,
    required final String message,
    final String? action,
  }) = _$WarningPayloadImpl;
  const WarningPayload._() : super._();

  factory WarningPayload.fromJson(Map<String, dynamic> json) =
      _$WarningPayloadImpl.fromJson;

  String get title;
  String get message;
  String? get action;

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WarningPayloadImplCopyWith<_$WarningPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CodePayloadImplCopyWith<$Res> {
  factory _$$CodePayloadImplCopyWith(
    _$CodePayloadImpl value,
    $Res Function(_$CodePayloadImpl) then,
  ) = __$$CodePayloadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String title,
    String code,
    String? language,
    String? filename,
    int? startLine,
    List<CodeChange>? changes,
    StreamingStatus streamingStatus,
  });
}

/// @nodoc
class __$$CodePayloadImplCopyWithImpl<$Res>
    extends _$PayloadCopyWithImpl<$Res, _$CodePayloadImpl>
    implements _$$CodePayloadImplCopyWith<$Res> {
  __$$CodePayloadImplCopyWithImpl(
    _$CodePayloadImpl _value,
    $Res Function(_$CodePayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? code = null,
    Object? language = freezed,
    Object? filename = freezed,
    Object? startLine = freezed,
    Object? changes = freezed,
    Object? streamingStatus = null,
  }) {
    return _then(
      _$CodePayloadImpl(
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        code:
            null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                    as String,
        language:
            freezed == language
                ? _value.language
                : language // ignore: cast_nullable_to_non_nullable
                    as String?,
        filename:
            freezed == filename
                ? _value.filename
                : filename // ignore: cast_nullable_to_non_nullable
                    as String?,
        startLine:
            freezed == startLine
                ? _value.startLine
                : startLine // ignore: cast_nullable_to_non_nullable
                    as int?,
        changes:
            freezed == changes
                ? _value._changes
                : changes // ignore: cast_nullable_to_non_nullable
                    as List<CodeChange>?,
        streamingStatus:
            null == streamingStatus
                ? _value.streamingStatus
                : streamingStatus // ignore: cast_nullable_to_non_nullable
                    as StreamingStatus,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CodePayloadImpl extends CodePayload {
  const _$CodePayloadImpl({
    required this.title,
    required this.code,
    this.language,
    this.filename,
    this.startLine,
    final List<CodeChange>? changes,
    this.streamingStatus = StreamingStatus.complete,
    final String? $type,
  }) : _changes = changes,
       $type = $type ?? 'code',
       super._();

  factory _$CodePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$CodePayloadImplFromJson(json);

  @override
  final String title;
  @override
  final String code;
  @override
  final String? language;
  @override
  final String? filename;
  @override
  final int? startLine;
  final List<CodeChange>? _changes;
  @override
  List<CodeChange>? get changes {
    final value = _changes;
    if (value == null) return null;
    if (_changes is EqualUnmodifiableListView) return _changes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final StreamingStatus streamingStatus;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Payload.code(title: $title, code: $code, language: $language, filename: $filename, startLine: $startLine, changes: $changes, streamingStatus: $streamingStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CodePayloadImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.filename, filename) ||
                other.filename == filename) &&
            (identical(other.startLine, startLine) ||
                other.startLine == startLine) &&
            const DeepCollectionEquality().equals(other._changes, _changes) &&
            (identical(other.streamingStatus, streamingStatus) ||
                other.streamingStatus == streamingStatus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    title,
    code,
    language,
    filename,
    startLine,
    const DeepCollectionEquality().hash(_changes),
    streamingStatus,
  );

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CodePayloadImplCopyWith<_$CodePayloadImpl> get copyWith =>
      __$$CodePayloadImplCopyWithImpl<_$CodePayloadImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )
    progress,
    required TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )
    complete,
    required TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )
    error,
    required TResult Function(String title, String message, String? action)
    warning,
    required TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )
    code,
    required TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    markdown,
    required TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    thinking,
    required TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )
    image,
    required TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )
    interactive,
    required TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )
    userMessage,
    required TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )
    taskExecution,
    required TResult Function(String reason, String? toolUseId) hidden,
  }) {
    return code(
      title,
      this.code,
      language,
      filename,
      startLine,
      changes,
      streamingStatus,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult? Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult? Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult? Function(String title, String message, String? action)? warning,
    TResult? Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult? Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult? Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult? Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult? Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult? Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult? Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult? Function(String reason, String? toolUseId)? hidden,
  }) {
    return code?.call(
      title,
      this.code,
      language,
      filename,
      startLine,
      changes,
      streamingStatus,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult Function(String title, String message, String? action)? warning,
    TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult Function(String reason, String? toolUseId)? hidden,
    required TResult orElse(),
  }) {
    if (code != null) {
      return code(
        title,
        this.code,
        language,
        filename,
        startLine,
        changes,
        streamingStatus,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ProgressPayload value) progress,
    required TResult Function(CompletePayload value) complete,
    required TResult Function(ErrorPayload value) error,
    required TResult Function(WarningPayload value) warning,
    required TResult Function(CodePayload value) code,
    required TResult Function(MarkdownPayload value) markdown,
    required TResult Function(ThinkingPayload value) thinking,
    required TResult Function(ImagePayload value) image,
    required TResult Function(InteractivePayload value) interactive,
    required TResult Function(UserMessagePayload value) userMessage,
    required TResult Function(TaskExecutionPayload value) taskExecution,
    required TResult Function(HiddenPayload value) hidden,
  }) {
    return code(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ProgressPayload value)? progress,
    TResult? Function(CompletePayload value)? complete,
    TResult? Function(ErrorPayload value)? error,
    TResult? Function(WarningPayload value)? warning,
    TResult? Function(CodePayload value)? code,
    TResult? Function(MarkdownPayload value)? markdown,
    TResult? Function(ThinkingPayload value)? thinking,
    TResult? Function(ImagePayload value)? image,
    TResult? Function(InteractivePayload value)? interactive,
    TResult? Function(UserMessagePayload value)? userMessage,
    TResult? Function(TaskExecutionPayload value)? taskExecution,
    TResult? Function(HiddenPayload value)? hidden,
  }) {
    return code?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ProgressPayload value)? progress,
    TResult Function(CompletePayload value)? complete,
    TResult Function(ErrorPayload value)? error,
    TResult Function(WarningPayload value)? warning,
    TResult Function(CodePayload value)? code,
    TResult Function(MarkdownPayload value)? markdown,
    TResult Function(ThinkingPayload value)? thinking,
    TResult Function(ImagePayload value)? image,
    TResult Function(InteractivePayload value)? interactive,
    TResult Function(UserMessagePayload value)? userMessage,
    TResult Function(TaskExecutionPayload value)? taskExecution,
    TResult Function(HiddenPayload value)? hidden,
    required TResult orElse(),
  }) {
    if (code != null) {
      return code(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CodePayloadImplToJson(this);
  }
}

abstract class CodePayload extends Payload {
  const factory CodePayload({
    required final String title,
    required final String code,
    final String? language,
    final String? filename,
    final int? startLine,
    final List<CodeChange>? changes,
    final StreamingStatus streamingStatus,
  }) = _$CodePayloadImpl;
  const CodePayload._() : super._();

  factory CodePayload.fromJson(Map<String, dynamic> json) =
      _$CodePayloadImpl.fromJson;

  String get title;
  String get code;
  String? get language;
  String? get filename;
  int? get startLine;
  List<CodeChange>? get changes;
  StreamingStatus get streamingStatus;

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CodePayloadImplCopyWith<_$CodePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MarkdownPayloadImplCopyWith<$Res> {
  factory _$$MarkdownPayloadImplCopyWith(
    _$MarkdownPayloadImpl value,
    $Res Function(_$MarkdownPayloadImpl) then,
  ) = __$$MarkdownPayloadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String title,
    String content,
    StreamingStatus streamingStatus,
    String? streamingId,
  });
}

/// @nodoc
class __$$MarkdownPayloadImplCopyWithImpl<$Res>
    extends _$PayloadCopyWithImpl<$Res, _$MarkdownPayloadImpl>
    implements _$$MarkdownPayloadImplCopyWith<$Res> {
  __$$MarkdownPayloadImplCopyWithImpl(
    _$MarkdownPayloadImpl _value,
    $Res Function(_$MarkdownPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? content = null,
    Object? streamingStatus = null,
    Object? streamingId = freezed,
  }) {
    return _then(
      _$MarkdownPayloadImpl(
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        content:
            null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                    as String,
        streamingStatus:
            null == streamingStatus
                ? _value.streamingStatus
                : streamingStatus // ignore: cast_nullable_to_non_nullable
                    as StreamingStatus,
        streamingId:
            freezed == streamingId
                ? _value.streamingId
                : streamingId // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MarkdownPayloadImpl extends MarkdownPayload {
  const _$MarkdownPayloadImpl({
    required this.title,
    required this.content,
    this.streamingStatus = StreamingStatus.complete,
    this.streamingId,
    final String? $type,
  }) : $type = $type ?? 'markdown',
       super._();

  factory _$MarkdownPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$MarkdownPayloadImplFromJson(json);

  @override
  final String title;
  @override
  final String content;
  @override
  @JsonKey()
  final StreamingStatus streamingStatus;
  @override
  final String? streamingId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Payload.markdown(title: $title, content: $content, streamingStatus: $streamingStatus, streamingId: $streamingId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MarkdownPayloadImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.streamingStatus, streamingStatus) ||
                other.streamingStatus == streamingStatus) &&
            (identical(other.streamingId, streamingId) ||
                other.streamingId == streamingId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, title, content, streamingStatus, streamingId);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MarkdownPayloadImplCopyWith<_$MarkdownPayloadImpl> get copyWith =>
      __$$MarkdownPayloadImplCopyWithImpl<_$MarkdownPayloadImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )
    progress,
    required TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )
    complete,
    required TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )
    error,
    required TResult Function(String title, String message, String? action)
    warning,
    required TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )
    code,
    required TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    markdown,
    required TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    thinking,
    required TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )
    image,
    required TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )
    interactive,
    required TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )
    userMessage,
    required TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )
    taskExecution,
    required TResult Function(String reason, String? toolUseId) hidden,
  }) {
    return markdown(title, content, streamingStatus, streamingId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult? Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult? Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult? Function(String title, String message, String? action)? warning,
    TResult? Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult? Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult? Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult? Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult? Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult? Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult? Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult? Function(String reason, String? toolUseId)? hidden,
  }) {
    return markdown?.call(title, content, streamingStatus, streamingId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult Function(String title, String message, String? action)? warning,
    TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult Function(String reason, String? toolUseId)? hidden,
    required TResult orElse(),
  }) {
    if (markdown != null) {
      return markdown(title, content, streamingStatus, streamingId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ProgressPayload value) progress,
    required TResult Function(CompletePayload value) complete,
    required TResult Function(ErrorPayload value) error,
    required TResult Function(WarningPayload value) warning,
    required TResult Function(CodePayload value) code,
    required TResult Function(MarkdownPayload value) markdown,
    required TResult Function(ThinkingPayload value) thinking,
    required TResult Function(ImagePayload value) image,
    required TResult Function(InteractivePayload value) interactive,
    required TResult Function(UserMessagePayload value) userMessage,
    required TResult Function(TaskExecutionPayload value) taskExecution,
    required TResult Function(HiddenPayload value) hidden,
  }) {
    return markdown(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ProgressPayload value)? progress,
    TResult? Function(CompletePayload value)? complete,
    TResult? Function(ErrorPayload value)? error,
    TResult? Function(WarningPayload value)? warning,
    TResult? Function(CodePayload value)? code,
    TResult? Function(MarkdownPayload value)? markdown,
    TResult? Function(ThinkingPayload value)? thinking,
    TResult? Function(ImagePayload value)? image,
    TResult? Function(InteractivePayload value)? interactive,
    TResult? Function(UserMessagePayload value)? userMessage,
    TResult? Function(TaskExecutionPayload value)? taskExecution,
    TResult? Function(HiddenPayload value)? hidden,
  }) {
    return markdown?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ProgressPayload value)? progress,
    TResult Function(CompletePayload value)? complete,
    TResult Function(ErrorPayload value)? error,
    TResult Function(WarningPayload value)? warning,
    TResult Function(CodePayload value)? code,
    TResult Function(MarkdownPayload value)? markdown,
    TResult Function(ThinkingPayload value)? thinking,
    TResult Function(ImagePayload value)? image,
    TResult Function(InteractivePayload value)? interactive,
    TResult Function(UserMessagePayload value)? userMessage,
    TResult Function(TaskExecutionPayload value)? taskExecution,
    TResult Function(HiddenPayload value)? hidden,
    required TResult orElse(),
  }) {
    if (markdown != null) {
      return markdown(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$MarkdownPayloadImplToJson(this);
  }
}

abstract class MarkdownPayload extends Payload {
  const factory MarkdownPayload({
    required final String title,
    required final String content,
    final StreamingStatus streamingStatus,
    final String? streamingId,
  }) = _$MarkdownPayloadImpl;
  const MarkdownPayload._() : super._();

  factory MarkdownPayload.fromJson(Map<String, dynamic> json) =
      _$MarkdownPayloadImpl.fromJson;

  String get title;
  String get content;
  StreamingStatus get streamingStatus;
  String? get streamingId;

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MarkdownPayloadImplCopyWith<_$MarkdownPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ThinkingPayloadImplCopyWith<$Res> {
  factory _$$ThinkingPayloadImplCopyWith(
    _$ThinkingPayloadImpl value,
    $Res Function(_$ThinkingPayloadImpl) then,
  ) = __$$ThinkingPayloadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String content,
    StreamingStatus streamingStatus,
    String? streamingId,
  });
}

/// @nodoc
class __$$ThinkingPayloadImplCopyWithImpl<$Res>
    extends _$PayloadCopyWithImpl<$Res, _$ThinkingPayloadImpl>
    implements _$$ThinkingPayloadImplCopyWith<$Res> {
  __$$ThinkingPayloadImplCopyWithImpl(
    _$ThinkingPayloadImpl _value,
    $Res Function(_$ThinkingPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
    Object? streamingStatus = null,
    Object? streamingId = freezed,
  }) {
    return _then(
      _$ThinkingPayloadImpl(
        content:
            null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                    as String,
        streamingStatus:
            null == streamingStatus
                ? _value.streamingStatus
                : streamingStatus // ignore: cast_nullable_to_non_nullable
                    as StreamingStatus,
        streamingId:
            freezed == streamingId
                ? _value.streamingId
                : streamingId // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ThinkingPayloadImpl extends ThinkingPayload {
  const _$ThinkingPayloadImpl({
    required this.content,
    this.streamingStatus = StreamingStatus.complete,
    this.streamingId,
    final String? $type,
  }) : $type = $type ?? 'thinking',
       super._();

  factory _$ThinkingPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThinkingPayloadImplFromJson(json);

  @override
  final String content;
  @override
  @JsonKey()
  final StreamingStatus streamingStatus;
  @override
  final String? streamingId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Payload.thinking(content: $content, streamingStatus: $streamingStatus, streamingId: $streamingId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThinkingPayloadImpl &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.streamingStatus, streamingStatus) ||
                other.streamingStatus == streamingStatus) &&
            (identical(other.streamingId, streamingId) ||
                other.streamingId == streamingId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, content, streamingStatus, streamingId);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ThinkingPayloadImplCopyWith<_$ThinkingPayloadImpl> get copyWith =>
      __$$ThinkingPayloadImplCopyWithImpl<_$ThinkingPayloadImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )
    progress,
    required TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )
    complete,
    required TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )
    error,
    required TResult Function(String title, String message, String? action)
    warning,
    required TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )
    code,
    required TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    markdown,
    required TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    thinking,
    required TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )
    image,
    required TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )
    interactive,
    required TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )
    userMessage,
    required TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )
    taskExecution,
    required TResult Function(String reason, String? toolUseId) hidden,
  }) {
    return thinking(content, streamingStatus, streamingId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult? Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult? Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult? Function(String title, String message, String? action)? warning,
    TResult? Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult? Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult? Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult? Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult? Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult? Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult? Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult? Function(String reason, String? toolUseId)? hidden,
  }) {
    return thinking?.call(content, streamingStatus, streamingId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult Function(String title, String message, String? action)? warning,
    TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult Function(String reason, String? toolUseId)? hidden,
    required TResult orElse(),
  }) {
    if (thinking != null) {
      return thinking(content, streamingStatus, streamingId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ProgressPayload value) progress,
    required TResult Function(CompletePayload value) complete,
    required TResult Function(ErrorPayload value) error,
    required TResult Function(WarningPayload value) warning,
    required TResult Function(CodePayload value) code,
    required TResult Function(MarkdownPayload value) markdown,
    required TResult Function(ThinkingPayload value) thinking,
    required TResult Function(ImagePayload value) image,
    required TResult Function(InteractivePayload value) interactive,
    required TResult Function(UserMessagePayload value) userMessage,
    required TResult Function(TaskExecutionPayload value) taskExecution,
    required TResult Function(HiddenPayload value) hidden,
  }) {
    return thinking(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ProgressPayload value)? progress,
    TResult? Function(CompletePayload value)? complete,
    TResult? Function(ErrorPayload value)? error,
    TResult? Function(WarningPayload value)? warning,
    TResult? Function(CodePayload value)? code,
    TResult? Function(MarkdownPayload value)? markdown,
    TResult? Function(ThinkingPayload value)? thinking,
    TResult? Function(ImagePayload value)? image,
    TResult? Function(InteractivePayload value)? interactive,
    TResult? Function(UserMessagePayload value)? userMessage,
    TResult? Function(TaskExecutionPayload value)? taskExecution,
    TResult? Function(HiddenPayload value)? hidden,
  }) {
    return thinking?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ProgressPayload value)? progress,
    TResult Function(CompletePayload value)? complete,
    TResult Function(ErrorPayload value)? error,
    TResult Function(WarningPayload value)? warning,
    TResult Function(CodePayload value)? code,
    TResult Function(MarkdownPayload value)? markdown,
    TResult Function(ThinkingPayload value)? thinking,
    TResult Function(ImagePayload value)? image,
    TResult Function(InteractivePayload value)? interactive,
    TResult Function(UserMessagePayload value)? userMessage,
    TResult Function(TaskExecutionPayload value)? taskExecution,
    TResult Function(HiddenPayload value)? hidden,
    required TResult orElse(),
  }) {
    if (thinking != null) {
      return thinking(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ThinkingPayloadImplToJson(this);
  }
}

abstract class ThinkingPayload extends Payload {
  const factory ThinkingPayload({
    required final String content,
    final StreamingStatus streamingStatus,
    final String? streamingId,
  }) = _$ThinkingPayloadImpl;
  const ThinkingPayload._() : super._();

  factory ThinkingPayload.fromJson(Map<String, dynamic> json) =
      _$ThinkingPayloadImpl.fromJson;

  String get content;
  StreamingStatus get streamingStatus;
  String? get streamingId;

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThinkingPayloadImplCopyWith<_$ThinkingPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ImagePayloadImplCopyWith<$Res> {
  factory _$$ImagePayloadImplCopyWith(
    _$ImagePayloadImpl value,
    $Res Function(_$ImagePayloadImpl) then,
  ) = __$$ImagePayloadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String title,
    String url,
    String? caption,
    int? width,
    int? height,
  });
}

/// @nodoc
class __$$ImagePayloadImplCopyWithImpl<$Res>
    extends _$PayloadCopyWithImpl<$Res, _$ImagePayloadImpl>
    implements _$$ImagePayloadImplCopyWith<$Res> {
  __$$ImagePayloadImplCopyWithImpl(
    _$ImagePayloadImpl _value,
    $Res Function(_$ImagePayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? url = null,
    Object? caption = freezed,
    Object? width = freezed,
    Object? height = freezed,
  }) {
    return _then(
      _$ImagePayloadImpl(
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        url:
            null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                    as String,
        caption:
            freezed == caption
                ? _value.caption
                : caption // ignore: cast_nullable_to_non_nullable
                    as String?,
        width:
            freezed == width
                ? _value.width
                : width // ignore: cast_nullable_to_non_nullable
                    as int?,
        height:
            freezed == height
                ? _value.height
                : height // ignore: cast_nullable_to_non_nullable
                    as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ImagePayloadImpl extends ImagePayload {
  const _$ImagePayloadImpl({
    required this.title,
    required this.url,
    this.caption,
    this.width,
    this.height,
    final String? $type,
  }) : $type = $type ?? 'image',
       super._();

  factory _$ImagePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImagePayloadImplFromJson(json);

  @override
  final String title;
  @override
  final String url;
  @override
  final String? caption;
  @override
  final int? width;
  @override
  final int? height;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Payload.image(title: $title, url: $url, caption: $caption, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImagePayloadImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.caption, caption) || other.caption == caption) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, title, url, caption, width, height);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImagePayloadImplCopyWith<_$ImagePayloadImpl> get copyWith =>
      __$$ImagePayloadImplCopyWithImpl<_$ImagePayloadImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )
    progress,
    required TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )
    complete,
    required TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )
    error,
    required TResult Function(String title, String message, String? action)
    warning,
    required TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )
    code,
    required TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    markdown,
    required TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    thinking,
    required TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )
    image,
    required TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )
    interactive,
    required TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )
    userMessage,
    required TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )
    taskExecution,
    required TResult Function(String reason, String? toolUseId) hidden,
  }) {
    return image(title, url, caption, width, height);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult? Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult? Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult? Function(String title, String message, String? action)? warning,
    TResult? Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult? Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult? Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult? Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult? Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult? Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult? Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult? Function(String reason, String? toolUseId)? hidden,
  }) {
    return image?.call(title, url, caption, width, height);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult Function(String title, String message, String? action)? warning,
    TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult Function(String reason, String? toolUseId)? hidden,
    required TResult orElse(),
  }) {
    if (image != null) {
      return image(title, url, caption, width, height);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ProgressPayload value) progress,
    required TResult Function(CompletePayload value) complete,
    required TResult Function(ErrorPayload value) error,
    required TResult Function(WarningPayload value) warning,
    required TResult Function(CodePayload value) code,
    required TResult Function(MarkdownPayload value) markdown,
    required TResult Function(ThinkingPayload value) thinking,
    required TResult Function(ImagePayload value) image,
    required TResult Function(InteractivePayload value) interactive,
    required TResult Function(UserMessagePayload value) userMessage,
    required TResult Function(TaskExecutionPayload value) taskExecution,
    required TResult Function(HiddenPayload value) hidden,
  }) {
    return image(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ProgressPayload value)? progress,
    TResult? Function(CompletePayload value)? complete,
    TResult? Function(ErrorPayload value)? error,
    TResult? Function(WarningPayload value)? warning,
    TResult? Function(CodePayload value)? code,
    TResult? Function(MarkdownPayload value)? markdown,
    TResult? Function(ThinkingPayload value)? thinking,
    TResult? Function(ImagePayload value)? image,
    TResult? Function(InteractivePayload value)? interactive,
    TResult? Function(UserMessagePayload value)? userMessage,
    TResult? Function(TaskExecutionPayload value)? taskExecution,
    TResult? Function(HiddenPayload value)? hidden,
  }) {
    return image?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ProgressPayload value)? progress,
    TResult Function(CompletePayload value)? complete,
    TResult Function(ErrorPayload value)? error,
    TResult Function(WarningPayload value)? warning,
    TResult Function(CodePayload value)? code,
    TResult Function(MarkdownPayload value)? markdown,
    TResult Function(ThinkingPayload value)? thinking,
    TResult Function(ImagePayload value)? image,
    TResult Function(InteractivePayload value)? interactive,
    TResult Function(UserMessagePayload value)? userMessage,
    TResult Function(TaskExecutionPayload value)? taskExecution,
    TResult Function(HiddenPayload value)? hidden,
    required TResult orElse(),
  }) {
    if (image != null) {
      return image(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ImagePayloadImplToJson(this);
  }
}

abstract class ImagePayload extends Payload {
  const factory ImagePayload({
    required final String title,
    required final String url,
    final String? caption,
    final int? width,
    final int? height,
  }) = _$ImagePayloadImpl;
  const ImagePayload._() : super._();

  factory ImagePayload.fromJson(Map<String, dynamic> json) =
      _$ImagePayloadImpl.fromJson;

  String get title;
  String get url;
  String? get caption;
  int? get width;
  int? get height;

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImagePayloadImplCopyWith<_$ImagePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$InteractivePayloadImplCopyWith<$Res> {
  factory _$$InteractivePayloadImplCopyWith(
    _$InteractivePayloadImpl value,
    $Res Function(_$InteractivePayloadImpl) then,
  ) = __$$InteractivePayloadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String title,
    String message,
    String requestId,
    InteractiveType interactiveType,
    PermissionStatus status,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class __$$InteractivePayloadImplCopyWithImpl<$Res>
    extends _$PayloadCopyWithImpl<$Res, _$InteractivePayloadImpl>
    implements _$$InteractivePayloadImplCopyWith<$Res> {
  __$$InteractivePayloadImplCopyWithImpl(
    _$InteractivePayloadImpl _value,
    $Res Function(_$InteractivePayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? message = null,
    Object? requestId = null,
    Object? interactiveType = null,
    Object? status = null,
    Object? metadata = freezed,
  }) {
    return _then(
      _$InteractivePayloadImpl(
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        message:
            null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                    as String,
        requestId:
            null == requestId
                ? _value.requestId
                : requestId // ignore: cast_nullable_to_non_nullable
                    as String,
        interactiveType:
            null == interactiveType
                ? _value.interactiveType
                : interactiveType // ignore: cast_nullable_to_non_nullable
                    as InteractiveType,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as PermissionStatus,
        metadata:
            freezed == metadata
                ? _value._metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                    as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InteractivePayloadImpl extends InteractivePayload {
  const _$InteractivePayloadImpl({
    required this.title,
    required this.message,
    required this.requestId,
    required this.interactiveType,
    this.status = PermissionStatus.pending,
    final Map<String, dynamic>? metadata,
    final String? $type,
  }) : _metadata = metadata,
       $type = $type ?? 'interactive',
       super._();

  factory _$InteractivePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$InteractivePayloadImplFromJson(json);

  @override
  final String title;
  @override
  final String message;
  @override
  final String requestId;
  @override
  final InteractiveType interactiveType;

  /// 权限状态 (pending/approved/denied/canceled)
  @override
  @JsonKey()
  final PermissionStatus status;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Payload.interactive(title: $title, message: $message, requestId: $requestId, interactiveType: $interactiveType, status: $status, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InteractivePayloadImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.interactiveType, interactiveType) ||
                other.interactiveType == interactiveType) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    title,
    message,
    requestId,
    interactiveType,
    status,
    const DeepCollectionEquality().hash(_metadata),
  );

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InteractivePayloadImplCopyWith<_$InteractivePayloadImpl> get copyWith =>
      __$$InteractivePayloadImplCopyWithImpl<_$InteractivePayloadImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )
    progress,
    required TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )
    complete,
    required TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )
    error,
    required TResult Function(String title, String message, String? action)
    warning,
    required TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )
    code,
    required TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    markdown,
    required TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    thinking,
    required TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )
    image,
    required TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )
    interactive,
    required TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )
    userMessage,
    required TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )
    taskExecution,
    required TResult Function(String reason, String? toolUseId) hidden,
  }) {
    return interactive(
      title,
      message,
      requestId,
      interactiveType,
      status,
      metadata,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult? Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult? Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult? Function(String title, String message, String? action)? warning,
    TResult? Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult? Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult? Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult? Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult? Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult? Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult? Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult? Function(String reason, String? toolUseId)? hidden,
  }) {
    return interactive?.call(
      title,
      message,
      requestId,
      interactiveType,
      status,
      metadata,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult Function(String title, String message, String? action)? warning,
    TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult Function(String reason, String? toolUseId)? hidden,
    required TResult orElse(),
  }) {
    if (interactive != null) {
      return interactive(
        title,
        message,
        requestId,
        interactiveType,
        status,
        metadata,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ProgressPayload value) progress,
    required TResult Function(CompletePayload value) complete,
    required TResult Function(ErrorPayload value) error,
    required TResult Function(WarningPayload value) warning,
    required TResult Function(CodePayload value) code,
    required TResult Function(MarkdownPayload value) markdown,
    required TResult Function(ThinkingPayload value) thinking,
    required TResult Function(ImagePayload value) image,
    required TResult Function(InteractivePayload value) interactive,
    required TResult Function(UserMessagePayload value) userMessage,
    required TResult Function(TaskExecutionPayload value) taskExecution,
    required TResult Function(HiddenPayload value) hidden,
  }) {
    return interactive(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ProgressPayload value)? progress,
    TResult? Function(CompletePayload value)? complete,
    TResult? Function(ErrorPayload value)? error,
    TResult? Function(WarningPayload value)? warning,
    TResult? Function(CodePayload value)? code,
    TResult? Function(MarkdownPayload value)? markdown,
    TResult? Function(ThinkingPayload value)? thinking,
    TResult? Function(ImagePayload value)? image,
    TResult? Function(InteractivePayload value)? interactive,
    TResult? Function(UserMessagePayload value)? userMessage,
    TResult? Function(TaskExecutionPayload value)? taskExecution,
    TResult? Function(HiddenPayload value)? hidden,
  }) {
    return interactive?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ProgressPayload value)? progress,
    TResult Function(CompletePayload value)? complete,
    TResult Function(ErrorPayload value)? error,
    TResult Function(WarningPayload value)? warning,
    TResult Function(CodePayload value)? code,
    TResult Function(MarkdownPayload value)? markdown,
    TResult Function(ThinkingPayload value)? thinking,
    TResult Function(ImagePayload value)? image,
    TResult Function(InteractivePayload value)? interactive,
    TResult Function(UserMessagePayload value)? userMessage,
    TResult Function(TaskExecutionPayload value)? taskExecution,
    TResult Function(HiddenPayload value)? hidden,
    required TResult orElse(),
  }) {
    if (interactive != null) {
      return interactive(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$InteractivePayloadImplToJson(this);
  }
}

abstract class InteractivePayload extends Payload {
  const factory InteractivePayload({
    required final String title,
    required final String message,
    required final String requestId,
    required final InteractiveType interactiveType,
    final PermissionStatus status,
    final Map<String, dynamic>? metadata,
  }) = _$InteractivePayloadImpl;
  const InteractivePayload._() : super._();

  factory InteractivePayload.fromJson(Map<String, dynamic> json) =
      _$InteractivePayloadImpl.fromJson;

  String get title;
  String get message;
  String get requestId;
  InteractiveType get interactiveType;

  /// 权限状态 (pending/approved/denied/canceled)
  PermissionStatus get status;
  Map<String, dynamic>? get metadata;

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InteractivePayloadImplCopyWith<_$InteractivePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UserMessagePayloadImplCopyWith<$Res> {
  factory _$$UserMessagePayloadImplCopyWith(
    _$UserMessagePayloadImpl value,
    $Res Function(_$UserMessagePayloadImpl) then,
  ) = __$$UserMessagePayloadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String content,
    bool isPending,
    bool isFailed,
    String? failureReason,
  });
}

/// @nodoc
class __$$UserMessagePayloadImplCopyWithImpl<$Res>
    extends _$PayloadCopyWithImpl<$Res, _$UserMessagePayloadImpl>
    implements _$$UserMessagePayloadImplCopyWith<$Res> {
  __$$UserMessagePayloadImplCopyWithImpl(
    _$UserMessagePayloadImpl _value,
    $Res Function(_$UserMessagePayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
    Object? isPending = null,
    Object? isFailed = null,
    Object? failureReason = freezed,
  }) {
    return _then(
      _$UserMessagePayloadImpl(
        content:
            null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                    as String,
        isPending:
            null == isPending
                ? _value.isPending
                : isPending // ignore: cast_nullable_to_non_nullable
                    as bool,
        isFailed:
            null == isFailed
                ? _value.isFailed
                : isFailed // ignore: cast_nullable_to_non_nullable
                    as bool,
        failureReason:
            freezed == failureReason
                ? _value.failureReason
                : failureReason // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserMessagePayloadImpl extends UserMessagePayload {
  const _$UserMessagePayloadImpl({
    required this.content,
    this.isPending = false,
    this.isFailed = false,
    this.failureReason,
    final String? $type,
  }) : $type = $type ?? 'userMessage',
       super._();

  factory _$UserMessagePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserMessagePayloadImplFromJson(json);

  @override
  final String content;
  @override
  @JsonKey()
  final bool isPending;
  @override
  @JsonKey()
  final bool isFailed;
  @override
  final String? failureReason;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Payload.userMessage(content: $content, isPending: $isPending, isFailed: $isFailed, failureReason: $failureReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserMessagePayloadImpl &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.isPending, isPending) ||
                other.isPending == isPending) &&
            (identical(other.isFailed, isFailed) ||
                other.isFailed == isFailed) &&
            (identical(other.failureReason, failureReason) ||
                other.failureReason == failureReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, content, isPending, isFailed, failureReason);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserMessagePayloadImplCopyWith<_$UserMessagePayloadImpl> get copyWith =>
      __$$UserMessagePayloadImplCopyWithImpl<_$UserMessagePayloadImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )
    progress,
    required TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )
    complete,
    required TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )
    error,
    required TResult Function(String title, String message, String? action)
    warning,
    required TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )
    code,
    required TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    markdown,
    required TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    thinking,
    required TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )
    image,
    required TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )
    interactive,
    required TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )
    userMessage,
    required TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )
    taskExecution,
    required TResult Function(String reason, String? toolUseId) hidden,
  }) {
    return userMessage(content, isPending, isFailed, failureReason);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult? Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult? Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult? Function(String title, String message, String? action)? warning,
    TResult? Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult? Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult? Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult? Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult? Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult? Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult? Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult? Function(String reason, String? toolUseId)? hidden,
  }) {
    return userMessage?.call(content, isPending, isFailed, failureReason);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult Function(String title, String message, String? action)? warning,
    TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult Function(String reason, String? toolUseId)? hidden,
    required TResult orElse(),
  }) {
    if (userMessage != null) {
      return userMessage(content, isPending, isFailed, failureReason);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ProgressPayload value) progress,
    required TResult Function(CompletePayload value) complete,
    required TResult Function(ErrorPayload value) error,
    required TResult Function(WarningPayload value) warning,
    required TResult Function(CodePayload value) code,
    required TResult Function(MarkdownPayload value) markdown,
    required TResult Function(ThinkingPayload value) thinking,
    required TResult Function(ImagePayload value) image,
    required TResult Function(InteractivePayload value) interactive,
    required TResult Function(UserMessagePayload value) userMessage,
    required TResult Function(TaskExecutionPayload value) taskExecution,
    required TResult Function(HiddenPayload value) hidden,
  }) {
    return userMessage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ProgressPayload value)? progress,
    TResult? Function(CompletePayload value)? complete,
    TResult? Function(ErrorPayload value)? error,
    TResult? Function(WarningPayload value)? warning,
    TResult? Function(CodePayload value)? code,
    TResult? Function(MarkdownPayload value)? markdown,
    TResult? Function(ThinkingPayload value)? thinking,
    TResult? Function(ImagePayload value)? image,
    TResult? Function(InteractivePayload value)? interactive,
    TResult? Function(UserMessagePayload value)? userMessage,
    TResult? Function(TaskExecutionPayload value)? taskExecution,
    TResult? Function(HiddenPayload value)? hidden,
  }) {
    return userMessage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ProgressPayload value)? progress,
    TResult Function(CompletePayload value)? complete,
    TResult Function(ErrorPayload value)? error,
    TResult Function(WarningPayload value)? warning,
    TResult Function(CodePayload value)? code,
    TResult Function(MarkdownPayload value)? markdown,
    TResult Function(ThinkingPayload value)? thinking,
    TResult Function(ImagePayload value)? image,
    TResult Function(InteractivePayload value)? interactive,
    TResult Function(UserMessagePayload value)? userMessage,
    TResult Function(TaskExecutionPayload value)? taskExecution,
    TResult Function(HiddenPayload value)? hidden,
    required TResult orElse(),
  }) {
    if (userMessage != null) {
      return userMessage(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$UserMessagePayloadImplToJson(this);
  }
}

abstract class UserMessagePayload extends Payload {
  const factory UserMessagePayload({
    required final String content,
    final bool isPending,
    final bool isFailed,
    final String? failureReason,
  }) = _$UserMessagePayloadImpl;
  const UserMessagePayload._() : super._();

  factory UserMessagePayload.fromJson(Map<String, dynamic> json) =
      _$UserMessagePayloadImpl.fromJson;

  String get content;
  bool get isPending;
  bool get isFailed;
  String? get failureReason;

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserMessagePayloadImplCopyWith<_$UserMessagePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TaskExecutionPayloadImplCopyWith<$Res> {
  factory _$$TaskExecutionPayloadImplCopyWith(
    _$TaskExecutionPayloadImpl value,
    $Res Function(_$TaskExecutionPayloadImpl) then,
  ) = __$$TaskExecutionPayloadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String title,
    List<TaskItem> tasks,
    TaskStatus overallStatus,
    String? summary,
    String? prompt,
    int? durationMs,
    bool isExpanded,
  });
}

/// @nodoc
class __$$TaskExecutionPayloadImplCopyWithImpl<$Res>
    extends _$PayloadCopyWithImpl<$Res, _$TaskExecutionPayloadImpl>
    implements _$$TaskExecutionPayloadImplCopyWith<$Res> {
  __$$TaskExecutionPayloadImplCopyWithImpl(
    _$TaskExecutionPayloadImpl _value,
    $Res Function(_$TaskExecutionPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? tasks = null,
    Object? overallStatus = null,
    Object? summary = freezed,
    Object? prompt = freezed,
    Object? durationMs = freezed,
    Object? isExpanded = null,
  }) {
    return _then(
      _$TaskExecutionPayloadImpl(
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        tasks:
            null == tasks
                ? _value._tasks
                : tasks // ignore: cast_nullable_to_non_nullable
                    as List<TaskItem>,
        overallStatus:
            null == overallStatus
                ? _value.overallStatus
                : overallStatus // ignore: cast_nullable_to_non_nullable
                    as TaskStatus,
        summary:
            freezed == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                    as String?,
        prompt:
            freezed == prompt
                ? _value.prompt
                : prompt // ignore: cast_nullable_to_non_nullable
                    as String?,
        durationMs:
            freezed == durationMs
                ? _value.durationMs
                : durationMs // ignore: cast_nullable_to_non_nullable
                    as int?,
        isExpanded:
            null == isExpanded
                ? _value.isExpanded
                : isExpanded // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskExecutionPayloadImpl extends TaskExecutionPayload {
  const _$TaskExecutionPayloadImpl({
    required this.title,
    required final List<TaskItem> tasks,
    required this.overallStatus,
    this.summary,
    this.prompt,
    this.durationMs,
    this.isExpanded = false,
    final String? $type,
  }) : _tasks = tasks,
       $type = $type ?? 'taskExecution',
       super._();

  factory _$TaskExecutionPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskExecutionPayloadImplFromJson(json);

  @override
  final String title;
  final List<TaskItem> _tasks;
  @override
  List<TaskItem> get tasks {
    if (_tasks is EqualUnmodifiableListView) return _tasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tasks);
  }

  @override
  final TaskStatus overallStatus;
  @override
  final String? summary;
  @override
  final String? prompt;
  @override
  final int? durationMs;
  @override
  @JsonKey()
  final bool isExpanded;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Payload.taskExecution(title: $title, tasks: $tasks, overallStatus: $overallStatus, summary: $summary, prompt: $prompt, durationMs: $durationMs, isExpanded: $isExpanded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskExecutionPayloadImpl &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._tasks, _tasks) &&
            (identical(other.overallStatus, overallStatus) ||
                other.overallStatus == overallStatus) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.prompt, prompt) || other.prompt == prompt) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.isExpanded, isExpanded) ||
                other.isExpanded == isExpanded));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    title,
    const DeepCollectionEquality().hash(_tasks),
    overallStatus,
    summary,
    prompt,
    durationMs,
    isExpanded,
  );

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskExecutionPayloadImplCopyWith<_$TaskExecutionPayloadImpl>
  get copyWith =>
      __$$TaskExecutionPayloadImplCopyWithImpl<_$TaskExecutionPayloadImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )
    progress,
    required TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )
    complete,
    required TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )
    error,
    required TResult Function(String title, String message, String? action)
    warning,
    required TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )
    code,
    required TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    markdown,
    required TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    thinking,
    required TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )
    image,
    required TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )
    interactive,
    required TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )
    userMessage,
    required TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )
    taskExecution,
    required TResult Function(String reason, String? toolUseId) hidden,
  }) {
    return taskExecution(
      title,
      tasks,
      overallStatus,
      summary,
      prompt,
      durationMs,
      isExpanded,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult? Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult? Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult? Function(String title, String message, String? action)? warning,
    TResult? Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult? Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult? Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult? Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult? Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult? Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult? Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult? Function(String reason, String? toolUseId)? hidden,
  }) {
    return taskExecution?.call(
      title,
      tasks,
      overallStatus,
      summary,
      prompt,
      durationMs,
      isExpanded,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult Function(String title, String message, String? action)? warning,
    TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult Function(String reason, String? toolUseId)? hidden,
    required TResult orElse(),
  }) {
    if (taskExecution != null) {
      return taskExecution(
        title,
        tasks,
        overallStatus,
        summary,
        prompt,
        durationMs,
        isExpanded,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ProgressPayload value) progress,
    required TResult Function(CompletePayload value) complete,
    required TResult Function(ErrorPayload value) error,
    required TResult Function(WarningPayload value) warning,
    required TResult Function(CodePayload value) code,
    required TResult Function(MarkdownPayload value) markdown,
    required TResult Function(ThinkingPayload value) thinking,
    required TResult Function(ImagePayload value) image,
    required TResult Function(InteractivePayload value) interactive,
    required TResult Function(UserMessagePayload value) userMessage,
    required TResult Function(TaskExecutionPayload value) taskExecution,
    required TResult Function(HiddenPayload value) hidden,
  }) {
    return taskExecution(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ProgressPayload value)? progress,
    TResult? Function(CompletePayload value)? complete,
    TResult? Function(ErrorPayload value)? error,
    TResult? Function(WarningPayload value)? warning,
    TResult? Function(CodePayload value)? code,
    TResult? Function(MarkdownPayload value)? markdown,
    TResult? Function(ThinkingPayload value)? thinking,
    TResult? Function(ImagePayload value)? image,
    TResult? Function(InteractivePayload value)? interactive,
    TResult? Function(UserMessagePayload value)? userMessage,
    TResult? Function(TaskExecutionPayload value)? taskExecution,
    TResult? Function(HiddenPayload value)? hidden,
  }) {
    return taskExecution?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ProgressPayload value)? progress,
    TResult Function(CompletePayload value)? complete,
    TResult Function(ErrorPayload value)? error,
    TResult Function(WarningPayload value)? warning,
    TResult Function(CodePayload value)? code,
    TResult Function(MarkdownPayload value)? markdown,
    TResult Function(ThinkingPayload value)? thinking,
    TResult Function(ImagePayload value)? image,
    TResult Function(InteractivePayload value)? interactive,
    TResult Function(UserMessagePayload value)? userMessage,
    TResult Function(TaskExecutionPayload value)? taskExecution,
    TResult Function(HiddenPayload value)? hidden,
    required TResult orElse(),
  }) {
    if (taskExecution != null) {
      return taskExecution(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskExecutionPayloadImplToJson(this);
  }
}

abstract class TaskExecutionPayload extends Payload {
  const factory TaskExecutionPayload({
    required final String title,
    required final List<TaskItem> tasks,
    required final TaskStatus overallStatus,
    final String? summary,
    final String? prompt,
    final int? durationMs,
    final bool isExpanded,
  }) = _$TaskExecutionPayloadImpl;
  const TaskExecutionPayload._() : super._();

  factory TaskExecutionPayload.fromJson(Map<String, dynamic> json) =
      _$TaskExecutionPayloadImpl.fromJson;

  String get title;
  List<TaskItem> get tasks;
  TaskStatus get overallStatus;
  String? get summary;
  String? get prompt;
  int? get durationMs;
  bool get isExpanded;

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskExecutionPayloadImplCopyWith<_$TaskExecutionPayloadImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$HiddenPayloadImplCopyWith<$Res> {
  factory _$$HiddenPayloadImplCopyWith(
    _$HiddenPayloadImpl value,
    $Res Function(_$HiddenPayloadImpl) then,
  ) = __$$HiddenPayloadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String reason, String? toolUseId});
}

/// @nodoc
class __$$HiddenPayloadImplCopyWithImpl<$Res>
    extends _$PayloadCopyWithImpl<$Res, _$HiddenPayloadImpl>
    implements _$$HiddenPayloadImplCopyWith<$Res> {
  __$$HiddenPayloadImplCopyWithImpl(
    _$HiddenPayloadImpl _value,
    $Res Function(_$HiddenPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? reason = null, Object? toolUseId = freezed}) {
    return _then(
      _$HiddenPayloadImpl(
        reason:
            null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                    as String,
        toolUseId:
            freezed == toolUseId
                ? _value.toolUseId
                : toolUseId // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HiddenPayloadImpl extends HiddenPayload {
  const _$HiddenPayloadImpl({
    required this.reason,
    this.toolUseId,
    final String? $type,
  }) : $type = $type ?? 'hidden',
       super._();

  factory _$HiddenPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$HiddenPayloadImplFromJson(json);

  @override
  final String reason;
  @override
  final String? toolUseId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Payload.hidden(reason: $reason, toolUseId: $toolUseId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HiddenPayloadImpl &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.toolUseId, toolUseId) ||
                other.toolUseId == toolUseId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, reason, toolUseId);

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HiddenPayloadImplCopyWith<_$HiddenPayloadImpl> get copyWith =>
      __$$HiddenPayloadImplCopyWithImpl<_$HiddenPayloadImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )
    progress,
    required TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )
    complete,
    required TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )
    error,
    required TResult Function(String title, String message, String? action)
    warning,
    required TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )
    code,
    required TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    markdown,
    required TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )
    thinking,
    required TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )
    image,
    required TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )
    interactive,
    required TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )
    userMessage,
    required TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )
    taskExecution,
    required TResult Function(String reason, String? toolUseId) hidden,
  }) {
    return hidden(reason, toolUseId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult? Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult? Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult? Function(String title, String message, String? action)? warning,
    TResult? Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult? Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult? Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult? Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult? Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult? Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult? Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult? Function(String reason, String? toolUseId)? hidden,
  }) {
    return hidden?.call(reason, toolUseId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String title,
      String? description,
      int current,
      int total,
      String? currentStep,
    )?
    progress,
    TResult Function(
      String title,
      String? summary,
      int? duration,
      int? toolCount,
    )?
    complete,
    TResult Function(
      String title,
      String message,
      String? stackTrace,
      String? suggestion,
    )?
    error,
    TResult Function(String title, String message, String? action)? warning,
    TResult Function(
      String title,
      String code,
      String? language,
      String? filename,
      int? startLine,
      List<CodeChange>? changes,
      StreamingStatus streamingStatus,
    )?
    code,
    TResult Function(
      String title,
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    markdown,
    TResult Function(
      String content,
      StreamingStatus streamingStatus,
      String? streamingId,
    )?
    thinking,
    TResult Function(
      String title,
      String url,
      String? caption,
      int? width,
      int? height,
    )?
    image,
    TResult Function(
      String title,
      String message,
      String requestId,
      InteractiveType interactiveType,
      PermissionStatus status,
      Map<String, dynamic>? metadata,
    )?
    interactive,
    TResult Function(
      String content,
      bool isPending,
      bool isFailed,
      String? failureReason,
    )?
    userMessage,
    TResult Function(
      String title,
      List<TaskItem> tasks,
      TaskStatus overallStatus,
      String? summary,
      String? prompt,
      int? durationMs,
      bool isExpanded,
    )?
    taskExecution,
    TResult Function(String reason, String? toolUseId)? hidden,
    required TResult orElse(),
  }) {
    if (hidden != null) {
      return hidden(reason, toolUseId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ProgressPayload value) progress,
    required TResult Function(CompletePayload value) complete,
    required TResult Function(ErrorPayload value) error,
    required TResult Function(WarningPayload value) warning,
    required TResult Function(CodePayload value) code,
    required TResult Function(MarkdownPayload value) markdown,
    required TResult Function(ThinkingPayload value) thinking,
    required TResult Function(ImagePayload value) image,
    required TResult Function(InteractivePayload value) interactive,
    required TResult Function(UserMessagePayload value) userMessage,
    required TResult Function(TaskExecutionPayload value) taskExecution,
    required TResult Function(HiddenPayload value) hidden,
  }) {
    return hidden(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ProgressPayload value)? progress,
    TResult? Function(CompletePayload value)? complete,
    TResult? Function(ErrorPayload value)? error,
    TResult? Function(WarningPayload value)? warning,
    TResult? Function(CodePayload value)? code,
    TResult? Function(MarkdownPayload value)? markdown,
    TResult? Function(ThinkingPayload value)? thinking,
    TResult? Function(ImagePayload value)? image,
    TResult? Function(InteractivePayload value)? interactive,
    TResult? Function(UserMessagePayload value)? userMessage,
    TResult? Function(TaskExecutionPayload value)? taskExecution,
    TResult? Function(HiddenPayload value)? hidden,
  }) {
    return hidden?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ProgressPayload value)? progress,
    TResult Function(CompletePayload value)? complete,
    TResult Function(ErrorPayload value)? error,
    TResult Function(WarningPayload value)? warning,
    TResult Function(CodePayload value)? code,
    TResult Function(MarkdownPayload value)? markdown,
    TResult Function(ThinkingPayload value)? thinking,
    TResult Function(ImagePayload value)? image,
    TResult Function(InteractivePayload value)? interactive,
    TResult Function(UserMessagePayload value)? userMessage,
    TResult Function(TaskExecutionPayload value)? taskExecution,
    TResult Function(HiddenPayload value)? hidden,
    required TResult orElse(),
  }) {
    if (hidden != null) {
      return hidden(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$HiddenPayloadImplToJson(this);
  }
}

abstract class HiddenPayload extends Payload {
  const factory HiddenPayload({
    required final String reason,
    final String? toolUseId,
  }) = _$HiddenPayloadImpl;
  const HiddenPayload._() : super._();

  factory HiddenPayload.fromJson(Map<String, dynamic> json) =
      _$HiddenPayloadImpl.fromJson;

  String get reason;
  String? get toolUseId;

  /// Create a copy of Payload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HiddenPayloadImplCopyWith<_$HiddenPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CodeChange _$CodeChangeFromJson(Map<String, dynamic> json) {
  return _CodeChange.fromJson(json);
}

/// @nodoc
mixin _$CodeChange {
  int get line => throw _privateConstructorUsedError;
  ChangeType get changeType => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;

  /// Serializes this CodeChange to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CodeChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CodeChangeCopyWith<CodeChange> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CodeChangeCopyWith<$Res> {
  factory $CodeChangeCopyWith(
    CodeChange value,
    $Res Function(CodeChange) then,
  ) = _$CodeChangeCopyWithImpl<$Res, CodeChange>;
  @useResult
  $Res call({int line, ChangeType changeType, String content});
}

/// @nodoc
class _$CodeChangeCopyWithImpl<$Res, $Val extends CodeChange>
    implements $CodeChangeCopyWith<$Res> {
  _$CodeChangeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CodeChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? line = null,
    Object? changeType = null,
    Object? content = null,
  }) {
    return _then(
      _value.copyWith(
            line:
                null == line
                    ? _value.line
                    : line // ignore: cast_nullable_to_non_nullable
                        as int,
            changeType:
                null == changeType
                    ? _value.changeType
                    : changeType // ignore: cast_nullable_to_non_nullable
                        as ChangeType,
            content:
                null == content
                    ? _value.content
                    : content // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CodeChangeImplCopyWith<$Res>
    implements $CodeChangeCopyWith<$Res> {
  factory _$$CodeChangeImplCopyWith(
    _$CodeChangeImpl value,
    $Res Function(_$CodeChangeImpl) then,
  ) = __$$CodeChangeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int line, ChangeType changeType, String content});
}

/// @nodoc
class __$$CodeChangeImplCopyWithImpl<$Res>
    extends _$CodeChangeCopyWithImpl<$Res, _$CodeChangeImpl>
    implements _$$CodeChangeImplCopyWith<$Res> {
  __$$CodeChangeImplCopyWithImpl(
    _$CodeChangeImpl _value,
    $Res Function(_$CodeChangeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CodeChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? line = null,
    Object? changeType = null,
    Object? content = null,
  }) {
    return _then(
      _$CodeChangeImpl(
        line:
            null == line
                ? _value.line
                : line // ignore: cast_nullable_to_non_nullable
                    as int,
        changeType:
            null == changeType
                ? _value.changeType
                : changeType // ignore: cast_nullable_to_non_nullable
                    as ChangeType,
        content:
            null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CodeChangeImpl implements _CodeChange {
  const _$CodeChangeImpl({
    required this.line,
    required this.changeType,
    required this.content,
  });

  factory _$CodeChangeImpl.fromJson(Map<String, dynamic> json) =>
      _$$CodeChangeImplFromJson(json);

  @override
  final int line;
  @override
  final ChangeType changeType;
  @override
  final String content;

  @override
  String toString() {
    return 'CodeChange(line: $line, changeType: $changeType, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CodeChangeImpl &&
            (identical(other.line, line) || other.line == line) &&
            (identical(other.changeType, changeType) ||
                other.changeType == changeType) &&
            (identical(other.content, content) || other.content == content));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, line, changeType, content);

  /// Create a copy of CodeChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CodeChangeImplCopyWith<_$CodeChangeImpl> get copyWith =>
      __$$CodeChangeImplCopyWithImpl<_$CodeChangeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CodeChangeImplToJson(this);
  }
}

abstract class _CodeChange implements CodeChange {
  const factory _CodeChange({
    required final int line,
    required final ChangeType changeType,
    required final String content,
  }) = _$CodeChangeImpl;

  factory _CodeChange.fromJson(Map<String, dynamic> json) =
      _$CodeChangeImpl.fromJson;

  @override
  int get line;
  @override
  ChangeType get changeType;
  @override
  String get content;

  /// Create a copy of CodeChange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CodeChangeImplCopyWith<_$CodeChangeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
