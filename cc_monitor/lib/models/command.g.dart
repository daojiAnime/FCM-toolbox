// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommandImpl _$$CommandImplFromJson(Map<String, dynamic> json) =>
    _$CommandImpl(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      type: $enumDecode(_$CommandTypeEnumMap, json['type']),
      status:
          $enumDecodeNullable(_$CommandStatusEnumMap, json['status']) ??
          CommandStatus.pending,
      payload: json['payload'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt:
          json['respondedAt'] == null
              ? null
              : DateTime.parse(json['respondedAt'] as String),
      expiresAt:
          json['expiresAt'] == null
              ? null
              : DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$$CommandImplToJson(_$CommandImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'type': _$CommandTypeEnumMap[instance.type]!,
      'status': _$CommandStatusEnumMap[instance.status]!,
      'payload': instance.payload,
      'createdAt': instance.createdAt.toIso8601String(),
      'respondedAt': instance.respondedAt?.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
    };

const _$CommandTypeEnumMap = {
  CommandType.permissionResponse: 'permission_response',
  CommandType.taskControl: 'task_control',
  CommandType.userInput: 'user_input',
  CommandType.todoUpdate: 'todo_update',
};

const _$CommandStatusEnumMap = {
  CommandStatus.pending: 'pending',
  CommandStatus.approved: 'approved',
  CommandStatus.denied: 'denied',
  CommandStatus.expired: 'expired',
};

_$PermissionResponsePayloadImpl _$$PermissionResponsePayloadImplFromJson(
  Map<String, dynamic> json,
) => _$PermissionResponsePayloadImpl(
  requestId: json['requestId'] as String,
  approved: json['approved'] as bool,
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$$PermissionResponsePayloadImplToJson(
  _$PermissionResponsePayloadImpl instance,
) => <String, dynamic>{
  'requestId': instance.requestId,
  'approved': instance.approved,
  'reason': instance.reason,
};

_$TaskControlPayloadImpl _$$TaskControlPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$TaskControlPayloadImpl(
  action: $enumDecode(_$TaskControlActionEnumMap, json['action']),
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$$TaskControlPayloadImplToJson(
  _$TaskControlPayloadImpl instance,
) => <String, dynamic>{
  'action': _$TaskControlActionEnumMap[instance.action]!,
  'reason': instance.reason,
};

const _$TaskControlActionEnumMap = {
  TaskControlAction.pause: 'pause',
  TaskControlAction.resume: 'resume',
  TaskControlAction.stop: 'stop',
};

_$UserInputPayloadImpl _$$UserInputPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$UserInputPayloadImpl(
  requestId: json['requestId'] as String,
  input: json['input'] as String,
);

Map<String, dynamic> _$$UserInputPayloadImplToJson(
  _$UserInputPayloadImpl instance,
) => <String, dynamic>{
  'requestId': instance.requestId,
  'input': instance.input,
};
