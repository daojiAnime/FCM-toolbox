import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message.dart';
import '../models/payload/payload.dart';
import '../providers/messages_provider.dart';
import '../providers/settings_provider.dart';

/// Firestore 消息监听服务 Provider
final firestoreMessageServiceProvider = Provider<FirestoreMessageService>((
  ref,
) {
  return FirestoreMessageService(ref);
});

/// Firestore 消息监听服务
/// 用于在不支持 FCM 的平台（如无 APNs 配置的 macOS）上实时接收消息
class FirestoreMessageService {
  final Ref _ref;
  StreamSubscription<QuerySnapshot>? _subscription;
  bool _isInitialized = false;

  // 记录已处理的消息 ID，避免重复处理
  final Set<String> _processedMessageIds = {};

  FirestoreMessageService(this._ref);

  /// 获取 Firestore 实例
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// 获取消息集合路径
  /// 格式: messages/{deviceId}/inbox
  String get _collectionPath {
    final settings = _ref.read(settingsProvider);
    final deviceId = settings.deviceId;
    return 'devices/$deviceId/messages';
  }

  /// 初始化监听
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('FirestoreMessageService: Already initialized');
      return;
    }

    try {
      debugPrint('FirestoreMessageService: Initializing...');
      debugPrint('FirestoreMessageService: Collection path: $_collectionPath');

      // 监听消息集合
      _subscription = _firestore
          .collection(_collectionPath)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen(_handleSnapshot, onError: _handleError);

      _isInitialized = true;
      debugPrint('FirestoreMessageService: Listening for messages');
    } catch (e) {
      debugPrint('FirestoreMessageService: Failed to initialize: $e');
    }
  }

  /// 处理快照更新
  void _handleSnapshot(QuerySnapshot snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final docId = change.doc.id;

        // 跳过已处理的消息
        if (_processedMessageIds.contains(docId)) {
          continue;
        }

        _processedMessageIds.add(docId);

        final data = change.doc.data() as Map<String, dynamic>?;
        if (data != null) {
          _handleNewMessage(docId, data);
        }
      }
    }
  }

  /// 处理新消息
  void _handleNewMessage(String docId, Map<String, dynamic> data) {
    debugPrint('FirestoreMessageService: New message received: $docId');

    try {
      final message = _parseMessage(docId, data);
      if (message != null) {
        _ref.read(messagesProvider.notifier).addMessage(message);
        debugPrint(
          'FirestoreMessageService: Message added to list: ${message.id}',
        );
      }
    } catch (e) {
      debugPrint('FirestoreMessageService: Failed to parse message: $e');
    }
  }

  /// 解析 Firestore 文档为 Message 对象
  Message? _parseMessage(String docId, Map<String, dynamic> data) {
    try {
      final type = data['type'] as String? ?? 'progress';

      // 解析时间戳
      DateTime createdAt;
      final createdAtField = data['createdAt'];
      if (createdAtField is Timestamp) {
        createdAt = createdAtField.toDate();
      } else if (createdAtField is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtField);
      } else {
        createdAt = DateTime.now();
      }

      return Message(
        id: docId,
        sessionId: data['sessionId'] as String? ?? 'unknown',
        projectName: data['projectName'] as String? ?? 'Unknown Project',
        projectPath: data['projectPath'] as String?,
        hookEvent: data['hookEvent'] as String?,
        toolName: data['toolName'] as String?,
        createdAt: createdAt,
        payload: _parsePayload(type, data),
      );
    } catch (e) {
      debugPrint('FirestoreMessageService: Parse error: $e');
      return null;
    }
  }

  /// 解析 Payload
  Payload _parsePayload(String type, Map<String, dynamic> data) {
    return switch (type) {
      'progress' => Payload.progress(
        title: data['title'] as String? ?? 'Processing',
        description: data['description'] as String?,
        current: data['current'] as int? ?? 0,
        total: data['total'] as int? ?? 0,
        currentStep: data['currentStep'] as String?,
      ),
      'complete' => Payload.complete(
        title: data['title'] as String? ?? 'Complete',
        summary: data['summary'] as String?,
        duration: data['duration'] as int?,
        toolCount: data['toolCount'] as int?,
      ),
      'error' => Payload.error(
        title: data['title'] as String? ?? 'Error',
        message: data['message'] as String? ?? 'Unknown error',
        stackTrace: data['stackTrace'] as String?,
        suggestion: data['suggestion'] as String?,
      ),
      'warning' => Payload.warning(
        title: data['title'] as String? ?? 'Warning',
        message: data['message'] as String? ?? 'Warning message',
        action: data['action'] as String?,
      ),
      'code' => Payload.code(
        title: data['title'] as String? ?? 'Code',
        code: data['code'] as String? ?? '',
        language: data['language'] as String?,
        filename: data['filename'] as String?,
        startLine: data['startLine'] as int?,
      ),
      'markdown' => Payload.markdown(
        title: data['title'] as String? ?? 'Content',
        content: data['content'] as String? ?? '',
      ),
      'image' => Payload.image(
        title: data['title'] as String? ?? 'Image',
        url: data['url'] as String? ?? '',
        caption: data['caption'] as String?,
        width: data['width'] as int?,
        height: data['height'] as int?,
      ),
      'interactive' => Payload.interactive(
        title: data['title'] as String? ?? 'Action Required',
        message: data['message'] as String? ?? '',
        requestId: data['requestId'] as String? ?? '',
        interactiveType: InteractiveType.values.firstWhere(
          (e) => e.name == data['interactiveType'],
          orElse: () => InteractiveType.confirm,
        ),
        metadata: data['metadata'] as Map<String, dynamic>?,
      ),
      _ => Payload.progress(
        title: data['title'] as String? ?? 'Message',
        description:
            data['description'] as String? ?? data['message'] as String?,
      ),
    };
  }

  /// 处理错误
  void _handleError(dynamic error) {
    debugPrint('FirestoreMessageService: Stream error: $error');
  }

  /// 停止监听
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
    _processedMessageIds.clear();
    debugPrint('FirestoreMessageService: Disposed');
  }

  /// 手动刷新消息
  Future<void> refresh() async {
    try {
      final snapshot =
          await _firestore
              .collection(_collectionPath)
              .orderBy('createdAt', descending: true)
              .limit(50)
              .get();

      for (var doc in snapshot.docs) {
        final docId = doc.id;
        if (!_processedMessageIds.contains(docId)) {
          _processedMessageIds.add(docId);
          final data = doc.data();
          _handleNewMessage(docId, data);
        }
      }
    } catch (e) {
      debugPrint('FirestoreMessageService: Refresh failed: $e');
    }
  }

  /// 清除已处理的消息记录（用于测试）
  void clearProcessedMessages() {
    _processedMessageIds.clear();
  }
}
