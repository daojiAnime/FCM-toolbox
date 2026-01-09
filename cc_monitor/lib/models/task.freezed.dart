// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TaskItem _$TaskItemFromJson(Map<String, dynamic> json) {
  return _TaskItem.fromJson(json);
}

/// @nodoc
mixin _$TaskItem {
  /// 任务 ID
  String get id => throw _privateConstructorUsedError;

  /// 任务名称 (文件路径或命令)
  String get name => throw _privateConstructorUsedError;

  /// 任务状态
  TaskItemStatus get status => throw _privateConstructorUsedError;

  /// 详细描述
  String? get description => throw _privateConstructorUsedError;

  /// 文件路径 (如果是文件操作)
  String? get filePath => throw _privateConstructorUsedError;

  /// 执行耗时
  int? get durationMs => throw _privateConstructorUsedError;

  /// 工具名称
  String? get toolName => throw _privateConstructorUsedError;

  /// 完整的输入参数 (Map) - 用于专用视图渲染
  Map<String, dynamic>? get input => throw _privateConstructorUsedError;

  /// 输入参数摘要 (用于快速展示)
  String? get inputSummary => throw _privateConstructorUsedError;

  /// 输出结果摘要
  String? get outputSummary => throw _privateConstructorUsedError;

  /// 是否有错误
  bool get hasError => throw _privateConstructorUsedError;

  /// 错误信息
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Serializes this TaskItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskItemCopyWith<TaskItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskItemCopyWith<$Res> {
  factory $TaskItemCopyWith(TaskItem value, $Res Function(TaskItem) then) =
      _$TaskItemCopyWithImpl<$Res, TaskItem>;
  @useResult
  $Res call({
    String id,
    String name,
    TaskItemStatus status,
    String? description,
    String? filePath,
    int? durationMs,
    String? toolName,
    Map<String, dynamic>? input,
    String? inputSummary,
    String? outputSummary,
    bool hasError,
    String? errorMessage,
  });
}

/// @nodoc
class _$TaskItemCopyWithImpl<$Res, $Val extends TaskItem>
    implements $TaskItemCopyWith<$Res> {
  _$TaskItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? status = null,
    Object? description = freezed,
    Object? filePath = freezed,
    Object? durationMs = freezed,
    Object? toolName = freezed,
    Object? input = freezed,
    Object? inputSummary = freezed,
    Object? outputSummary = freezed,
    Object? hasError = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as TaskItemStatus,
            description:
                freezed == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String?,
            filePath:
                freezed == filePath
                    ? _value.filePath
                    : filePath // ignore: cast_nullable_to_non_nullable
                        as String?,
            durationMs:
                freezed == durationMs
                    ? _value.durationMs
                    : durationMs // ignore: cast_nullable_to_non_nullable
                        as int?,
            toolName:
                freezed == toolName
                    ? _value.toolName
                    : toolName // ignore: cast_nullable_to_non_nullable
                        as String?,
            input:
                freezed == input
                    ? _value.input
                    : input // ignore: cast_nullable_to_non_nullable
                        as Map<String, dynamic>?,
            inputSummary:
                freezed == inputSummary
                    ? _value.inputSummary
                    : inputSummary // ignore: cast_nullable_to_non_nullable
                        as String?,
            outputSummary:
                freezed == outputSummary
                    ? _value.outputSummary
                    : outputSummary // ignore: cast_nullable_to_non_nullable
                        as String?,
            hasError:
                null == hasError
                    ? _value.hasError
                    : hasError // ignore: cast_nullable_to_non_nullable
                        as bool,
            errorMessage:
                freezed == errorMessage
                    ? _value.errorMessage
                    : errorMessage // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaskItemImplCopyWith<$Res>
    implements $TaskItemCopyWith<$Res> {
  factory _$$TaskItemImplCopyWith(
    _$TaskItemImpl value,
    $Res Function(_$TaskItemImpl) then,
  ) = __$$TaskItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    TaskItemStatus status,
    String? description,
    String? filePath,
    int? durationMs,
    String? toolName,
    Map<String, dynamic>? input,
    String? inputSummary,
    String? outputSummary,
    bool hasError,
    String? errorMessage,
  });
}

/// @nodoc
class __$$TaskItemImplCopyWithImpl<$Res>
    extends _$TaskItemCopyWithImpl<$Res, _$TaskItemImpl>
    implements _$$TaskItemImplCopyWith<$Res> {
  __$$TaskItemImplCopyWithImpl(
    _$TaskItemImpl _value,
    $Res Function(_$TaskItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TaskItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? status = null,
    Object? description = freezed,
    Object? filePath = freezed,
    Object? durationMs = freezed,
    Object? toolName = freezed,
    Object? input = freezed,
    Object? inputSummary = freezed,
    Object? outputSummary = freezed,
    Object? hasError = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$TaskItemImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as TaskItemStatus,
        description:
            freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String?,
        filePath:
            freezed == filePath
                ? _value.filePath
                : filePath // ignore: cast_nullable_to_non_nullable
                    as String?,
        durationMs:
            freezed == durationMs
                ? _value.durationMs
                : durationMs // ignore: cast_nullable_to_non_nullable
                    as int?,
        toolName:
            freezed == toolName
                ? _value.toolName
                : toolName // ignore: cast_nullable_to_non_nullable
                    as String?,
        input:
            freezed == input
                ? _value._input
                : input // ignore: cast_nullable_to_non_nullable
                    as Map<String, dynamic>?,
        inputSummary:
            freezed == inputSummary
                ? _value.inputSummary
                : inputSummary // ignore: cast_nullable_to_non_nullable
                    as String?,
        outputSummary:
            freezed == outputSummary
                ? _value.outputSummary
                : outputSummary // ignore: cast_nullable_to_non_nullable
                    as String?,
        hasError:
            null == hasError
                ? _value.hasError
                : hasError // ignore: cast_nullable_to_non_nullable
                    as bool,
        errorMessage:
            freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskItemImpl extends _TaskItem {
  const _$TaskItemImpl({
    required this.id,
    required this.name,
    required this.status,
    this.description,
    this.filePath,
    this.durationMs,
    this.toolName,
    final Map<String, dynamic>? input,
    this.inputSummary,
    this.outputSummary,
    this.hasError = false,
    this.errorMessage,
  }) : _input = input,
       super._();

  factory _$TaskItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskItemImplFromJson(json);

  /// 任务 ID
  @override
  final String id;

  /// 任务名称 (文件路径或命令)
  @override
  final String name;

  /// 任务状态
  @override
  final TaskItemStatus status;

  /// 详细描述
  @override
  final String? description;

  /// 文件路径 (如果是文件操作)
  @override
  final String? filePath;

  /// 执行耗时
  @override
  final int? durationMs;

  /// 工具名称
  @override
  final String? toolName;

  /// 完整的输入参数 (Map) - 用于专用视图渲染
  final Map<String, dynamic>? _input;

  /// 完整的输入参数 (Map) - 用于专用视图渲染
  @override
  Map<String, dynamic>? get input {
    final value = _input;
    if (value == null) return null;
    if (_input is EqualUnmodifiableMapView) return _input;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// 输入参数摘要 (用于快速展示)
  @override
  final String? inputSummary;

  /// 输出结果摘要
  @override
  final String? outputSummary;

  /// 是否有错误
  @override
  @JsonKey()
  final bool hasError;

  /// 错误信息
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'TaskItem(id: $id, name: $name, status: $status, description: $description, filePath: $filePath, durationMs: $durationMs, toolName: $toolName, input: $input, inputSummary: $inputSummary, outputSummary: $outputSummary, hasError: $hasError, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.toolName, toolName) ||
                other.toolName == toolName) &&
            const DeepCollectionEquality().equals(other._input, _input) &&
            (identical(other.inputSummary, inputSummary) ||
                other.inputSummary == inputSummary) &&
            (identical(other.outputSummary, outputSummary) ||
                other.outputSummary == outputSummary) &&
            (identical(other.hasError, hasError) ||
                other.hasError == hasError) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    status,
    description,
    filePath,
    durationMs,
    toolName,
    const DeepCollectionEquality().hash(_input),
    inputSummary,
    outputSummary,
    hasError,
    errorMessage,
  );

  /// Create a copy of TaskItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskItemImplCopyWith<_$TaskItemImpl> get copyWith =>
      __$$TaskItemImplCopyWithImpl<_$TaskItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskItemImplToJson(this);
  }
}

abstract class _TaskItem extends TaskItem {
  const factory _TaskItem({
    required final String id,
    required final String name,
    required final TaskItemStatus status,
    final String? description,
    final String? filePath,
    final int? durationMs,
    final String? toolName,
    final Map<String, dynamic>? input,
    final String? inputSummary,
    final String? outputSummary,
    final bool hasError,
    final String? errorMessage,
  }) = _$TaskItemImpl;
  const _TaskItem._() : super._();

  factory _TaskItem.fromJson(Map<String, dynamic> json) =
      _$TaskItemImpl.fromJson;

  /// 任务 ID
  @override
  String get id;

  /// 任务名称 (文件路径或命令)
  @override
  String get name;

  /// 任务状态
  @override
  TaskItemStatus get status;

  /// 详细描述
  @override
  String? get description;

  /// 文件路径 (如果是文件操作)
  @override
  String? get filePath;

  /// 执行耗时
  @override
  int? get durationMs;

  /// 工具名称
  @override
  String? get toolName;

  /// 完整的输入参数 (Map) - 用于专用视图渲染
  @override
  Map<String, dynamic>? get input;

  /// 输入参数摘要 (用于快速展示)
  @override
  String? get inputSummary;

  /// 输出结果摘要
  @override
  String? get outputSummary;

  /// 是否有错误
  @override
  bool get hasError;

  /// 错误信息
  @override
  String? get errorMessage;

  /// Create a copy of TaskItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskItemImplCopyWith<_$TaskItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
