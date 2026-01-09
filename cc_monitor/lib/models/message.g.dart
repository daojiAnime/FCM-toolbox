// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageImpl _$$MessageImplFromJson(Map<String, dynamic> json) =>
    _$MessageImpl(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      payload: Payload.fromJson(json['payload'] as Map<String, dynamic>),
      projectName: json['projectName'] as String,
      projectPath: json['projectPath'] as String?,
      hookEvent: json['hookEvent'] as String?,
      toolName: json['toolName'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      role: json['role'] as String? ?? 'assistant',
      replyToId: json['replyToId'] as String?,
      parentId: json['parentId'] as String?,
      contentUuid: json['contentUuid'] as String?,
      isSidechain: json['isSidechain'] as bool? ?? false,
      taskPrompt: json['taskPrompt'] as String?,
    );

Map<String, dynamic> _$$MessageImplToJson(_$MessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'payload': instance.payload,
      'projectName': instance.projectName,
      'projectPath': instance.projectPath,
      'hookEvent': instance.hookEvent,
      'toolName': instance.toolName,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt.toIso8601String(),
      'role': instance.role,
      'replyToId': instance.replyToId,
      'parentId': instance.parentId,
      'contentUuid': instance.contentUuid,
      'isSidechain': instance.isSidechain,
      'taskPrompt': instance.taskPrompt,
    };
