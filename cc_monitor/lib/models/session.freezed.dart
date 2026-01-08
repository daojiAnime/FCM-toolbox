// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SessionProgress _$SessionProgressFromJson(Map<String, dynamic> json) {
  return _SessionProgress.fromJson(json);
}

/// @nodoc
mixin _$SessionProgress {
  int get current => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  String? get currentStep => throw _privateConstructorUsedError;

  /// Serializes this SessionProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SessionProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionProgressCopyWith<SessionProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionProgressCopyWith<$Res> {
  factory $SessionProgressCopyWith(
    SessionProgress value,
    $Res Function(SessionProgress) then,
  ) = _$SessionProgressCopyWithImpl<$Res, SessionProgress>;
  @useResult
  $Res call({int current, int total, String? currentStep});
}

/// @nodoc
class _$SessionProgressCopyWithImpl<$Res, $Val extends SessionProgress>
    implements $SessionProgressCopyWith<$Res> {
  _$SessionProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? current = null,
    Object? total = null,
    Object? currentStep = freezed,
  }) {
    return _then(
      _value.copyWith(
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SessionProgressImplCopyWith<$Res>
    implements $SessionProgressCopyWith<$Res> {
  factory _$$SessionProgressImplCopyWith(
    _$SessionProgressImpl value,
    $Res Function(_$SessionProgressImpl) then,
  ) = __$$SessionProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int current, int total, String? currentStep});
}

/// @nodoc
class __$$SessionProgressImplCopyWithImpl<$Res>
    extends _$SessionProgressCopyWithImpl<$Res, _$SessionProgressImpl>
    implements _$$SessionProgressImplCopyWith<$Res> {
  __$$SessionProgressImplCopyWithImpl(
    _$SessionProgressImpl _value,
    $Res Function(_$SessionProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SessionProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? current = null,
    Object? total = null,
    Object? currentStep = freezed,
  }) {
    return _then(
      _$SessionProgressImpl(
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
class _$SessionProgressImpl implements _SessionProgress {
  const _$SessionProgressImpl({
    this.current = 0,
    this.total = 0,
    this.currentStep,
  });

  factory _$SessionProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionProgressImplFromJson(json);

  @override
  @JsonKey()
  final int current;
  @override
  @JsonKey()
  final int total;
  @override
  final String? currentStep;

  @override
  String toString() {
    return 'SessionProgress(current: $current, total: $total, currentStep: $currentStep)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionProgressImpl &&
            (identical(other.current, current) || other.current == current) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, current, total, currentStep);

  /// Create a copy of SessionProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionProgressImplCopyWith<_$SessionProgressImpl> get copyWith =>
      __$$SessionProgressImplCopyWithImpl<_$SessionProgressImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionProgressImplToJson(this);
  }
}

abstract class _SessionProgress implements SessionProgress {
  const factory _SessionProgress({
    final int current,
    final int total,
    final String? currentStep,
  }) = _$SessionProgressImpl;

  factory _SessionProgress.fromJson(Map<String, dynamic> json) =
      _$SessionProgressImpl.fromJson;

  @override
  int get current;
  @override
  int get total;
  @override
  String? get currentStep;

  /// Create a copy of SessionProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionProgressImplCopyWith<_$SessionProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TodoItem _$TodoItemFromJson(Map<String, dynamic> json) {
  return _TodoItem.fromJson(json);
}

/// @nodoc
mixin _$TodoItem {
  String get content => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get activeForm => throw _privateConstructorUsedError;

  /// Serializes this TodoItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TodoItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TodoItemCopyWith<TodoItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TodoItemCopyWith<$Res> {
  factory $TodoItemCopyWith(TodoItem value, $Res Function(TodoItem) then) =
      _$TodoItemCopyWithImpl<$Res, TodoItem>;
  @useResult
  $Res call({String content, String status, String? activeForm});
}

/// @nodoc
class _$TodoItemCopyWithImpl<$Res, $Val extends TodoItem>
    implements $TodoItemCopyWith<$Res> {
  _$TodoItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TodoItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
    Object? status = null,
    Object? activeForm = freezed,
  }) {
    return _then(
      _value.copyWith(
            content:
                null == content
                    ? _value.content
                    : content // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            activeForm:
                freezed == activeForm
                    ? _value.activeForm
                    : activeForm // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TodoItemImplCopyWith<$Res>
    implements $TodoItemCopyWith<$Res> {
  factory _$$TodoItemImplCopyWith(
    _$TodoItemImpl value,
    $Res Function(_$TodoItemImpl) then,
  ) = __$$TodoItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String content, String status, String? activeForm});
}

/// @nodoc
class __$$TodoItemImplCopyWithImpl<$Res>
    extends _$TodoItemCopyWithImpl<$Res, _$TodoItemImpl>
    implements _$$TodoItemImplCopyWith<$Res> {
  __$$TodoItemImplCopyWithImpl(
    _$TodoItemImpl _value,
    $Res Function(_$TodoItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TodoItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
    Object? status = null,
    Object? activeForm = freezed,
  }) {
    return _then(
      _$TodoItemImpl(
        content:
            null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        activeForm:
            freezed == activeForm
                ? _value.activeForm
                : activeForm // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TodoItemImpl implements _TodoItem {
  const _$TodoItemImpl({
    required this.content,
    required this.status,
    this.activeForm,
  });

  factory _$TodoItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$TodoItemImplFromJson(json);

  @override
  final String content;
  @override
  final String status;
  @override
  final String? activeForm;

  @override
  String toString() {
    return 'TodoItem(content: $content, status: $status, activeForm: $activeForm)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TodoItemImpl &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.activeForm, activeForm) ||
                other.activeForm == activeForm));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, content, status, activeForm);

  /// Create a copy of TodoItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TodoItemImplCopyWith<_$TodoItemImpl> get copyWith =>
      __$$TodoItemImplCopyWithImpl<_$TodoItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TodoItemImplToJson(this);
  }
}

abstract class _TodoItem implements TodoItem {
  const factory _TodoItem({
    required final String content,
    required final String status,
    final String? activeForm,
  }) = _$TodoItemImpl;

  factory _TodoItem.fromJson(Map<String, dynamic> json) =
      _$TodoItemImpl.fromJson;

  @override
  String get content;
  @override
  String get status;
  @override
  String? get activeForm;

  /// Create a copy of TodoItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TodoItemImplCopyWith<_$TodoItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Session _$SessionFromJson(Map<String, dynamic> json) {
  return _Session.fromJson(json);
}

/// @nodoc
mixin _$Session {
  /// 会话 ID
  String get id => throw _privateConstructorUsedError;

  /// 项目名称
  String get projectName => throw _privateConstructorUsedError;

  /// 项目路径
  String? get projectPath => throw _privateConstructorUsedError;

  /// 会话状态
  SessionStatus get status => throw _privateConstructorUsedError;

  /// 进度信息
  SessionProgress? get progress => throw _privateConstructorUsedError;

  /// Todo 列表
  List<TodoItem> get todos => throw _privateConstructorUsedError;

  /// 当前任务描述
  String? get currentTask => throw _privateConstructorUsedError;

  /// 开始时间
  DateTime get startedAt => throw _privateConstructorUsedError;

  /// 最后更新时间
  DateTime get lastUpdatedAt => throw _privateConstructorUsedError;

  /// 结束时间
  DateTime? get endedAt => throw _privateConstructorUsedError;

  /// 总工具调用次数
  int get toolCallCount => throw _privateConstructorUsedError;

  /// Serializes this Session to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Session
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionCopyWith<Session> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionCopyWith<$Res> {
  factory $SessionCopyWith(Session value, $Res Function(Session) then) =
      _$SessionCopyWithImpl<$Res, Session>;
  @useResult
  $Res call({
    String id,
    String projectName,
    String? projectPath,
    SessionStatus status,
    SessionProgress? progress,
    List<TodoItem> todos,
    String? currentTask,
    DateTime startedAt,
    DateTime lastUpdatedAt,
    DateTime? endedAt,
    int toolCallCount,
  });

  $SessionProgressCopyWith<$Res>? get progress;
}

/// @nodoc
class _$SessionCopyWithImpl<$Res, $Val extends Session>
    implements $SessionCopyWith<$Res> {
  _$SessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Session
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectName = null,
    Object? projectPath = freezed,
    Object? status = null,
    Object? progress = freezed,
    Object? todos = null,
    Object? currentTask = freezed,
    Object? startedAt = null,
    Object? lastUpdatedAt = null,
    Object? endedAt = freezed,
    Object? toolCallCount = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            projectName:
                null == projectName
                    ? _value.projectName
                    : projectName // ignore: cast_nullable_to_non_nullable
                        as String,
            projectPath:
                freezed == projectPath
                    ? _value.projectPath
                    : projectPath // ignore: cast_nullable_to_non_nullable
                        as String?,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as SessionStatus,
            progress:
                freezed == progress
                    ? _value.progress
                    : progress // ignore: cast_nullable_to_non_nullable
                        as SessionProgress?,
            todos:
                null == todos
                    ? _value.todos
                    : todos // ignore: cast_nullable_to_non_nullable
                        as List<TodoItem>,
            currentTask:
                freezed == currentTask
                    ? _value.currentTask
                    : currentTask // ignore: cast_nullable_to_non_nullable
                        as String?,
            startedAt:
                null == startedAt
                    ? _value.startedAt
                    : startedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            lastUpdatedAt:
                null == lastUpdatedAt
                    ? _value.lastUpdatedAt
                    : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            endedAt:
                freezed == endedAt
                    ? _value.endedAt
                    : endedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            toolCallCount:
                null == toolCallCount
                    ? _value.toolCallCount
                    : toolCallCount // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }

  /// Create a copy of Session
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SessionProgressCopyWith<$Res>? get progress {
    if (_value.progress == null) {
      return null;
    }

    return $SessionProgressCopyWith<$Res>(_value.progress!, (value) {
      return _then(_value.copyWith(progress: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SessionImplCopyWith<$Res> implements $SessionCopyWith<$Res> {
  factory _$$SessionImplCopyWith(
    _$SessionImpl value,
    $Res Function(_$SessionImpl) then,
  ) = __$$SessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String projectName,
    String? projectPath,
    SessionStatus status,
    SessionProgress? progress,
    List<TodoItem> todos,
    String? currentTask,
    DateTime startedAt,
    DateTime lastUpdatedAt,
    DateTime? endedAt,
    int toolCallCount,
  });

  @override
  $SessionProgressCopyWith<$Res>? get progress;
}

/// @nodoc
class __$$SessionImplCopyWithImpl<$Res>
    extends _$SessionCopyWithImpl<$Res, _$SessionImpl>
    implements _$$SessionImplCopyWith<$Res> {
  __$$SessionImplCopyWithImpl(
    _$SessionImpl _value,
    $Res Function(_$SessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Session
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectName = null,
    Object? projectPath = freezed,
    Object? status = null,
    Object? progress = freezed,
    Object? todos = null,
    Object? currentTask = freezed,
    Object? startedAt = null,
    Object? lastUpdatedAt = null,
    Object? endedAt = freezed,
    Object? toolCallCount = null,
  }) {
    return _then(
      _$SessionImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        projectName:
            null == projectName
                ? _value.projectName
                : projectName // ignore: cast_nullable_to_non_nullable
                    as String,
        projectPath:
            freezed == projectPath
                ? _value.projectPath
                : projectPath // ignore: cast_nullable_to_non_nullable
                    as String?,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as SessionStatus,
        progress:
            freezed == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                    as SessionProgress?,
        todos:
            null == todos
                ? _value._todos
                : todos // ignore: cast_nullable_to_non_nullable
                    as List<TodoItem>,
        currentTask:
            freezed == currentTask
                ? _value.currentTask
                : currentTask // ignore: cast_nullable_to_non_nullable
                    as String?,
        startedAt:
            null == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        lastUpdatedAt:
            null == lastUpdatedAt
                ? _value.lastUpdatedAt
                : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        endedAt:
            freezed == endedAt
                ? _value.endedAt
                : endedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        toolCallCount:
            null == toolCallCount
                ? _value.toolCallCount
                : toolCallCount // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionImpl extends _Session {
  const _$SessionImpl({
    required this.id,
    required this.projectName,
    this.projectPath,
    this.status = SessionStatus.running,
    this.progress,
    final List<TodoItem> todos = const [],
    this.currentTask,
    required this.startedAt,
    required this.lastUpdatedAt,
    this.endedAt,
    this.toolCallCount = 0,
  }) : _todos = todos,
       super._();

  factory _$SessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionImplFromJson(json);

  /// 会话 ID
  @override
  final String id;

  /// 项目名称
  @override
  final String projectName;

  /// 项目路径
  @override
  final String? projectPath;

  /// 会话状态
  @override
  @JsonKey()
  final SessionStatus status;

  /// 进度信息
  @override
  final SessionProgress? progress;

  /// Todo 列表
  final List<TodoItem> _todos;

  /// Todo 列表
  @override
  @JsonKey()
  List<TodoItem> get todos {
    if (_todos is EqualUnmodifiableListView) return _todos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_todos);
  }

  /// 当前任务描述
  @override
  final String? currentTask;

  /// 开始时间
  @override
  final DateTime startedAt;

  /// 最后更新时间
  @override
  final DateTime lastUpdatedAt;

  /// 结束时间
  @override
  final DateTime? endedAt;

  /// 总工具调用次数
  @override
  @JsonKey()
  final int toolCallCount;

  @override
  String toString() {
    return 'Session(id: $id, projectName: $projectName, projectPath: $projectPath, status: $status, progress: $progress, todos: $todos, currentTask: $currentTask, startedAt: $startedAt, lastUpdatedAt: $lastUpdatedAt, endedAt: $endedAt, toolCallCount: $toolCallCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectName, projectName) ||
                other.projectName == projectName) &&
            (identical(other.projectPath, projectPath) ||
                other.projectPath == projectPath) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            const DeepCollectionEquality().equals(other._todos, _todos) &&
            (identical(other.currentTask, currentTask) ||
                other.currentTask == currentTask) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.lastUpdatedAt, lastUpdatedAt) ||
                other.lastUpdatedAt == lastUpdatedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.toolCallCount, toolCallCount) ||
                other.toolCallCount == toolCallCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    projectName,
    projectPath,
    status,
    progress,
    const DeepCollectionEquality().hash(_todos),
    currentTask,
    startedAt,
    lastUpdatedAt,
    endedAt,
    toolCallCount,
  );

  /// Create a copy of Session
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionImplCopyWith<_$SessionImpl> get copyWith =>
      __$$SessionImplCopyWithImpl<_$SessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionImplToJson(this);
  }
}

abstract class _Session extends Session {
  const factory _Session({
    required final String id,
    required final String projectName,
    final String? projectPath,
    final SessionStatus status,
    final SessionProgress? progress,
    final List<TodoItem> todos,
    final String? currentTask,
    required final DateTime startedAt,
    required final DateTime lastUpdatedAt,
    final DateTime? endedAt,
    final int toolCallCount,
  }) = _$SessionImpl;
  const _Session._() : super._();

  factory _Session.fromJson(Map<String, dynamic> json) = _$SessionImpl.fromJson;

  /// 会话 ID
  @override
  String get id;

  /// 项目名称
  @override
  String get projectName;

  /// 项目路径
  @override
  String? get projectPath;

  /// 会话状态
  @override
  SessionStatus get status;

  /// 进度信息
  @override
  SessionProgress? get progress;

  /// Todo 列表
  @override
  List<TodoItem> get todos;

  /// 当前任务描述
  @override
  String? get currentTask;

  /// 开始时间
  @override
  DateTime get startedAt;

  /// 最后更新时间
  @override
  DateTime get lastUpdatedAt;

  /// 结束时间
  @override
  DateTime? get endedAt;

  /// 总工具调用次数
  @override
  int get toolCallCount;

  /// Create a copy of Session
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionImplCopyWith<_$SessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
