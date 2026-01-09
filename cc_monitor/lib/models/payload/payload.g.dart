// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProgressPayloadImpl _$$ProgressPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$ProgressPayloadImpl(
  title: json['title'] as String,
  description: json['description'] as String?,
  current: (json['current'] as num?)?.toInt() ?? 0,
  total: (json['total'] as num?)?.toInt() ?? 0,
  currentStep: json['currentStep'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$ProgressPayloadImplToJson(
  _$ProgressPayloadImpl instance,
) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'current': instance.current,
  'total': instance.total,
  'currentStep': instance.currentStep,
  'runtimeType': instance.$type,
};

_$CompletePayloadImpl _$$CompletePayloadImplFromJson(
  Map<String, dynamic> json,
) => _$CompletePayloadImpl(
  title: json['title'] as String,
  summary: json['summary'] as String?,
  duration: (json['duration'] as num?)?.toInt(),
  toolCount: (json['toolCount'] as num?)?.toInt(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$CompletePayloadImplToJson(
  _$CompletePayloadImpl instance,
) => <String, dynamic>{
  'title': instance.title,
  'summary': instance.summary,
  'duration': instance.duration,
  'toolCount': instance.toolCount,
  'runtimeType': instance.$type,
};

_$ErrorPayloadImpl _$$ErrorPayloadImplFromJson(Map<String, dynamic> json) =>
    _$ErrorPayloadImpl(
      title: json['title'] as String,
      message: json['message'] as String,
      stackTrace: json['stackTrace'] as String?,
      suggestion: json['suggestion'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ErrorPayloadImplToJson(_$ErrorPayloadImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'message': instance.message,
      'stackTrace': instance.stackTrace,
      'suggestion': instance.suggestion,
      'runtimeType': instance.$type,
    };

_$WarningPayloadImpl _$$WarningPayloadImplFromJson(Map<String, dynamic> json) =>
    _$WarningPayloadImpl(
      title: json['title'] as String,
      message: json['message'] as String,
      action: json['action'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$WarningPayloadImplToJson(
  _$WarningPayloadImpl instance,
) => <String, dynamic>{
  'title': instance.title,
  'message': instance.message,
  'action': instance.action,
  'runtimeType': instance.$type,
};

_$CodePayloadImpl _$$CodePayloadImplFromJson(Map<String, dynamic> json) =>
    _$CodePayloadImpl(
      title: json['title'] as String,
      code: json['code'] as String,
      language: json['language'] as String?,
      filename: json['filename'] as String?,
      startLine: (json['startLine'] as num?)?.toInt(),
      changes:
          (json['changes'] as List<dynamic>?)
              ?.map((e) => CodeChange.fromJson(e as Map<String, dynamic>))
              .toList(),
      streamingStatus:
          $enumDecodeNullable(
            _$StreamingStatusEnumMap,
            json['streamingStatus'],
          ) ??
          StreamingStatus.complete,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$CodePayloadImplToJson(_$CodePayloadImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'code': instance.code,
      'language': instance.language,
      'filename': instance.filename,
      'startLine': instance.startLine,
      'changes': instance.changes,
      'streamingStatus': _$StreamingStatusEnumMap[instance.streamingStatus]!,
      'runtimeType': instance.$type,
    };

const _$StreamingStatusEnumMap = {
  StreamingStatus.pending: 'pending',
  StreamingStatus.streaming: 'streaming',
  StreamingStatus.complete: 'complete',
  StreamingStatus.error: 'error',
};

_$MarkdownPayloadImpl _$$MarkdownPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$MarkdownPayloadImpl(
  title: json['title'] as String,
  content: json['content'] as String,
  streamingStatus:
      $enumDecodeNullable(_$StreamingStatusEnumMap, json['streamingStatus']) ??
      StreamingStatus.complete,
  streamingId: json['streamingId'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$MarkdownPayloadImplToJson(
  _$MarkdownPayloadImpl instance,
) => <String, dynamic>{
  'title': instance.title,
  'content': instance.content,
  'streamingStatus': _$StreamingStatusEnumMap[instance.streamingStatus]!,
  'streamingId': instance.streamingId,
  'runtimeType': instance.$type,
};

_$ThinkingPayloadImpl _$$ThinkingPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$ThinkingPayloadImpl(
  content: json['content'] as String,
  streamingStatus:
      $enumDecodeNullable(_$StreamingStatusEnumMap, json['streamingStatus']) ??
      StreamingStatus.complete,
  streamingId: json['streamingId'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$ThinkingPayloadImplToJson(
  _$ThinkingPayloadImpl instance,
) => <String, dynamic>{
  'content': instance.content,
  'streamingStatus': _$StreamingStatusEnumMap[instance.streamingStatus]!,
  'streamingId': instance.streamingId,
  'runtimeType': instance.$type,
};

_$ImagePayloadImpl _$$ImagePayloadImplFromJson(Map<String, dynamic> json) =>
    _$ImagePayloadImpl(
      title: json['title'] as String,
      url: json['url'] as String,
      caption: json['caption'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ImagePayloadImplToJson(_$ImagePayloadImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'url': instance.url,
      'caption': instance.caption,
      'width': instance.width,
      'height': instance.height,
      'runtimeType': instance.$type,
    };

_$InteractivePayloadImpl _$$InteractivePayloadImplFromJson(
  Map<String, dynamic> json,
) => _$InteractivePayloadImpl(
  title: json['title'] as String,
  message: json['message'] as String,
  requestId: json['requestId'] as String,
  interactiveType: $enumDecode(
    _$InteractiveTypeEnumMap,
    json['interactiveType'],
  ),
  status:
      $enumDecodeNullable(_$PermissionStatusEnumMap, json['status']) ??
      PermissionStatus.pending,
  metadata: json['metadata'] as Map<String, dynamic>?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$InteractivePayloadImplToJson(
  _$InteractivePayloadImpl instance,
) => <String, dynamic>{
  'title': instance.title,
  'message': instance.message,
  'requestId': instance.requestId,
  'interactiveType': _$InteractiveTypeEnumMap[instance.interactiveType]!,
  'status': _$PermissionStatusEnumMap[instance.status]!,
  'metadata': instance.metadata,
  'runtimeType': instance.$type,
};

const _$InteractiveTypeEnumMap = {
  InteractiveType.permission: 'permission',
  InteractiveType.confirm: 'confirm',
  InteractiveType.input: 'input',
  InteractiveType.choice: 'choice',
};

const _$PermissionStatusEnumMap = {
  PermissionStatus.pending: 'pending',
  PermissionStatus.approved: 'approved',
  PermissionStatus.denied: 'denied',
  PermissionStatus.canceled: 'canceled',
};

_$UserMessagePayloadImpl _$$UserMessagePayloadImplFromJson(
  Map<String, dynamic> json,
) => _$UserMessagePayloadImpl(
  content: json['content'] as String,
  isPending: json['isPending'] as bool? ?? false,
  isFailed: json['isFailed'] as bool? ?? false,
  failureReason: json['failureReason'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$UserMessagePayloadImplToJson(
  _$UserMessagePayloadImpl instance,
) => <String, dynamic>{
  'content': instance.content,
  'isPending': instance.isPending,
  'isFailed': instance.isFailed,
  'failureReason': instance.failureReason,
  'runtimeType': instance.$type,
};

_$TaskExecutionPayloadImpl _$$TaskExecutionPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$TaskExecutionPayloadImpl(
  title: json['title'] as String,
  tasks:
      (json['tasks'] as List<dynamic>)
          .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
          .toList(),
  overallStatus: $enumDecode(_$TaskStatusEnumMap, json['overallStatus']),
  summary: json['summary'] as String?,
  prompt: json['prompt'] as String?,
  durationMs: (json['durationMs'] as num?)?.toInt(),
  isExpanded: json['isExpanded'] as bool? ?? false,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$TaskExecutionPayloadImplToJson(
  _$TaskExecutionPayloadImpl instance,
) => <String, dynamic>{
  'title': instance.title,
  'tasks': instance.tasks,
  'overallStatus': _$TaskStatusEnumMap[instance.overallStatus]!,
  'summary': instance.summary,
  'prompt': instance.prompt,
  'durationMs': instance.durationMs,
  'isExpanded': instance.isExpanded,
  'runtimeType': instance.$type,
};

const _$TaskStatusEnumMap = {
  TaskStatus.pending: 'pending',
  TaskStatus.running: 'running',
  TaskStatus.completed: 'completed',
  TaskStatus.partial: 'partial',
  TaskStatus.error: 'error',
};

_$HiddenPayloadImpl _$$HiddenPayloadImplFromJson(Map<String, dynamic> json) =>
    _$HiddenPayloadImpl(
      reason: json['reason'] as String,
      toolUseId: json['toolUseId'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$HiddenPayloadImplToJson(_$HiddenPayloadImpl instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'toolUseId': instance.toolUseId,
      'runtimeType': instance.$type,
    };

_$CodeChangeImpl _$$CodeChangeImplFromJson(Map<String, dynamic> json) =>
    _$CodeChangeImpl(
      line: (json['line'] as num).toInt(),
      changeType: $enumDecode(_$ChangeTypeEnumMap, json['changeType']),
      content: json['content'] as String,
    );

Map<String, dynamic> _$$CodeChangeImplToJson(_$CodeChangeImpl instance) =>
    <String, dynamic>{
      'line': instance.line,
      'changeType': _$ChangeTypeEnumMap[instance.changeType]!,
      'content': instance.content,
    };

const _$ChangeTypeEnumMap = {
  ChangeType.add: 'add',
  ChangeType.remove: 'remove',
  ChangeType.modify: 'modify',
};
