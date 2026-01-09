// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskItemImpl _$$TaskItemImplFromJson(Map<String, dynamic> json) =>
    _$TaskItemImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      status: $enumDecode(_$TaskItemStatusEnumMap, json['status']),
      description: json['description'] as String?,
      filePath: json['filePath'] as String?,
      durationMs: (json['durationMs'] as num?)?.toInt(),
      toolName: json['toolName'] as String?,
      input: json['input'] as Map<String, dynamic>?,
      inputSummary: json['inputSummary'] as String?,
      outputSummary: json['outputSummary'] as String?,
      hasError: json['hasError'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$$TaskItemImplToJson(_$TaskItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': _$TaskItemStatusEnumMap[instance.status]!,
      'description': instance.description,
      'filePath': instance.filePath,
      'durationMs': instance.durationMs,
      'toolName': instance.toolName,
      'input': instance.input,
      'inputSummary': instance.inputSummary,
      'outputSummary': instance.outputSummary,
      'hasError': instance.hasError,
      'errorMessage': instance.errorMessage,
    };

const _$TaskItemStatusEnumMap = {
  TaskItemStatus.pending: 'pending',
  TaskItemStatus.running: 'running',
  TaskItemStatus.completed: 'completed',
  TaskItemStatus.error: 'error',
};
