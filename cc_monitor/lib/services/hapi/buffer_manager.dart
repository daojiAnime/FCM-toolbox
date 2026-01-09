import 'dart:async';

import '../../common/logger.dart';

/// 缓冲区条目，带时间戳用于 TTL 管理
class BufferEntry<T> {
  BufferEntry(this.value) : createdAt = DateTime.now();

  final T value;
  final DateTime createdAt;

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(createdAt) > ttl;
  }
}

/// 统一缓冲区管理器 (Singleton 模式)
/// 管理流式内容、元数据、待处理结果等缓冲区
/// 提供生命周期管理、内存限制和自动清理
class BufferManager {
  BufferManager._() {
    // 启动定期清理任务
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => cleanup(),
    );
  }

  static final BufferManager instance = BufferManager._();

  // 配置参数
  static const int maxBufferSize = 10 * 1024 * 1024; // 10MB 总大小限制
  static const Duration defaultTtl = Duration(hours: 1);
  static const int maxBufferCount = 1000; // 最多 1000 个条目

  // 流式内容缓冲
  final _streamingBuffers = <String, BufferEntry<StringBuffer>>{};

  // 流式内容元数据
  final _streamingMetadata = <String, BufferEntry<Map<String, dynamic>>>{};

  // 待处理的工具结果
  final _pendingToolResults = <String, BufferEntry<Map<String, dynamic>>>{};

  // 待处理的会话更新
  final _pendingSessionUpdates = <String, BufferEntry<Map<String, dynamic>>>{};

  Timer? _cleanupTimer;

  // ============ 流式内容缓冲操作 ============

  /// 初始化流式缓冲
  void initStreamingBuffer(String messageId, Map<String, dynamic> metadata) {
    if (_streamingBuffers.length >= maxBufferCount) {
      _evictOldestBuffers(_streamingBuffers);
    }
    _streamingBuffers[messageId] = BufferEntry(StringBuffer());
    _streamingMetadata[messageId] = BufferEntry(metadata);
    Log.d('BufferMgr', 'Init streaming buffer: $messageId');
  }

  /// 追加流式内容
  void appendStreamingContent(String messageId, String chunk) {
    final entry = _streamingBuffers[messageId];
    if (entry != null) {
      entry.value.write(chunk);
    }
  }

  /// 获取流式内容
  String? getStreamingContent(String messageId) {
    return _streamingBuffers[messageId]?.value.toString();
  }

  /// 获取流式元数据
  Map<String, dynamic>? getStreamingMetadata(String messageId) {
    return _streamingMetadata[messageId]?.value;
  }

  /// 检查流式缓冲是否存在
  bool hasStreamingBuffer(String messageId) {
    return _streamingBuffers.containsKey(messageId);
  }

  /// 移除流式缓冲
  void removeStreamingBuffer(String messageId) {
    _streamingBuffers.remove(messageId);
    _streamingMetadata.remove(messageId);
    Log.d('BufferMgr', 'Removed streaming buffer: $messageId');
  }

  // ============ 待处理工具结果操作 ============

  /// 添加待处理工具结果
  void addPendingToolResult(String toolUseId, Map<String, dynamic> result) {
    if (_pendingToolResults.length >= maxBufferCount) {
      _evictOldestBuffers(_pendingToolResults);
    }
    _pendingToolResults[toolUseId] = BufferEntry(result);
    Log.d('BufferMgr', 'Added pending tool result: $toolUseId');
  }

  /// 获取待处理工具结果
  Map<String, dynamic>? getPendingToolResult(String toolUseId) {
    return _pendingToolResults[toolUseId]?.value;
  }

  /// 移除待处理工具结果
  void removePendingToolResult(String toolUseId) {
    _pendingToolResults.remove(toolUseId);
  }

  /// 获取所有待处理工具结果
  Map<String, Map<String, dynamic>> getAllPendingToolResults() {
    return _pendingToolResults.map((k, v) => MapEntry(k, v.value));
  }

  /// 检查是否有待处理工具结果
  bool hasPendingToolResults() {
    return _pendingToolResults.isNotEmpty;
  }

  /// 清空待处理工具结果
  void clearPendingToolResults() {
    _pendingToolResults.clear();
    Log.d('BufferMgr', 'Cleared all pending tool results');
  }

  // ============ 待处理会话更新操作 ============

  /// 添加待处理会话更新
  void addPendingSessionUpdate(String sessionId, Map<String, dynamic> data) {
    _pendingSessionUpdates[sessionId] = BufferEntry(data);
  }

  /// 获取并清空所有待处理会话更新
  Map<String, Map<String, dynamic>> consumePendingSessionUpdates() {
    if (_pendingSessionUpdates.isEmpty) {
      return {};
    }
    final result = _pendingSessionUpdates.map((k, v) => MapEntry(k, v.value));
    _pendingSessionUpdates.clear();
    return result;
  }

  /// 检查是否有待处理会话更新
  bool hasPendingSessionUpdates() {
    return _pendingSessionUpdates.isNotEmpty;
  }

  // ============ 生命周期管理 ============

  /// 清理过期条目
  void cleanup({Duration? ttl}) {
    final effectiveTtl = ttl ?? defaultTtl;
    var removedCount = 0;

    removedCount += _cleanupExpired(_streamingBuffers, effectiveTtl);
    removedCount += _cleanupExpired(_streamingMetadata, effectiveTtl);
    removedCount += _cleanupExpired(_pendingToolResults, effectiveTtl);
    removedCount += _cleanupExpired(_pendingSessionUpdates, effectiveTtl);

    if (removedCount > 0) {
      Log.i('BufferMgr', 'Cleanup: removed $removedCount expired entries');
    }
  }

  /// 清空所有缓冲区
  void clearAll() {
    _streamingBuffers.clear();
    _streamingMetadata.clear();
    _pendingToolResults.clear();
    _pendingSessionUpdates.clear();
    Log.i('BufferMgr', 'All buffers cleared');
  }

  /// 获取缓冲区统计信息
  BufferStats getStats() {
    return BufferStats(
      streamingBufferCount: _streamingBuffers.length,
      metadataCount: _streamingMetadata.length,
      pendingToolResultCount: _pendingToolResults.length,
      pendingSessionUpdateCount: _pendingSessionUpdates.length,
      estimatedSize: _estimateTotalSize(),
    );
  }

  /// 释放资源
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    clearAll();
    Log.i('BufferMgr', 'Disposed');
  }

  // ============ 私有辅助方法 ============

  int _cleanupExpired<T>(Map<String, BufferEntry<T>> map, Duration ttl) {
    final expiredKeys = <String>[];
    for (final entry in map.entries) {
      if (entry.value.isExpired(ttl)) {
        expiredKeys.add(entry.key);
      }
    }
    for (final key in expiredKeys) {
      map.remove(key);
    }
    return expiredKeys.length;
  }

  void _evictOldestBuffers<T>(Map<String, BufferEntry<T>> map) {
    // 按创建时间排序，移除最旧的 10%
    final entries =
        map.entries.toList()
          ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

    final toRemove = (entries.length * 0.1).ceil();
    for (var i = 0; i < toRemove && i < entries.length; i++) {
      map.remove(entries[i].key);
    }
    Log.w('BufferMgr', 'Evicted $toRemove oldest entries due to size limit');
  }

  int _estimateTotalSize() {
    var size = 0;
    for (final entry in _streamingBuffers.values) {
      size += entry.value.length * 2; // UTF-16
    }
    // 粗略估计其他缓冲区大小
    size += _streamingMetadata.length * 1024;
    size += _pendingToolResults.length * 2048;
    size += _pendingSessionUpdates.length * 512;
    return size;
  }
}

/// 缓冲区统计信息
class BufferStats {
  const BufferStats({
    required this.streamingBufferCount,
    required this.metadataCount,
    required this.pendingToolResultCount,
    required this.pendingSessionUpdateCount,
    required this.estimatedSize,
  });

  final int streamingBufferCount;
  final int metadataCount;
  final int pendingToolResultCount;
  final int pendingSessionUpdateCount;
  final int estimatedSize;

  int get totalCount =>
      streamingBufferCount +
      metadataCount +
      pendingToolResultCount +
      pendingSessionUpdateCount;

  String get formattedSize {
    if (estimatedSize < 1024) return '$estimatedSize B';
    if (estimatedSize < 1024 * 1024) {
      return '${(estimatedSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(estimatedSize / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  String toString() => 'BufferStats(total: $totalCount, size: $formattedSize)';
}
