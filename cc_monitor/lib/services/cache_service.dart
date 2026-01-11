import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 重新导出工具类,便于现有代码使用
export '../utils/timing/timing.dart';

/// 缓存条目
class CacheEntry<T> {
  CacheEntry({required this.data, required this.createdAt, this.expiresAt});

  final T data;
  final DateTime createdAt;
  final DateTime? expiresAt;

  /// 是否已过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 缓存年龄
  Duration get age => DateTime.now().difference(createdAt);
}

/// 内存缓存服务
class CacheService {
  CacheService({
    this.defaultTtl = const Duration(minutes: 5),
    this.maxEntries = 100,
  });

  final Duration defaultTtl;
  final int maxEntries;
  final _cache = <String, CacheEntry<dynamic>>{};
  Timer? _cleanupTimer;

  /// 获取缓存数据
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T;
  }

  /// 设置缓存数据
  void set<T>(String key, T data, {Duration? ttl}) {
    // 如果缓存已满，清理过期条目
    if (_cache.length >= maxEntries) {
      _cleanupExpired();
    }

    // 如果仍然满，删除最旧的条目
    if (_cache.length >= maxEntries) {
      _evictOldest();
    }

    final effectiveTtl = ttl ?? defaultTtl;
    _cache[key] = CacheEntry(
      data: data,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(effectiveTtl),
    );

    _scheduleCleanup();
  }

  /// 删除缓存条目
  void remove(String key) {
    _cache.remove(key);
  }

  /// 清除所有缓存
  void clear() {
    _cache.clear();
  }

  /// 清除匹配前缀的缓存
  void clearPrefix(String prefix) {
    final keysToRemove =
        _cache.keys.where((key) => key.startsWith(prefix)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// 获取或设置缓存（如果不存在则调用 factory 创建）
  Future<T> getOrSet<T>(
    String key,
    Future<T> Function() factory, {
    Duration? ttl,
  }) async {
    final cached = get<T>(key);
    if (cached != null) return cached;

    final data = await factory();
    set(key, data, ttl: ttl);
    return data;
  }

  /// 清理过期条目
  void _cleanupExpired() {
    final expiredKeys =
        _cache.entries
            .where((e) => e.value.isExpired)
            .map((e) => e.key)
            .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// 驱逐最旧的条目
  void _evictOldest() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.createdAt.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = entry.value.createdAt;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }

  /// 安排定期清理
  void _scheduleCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer(const Duration(minutes: 1), () {
      _cleanupExpired();
      if (_cache.isNotEmpty) {
        _scheduleCleanup();
      }
    });
  }

  /// 释放资源
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }

  /// 缓存统计
  CacheStats get stats => CacheStats(
    entryCount: _cache.length,
    maxEntries: maxEntries,
    expiredCount: _cache.values.where((e) => e.isExpired).length,
  );
}

/// 缓存统计信息
class CacheStats {
  const CacheStats({
    required this.entryCount,
    required this.maxEntries,
    required this.expiredCount,
  });

  final int entryCount;
  final int maxEntries;
  final int expiredCount;

  double get usagePercent => entryCount / maxEntries * 100;
}

/// 缓存服务 Provider
final cacheServiceProvider = Provider<CacheService>((ref) {
  final service = CacheService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// 缓存键常量
class CacheKeys {
  CacheKeys._();

  /// 会话列表
  static const String sessions = 'sessions';

  /// 机器列表
  static const String machines = 'machines';

  /// 会话消息前缀 (使用 ${sessionMessages}_$sessionId 格式)
  static const String sessionMessages = 'session_messages';

  /// 会话详情前缀
  static const String sessionDetail = 'session_detail';

  /// 构建会话消息缓存键
  static String messagesKey(String sessionId) =>
      '${sessionMessages}_$sessionId';

  /// 构建会话详情缓存键
  static String detailKey(String sessionId) => '${sessionDetail}_$sessionId';

  /// 会话文件缓存键
  static String sessionFiles(String id, String? path) =>
      'session_files:$id:${path ?? 'root'}';

  /// 会话 diff 缓存键
  static String sessionDiff(String id) => 'session_diff:$id';
}
