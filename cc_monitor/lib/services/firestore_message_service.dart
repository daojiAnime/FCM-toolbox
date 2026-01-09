import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/logger.dart';
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

  // LRU 限制：最多保留 1000 条已处理的消息 ID
  static const int _maxProcessedIds = 1000;

  // 使用 LinkedHashSet 保持插入顺序，方便实现 FIFO 清理
  final Set<String> _processedMessageIds = {};

  // 重连机制
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  static const int _initialBackoffSeconds = 5;
  static const int _maxBackoffSeconds = 60;

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
      Log.w('Firestore', 'Already initialized');
      return;
    }

    try {
      Log.i('Firestore', 'Initializing with collection: $_collectionPath');

      // 监听消息集合
      _subscription = _firestore
          .collection(_collectionPath)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen(_handleSnapshot, onError: _handleError);

      _isInitialized = true;
      _reconnectAttempts = 0; // 重置重连计数
      Log.i('Firestore', 'Listening for messages');
    } catch (e) {
      Log.e('Firestore', 'Failed to initialize', e);
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

        // 添加新消息 ID，并实现 LRU 限制
        _addProcessedMessageId(docId);

        final data = change.doc.data() as Map<String, dynamic>?;
        if (data != null) {
          _handleNewMessage(docId, data);
        }
      }
    }
  }

  /// 添加已处理的消息 ID，并实现 FIFO 清理
  void _addProcessedMessageId(String messageId) {
    _processedMessageIds.add(messageId);

    // 如果超过最大限制，移除最早的 ID
    if (_processedMessageIds.length > _maxProcessedIds) {
      final toRemove = _processedMessageIds.length - _maxProcessedIds;
      final itemsToRemove = _processedMessageIds.take(toRemove).toList();
      _processedMessageIds.removeAll(itemsToRemove);
    }
  }

  /// 处理新消息
  void _handleNewMessage(String docId, Map<String, dynamic> data) {
    try {
      final message = _parseMessage(docId, data);
      if (message != null) {
        _ref.read(messagesProvider.notifier).addMessage(message);
      }
    } catch (e) {
      Log.e('Firestore', 'Failed to parse message', e);
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
      Log.e('Firestore', 'Parse error', e);
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

  /// 处理错误并实现自动重连
  void _handleError(dynamic error) {
    Log.e('Firestore', 'Stream error', error);

    // 标记为未初始化，以便重连
    _isInitialized = false;

    // 取消当前订阅
    _subscription?.cancel();
    _subscription = null;

    // 安排重连
    _scheduleReconnect();
  }

  /// 使用指数退避策略安排重连
  void _scheduleReconnect() {
    // 取消之前的重连计时器
    _reconnectTimer?.cancel();

    // 计算退避时间：min(初始时间 * 2^尝试次数, 最大时间)
    final backoffSeconds = (_initialBackoffSeconds * (1 << _reconnectAttempts))
        .clamp(0, _maxBackoffSeconds);

    _reconnectAttempts++;

    Log.i(
      'Firestore',
      'Reconnecting in ${backoffSeconds}s (attempt $_reconnectAttempts)',
    );

    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      Log.i('Firestore', 'Attempting to reconnect...');
      initialize();
    });
  }

  /// 停止监听
  void dispose() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
    _reconnectAttempts = 0;
    _processedMessageIds.clear();
    Log.i('Firestore', 'Disposed');
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
          _addProcessedMessageId(docId);
          final data = doc.data();
          _handleNewMessage(docId, data);
        }
      }
    } catch (e) {
      Log.e('Firestore', 'Refresh failed', e);
    }
  }

  /// 清除已处理的消息记录（用于测试）
  void clearProcessedMessages() {
    _processedMessageIds.clear();
  }
}
