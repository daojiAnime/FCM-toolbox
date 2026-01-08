import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      debugPrint('[Cache] Entry expired: $key');
      return null;
    }

    debugPrint('[Cache] Hit: $key (age: ${entry.age.inSeconds}s)');
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

    debugPrint('[Cache] Set: $key (ttl: ${effectiveTtl.inSeconds}s)');
    _scheduleCleanup();
  }

  /// 删除缓存条目
  void remove(String key) {
    _cache.remove(key);
    debugPrint('[Cache] Removed: $key');
  }

  /// 清除所有缓存
  void clear() {
    _cache.clear();
    debugPrint('[Cache] Cleared all entries');
  }

  /// 清除匹配前缀的缓存
  void clearPrefix(String prefix) {
    final keysToRemove =
        _cache.keys.where((key) => key.startsWith(prefix)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    debugPrint(
      '[Cache] Cleared ${keysToRemove.length} entries with prefix: $prefix',
    );
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

    if (expiredKeys.isNotEmpty) {
      debugPrint('[Cache] Cleaned up ${expiredKeys.length} expired entries');
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
      debugPrint('[Cache] Evicted oldest entry: $oldestKey');
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

/// 防抖器
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  Timer? _timer;

  /// 执行防抖操作
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// 立即执行并取消待处理的操作
  void runNow(VoidCallback action) {
    _timer?.cancel();
    action();
  }

  /// 取消待处理的操作
  void cancel() {
    _timer?.cancel();
  }

  /// 释放资源
  void dispose() {
    _timer?.cancel();
  }
}

/// 节流器
class Throttler {
  Throttler({this.interval = const Duration(milliseconds: 100)});

  final Duration interval;
  DateTime? _lastRun;
  Timer? _timer;
  VoidCallback? _pendingAction;

  /// 执行节流操作
  void run(VoidCallback action) {
    final now = DateTime.now();

    if (_lastRun == null || now.difference(_lastRun!) >= interval) {
      // 可以立即执行
      _lastRun = now;
      action();
    } else {
      // 保存待执行的操作
      _pendingAction = action;
      _timer?.cancel();
      _timer = Timer(interval - now.difference(_lastRun!), () {
        _lastRun = DateTime.now();
        _pendingAction?.call();
        _pendingAction = null;
      });
    }
  }

  /// 释放资源
  void dispose() {
    _timer?.cancel();
  }
}

/// 批量更新收集器
/// 收集多个更新操作，批量执行以减少重绘
class BatchUpdater<T> {
  BatchUpdater({
    required this.onFlush,
    this.maxBatchSize = 50,
    this.flushDelay = const Duration(milliseconds: 100),
  });

  final void Function(List<T> items) onFlush;
  final int maxBatchSize;
  final Duration flushDelay;

  final List<T> _pendingItems = [];
  Timer? _flushTimer;

  /// 添加项目到批次
  void add(T item) {
    _pendingItems.add(item);

    if (_pendingItems.length >= maxBatchSize) {
      // 批次已满，立即刷新
      flush();
    } else {
      // 延迟刷新
      _scheduleFlush();
    }
  }

  /// 添加多个项目
  void addAll(Iterable<T> items) {
    for (final item in items) {
      add(item);
    }
  }

  /// 立即刷新所有待处理项目
  void flush() {
    if (_pendingItems.isEmpty) return;

    _flushTimer?.cancel();
    final items = List<T>.from(_pendingItems);
    _pendingItems.clear();

    debugPrint('[BatchUpdater] Flushing ${items.length} items');
    onFlush(items);
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(flushDelay, flush);
  }

  /// 释放资源
  void dispose() {
    flush(); // 确保所有待处理项目都被处理
    _flushTimer?.cancel();
  }
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
  static const String sessions = 'sessions';
  static const String machines = 'machines';
  static String sessionDetail(String id) => 'session:$id';
  static String sessionFiles(String id, String? path) =>
      'session_files:$id:${path ?? 'root'}';
  static String sessionDiff(String id) => 'session_diff:$id';
}
