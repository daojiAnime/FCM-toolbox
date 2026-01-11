import '../../cache_service.dart';
import '../../../common/logger.dart';

/// 缓存仓库装饰器 (Decorator 模式)
/// 为 API 调用提供透明的缓存支持
class CachedRepository {
  CachedRepository(this._cacheService);

  final CacheService? _cacheService;

  /// 带缓存的数据获取
  /// [key] - 缓存键
  /// [fetcher] - 数据获取函数
  /// [ttl] - 缓存有效期
  /// [forceRefresh] - 是否强制刷新（跳过缓存）
  Future<T> fetch<T>({
    required String key,
    required Future<T> Function() fetcher,
    Duration ttl = const Duration(seconds: 30),
    bool forceRefresh = false,
  }) async {
    // 如果没有缓存服务，直接获取
    if (_cacheService == null) {
      return fetcher();
    }

    // 检查缓存
    if (!forceRefresh) {
      final cached = _cacheService.get<T>(key);
      if (cached != null) {
        Log.d('CachedRepo', 'Cache hit: $key');
        return cached;
      }
    }

    // 获取新数据
    Log.d('CachedRepo', 'Cache miss: $key, fetching...');
    final result = await fetcher();

    // 缓存结果
    _cacheService.set(key, result, ttl: ttl);
    Log.d('CachedRepo', 'Cached: $key (ttl: ${ttl.inSeconds}s)');

    return result;
  }

  /// 使缓存失效
  void invalidate(String key) {
    _cacheService?.remove(key);
    Log.d('CachedRepo', 'Invalidated: $key');
  }

  /// 使用前缀批量使缓存失效
  void invalidateByPrefix(String prefix) {
    _cacheService?.clearPrefix(prefix);
    Log.d('CachedRepo', 'Invalidated by prefix: $prefix');
  }

  /// 清空所有缓存
  void clear() {
    _cacheService?.clear();
    Log.d('CachedRepo', 'All cache cleared');
  }
}
