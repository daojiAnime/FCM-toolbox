import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database_service.g.dart';

// ============================================================
// 表定义
// ============================================================

/// 消息表
class MessagesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageId => text().unique()();
  TextColumn get sessionId => text()();
  TextColumn get projectName => text()();
  TextColumn get projectPath => text().nullable()();
  TextColumn get hookEvent => text().nullable()();
  TextColumn get toolName => text().nullable()();
  TextColumn get payloadType => text()();
  TextColumn get payloadJson => text()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

/// 会话表
class SessionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text().unique()();
  TextColumn get projectName => text()();
  TextColumn get projectPath => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('running'))();
  IntColumn get progressCurrent => integer().withDefault(const Constant(0))();
  IntColumn get progressTotal => integer().withDefault(const Constant(0))();
  TextColumn get currentStep => text().nullable()();
  TextColumn get todosJson => text().withDefault(const Constant('[]'))();
  IntColumn get toolCallCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get lastUpdatedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
}

// ============================================================
// 数据库定义
// ============================================================

@DriftDatabase(tables: [MessagesTable, SessionsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ============================================================
  // 消息操作
  // ============================================================

  /// 插入消息
  Future<int> insertMessage(MessagesTableCompanion message) {
    return into(
      messagesTable,
    ).insert(message, mode: InsertMode.insertOrReplace);
  }

  /// 获取所有消息
  Future<List<MessagesTableData>> getAllMessages() {
    return (select(
      messagesTable,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  /// 获取会话消息
  Future<List<MessagesTableData>> getSessionMessages(String sessionId) {
    return (select(messagesTable)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 监听所有消息
  Stream<List<MessagesTableData>> watchAllMessages() {
    return (select(
      messagesTable,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  /// 监听会话消息
  Stream<List<MessagesTableData>> watchSessionMessages(String sessionId) {
    return (select(messagesTable)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// 标记消息已读
  Future<int> markAsRead(String messageId) {
    return (update(messagesTable)..where((t) => t.messageId.equals(messageId)))
        .write(const MessagesTableCompanion(isRead: Value(true)));
  }

  /// 删除消息
  Future<int> deleteMessage(String messageId) {
    return (delete(
      messagesTable,
    )..where((t) => t.messageId.equals(messageId))).go();
  }

  /// 获取未读消息数
  Future<int> getUnreadCount() async {
    final count = countAll();
    final query = selectOnly(messagesTable)
      ..addColumns([count])
      ..where(messagesTable.isRead.equals(false));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============================================================
  // 会话操作
  // ============================================================

  /// 插入或更新会话
  Future<int> upsertSession(SessionsTableCompanion session) {
    return into(
      sessionsTable,
    ).insert(session, mode: InsertMode.insertOrReplace);
  }

  /// 获取所有会话
  Future<List<SessionsTableData>> getAllSessions() {
    return (select(
      sessionsTable,
    )..orderBy([(t) => OrderingTerm.desc(t.lastUpdatedAt)])).get();
  }

  /// 监听所有会话
  Stream<List<SessionsTableData>> watchAllSessions() {
    return (select(
      sessionsTable,
    )..orderBy([(t) => OrderingTerm.desc(t.lastUpdatedAt)])).watch();
  }

  /// 监听活跃会话
  Stream<List<SessionsTableData>> watchActiveSessions() {
    return (select(sessionsTable)
          ..where((t) => t.status.isIn(['running', 'waiting']))
          ..orderBy([(t) => OrderingTerm.desc(t.lastUpdatedAt)]))
        .watch();
  }

  /// 获取会话
  Future<SessionsTableData?> getSession(String sessionId) {
    return (select(
      sessionsTable,
    )..where((t) => t.sessionId.equals(sessionId))).getSingleOrNull();
  }

  /// 更新会话状态
  Future<int> updateSessionStatus(String sessionId, String status) {
    return (update(
      sessionsTable,
    )..where((t) => t.sessionId.equals(sessionId))).write(
      SessionsTableCompanion(
        status: Value(status),
        lastUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 删除会话及其消息
  Future<void> deleteSession(String sessionId) async {
    await (delete(
      messagesTable,
    )..where((t) => t.sessionId.equals(sessionId))).go();
    await (delete(
      sessionsTable,
    )..where((t) => t.sessionId.equals(sessionId))).go();
  }

  /// 清理旧数据 (保留最近 7 天)
  Future<void> cleanupOldData() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    await (delete(
      messagesTable,
    )..where((t) => t.createdAt.isSmallerThanValue(cutoff))).go();
    await (delete(
      sessionsTable,
    )..where((t) => t.lastUpdatedAt.isSmallerThanValue(cutoff))).go();
  }
}

// ============================================================
// 数据库连接
// ============================================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cc_monitor.db'));
    return NativeDatabase.createInBackground(file);
  });
}

// ============================================================
// Provider
// ============================================================

/// 数据库 Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// 消息列表 Provider
final messagesProvider = StreamProvider<List<MessagesTableData>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllMessages();
});

/// 未读消息数 Provider
final unreadCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getUnreadCount();
});

/// 会话列表 Provider
final sessionsProvider = StreamProvider<List<SessionsTableData>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSessions();
});

/// 活跃会话 Provider
final activeSessionsProvider = StreamProvider<List<SessionsTableData>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchActiveSessions();
});
