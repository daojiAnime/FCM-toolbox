import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../models/command.dart';
import '../models/message.dart';
import '../common/constants.dart';

/// Firestore 服务 Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Firestore 服务 - 双向同步
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // 会话操作
  // ============================================================

  /// 获取会话集合引用
  CollectionReference<Map<String, dynamic>> get _sessionsRef =>
      _firestore.collection(AppConstants.sessionsCollection);

  /// 监听所有会话
  Stream<List<Session>> watchSessions() {
    return _sessionsRef
        .orderBy('lastUpdatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Session.fromJson(_convertTimestamps(data));
          }).toList();
        });
  }

  /// 监听单个会话
  Stream<Session?> watchSession(String sessionId) {
    return _sessionsRef.doc(sessionId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data()!;
      data['id'] = snapshot.id;
      return Session.fromJson(_convertTimestamps(data));
    });
  }

  /// 获取活跃会话
  Stream<List<Session>> watchActiveSessions() {
    return _sessionsRef
        .where('status', whereIn: ['running', 'waiting'])
        .orderBy('lastUpdatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Session.fromJson(_convertTimestamps(data));
          }).toList();
        });
  }

  // ============================================================
  // 消息操作
  // ============================================================

  /// 获取会话消息集合引用
  CollectionReference<Map<String, dynamic>> _messagesRef(String sessionId) =>
      _sessionsRef.doc(sessionId).collection(AppConstants.messagesCollection);

  /// 监听会话消息
  Stream<List<Message>> watchMessages(String sessionId) {
    return _messagesRef(
      sessionId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Message.fromJson(_convertTimestamps(data));
      }).toList();
    });
  }

  /// 标记消息已读
  Future<void> markMessageAsRead(String sessionId, String messageId) async {
    await _messagesRef(sessionId).doc(messageId).update({'isRead': true});
  }

  // ============================================================
  // 指令操作 (上行)
  // ============================================================

  /// 获取指令集合引用
  CollectionReference<Map<String, dynamic>> _commandsRef(String sessionId) =>
      _sessionsRef.doc(sessionId).collection(AppConstants.commandsCollection);

  /// 发送权限响应
  Future<void> sendPermissionResponse({
    required String sessionId,
    required String requestId,
    required bool approved,
    String? reason,
  }) async {
    final command = Command(
      id: '', // Firestore 自动生成
      sessionId: sessionId,
      type: CommandType.permissionResponse,
      payload: {'requestId': requestId, 'approved': approved, 'reason': reason},
      createdAt: DateTime.now(),
      respondedAt: DateTime.now(),
    );

    await _commandsRef(sessionId).add(command.toJson());
  }

  /// 发送任务控制指令
  Future<void> sendTaskControl({
    required String sessionId,
    required TaskControlAction action,
    String? reason,
  }) async {
    final command = Command(
      id: '',
      sessionId: sessionId,
      type: CommandType.taskControl,
      payload: {'action': action.name, 'reason': reason},
      createdAt: DateTime.now(),
    );

    await _commandsRef(sessionId).add(command.toJson());
  }

  /// 发送用户输入
  Future<void> sendUserInput({
    required String sessionId,
    required String requestId,
    required String input,
  }) async {
    final command = Command(
      id: '',
      sessionId: sessionId,
      type: CommandType.userInput,
      payload: {'requestId': requestId, 'input': input},
      createdAt: DateTime.now(),
    );

    await _commandsRef(sessionId).add(command.toJson());
  }

  /// 监听待处理指令
  Stream<List<Command>> watchPendingCommands(String sessionId) {
    return _commandsRef(sessionId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Command.fromJson(_convertTimestamps(data));
          }).toList();
        });
  }

  // ============================================================
  // 工具方法
  // ============================================================

  /// 转换 Firestore Timestamp 为 DateTime
  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    for (final key in result.keys.toList()) {
      final value = result[key];
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        result[key] = _convertTimestamps(value);
      } else if (value is List) {
        result[key] =
            value.map((item) {
              if (item is Map<String, dynamic>) {
                return _convertTimestamps(item);
              } else if (item is Timestamp) {
                return item.toDate().toIso8601String();
              }
              return item;
            }).toList();
      }
    }

    return result;
  }
}
