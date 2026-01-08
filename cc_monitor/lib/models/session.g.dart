// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionProgressImpl _$$SessionProgressImplFromJson(
  Map<String, dynamic> json,
) => _$SessionProgressImpl(
  current: (json['current'] as num?)?.toInt() ?? 0,
  total: (json['total'] as num?)?.toInt() ?? 0,
  currentStep: json['currentStep'] as String?,
);

Map<String, dynamic> _$$SessionProgressImplToJson(
  _$SessionProgressImpl instance,
) => <String, dynamic>{
  'current': instance.current,
  'total': instance.total,
  'currentStep': instance.currentStep,
};

_$TodoItemImpl _$$TodoItemImplFromJson(Map<String, dynamic> json) =>
    _$TodoItemImpl(
      content: json['content'] as String,
      status: json['status'] as String,
      activeForm: json['activeForm'] as String?,
    );

Map<String, dynamic> _$$TodoItemImplToJson(_$TodoItemImpl instance) =>
    <String, dynamic>{
      'content': instance.content,
      'status': instance.status,
      'activeForm': instance.activeForm,
    };

_$SessionImpl _$$SessionImplFromJson(Map<String, dynamic> json) =>
    _$SessionImpl(
      id: json['id'] as String,
      projectName: json['projectName'] as String,
      projectPath: json['projectPath'] as String?,
      status:
          $enumDecodeNullable(_$SessionStatusEnumMap, json['status']) ??
          SessionStatus.running,
      progress:
          json['progress'] == null
              ? null
              : SessionProgress.fromJson(
                json['progress'] as Map<String, dynamic>,
              ),
      todos:
          (json['todos'] as List<dynamic>?)
              ?.map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      currentTask: json['currentTask'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      endedAt:
          json['endedAt'] == null
              ? null
              : DateTime.parse(json['endedAt'] as String),
      toolCallCount: (json['toolCallCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$SessionImplToJson(_$SessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectName': instance.projectName,
      'projectPath': instance.projectPath,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'todos': instance.todos,
      'currentTask': instance.currentTask,
      'startedAt': instance.startedAt.toIso8601String(),
      'lastUpdatedAt': instance.lastUpdatedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'toolCallCount': instance.toolCallCount,
    };

const _$SessionStatusEnumMap = {
  SessionStatus.running: 'running',
  SessionStatus.waiting: 'waiting',
  SessionStatus.completed: 'completed',
};
