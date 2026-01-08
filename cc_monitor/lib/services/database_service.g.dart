// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_service.dart';

// ignore_for_file: type=lint
class $MessagesTableTable extends MessagesTable
    with TableInfo<$MessagesTableTable, MessagesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectNameMeta = const VerificationMeta(
    'projectName',
  );
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
    'project_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectPathMeta = const VerificationMeta(
    'projectPath',
  );
  @override
  late final GeneratedColumn<String> projectPath = GeneratedColumn<String>(
    'project_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hookEventMeta = const VerificationMeta(
    'hookEvent',
  );
  @override
  late final GeneratedColumn<String> hookEvent = GeneratedColumn<String>(
    'hook_event',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toolNameMeta = const VerificationMeta(
    'toolName',
  );
  @override
  late final GeneratedColumn<String> toolName = GeneratedColumn<String>(
    'tool_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadTypeMeta = const VerificationMeta(
    'payloadType',
  );
  @override
  late final GeneratedColumn<String> payloadType = GeneratedColumn<String>(
    'payload_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    messageId,
    sessionId,
    projectName,
    projectPath,
    hookEvent,
    toolName,
    payloadType,
    payloadJson,
    isRead,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessagesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('project_name')) {
      context.handle(
        _projectNameMeta,
        projectName.isAcceptableOrUnknown(
          data['project_name']!,
          _projectNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectNameMeta);
    }
    if (data.containsKey('project_path')) {
      context.handle(
        _projectPathMeta,
        projectPath.isAcceptableOrUnknown(
          data['project_path']!,
          _projectPathMeta,
        ),
      );
    }
    if (data.containsKey('hook_event')) {
      context.handle(
        _hookEventMeta,
        hookEvent.isAcceptableOrUnknown(data['hook_event']!, _hookEventMeta),
      );
    }
    if (data.containsKey('tool_name')) {
      context.handle(
        _toolNameMeta,
        toolName.isAcceptableOrUnknown(data['tool_name']!, _toolNameMeta),
      );
    }
    if (data.containsKey('payload_type')) {
      context.handle(
        _payloadTypeMeta,
        payloadType.isAcceptableOrUnknown(
          data['payload_type']!,
          _payloadTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessagesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessagesTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      messageId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}message_id'],
          )!,
      sessionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}session_id'],
          )!,
      projectName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}project_name'],
          )!,
      projectPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_path'],
      ),
      hookEvent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hook_event'],
      ),
      toolName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_name'],
      ),
      payloadType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payload_type'],
          )!,
      payloadJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payload_json'],
          )!,
      isRead:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_read'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $MessagesTableTable createAlias(String alias) {
    return $MessagesTableTable(attachedDatabase, alias);
  }
}

class MessagesTableData extends DataClass
    implements Insertable<MessagesTableData> {
  final int id;
  final String messageId;
  final String sessionId;
  final String projectName;
  final String? projectPath;
  final String? hookEvent;
  final String? toolName;
  final String payloadType;
  final String payloadJson;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? syncedAt;
  const MessagesTableData({
    required this.id,
    required this.messageId,
    required this.sessionId,
    required this.projectName,
    this.projectPath,
    this.hookEvent,
    this.toolName,
    required this.payloadType,
    required this.payloadJson,
    required this.isRead,
    required this.createdAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message_id'] = Variable<String>(messageId);
    map['session_id'] = Variable<String>(sessionId);
    map['project_name'] = Variable<String>(projectName);
    if (!nullToAbsent || projectPath != null) {
      map['project_path'] = Variable<String>(projectPath);
    }
    if (!nullToAbsent || hookEvent != null) {
      map['hook_event'] = Variable<String>(hookEvent);
    }
    if (!nullToAbsent || toolName != null) {
      map['tool_name'] = Variable<String>(toolName);
    }
    map['payload_type'] = Variable<String>(payloadType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['is_read'] = Variable<bool>(isRead);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  MessagesTableCompanion toCompanion(bool nullToAbsent) {
    return MessagesTableCompanion(
      id: Value(id),
      messageId: Value(messageId),
      sessionId: Value(sessionId),
      projectName: Value(projectName),
      projectPath:
          projectPath == null && nullToAbsent
              ? const Value.absent()
              : Value(projectPath),
      hookEvent:
          hookEvent == null && nullToAbsent
              ? const Value.absent()
              : Value(hookEvent),
      toolName:
          toolName == null && nullToAbsent
              ? const Value.absent()
              : Value(toolName),
      payloadType: Value(payloadType),
      payloadJson: Value(payloadJson),
      isRead: Value(isRead),
      createdAt: Value(createdAt),
      syncedAt:
          syncedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(syncedAt),
    );
  }

  factory MessagesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessagesTableData(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      projectName: serializer.fromJson<String>(json['projectName']),
      projectPath: serializer.fromJson<String?>(json['projectPath']),
      hookEvent: serializer.fromJson<String?>(json['hookEvent']),
      toolName: serializer.fromJson<String?>(json['toolName']),
      payloadType: serializer.fromJson<String>(json['payloadType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<String>(messageId),
      'sessionId': serializer.toJson<String>(sessionId),
      'projectName': serializer.toJson<String>(projectName),
      'projectPath': serializer.toJson<String?>(projectPath),
      'hookEvent': serializer.toJson<String?>(hookEvent),
      'toolName': serializer.toJson<String?>(toolName),
      'payloadType': serializer.toJson<String>(payloadType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'isRead': serializer.toJson<bool>(isRead),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  MessagesTableData copyWith({
    int? id,
    String? messageId,
    String? sessionId,
    String? projectName,
    Value<String?> projectPath = const Value.absent(),
    Value<String?> hookEvent = const Value.absent(),
    Value<String?> toolName = const Value.absent(),
    String? payloadType,
    String? payloadJson,
    bool? isRead,
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => MessagesTableData(
    id: id ?? this.id,
    messageId: messageId ?? this.messageId,
    sessionId: sessionId ?? this.sessionId,
    projectName: projectName ?? this.projectName,
    projectPath: projectPath.present ? projectPath.value : this.projectPath,
    hookEvent: hookEvent.present ? hookEvent.value : this.hookEvent,
    toolName: toolName.present ? toolName.value : this.toolName,
    payloadType: payloadType ?? this.payloadType,
    payloadJson: payloadJson ?? this.payloadJson,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  MessagesTableData copyWithCompanion(MessagesTableCompanion data) {
    return MessagesTableData(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      projectName:
          data.projectName.present ? data.projectName.value : this.projectName,
      projectPath:
          data.projectPath.present ? data.projectPath.value : this.projectPath,
      hookEvent: data.hookEvent.present ? data.hookEvent.value : this.hookEvent,
      toolName: data.toolName.present ? data.toolName.value : this.toolName,
      payloadType:
          data.payloadType.present ? data.payloadType.value : this.payloadType,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessagesTableData(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('sessionId: $sessionId, ')
          ..write('projectName: $projectName, ')
          ..write('projectPath: $projectPath, ')
          ..write('hookEvent: $hookEvent, ')
          ..write('toolName: $toolName, ')
          ..write('payloadType: $payloadType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    messageId,
    sessionId,
    projectName,
    projectPath,
    hookEvent,
    toolName,
    payloadType,
    payloadJson,
    isRead,
    createdAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessagesTableData &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.sessionId == this.sessionId &&
          other.projectName == this.projectName &&
          other.projectPath == this.projectPath &&
          other.hookEvent == this.hookEvent &&
          other.toolName == this.toolName &&
          other.payloadType == this.payloadType &&
          other.payloadJson == this.payloadJson &&
          other.isRead == this.isRead &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class MessagesTableCompanion extends UpdateCompanion<MessagesTableData> {
  final Value<int> id;
  final Value<String> messageId;
  final Value<String> sessionId;
  final Value<String> projectName;
  final Value<String?> projectPath;
  final Value<String?> hookEvent;
  final Value<String?> toolName;
  final Value<String> payloadType;
  final Value<String> payloadJson;
  final Value<bool> isRead;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  const MessagesTableCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.projectPath = const Value.absent(),
    this.hookEvent = const Value.absent(),
    this.toolName = const Value.absent(),
    this.payloadType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  MessagesTableCompanion.insert({
    this.id = const Value.absent(),
    required String messageId,
    required String sessionId,
    required String projectName,
    this.projectPath = const Value.absent(),
    this.hookEvent = const Value.absent(),
    this.toolName = const Value.absent(),
    required String payloadType,
    required String payloadJson,
    this.isRead = const Value.absent(),
    required DateTime createdAt,
    this.syncedAt = const Value.absent(),
  }) : messageId = Value(messageId),
       sessionId = Value(sessionId),
       projectName = Value(projectName),
       payloadType = Value(payloadType),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<MessagesTableData> custom({
    Expression<int>? id,
    Expression<String>? messageId,
    Expression<String>? sessionId,
    Expression<String>? projectName,
    Expression<String>? projectPath,
    Expression<String>? hookEvent,
    Expression<String>? toolName,
    Expression<String>? payloadType,
    Expression<String>? payloadJson,
    Expression<bool>? isRead,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (sessionId != null) 'session_id': sessionId,
      if (projectName != null) 'project_name': projectName,
      if (projectPath != null) 'project_path': projectPath,
      if (hookEvent != null) 'hook_event': hookEvent,
      if (toolName != null) 'tool_name': toolName,
      if (payloadType != null) 'payload_type': payloadType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (isRead != null) 'is_read': isRead,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  MessagesTableCompanion copyWith({
    Value<int>? id,
    Value<String>? messageId,
    Value<String>? sessionId,
    Value<String>? projectName,
    Value<String?>? projectPath,
    Value<String?>? hookEvent,
    Value<String?>? toolName,
    Value<String>? payloadType,
    Value<String>? payloadJson,
    Value<bool>? isRead,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
  }) {
    return MessagesTableCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      sessionId: sessionId ?? this.sessionId,
      projectName: projectName ?? this.projectName,
      projectPath: projectPath ?? this.projectPath,
      hookEvent: hookEvent ?? this.hookEvent,
      toolName: toolName ?? this.toolName,
      payloadType: payloadType ?? this.payloadType,
      payloadJson: payloadJson ?? this.payloadJson,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (projectPath.present) {
      map['project_path'] = Variable<String>(projectPath.value);
    }
    if (hookEvent.present) {
      map['hook_event'] = Variable<String>(hookEvent.value);
    }
    if (toolName.present) {
      map['tool_name'] = Variable<String>(toolName.value);
    }
    if (payloadType.present) {
      map['payload_type'] = Variable<String>(payloadType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesTableCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('sessionId: $sessionId, ')
          ..write('projectName: $projectName, ')
          ..write('projectPath: $projectPath, ')
          ..write('hookEvent: $hookEvent, ')
          ..write('toolName: $toolName, ')
          ..write('payloadType: $payloadType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $SessionsTableTable extends SessionsTable
    with TableInfo<$SessionsTableTable, SessionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _projectNameMeta = const VerificationMeta(
    'projectName',
  );
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
    'project_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectPathMeta = const VerificationMeta(
    'projectPath',
  );
  @override
  late final GeneratedColumn<String> projectPath = GeneratedColumn<String>(
    'project_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('running'),
  );
  static const VerificationMeta _progressCurrentMeta = const VerificationMeta(
    'progressCurrent',
  );
  @override
  late final GeneratedColumn<int> progressCurrent = GeneratedColumn<int>(
    'progress_current',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _progressTotalMeta = const VerificationMeta(
    'progressTotal',
  );
  @override
  late final GeneratedColumn<int> progressTotal = GeneratedColumn<int>(
    'progress_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentStepMeta = const VerificationMeta(
    'currentStep',
  );
  @override
  late final GeneratedColumn<String> currentStep = GeneratedColumn<String>(
    'current_step',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _todosJsonMeta = const VerificationMeta(
    'todosJson',
  );
  @override
  late final GeneratedColumn<String> todosJson = GeneratedColumn<String>(
    'todos_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _toolCallCountMeta = const VerificationMeta(
    'toolCallCount',
  );
  @override
  late final GeneratedColumn<int> toolCallCount = GeneratedColumn<int>(
    'tool_call_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdatedAt =
      GeneratedColumn<DateTime>(
        'last_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    projectName,
    projectPath,
    status,
    progressCurrent,
    progressTotal,
    currentStep,
    todosJson,
    toolCallCount,
    startedAt,
    lastUpdatedAt,
    endedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('project_name')) {
      context.handle(
        _projectNameMeta,
        projectName.isAcceptableOrUnknown(
          data['project_name']!,
          _projectNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectNameMeta);
    }
    if (data.containsKey('project_path')) {
      context.handle(
        _projectPathMeta,
        projectPath.isAcceptableOrUnknown(
          data['project_path']!,
          _projectPathMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('progress_current')) {
      context.handle(
        _progressCurrentMeta,
        progressCurrent.isAcceptableOrUnknown(
          data['progress_current']!,
          _progressCurrentMeta,
        ),
      );
    }
    if (data.containsKey('progress_total')) {
      context.handle(
        _progressTotalMeta,
        progressTotal.isAcceptableOrUnknown(
          data['progress_total']!,
          _progressTotalMeta,
        ),
      );
    }
    if (data.containsKey('current_step')) {
      context.handle(
        _currentStepMeta,
        currentStep.isAcceptableOrUnknown(
          data['current_step']!,
          _currentStepMeta,
        ),
      );
    }
    if (data.containsKey('todos_json')) {
      context.handle(
        _todosJsonMeta,
        todosJson.isAcceptableOrUnknown(data['todos_json']!, _todosJsonMeta),
      );
    }
    if (data.containsKey('tool_call_count')) {
      context.handle(
        _toolCallCountMeta,
        toolCallCount.isAcceptableOrUnknown(
          data['tool_call_count']!,
          _toolCallCountMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionsTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      sessionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}session_id'],
          )!,
      projectName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}project_name'],
          )!,
      projectPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_path'],
      ),
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      progressCurrent:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}progress_current'],
          )!,
      progressTotal:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}progress_total'],
          )!,
      currentStep: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_step'],
      ),
      todosJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}todos_json'],
          )!,
      toolCallCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}tool_call_count'],
          )!,
      startedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}started_at'],
          )!,
      lastUpdatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}last_updated_at'],
          )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
    );
  }

  @override
  $SessionsTableTable createAlias(String alias) {
    return $SessionsTableTable(attachedDatabase, alias);
  }
}

class SessionsTableData extends DataClass
    implements Insertable<SessionsTableData> {
  final int id;
  final String sessionId;
  final String projectName;
  final String? projectPath;
  final String status;
  final int progressCurrent;
  final int progressTotal;
  final String? currentStep;
  final String todosJson;
  final int toolCallCount;
  final DateTime startedAt;
  final DateTime lastUpdatedAt;
  final DateTime? endedAt;
  const SessionsTableData({
    required this.id,
    required this.sessionId,
    required this.projectName,
    this.projectPath,
    required this.status,
    required this.progressCurrent,
    required this.progressTotal,
    this.currentStep,
    required this.todosJson,
    required this.toolCallCount,
    required this.startedAt,
    required this.lastUpdatedAt,
    this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['project_name'] = Variable<String>(projectName);
    if (!nullToAbsent || projectPath != null) {
      map['project_path'] = Variable<String>(projectPath);
    }
    map['status'] = Variable<String>(status);
    map['progress_current'] = Variable<int>(progressCurrent);
    map['progress_total'] = Variable<int>(progressTotal);
    if (!nullToAbsent || currentStep != null) {
      map['current_step'] = Variable<String>(currentStep);
    }
    map['todos_json'] = Variable<String>(todosJson);
    map['tool_call_count'] = Variable<int>(toolCallCount);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['last_updated_at'] = Variable<DateTime>(lastUpdatedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    return map;
  }

  SessionsTableCompanion toCompanion(bool nullToAbsent) {
    return SessionsTableCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      projectName: Value(projectName),
      projectPath:
          projectPath == null && nullToAbsent
              ? const Value.absent()
              : Value(projectPath),
      status: Value(status),
      progressCurrent: Value(progressCurrent),
      progressTotal: Value(progressTotal),
      currentStep:
          currentStep == null && nullToAbsent
              ? const Value.absent()
              : Value(currentStep),
      todosJson: Value(todosJson),
      toolCallCount: Value(toolCallCount),
      startedAt: Value(startedAt),
      lastUpdatedAt: Value(lastUpdatedAt),
      endedAt:
          endedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(endedAt),
    );
  }

  factory SessionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionsTableData(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      projectName: serializer.fromJson<String>(json['projectName']),
      projectPath: serializer.fromJson<String?>(json['projectPath']),
      status: serializer.fromJson<String>(json['status']),
      progressCurrent: serializer.fromJson<int>(json['progressCurrent']),
      progressTotal: serializer.fromJson<int>(json['progressTotal']),
      currentStep: serializer.fromJson<String?>(json['currentStep']),
      todosJson: serializer.fromJson<String>(json['todosJson']),
      toolCallCount: serializer.fromJson<int>(json['toolCallCount']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      lastUpdatedAt: serializer.fromJson<DateTime>(json['lastUpdatedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'projectName': serializer.toJson<String>(projectName),
      'projectPath': serializer.toJson<String?>(projectPath),
      'status': serializer.toJson<String>(status),
      'progressCurrent': serializer.toJson<int>(progressCurrent),
      'progressTotal': serializer.toJson<int>(progressTotal),
      'currentStep': serializer.toJson<String?>(currentStep),
      'todosJson': serializer.toJson<String>(todosJson),
      'toolCallCount': serializer.toJson<int>(toolCallCount),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'lastUpdatedAt': serializer.toJson<DateTime>(lastUpdatedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
    };
  }

  SessionsTableData copyWith({
    int? id,
    String? sessionId,
    String? projectName,
    Value<String?> projectPath = const Value.absent(),
    String? status,
    int? progressCurrent,
    int? progressTotal,
    Value<String?> currentStep = const Value.absent(),
    String? todosJson,
    int? toolCallCount,
    DateTime? startedAt,
    DateTime? lastUpdatedAt,
    Value<DateTime?> endedAt = const Value.absent(),
  }) => SessionsTableData(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    projectName: projectName ?? this.projectName,
    projectPath: projectPath.present ? projectPath.value : this.projectPath,
    status: status ?? this.status,
    progressCurrent: progressCurrent ?? this.progressCurrent,
    progressTotal: progressTotal ?? this.progressTotal,
    currentStep: currentStep.present ? currentStep.value : this.currentStep,
    todosJson: todosJson ?? this.todosJson,
    toolCallCount: toolCallCount ?? this.toolCallCount,
    startedAt: startedAt ?? this.startedAt,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
  );
  SessionsTableData copyWithCompanion(SessionsTableCompanion data) {
    return SessionsTableData(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      projectName:
          data.projectName.present ? data.projectName.value : this.projectName,
      projectPath:
          data.projectPath.present ? data.projectPath.value : this.projectPath,
      status: data.status.present ? data.status.value : this.status,
      progressCurrent:
          data.progressCurrent.present
              ? data.progressCurrent.value
              : this.progressCurrent,
      progressTotal:
          data.progressTotal.present
              ? data.progressTotal.value
              : this.progressTotal,
      currentStep:
          data.currentStep.present ? data.currentStep.value : this.currentStep,
      todosJson: data.todosJson.present ? data.todosJson.value : this.todosJson,
      toolCallCount:
          data.toolCallCount.present
              ? data.toolCallCount.value
              : this.toolCallCount,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      lastUpdatedAt:
          data.lastUpdatedAt.present
              ? data.lastUpdatedAt.value
              : this.lastUpdatedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionsTableData(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('projectName: $projectName, ')
          ..write('projectPath: $projectPath, ')
          ..write('status: $status, ')
          ..write('progressCurrent: $progressCurrent, ')
          ..write('progressTotal: $progressTotal, ')
          ..write('currentStep: $currentStep, ')
          ..write('todosJson: $todosJson, ')
          ..write('toolCallCount: $toolCallCount, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    projectName,
    projectPath,
    status,
    progressCurrent,
    progressTotal,
    currentStep,
    todosJson,
    toolCallCount,
    startedAt,
    lastUpdatedAt,
    endedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionsTableData &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.projectName == this.projectName &&
          other.projectPath == this.projectPath &&
          other.status == this.status &&
          other.progressCurrent == this.progressCurrent &&
          other.progressTotal == this.progressTotal &&
          other.currentStep == this.currentStep &&
          other.todosJson == this.todosJson &&
          other.toolCallCount == this.toolCallCount &&
          other.startedAt == this.startedAt &&
          other.lastUpdatedAt == this.lastUpdatedAt &&
          other.endedAt == this.endedAt);
}

class SessionsTableCompanion extends UpdateCompanion<SessionsTableData> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<String> projectName;
  final Value<String?> projectPath;
  final Value<String> status;
  final Value<int> progressCurrent;
  final Value<int> progressTotal;
  final Value<String?> currentStep;
  final Value<String> todosJson;
  final Value<int> toolCallCount;
  final Value<DateTime> startedAt;
  final Value<DateTime> lastUpdatedAt;
  final Value<DateTime?> endedAt;
  const SessionsTableCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.projectPath = const Value.absent(),
    this.status = const Value.absent(),
    this.progressCurrent = const Value.absent(),
    this.progressTotal = const Value.absent(),
    this.currentStep = const Value.absent(),
    this.todosJson = const Value.absent(),
    this.toolCallCount = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
  });
  SessionsTableCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required String projectName,
    this.projectPath = const Value.absent(),
    this.status = const Value.absent(),
    this.progressCurrent = const Value.absent(),
    this.progressTotal = const Value.absent(),
    this.currentStep = const Value.absent(),
    this.todosJson = const Value.absent(),
    this.toolCallCount = const Value.absent(),
    required DateTime startedAt,
    required DateTime lastUpdatedAt,
    this.endedAt = const Value.absent(),
  }) : sessionId = Value(sessionId),
       projectName = Value(projectName),
       startedAt = Value(startedAt),
       lastUpdatedAt = Value(lastUpdatedAt);
  static Insertable<SessionsTableData> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<String>? projectName,
    Expression<String>? projectPath,
    Expression<String>? status,
    Expression<int>? progressCurrent,
    Expression<int>? progressTotal,
    Expression<String>? currentStep,
    Expression<String>? todosJson,
    Expression<int>? toolCallCount,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? lastUpdatedAt,
    Expression<DateTime>? endedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (projectName != null) 'project_name': projectName,
      if (projectPath != null) 'project_path': projectPath,
      if (status != null) 'status': status,
      if (progressCurrent != null) 'progress_current': progressCurrent,
      if (progressTotal != null) 'progress_total': progressTotal,
      if (currentStep != null) 'current_step': currentStep,
      if (todosJson != null) 'todos_json': todosJson,
      if (toolCallCount != null) 'tool_call_count': toolCallCount,
      if (startedAt != null) 'started_at': startedAt,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
      if (endedAt != null) 'ended_at': endedAt,
    });
  }

  SessionsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<String>? projectName,
    Value<String?>? projectPath,
    Value<String>? status,
    Value<int>? progressCurrent,
    Value<int>? progressTotal,
    Value<String?>? currentStep,
    Value<String>? todosJson,
    Value<int>? toolCallCount,
    Value<DateTime>? startedAt,
    Value<DateTime>? lastUpdatedAt,
    Value<DateTime?>? endedAt,
  }) {
    return SessionsTableCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      projectName: projectName ?? this.projectName,
      projectPath: projectPath ?? this.projectPath,
      status: status ?? this.status,
      progressCurrent: progressCurrent ?? this.progressCurrent,
      progressTotal: progressTotal ?? this.progressTotal,
      currentStep: currentStep ?? this.currentStep,
      todosJson: todosJson ?? this.todosJson,
      toolCallCount: toolCallCount ?? this.toolCallCount,
      startedAt: startedAt ?? this.startedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (projectPath.present) {
      map['project_path'] = Variable<String>(projectPath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progressCurrent.present) {
      map['progress_current'] = Variable<int>(progressCurrent.value);
    }
    if (progressTotal.present) {
      map['progress_total'] = Variable<int>(progressTotal.value);
    }
    if (currentStep.present) {
      map['current_step'] = Variable<String>(currentStep.value);
    }
    if (todosJson.present) {
      map['todos_json'] = Variable<String>(todosJson.value);
    }
    if (toolCallCount.present) {
      map['tool_call_count'] = Variable<int>(toolCallCount.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<DateTime>(lastUpdatedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsTableCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('projectName: $projectName, ')
          ..write('projectPath: $projectPath, ')
          ..write('status: $status, ')
          ..write('progressCurrent: $progressCurrent, ')
          ..write('progressTotal: $progressTotal, ')
          ..write('currentStep: $currentStep, ')
          ..write('todosJson: $todosJson, ')
          ..write('toolCallCount: $toolCallCount, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MessagesTableTable messagesTable = $MessagesTableTable(this);
  late final $SessionsTableTable sessionsTable = $SessionsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    messagesTable,
    sessionsTable,
  ];
}

typedef $$MessagesTableTableCreateCompanionBuilder =
    MessagesTableCompanion Function({
      Value<int> id,
      required String messageId,
      required String sessionId,
      required String projectName,
      Value<String?> projectPath,
      Value<String?> hookEvent,
      Value<String?> toolName,
      required String payloadType,
      required String payloadJson,
      Value<bool> isRead,
      required DateTime createdAt,
      Value<DateTime?> syncedAt,
    });
typedef $$MessagesTableTableUpdateCompanionBuilder =
    MessagesTableCompanion Function({
      Value<int> id,
      Value<String> messageId,
      Value<String> sessionId,
      Value<String> projectName,
      Value<String?> projectPath,
      Value<String?> hookEvent,
      Value<String?> toolName,
      Value<String> payloadType,
      Value<String> payloadJson,
      Value<bool> isRead,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });

class $$MessagesTableTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectPath => $composableBuilder(
    column: $table.projectPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hookEvent => $composableBuilder(
    column: $table.hookEvent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolName => $composableBuilder(
    column: $table.toolName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectPath => $composableBuilder(
    column: $table.projectPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hookEvent => $composableBuilder(
    column: $table.hookEvent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolName => $composableBuilder(
    column: $table.toolName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectPath => $composableBuilder(
    column: $table.projectPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hookEvent =>
      $composableBuilder(column: $table.hookEvent, builder: (column) => column);

  GeneratedColumn<String> get toolName =>
      $composableBuilder(column: $table.toolName, builder: (column) => column);

  GeneratedColumn<String> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$MessagesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTableTable,
          MessagesTableData,
          $$MessagesTableTableFilterComposer,
          $$MessagesTableTableOrderingComposer,
          $$MessagesTableTableAnnotationComposer,
          $$MessagesTableTableCreateCompanionBuilder,
          $$MessagesTableTableUpdateCompanionBuilder,
          (
            MessagesTableData,
            BaseReferences<
              _$AppDatabase,
              $MessagesTableTable,
              MessagesTableData
            >,
          ),
          MessagesTableData,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableTableManager(_$AppDatabase db, $MessagesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$MessagesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$MessagesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$MessagesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> projectName = const Value.absent(),
                Value<String?> projectPath = const Value.absent(),
                Value<String?> hookEvent = const Value.absent(),
                Value<String?> toolName = const Value.absent(),
                Value<String> payloadType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => MessagesTableCompanion(
                id: id,
                messageId: messageId,
                sessionId: sessionId,
                projectName: projectName,
                projectPath: projectPath,
                hookEvent: hookEvent,
                toolName: toolName,
                payloadType: payloadType,
                payloadJson: payloadJson,
                isRead: isRead,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String messageId,
                required String sessionId,
                required String projectName,
                Value<String?> projectPath = const Value.absent(),
                Value<String?> hookEvent = const Value.absent(),
                Value<String?> toolName = const Value.absent(),
                required String payloadType,
                required String payloadJson,
                Value<bool> isRead = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => MessagesTableCompanion.insert(
                id: id,
                messageId: messageId,
                sessionId: sessionId,
                projectName: projectName,
                projectPath: projectPath,
                hookEvent: hookEvent,
                toolName: toolName,
                payloadType: payloadType,
                payloadJson: payloadJson,
                isRead: isRead,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTableTable,
      MessagesTableData,
      $$MessagesTableTableFilterComposer,
      $$MessagesTableTableOrderingComposer,
      $$MessagesTableTableAnnotationComposer,
      $$MessagesTableTableCreateCompanionBuilder,
      $$MessagesTableTableUpdateCompanionBuilder,
      (
        MessagesTableData,
        BaseReferences<_$AppDatabase, $MessagesTableTable, MessagesTableData>,
      ),
      MessagesTableData,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableTableCreateCompanionBuilder =
    SessionsTableCompanion Function({
      Value<int> id,
      required String sessionId,
      required String projectName,
      Value<String?> projectPath,
      Value<String> status,
      Value<int> progressCurrent,
      Value<int> progressTotal,
      Value<String?> currentStep,
      Value<String> todosJson,
      Value<int> toolCallCount,
      required DateTime startedAt,
      required DateTime lastUpdatedAt,
      Value<DateTime?> endedAt,
    });
typedef $$SessionsTableTableUpdateCompanionBuilder =
    SessionsTableCompanion Function({
      Value<int> id,
      Value<String> sessionId,
      Value<String> projectName,
      Value<String?> projectPath,
      Value<String> status,
      Value<int> progressCurrent,
      Value<int> progressTotal,
      Value<String?> currentStep,
      Value<String> todosJson,
      Value<int> toolCallCount,
      Value<DateTime> startedAt,
      Value<DateTime> lastUpdatedAt,
      Value<DateTime?> endedAt,
    });

class $$SessionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTableTable> {
  $$SessionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectPath => $composableBuilder(
    column: $table.projectPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progressCurrent => $composableBuilder(
    column: $table.progressCurrent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progressTotal => $composableBuilder(
    column: $table.progressTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get todosJson => $composableBuilder(
    column: $table.todosJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toolCallCount => $composableBuilder(
    column: $table.toolCallCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTableTable> {
  $$SessionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectPath => $composableBuilder(
    column: $table.projectPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progressCurrent => $composableBuilder(
    column: $table.progressCurrent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progressTotal => $composableBuilder(
    column: $table.progressTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get todosJson => $composableBuilder(
    column: $table.todosJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toolCallCount => $composableBuilder(
    column: $table.toolCallCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTableTable> {
  $$SessionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectPath => $composableBuilder(
    column: $table.projectPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get progressCurrent => $composableBuilder(
    column: $table.progressCurrent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get progressTotal => $composableBuilder(
    column: $table.progressTotal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => column,
  );

  GeneratedColumn<String> get todosJson =>
      $composableBuilder(column: $table.todosJson, builder: (column) => column);

  GeneratedColumn<int> get toolCallCount => $composableBuilder(
    column: $table.toolCallCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);
}

class $$SessionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTableTable,
          SessionsTableData,
          $$SessionsTableTableFilterComposer,
          $$SessionsTableTableOrderingComposer,
          $$SessionsTableTableAnnotationComposer,
          $$SessionsTableTableCreateCompanionBuilder,
          $$SessionsTableTableUpdateCompanionBuilder,
          (
            SessionsTableData,
            BaseReferences<
              _$AppDatabase,
              $SessionsTableTable,
              SessionsTableData
            >,
          ),
          SessionsTableData,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableTableManager(_$AppDatabase db, $SessionsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SessionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$SessionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$SessionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> projectName = const Value.absent(),
                Value<String?> projectPath = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> progressCurrent = const Value.absent(),
                Value<int> progressTotal = const Value.absent(),
                Value<String?> currentStep = const Value.absent(),
                Value<String> todosJson = const Value.absent(),
                Value<int> toolCallCount = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> lastUpdatedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
              }) => SessionsTableCompanion(
                id: id,
                sessionId: sessionId,
                projectName: projectName,
                projectPath: projectPath,
                status: status,
                progressCurrent: progressCurrent,
                progressTotal: progressTotal,
                currentStep: currentStep,
                todosJson: todosJson,
                toolCallCount: toolCallCount,
                startedAt: startedAt,
                lastUpdatedAt: lastUpdatedAt,
                endedAt: endedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required String projectName,
                Value<String?> projectPath = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> progressCurrent = const Value.absent(),
                Value<int> progressTotal = const Value.absent(),
                Value<String?> currentStep = const Value.absent(),
                Value<String> todosJson = const Value.absent(),
                Value<int> toolCallCount = const Value.absent(),
                required DateTime startedAt,
                required DateTime lastUpdatedAt,
                Value<DateTime?> endedAt = const Value.absent(),
              }) => SessionsTableCompanion.insert(
                id: id,
                sessionId: sessionId,
                projectName: projectName,
                projectPath: projectPath,
                status: status,
                progressCurrent: progressCurrent,
                progressTotal: progressTotal,
                currentStep: currentStep,
                todosJson: todosJson,
                toolCallCount: toolCallCount,
                startedAt: startedAt,
                lastUpdatedAt: lastUpdatedAt,
                endedAt: endedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTableTable,
      SessionsTableData,
      $$SessionsTableTableFilterComposer,
      $$SessionsTableTableOrderingComposer,
      $$SessionsTableTableAnnotationComposer,
      $$SessionsTableTableCreateCompanionBuilder,
      $$SessionsTableTableUpdateCompanionBuilder,
      (
        SessionsTableData,
        BaseReferences<_$AppDatabase, $SessionsTableTable, SessionsTableData>,
      ),
      SessionsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MessagesTableTableTableManager get messagesTable =>
      $$MessagesTableTableTableManager(_db, _db.messagesTable);
  $$SessionsTableTableTableManager get sessionsTable =>
      $$SessionsTableTableTableManager(_db, _db.sessionsTable);
}
