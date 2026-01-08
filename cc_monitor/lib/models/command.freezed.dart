// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'command.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Command _$CommandFromJson(Map<String, dynamic> json) {
  return _Command.fromJson(json);
}

/// @nodoc
mixin _$Command {
  /// 指令 ID
  String get id => throw _privateConstructorUsedError;

  /// 会话 ID
  String get sessionId => throw _privateConstructorUsedError;

  /// 指令类型
  CommandType get type => throw _privateConstructorUsedError;

  /// 指令状态
  CommandStatus get status => throw _privateConstructorUsedError;

  /// 指令负载
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;

  /// 创建时间
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// 响应时间
  DateTime? get respondedAt => throw _privateConstructorUsedError;

  /// 过期时间
  DateTime? get expiresAt => throw _privateConstructorUsedError;

  /// Serializes this Command to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Command
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommandCopyWith<Command> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommandCopyWith<$Res> {
  factory $CommandCopyWith(Command value, $Res Function(Command) then) =
      _$CommandCopyWithImpl<$Res, Command>;
  @useResult
  $Res call({
    String id,
    String sessionId,
    CommandType type,
    CommandStatus status,
    Map<String, dynamic> payload,
    DateTime createdAt,
    DateTime? respondedAt,
    DateTime? expiresAt,
  });
}

/// @nodoc
class _$CommandCopyWithImpl<$Res, $Val extends Command>
    implements $CommandCopyWith<$Res> {
  _$CommandCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Command
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? type = null,
    Object? status = null,
    Object? payload = null,
    Object? createdAt = null,
    Object? respondedAt = freezed,
    Object? expiresAt = freezed,
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
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as CommandType,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as CommandStatus,
            payload:
                null == payload
                    ? _value.payload
                    : payload // ignore: cast_nullable_to_non_nullable
                        as Map<String, dynamic>,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            respondedAt:
                freezed == respondedAt
                    ? _value.respondedAt
                    : respondedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            expiresAt:
                freezed == expiresAt
                    ? _value.expiresAt
                    : expiresAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CommandImplCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory _$$CommandImplCopyWith(
    _$CommandImpl value,
    $Res Function(_$CommandImpl) then,
  ) = __$$CommandImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String sessionId,
    CommandType type,
    CommandStatus status,
    Map<String, dynamic> payload,
    DateTime createdAt,
    DateTime? respondedAt,
    DateTime? expiresAt,
  });
}

/// @nodoc
class __$$CommandImplCopyWithImpl<$Res>
    extends _$CommandCopyWithImpl<$Res, _$CommandImpl>
    implements _$$CommandImplCopyWith<$Res> {
  __$$CommandImplCopyWithImpl(
    _$CommandImpl _value,
    $Res Function(_$CommandImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Command
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? type = null,
    Object? status = null,
    Object? payload = null,
    Object? createdAt = null,
    Object? respondedAt = freezed,
    Object? expiresAt = freezed,
  }) {
    return _then(
      _$CommandImpl(
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
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as CommandType,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as CommandStatus,
        payload:
            null == payload
                ? _value._payload
                : payload // ignore: cast_nullable_to_non_nullable
                    as Map<String, dynamic>,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        respondedAt:
            freezed == respondedAt
                ? _value.respondedAt
                : respondedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        expiresAt:
            freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CommandImpl extends _Command {
  const _$CommandImpl({
    required this.id,
    required this.sessionId,
    required this.type,
    this.status = CommandStatus.pending,
    required final Map<String, dynamic> payload,
    required this.createdAt,
    this.respondedAt,
    this.expiresAt,
  }) : _payload = payload,
       super._();

  factory _$CommandImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommandImplFromJson(json);

  /// 指令 ID
  @override
  final String id;

  /// 会话 ID
  @override
  final String sessionId;

  /// 指令类型
  @override
  final CommandType type;

  /// 指令状态
  @override
  @JsonKey()
  final CommandStatus status;

  /// 指令负载
  final Map<String, dynamic> _payload;

  /// 指令负载
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  /// 创建时间
  @override
  final DateTime createdAt;

  /// 响应时间
  @override
  final DateTime? respondedAt;

  /// 过期时间
  @override
  final DateTime? expiresAt;

  @override
  String toString() {
    return 'Command(id: $id, sessionId: $sessionId, type: $type, status: $status, payload: $payload, createdAt: $createdAt, respondedAt: $respondedAt, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommandImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.respondedAt, respondedAt) ||
                other.respondedAt == respondedAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    sessionId,
    type,
    status,
    const DeepCollectionEquality().hash(_payload),
    createdAt,
    respondedAt,
    expiresAt,
  );

  /// Create a copy of Command
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommandImplCopyWith<_$CommandImpl> get copyWith =>
      __$$CommandImplCopyWithImpl<_$CommandImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CommandImplToJson(this);
  }
}

abstract class _Command extends Command {
  const factory _Command({
    required final String id,
    required final String sessionId,
    required final CommandType type,
    final CommandStatus status,
    required final Map<String, dynamic> payload,
    required final DateTime createdAt,
    final DateTime? respondedAt,
    final DateTime? expiresAt,
  }) = _$CommandImpl;
  const _Command._() : super._();

  factory _Command.fromJson(Map<String, dynamic> json) = _$CommandImpl.fromJson;

  /// 指令 ID
  @override
  String get id;

  /// 会话 ID
  @override
  String get sessionId;

  /// 指令类型
  @override
  CommandType get type;

  /// 指令状态
  @override
  CommandStatus get status;

  /// 指令负载
  @override
  Map<String, dynamic> get payload;

  /// 创建时间
  @override
  DateTime get createdAt;

  /// 响应时间
  @override
  DateTime? get respondedAt;

  /// 过期时间
  @override
  DateTime? get expiresAt;

  /// Create a copy of Command
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommandImplCopyWith<_$CommandImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PermissionResponsePayload _$PermissionResponsePayloadFromJson(
  Map<String, dynamic> json,
) {
  return _PermissionResponsePayload.fromJson(json);
}

/// @nodoc
mixin _$PermissionResponsePayload {
  String get requestId => throw _privateConstructorUsedError;
  bool get approved => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;

  /// Serializes this PermissionResponsePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PermissionResponsePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PermissionResponsePayloadCopyWith<PermissionResponsePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PermissionResponsePayloadCopyWith<$Res> {
  factory $PermissionResponsePayloadCopyWith(
    PermissionResponsePayload value,
    $Res Function(PermissionResponsePayload) then,
  ) = _$PermissionResponsePayloadCopyWithImpl<$Res, PermissionResponsePayload>;
  @useResult
  $Res call({String requestId, bool approved, String? reason});
}

/// @nodoc
class _$PermissionResponsePayloadCopyWithImpl<
  $Res,
  $Val extends PermissionResponsePayload
>
    implements $PermissionResponsePayloadCopyWith<$Res> {
  _$PermissionResponsePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PermissionResponsePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestId = null,
    Object? approved = null,
    Object? reason = freezed,
  }) {
    return _then(
      _value.copyWith(
            requestId:
                null == requestId
                    ? _value.requestId
                    : requestId // ignore: cast_nullable_to_non_nullable
                        as String,
            approved:
                null == approved
                    ? _value.approved
                    : approved // ignore: cast_nullable_to_non_nullable
                        as bool,
            reason:
                freezed == reason
                    ? _value.reason
                    : reason // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PermissionResponsePayloadImplCopyWith<$Res>
    implements $PermissionResponsePayloadCopyWith<$Res> {
  factory _$$PermissionResponsePayloadImplCopyWith(
    _$PermissionResponsePayloadImpl value,
    $Res Function(_$PermissionResponsePayloadImpl) then,
  ) = __$$PermissionResponsePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String requestId, bool approved, String? reason});
}

/// @nodoc
class __$$PermissionResponsePayloadImplCopyWithImpl<$Res>
    extends
        _$PermissionResponsePayloadCopyWithImpl<
          $Res,
          _$PermissionResponsePayloadImpl
        >
    implements _$$PermissionResponsePayloadImplCopyWith<$Res> {
  __$$PermissionResponsePayloadImplCopyWithImpl(
    _$PermissionResponsePayloadImpl _value,
    $Res Function(_$PermissionResponsePayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PermissionResponsePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestId = null,
    Object? approved = null,
    Object? reason = freezed,
  }) {
    return _then(
      _$PermissionResponsePayloadImpl(
        requestId:
            null == requestId
                ? _value.requestId
                : requestId // ignore: cast_nullable_to_non_nullable
                    as String,
        approved:
            null == approved
                ? _value.approved
                : approved // ignore: cast_nullable_to_non_nullable
                    as bool,
        reason:
            freezed == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PermissionResponsePayloadImpl implements _PermissionResponsePayload {
  const _$PermissionResponsePayloadImpl({
    required this.requestId,
    required this.approved,
    this.reason,
  });

  factory _$PermissionResponsePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$PermissionResponsePayloadImplFromJson(json);

  @override
  final String requestId;
  @override
  final bool approved;
  @override
  final String? reason;

  @override
  String toString() {
    return 'PermissionResponsePayload(requestId: $requestId, approved: $approved, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PermissionResponsePayloadImpl &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.approved, approved) ||
                other.approved == approved) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, requestId, approved, reason);

  /// Create a copy of PermissionResponsePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PermissionResponsePayloadImplCopyWith<_$PermissionResponsePayloadImpl>
  get copyWith => __$$PermissionResponsePayloadImplCopyWithImpl<
    _$PermissionResponsePayloadImpl
  >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PermissionResponsePayloadImplToJson(this);
  }
}

abstract class _PermissionResponsePayload implements PermissionResponsePayload {
  const factory _PermissionResponsePayload({
    required final String requestId,
    required final bool approved,
    final String? reason,
  }) = _$PermissionResponsePayloadImpl;

  factory _PermissionResponsePayload.fromJson(Map<String, dynamic> json) =
      _$PermissionResponsePayloadImpl.fromJson;

  @override
  String get requestId;
  @override
  bool get approved;
  @override
  String? get reason;

  /// Create a copy of PermissionResponsePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PermissionResponsePayloadImplCopyWith<_$PermissionResponsePayloadImpl>
  get copyWith => throw _privateConstructorUsedError;
}

TaskControlPayload _$TaskControlPayloadFromJson(Map<String, dynamic> json) {
  return _TaskControlPayload.fromJson(json);
}

/// @nodoc
mixin _$TaskControlPayload {
  TaskControlAction get action => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;

  /// Serializes this TaskControlPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskControlPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskControlPayloadCopyWith<TaskControlPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskControlPayloadCopyWith<$Res> {
  factory $TaskControlPayloadCopyWith(
    TaskControlPayload value,
    $Res Function(TaskControlPayload) then,
  ) = _$TaskControlPayloadCopyWithImpl<$Res, TaskControlPayload>;
  @useResult
  $Res call({TaskControlAction action, String? reason});
}

/// @nodoc
class _$TaskControlPayloadCopyWithImpl<$Res, $Val extends TaskControlPayload>
    implements $TaskControlPayloadCopyWith<$Res> {
  _$TaskControlPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskControlPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? action = null, Object? reason = freezed}) {
    return _then(
      _value.copyWith(
            action:
                null == action
                    ? _value.action
                    : action // ignore: cast_nullable_to_non_nullable
                        as TaskControlAction,
            reason:
                freezed == reason
                    ? _value.reason
                    : reason // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaskControlPayloadImplCopyWith<$Res>
    implements $TaskControlPayloadCopyWith<$Res> {
  factory _$$TaskControlPayloadImplCopyWith(
    _$TaskControlPayloadImpl value,
    $Res Function(_$TaskControlPayloadImpl) then,
  ) = __$$TaskControlPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({TaskControlAction action, String? reason});
}

/// @nodoc
class __$$TaskControlPayloadImplCopyWithImpl<$Res>
    extends _$TaskControlPayloadCopyWithImpl<$Res, _$TaskControlPayloadImpl>
    implements _$$TaskControlPayloadImplCopyWith<$Res> {
  __$$TaskControlPayloadImplCopyWithImpl(
    _$TaskControlPayloadImpl _value,
    $Res Function(_$TaskControlPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TaskControlPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? action = null, Object? reason = freezed}) {
    return _then(
      _$TaskControlPayloadImpl(
        action:
            null == action
                ? _value.action
                : action // ignore: cast_nullable_to_non_nullable
                    as TaskControlAction,
        reason:
            freezed == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskControlPayloadImpl implements _TaskControlPayload {
  const _$TaskControlPayloadImpl({required this.action, this.reason});

  factory _$TaskControlPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskControlPayloadImplFromJson(json);

  @override
  final TaskControlAction action;
  @override
  final String? reason;

  @override
  String toString() {
    return 'TaskControlPayload(action: $action, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskControlPayloadImpl &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, action, reason);

  /// Create a copy of TaskControlPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskControlPayloadImplCopyWith<_$TaskControlPayloadImpl> get copyWith =>
      __$$TaskControlPayloadImplCopyWithImpl<_$TaskControlPayloadImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskControlPayloadImplToJson(this);
  }
}

abstract class _TaskControlPayload implements TaskControlPayload {
  const factory _TaskControlPayload({
    required final TaskControlAction action,
    final String? reason,
  }) = _$TaskControlPayloadImpl;

  factory _TaskControlPayload.fromJson(Map<String, dynamic> json) =
      _$TaskControlPayloadImpl.fromJson;

  @override
  TaskControlAction get action;
  @override
  String? get reason;

  /// Create a copy of TaskControlPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskControlPayloadImplCopyWith<_$TaskControlPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserInputPayload _$UserInputPayloadFromJson(Map<String, dynamic> json) {
  return _UserInputPayload.fromJson(json);
}

/// @nodoc
mixin _$UserInputPayload {
  String get requestId => throw _privateConstructorUsedError;
  String get input => throw _privateConstructorUsedError;

  /// Serializes this UserInputPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserInputPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserInputPayloadCopyWith<UserInputPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserInputPayloadCopyWith<$Res> {
  factory $UserInputPayloadCopyWith(
    UserInputPayload value,
    $Res Function(UserInputPayload) then,
  ) = _$UserInputPayloadCopyWithImpl<$Res, UserInputPayload>;
  @useResult
  $Res call({String requestId, String input});
}

/// @nodoc
class _$UserInputPayloadCopyWithImpl<$Res, $Val extends UserInputPayload>
    implements $UserInputPayloadCopyWith<$Res> {
  _$UserInputPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserInputPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? requestId = null, Object? input = null}) {
    return _then(
      _value.copyWith(
            requestId:
                null == requestId
                    ? _value.requestId
                    : requestId // ignore: cast_nullable_to_non_nullable
                        as String,
            input:
                null == input
                    ? _value.input
                    : input // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserInputPayloadImplCopyWith<$Res>
    implements $UserInputPayloadCopyWith<$Res> {
  factory _$$UserInputPayloadImplCopyWith(
    _$UserInputPayloadImpl value,
    $Res Function(_$UserInputPayloadImpl) then,
  ) = __$$UserInputPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String requestId, String input});
}

/// @nodoc
class __$$UserInputPayloadImplCopyWithImpl<$Res>
    extends _$UserInputPayloadCopyWithImpl<$Res, _$UserInputPayloadImpl>
    implements _$$UserInputPayloadImplCopyWith<$Res> {
  __$$UserInputPayloadImplCopyWithImpl(
    _$UserInputPayloadImpl _value,
    $Res Function(_$UserInputPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserInputPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? requestId = null, Object? input = null}) {
    return _then(
      _$UserInputPayloadImpl(
        requestId:
            null == requestId
                ? _value.requestId
                : requestId // ignore: cast_nullable_to_non_nullable
                    as String,
        input:
            null == input
                ? _value.input
                : input // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserInputPayloadImpl implements _UserInputPayload {
  const _$UserInputPayloadImpl({required this.requestId, required this.input});

  factory _$UserInputPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserInputPayloadImplFromJson(json);

  @override
  final String requestId;
  @override
  final String input;

  @override
  String toString() {
    return 'UserInputPayload(requestId: $requestId, input: $input)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserInputPayloadImpl &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.input, input) || other.input == input));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, requestId, input);

  /// Create a copy of UserInputPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserInputPayloadImplCopyWith<_$UserInputPayloadImpl> get copyWith =>
      __$$UserInputPayloadImplCopyWithImpl<_$UserInputPayloadImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UserInputPayloadImplToJson(this);
  }
}

abstract class _UserInputPayload implements UserInputPayload {
  const factory _UserInputPayload({
    required final String requestId,
    required final String input,
  }) = _$UserInputPayloadImpl;

  factory _UserInputPayload.fromJson(Map<String, dynamic> json) =
      _$UserInputPayloadImpl.fromJson;

  @override
  String get requestId;
  @override
  String get input;

  /// Create a copy of UserInputPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserInputPayloadImplCopyWith<_$UserInputPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
