// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Message _$MessageFromJson(Map<String, dynamic> json) {
  return _Message.fromJson(json);
}

/// @nodoc
mixin _$Message {
  /// 消息 ID
  String get id => throw _privateConstructorUsedError;

  /// 会话 ID
  String get sessionId => throw _privateConstructorUsedError;

  /// 消息负载
  Payload get payload => throw _privateConstructorUsedError;

  /// 项目名称
  String get projectName => throw _privateConstructorUsedError;

  /// 项目路径
  String? get projectPath => throw _privateConstructorUsedError;

  /// Hook 事件类型
  String? get hookEvent => throw _privateConstructorUsedError;

  /// 工具名称 (如果是工具相关消息)
  String? get toolName => throw _privateConstructorUsedError;

  /// 是否已读
  bool get isRead => throw _privateConstructorUsedError;

  /// 创建时间
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// 消息角色 (user/assistant/system)
  String get role => throw _privateConstructorUsedError;

  /// 回复的消息 ID (用于引用)
  String? get replyToId => throw _privateConstructorUsedError;

  /// 父消息 ID (用于 Task 子任务折叠)
  String? get parentId => throw _privateConstructorUsedError;

  /// 内容 UUID (用于 hapi 消息追踪)
  String? get contentUuid => throw _privateConstructorUsedError;

  /// 是否为 sidechain 消息 (Task 子任务)
  bool get isSidechain => throw _privateConstructorUsedError;

  /// Task prompt (用于 sidechain root 匹配)
  String? get taskPrompt => throw _privateConstructorUsedError;

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageCopyWith<Message> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageCopyWith<$Res> {
  factory $MessageCopyWith(Message value, $Res Function(Message) then) =
      _$MessageCopyWithImpl<$Res, Message>;
  @useResult
  $Res call({
    String id,
    String sessionId,
    Payload payload,
    String projectName,
    String? projectPath,
    String? hookEvent,
    String? toolName,
    bool isRead,
    DateTime createdAt,
    String role,
    String? replyToId,
    String? parentId,
    String? contentUuid,
    bool isSidechain,
    String? taskPrompt,
  });

  $PayloadCopyWith<$Res> get payload;
}

/// @nodoc
class _$MessageCopyWithImpl<$Res, $Val extends Message>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? payload = null,
    Object? projectName = null,
    Object? projectPath = freezed,
    Object? hookEvent = freezed,
    Object? toolName = freezed,
    Object? isRead = null,
    Object? createdAt = null,
    Object? role = null,
    Object? replyToId = freezed,
    Object? parentId = freezed,
    Object? contentUuid = freezed,
    Object? isSidechain = null,
    Object? taskPrompt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            sessionId:
                null == sessionId
                    ? _value.sessionId
                    : sessionId // ignore: cast_nullable_to_non_nullable
                        as String,
            payload:
                null == payload
                    ? _value.payload
                    : payload // ignore: cast_nullable_to_non_nullable
                        as Payload,
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
            hookEvent:
                freezed == hookEvent
                    ? _value.hookEvent
                    : hookEvent // ignore: cast_nullable_to_non_nullable
                        as String?,
            toolName:
                freezed == toolName
                    ? _value.toolName
                    : toolName // ignore: cast_nullable_to_non_nullable
                        as String?,
            isRead:
                null == isRead
                    ? _value.isRead
                    : isRead // ignore: cast_nullable_to_non_nullable
                        as bool,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            role:
                null == role
                    ? _value.role
                    : role // ignore: cast_nullable_to_non_nullable
                        as String,
            replyToId:
                freezed == replyToId
                    ? _value.replyToId
                    : replyToId // ignore: cast_nullable_to_non_nullable
                        as String?,
            parentId:
                freezed == parentId
                    ? _value.parentId
                    : parentId // ignore: cast_nullable_to_non_nullable
                        as String?,
            contentUuid:
                freezed == contentUuid
                    ? _value.contentUuid
                    : contentUuid // ignore: cast_nullable_to_non_nullable
                        as String?,
            isSidechain:
                null == isSidechain
                    ? _value.isSidechain
                    : isSidechain // ignore: cast_nullable_to_non_nullable
                        as bool,
            taskPrompt:
                freezed == taskPrompt
                    ? _value.taskPrompt
                    : taskPrompt // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PayloadCopyWith<$Res> get payload {
    return $PayloadCopyWith<$Res>(_value.payload, (value) {
      return _then(_value.copyWith(payload: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MessageImplCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$$MessageImplCopyWith(
    _$MessageImpl value,
    $Res Function(_$MessageImpl) then,
  ) = __$$MessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String sessionId,
    Payload payload,
    String projectName,
    String? projectPath,
    String? hookEvent,
    String? toolName,
    bool isRead,
    DateTime createdAt,
    String role,
    String? replyToId,
    String? parentId,
    String? contentUuid,
    bool isSidechain,
    String? taskPrompt,
  });

  @override
  $PayloadCopyWith<$Res> get payload;
}

/// @nodoc
class __$$MessageImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$MessageImpl>
    implements _$$MessageImplCopyWith<$Res> {
  __$$MessageImplCopyWithImpl(
    _$MessageImpl _value,
    $Res Function(_$MessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? payload = null,
    Object? projectName = null,
    Object? projectPath = freezed,
    Object? hookEvent = freezed,
    Object? toolName = freezed,
    Object? isRead = null,
    Object? createdAt = null,
    Object? role = null,
    Object? replyToId = freezed,
    Object? parentId = freezed,
    Object? contentUuid = freezed,
    Object? isSidechain = null,
    Object? taskPrompt = freezed,
  }) {
    return _then(
      _$MessageImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        sessionId:
            null == sessionId
                ? _value.sessionId
                : sessionId // ignore: cast_nullable_to_non_nullable
                    as String,
        payload:
            null == payload
                ? _value.payload
                : payload // ignore: cast_nullable_to_non_nullable
                    as Payload,
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
        hookEvent:
            freezed == hookEvent
                ? _value.hookEvent
                : hookEvent // ignore: cast_nullable_to_non_nullable
                    as String?,
        toolName:
            freezed == toolName
                ? _value.toolName
                : toolName // ignore: cast_nullable_to_non_nullable
                    as String?,
        isRead:
            null == isRead
                ? _value.isRead
                : isRead // ignore: cast_nullable_to_non_nullable
                    as bool,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        role:
            null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                    as String,
        replyToId:
            freezed == replyToId
                ? _value.replyToId
                : replyToId // ignore: cast_nullable_to_non_nullable
                    as String?,
        parentId:
            freezed == parentId
                ? _value.parentId
                : parentId // ignore: cast_nullable_to_non_nullable
                    as String?,
        contentUuid:
            freezed == contentUuid
                ? _value.contentUuid
                : contentUuid // ignore: cast_nullable_to_non_nullable
                    as String?,
        isSidechain:
            null == isSidechain
                ? _value.isSidechain
                : isSidechain // ignore: cast_nullable_to_non_nullable
                    as bool,
        taskPrompt:
            freezed == taskPrompt
                ? _value.taskPrompt
                : taskPrompt // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageImpl extends _Message {
  const _$MessageImpl({
    required this.id,
    required this.sessionId,
    required this.payload,
    required this.projectName,
    this.projectPath,
    this.hookEvent,
    this.toolName,
    this.isRead = false,
    required this.createdAt,
    this.role = 'assistant',
    this.replyToId,
    this.parentId,
    this.contentUuid,
    this.isSidechain = false,
    this.taskPrompt,
  }) : super._();

  factory _$MessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageImplFromJson(json);

  /// 消息 ID
  @override
  final String id;

  /// 会话 ID
  @override
  final String sessionId;

  /// 消息负载
  @override
  final Payload payload;

  /// 项目名称
  @override
  final String projectName;

  /// 项目路径
  @override
  final String? projectPath;

  /// Hook 事件类型
  @override
  final String? hookEvent;

  /// 工具名称 (如果是工具相关消息)
  @override
  final String? toolName;

  /// 是否已读
  @override
  @JsonKey()
  final bool isRead;

  /// 创建时间
  @override
  final DateTime createdAt;

  /// 消息角色 (user/assistant/system)
  @override
  @JsonKey()
  final String role;

  /// 回复的消息 ID (用于引用)
  @override
  final String? replyToId;

  /// 父消息 ID (用于 Task 子任务折叠)
  @override
  final String? parentId;

  /// 内容 UUID (用于 hapi 消息追踪)
  @override
  final String? contentUuid;

  /// 是否为 sidechain 消息 (Task 子任务)
  @override
  @JsonKey()
  final bool isSidechain;

  /// Task prompt (用于 sidechain root 匹配)
  @override
  final String? taskPrompt;

  @override
  String toString() {
    return 'Message(id: $id, sessionId: $sessionId, payload: $payload, projectName: $projectName, projectPath: $projectPath, hookEvent: $hookEvent, toolName: $toolName, isRead: $isRead, createdAt: $createdAt, role: $role, replyToId: $replyToId, parentId: $parentId, contentUuid: $contentUuid, isSidechain: $isSidechain, taskPrompt: $taskPrompt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.payload, payload) || other.payload == payload) &&
            (identical(other.projectName, projectName) ||
                other.projectName == projectName) &&
            (identical(other.projectPath, projectPath) ||
                other.projectPath == projectPath) &&
            (identical(other.hookEvent, hookEvent) ||
                other.hookEvent == hookEvent) &&
            (identical(other.toolName, toolName) ||
                other.toolName == toolName) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.replyToId, replyToId) ||
                other.replyToId == replyToId) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.contentUuid, contentUuid) ||
                other.contentUuid == contentUuid) &&
            (identical(other.isSidechain, isSidechain) ||
                other.isSidechain == isSidechain) &&
            (identical(other.taskPrompt, taskPrompt) ||
                other.taskPrompt == taskPrompt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    sessionId,
    payload,
    projectName,
    projectPath,
    hookEvent,
    toolName,
    isRead,
    createdAt,
    role,
    replyToId,
    parentId,
    contentUuid,
    isSidechain,
    taskPrompt,
  );

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      __$$MessageImplCopyWithImpl<_$MessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageImplToJson(this);
  }
}

abstract class _Message extends Message {
  const factory _Message({
    required final String id,
    required final String sessionId,
    required final Payload payload,
    required final String projectName,
    final String? projectPath,
    final String? hookEvent,
    final String? toolName,
    final bool isRead,
    required final DateTime createdAt,
    final String role,
    final String? replyToId,
    final String? parentId,
    final String? contentUuid,
    final bool isSidechain,
    final String? taskPrompt,
  }) = _$MessageImpl;
  const _Message._() : super._();

  factory _Message.fromJson(Map<String, dynamic> json) = _$MessageImpl.fromJson;

  /// 消息 ID
  @override
  String get id;

  /// 会话 ID
  @override
  String get sessionId;

  /// 消息负载
  @override
  Payload get payload;

  /// 项目名称
  @override
  String get projectName;

  /// 项目路径
  @override
  String? get projectPath;

  /// Hook 事件类型
  @override
  String? get hookEvent;

  /// 工具名称 (如果是工具相关消息)
  @override
  String? get toolName;

  /// 是否已读
  @override
  bool get isRead;

  /// 创建时间
  @override
  DateTime get createdAt;

  /// 消息角色 (user/assistant/system)
  @override
  String get role;

  /// 回复的消息 ID (用于引用)
  @override
  String? get replyToId;

  /// 父消息 ID (用于 Task 子任务折叠)
  @override
  String? get parentId;

  /// 内容 UUID (用于 hapi 消息追踪)
  @override
  String? get contentUuid;

  /// 是否为 sidechain 消息 (Task 子任务)
  @override
  bool get isSidechain;

  /// Task prompt (用于 sidechain root 匹配)
  @override
  String? get taskPrompt;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
