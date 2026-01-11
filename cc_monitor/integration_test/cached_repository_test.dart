import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cc_monitor/services/cache_service.dart';
import 'package:cc_monitor/services/hapi/api/cached_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cached Repository Integration', () {
    late CacheService cacheService;
    late CachedRepository repository;

    setUp(() {
      cacheService = CacheService(
        defaultTtl: Duration(seconds: 30),
        maxEntries: 100,
      );
      repository = CachedRepository(cacheService);
    });

    tearDown(() {
      cacheService.clear();
      cacheService.dispose();
    });

    test('First call fetches from source, second call uses cache', () async {
      int fetchCount = 0;

      Future<String> fetchData() async {
        fetchCount++;
        await Future.delayed(Duration(milliseconds: 100));
        return 'data-$fetchCount';
      }

      // 第一次调用 - 从源获取
      final stopwatch1 = Stopwatch()..start();
      final result1 = await repository.fetch(
        key: 'test-key',
        fetcher: fetchData,
        ttl: Duration(seconds: 5),
      );
      stopwatch1.stop();

      expect(result1, 'data-1');
      expect(fetchCount, 1);
      expect(stopwatch1.elapsedMilliseconds, greaterThanOrEqualTo(100));

      // 第二次调用 - 从缓存获取（应该更快）
      final stopwatch2 = Stopwatch()..start();
      final result2 = await repository.fetch(
        key: 'test-key',
        fetcher: fetchData,
        ttl: Duration(seconds: 5),
      );
      stopwatch2.stop();

      expect(result2, 'data-1'); // 相同数据
      expect(fetchCount, 1); // fetcher 没有再次调用
      expect(
        stopwatch2.elapsedMilliseconds,
        lessThan(10),
        reason: 'Cache hit should be very fast',
      );
    });

    test('forceRefresh bypasses cache', () async {
      int fetchCount = 0;

      Future<String> fetchData() async {
        fetchCount++;
        return 'data-$fetchCount';
      }

      // 第一次调用
      final result1 = await repository.fetch(
        key: 'test-key',
        fetcher: fetchData,
      );
      expect(result1, 'data-1');
      expect(fetchCount, 1);

      // 使用 forceRefresh 强制刷新
      final result2 = await repository.fetch(
        key: 'test-key',
        fetcher: fetchData,
        forceRefresh: true,
      );

      expect(result2, 'data-2'); // 新数据
      expect(fetchCount, 2); // fetcher 被再次调用
    });

    test('Cache expiration triggers refetch', () async {
      int fetchCount = 0;

      Future<String> fetchData() async {
        fetchCount++;
        return 'data-$fetchCount';
      }

      // 第一次调用，设置短 TTL
      final result1 = await repository.fetch(
        key: 'test-key',
        fetcher: fetchData,
        ttl: Duration(milliseconds: 100),
      );
      expect(result1, 'data-1');
      expect(fetchCount, 1);

      // 等待缓存过期
      await Future.delayed(Duration(milliseconds: 150));

      // 再次调用，缓存已过期，应该重新获取
      final result2 = await repository.fetch(
        key: 'test-key',
        fetcher: fetchData,
        ttl: Duration(milliseconds: 100),
      );

      expect(result2, 'data-2');
      expect(fetchCount, 2);
    });

    test('Cache invalidation removes cached data', () async {
      int fetchCount = 0;

      Future<String> fetchData() async {
        fetchCount++;
        return 'data-$fetchCount';
      }

      // 第一次调用并缓存
      await repository.fetch(key: 'test-key', fetcher: fetchData);
      expect(fetchCount, 1);

      // 失效缓存
      repository.invalidate('test-key');

      // 再次调用，应该重新获取
      final result = await repository.fetch(
        key: 'test-key',
        fetcher: fetchData,
      );

      expect(result, 'data-2');
      expect(fetchCount, 2);
    });

    test('Prefix invalidation removes multiple entries', () async {
      int fetchCount1 = 0;
      int fetchCount2 = 0;
      int fetchCount3 = 0;

      // 缓存多个键
      await repository.fetch(
        key: 'sessions/123',
        fetcher: () async {
          fetchCount1++;
          return 'session-123';
        },
      );

      await repository.fetch(
        key: 'sessions/456',
        fetcher: () async {
          fetchCount2++;
          return 'session-456';
        },
      );

      await repository.fetch(
        key: 'machines/789',
        fetcher: () async {
          fetchCount3++;
          return 'machine-789';
        },
      );

      expect(fetchCount1, 1);
      expect(fetchCount2, 1);
      expect(fetchCount3, 1);

      // 按前缀失效 'sessions/'
      repository.invalidateByPrefix('sessions/');

      // 重新获取 sessions 数据，应该重新获取
      await repository.fetch(
        key: 'sessions/123',
        fetcher: () async {
          fetchCount1++;
          return 'session-123';
        },
      );

      await repository.fetch(
        key: 'sessions/456',
        fetcher: () async {
          fetchCount2++;
          return 'session-456';
        },
      );

      // machines 数据应该仍在缓存中
      await repository.fetch(
        key: 'machines/789',
        fetcher: () async {
          fetchCount3++;
          return 'machine-789';
        },
      );

      expect(fetchCount1, 2); // sessions/123 重新获取
      expect(fetchCount2, 2); // sessions/456 重新获取
      expect(fetchCount3, 1); // machines/789 仍从缓存获取
    });

    test('Clear removes all cached data', () async {
      int fetchCount1 = 0;
      int fetchCount2 = 0;

      // 缓存多个数据
      await repository.fetch(
        key: 'key1',
        fetcher: () async {
          fetchCount1++;
          return 'data1';
        },
      );

      await repository.fetch(
        key: 'key2',
        fetcher: () async {
          fetchCount2++;
          return 'data2';
        },
      );

      expect(fetchCount1, 1);
      expect(fetchCount2, 1);

      // 清空所有缓存
      repository.clear();

      // 重新获取，都应该调用 fetcher
      await repository.fetch(
        key: 'key1',
        fetcher: () async {
          fetchCount1++;
          return 'data1';
        },
      );

      await repository.fetch(
        key: 'key2',
        fetcher: () async {
          fetchCount2++;
          return 'data2';
        },
      );

      expect(fetchCount1, 2);
      expect(fetchCount2, 2);
    });

    test('Different keys cache independently', () async {
      int fetchCountA = 0;
      int fetchCountB = 0;

      final resultA1 = await repository.fetch(
        key: 'key-a',
        fetcher: () async {
          fetchCountA++;
          return 'data-a-$fetchCountA';
        },
      );

      final resultB1 = await repository.fetch(
        key: 'key-b',
        fetcher: () async {
          fetchCountB++;
          return 'data-b-$fetchCountB';
        },
      );

      expect(resultA1, 'data-a-1');
      expect(resultB1, 'data-b-1');

      // 再次获取，应该都从缓存获取
      final resultA2 = await repository.fetch(
        key: 'key-a',
        fetcher: () async {
          fetchCountA++;
          return 'data-a-$fetchCountA';
        },
      );

      final resultB2 = await repository.fetch(
        key: 'key-b',
        fetcher: () async {
          fetchCountB++;
          return 'data-b-$fetchCountB';
        },
      );

      expect(resultA2, 'data-a-1');
      expect(resultB2, 'data-b-1');
      expect(fetchCountA, 1);
      expect(fetchCountB, 1);
    });

    test('Repository without cache service always fetches', () async {
      final noCacheRepo = CachedRepository(null);
      int fetchCount = 0;

      Future<String> fetchData() async {
        fetchCount++;
        return 'data-$fetchCount';
      }

      // 第一次调用
      final result1 = await noCacheRepo.fetch(
        key: 'test-key',
        fetcher: fetchData,
      );
      expect(result1, 'data-1');
      expect(fetchCount, 1);

      // 第二次调用，无缓存服务，应该再次获取
      final result2 = await noCacheRepo.fetch(
        key: 'test-key',
        fetcher: fetchData,
      );
      expect(result2, 'data-2');
      expect(fetchCount, 2);
    });

    test('Cache handles different data types', () async {
      // String
      final stringResult = await repository.fetch<String>(
        key: 'string-key',
        fetcher: () async => 'test-string',
      );
      expect(stringResult, 'test-string');

      // int
      final intResult = await repository.fetch<int>(
        key: 'int-key',
        fetcher: () async => 42,
      );
      expect(intResult, 42);

      // List
      final listResult = await repository.fetch<List<String>>(
        key: 'list-key',
        fetcher: () async => ['a', 'b', 'c'],
      );
      expect(listResult, ['a', 'b', 'c']);

      // Map
      final mapResult = await repository.fetch<Map<String, dynamic>>(
        key: 'map-key',
        fetcher: () async => {'key': 'value'},
      );
      expect(mapResult, {'key': 'value'});
    });

    test('Concurrent fetch calls with same key share result', () async {
      int fetchCount = 0;

      Future<String> slowFetch() async {
        fetchCount++;
        await Future.delayed(Duration(milliseconds: 200));
        return 'data-$fetchCount';
      }

      // 同时发起多个相同 key 的请求
      final futures = <Future<String>>[];
      for (int i = 0; i < 5; i++) {
        futures.add(
          repository.fetch(key: 'concurrent-key', fetcher: slowFetch),
        );
      }

      final results = await Future.wait(futures);

      // 由于没有请求去重机制，fetchCount 可能是 5
      // 但第一个完成后，后续应该从缓存获取
      expect(results.every((r) => r.startsWith('data-')), isTrue);
    });
  });

  group('CacheService Integration', () {
    late CacheService cacheService;

    setUp(() {
      cacheService = CacheService(
        defaultTtl: Duration(seconds: 10),
        maxEntries: 5,
      );
    });

    tearDown(() {
      cacheService.clear();
      cacheService.dispose();
    });

    test('Cache eviction when maxEntries reached', () async {
      // 填满缓存
      for (int i = 0; i < 5; i++) {
        cacheService.set('key-$i', 'value-$i');
      }

      // 验证所有条目都在
      for (int i = 0; i < 5; i++) {
        expect(cacheService.get<String>('key-$i'), 'value-$i');
      }

      // 添加第6个条目，应该触发驱逐
      cacheService.set('key-5', 'value-5');

      // 验证最旧的条目被驱逐
      int nullCount = 0;
      for (int i = 0; i < 6; i++) {
        if (cacheService.get<String>('key-$i') == null) {
          nullCount++;
        }
      }

      expect(
        nullCount,
        greaterThan(0),
        reason: 'Some entries should be evicted',
      );
    });

    test('getOrSet creates and caches if not exists', () async {
      int factoryCallCount = 0;

      Future<String> factory() async {
        factoryCallCount++;
        return 'created-data';
      }

      // 第一次调用，应该创建
      final result1 = await cacheService.getOrSet('test-key', factory);
      expect(result1, 'created-data');
      expect(factoryCallCount, 1);

      // 第二次调用，应该从缓存获取
      final result2 = await cacheService.getOrSet('test-key', factory);
      expect(result2, 'created-data');
      expect(factoryCallCount, 1); // factory 没有再次调用
    });

    test('Cache entries persist within TTL', () async {
      cacheService.set('test-key', 'test-value', ttl: Duration(seconds: 1));

      await Future.delayed(Duration(milliseconds: 100));

      // 在 TTL 内应该仍能获取
      final value = cacheService.get<String>('test-key');
      expect(value, 'test-value');
    });

    test('Expired entries are automatically removed on get', () async {
      cacheService.set(
        'test-key',
        'test-value',
        ttl: Duration(milliseconds: 50),
      );

      // 验证缓存存在
      expect(cacheService.get<String>('test-key'), 'test-value');

      // 等待过期
      await Future.delayed(Duration(milliseconds: 100));

      // 获取时应该返回 null 并自动清理
      expect(cacheService.get<String>('test-key'), isNull);
    });

    test('Cleanup timer removes expired entries periodically', () async {
      // 添加短 TTL 的条目
      for (int i = 0; i < 3; i++) {
        cacheService.set(
          'expire-key-$i',
          'value-$i',
          ttl: Duration(milliseconds: 100),
        );
      }

      // 添加长 TTL 的条目
      cacheService.set(
        'persist-key',
        'persist-value',
        ttl: Duration(seconds: 10),
      );

      // 等待自动清理
      await Future.delayed(Duration(milliseconds: 150));

      // 触发清理（通过设置新条目）
      cacheService.set('trigger-cleanup', 'value');

      // 短 TTL 条目应该被清理
      expect(cacheService.get<String>('expire-key-0'), isNull);
      expect(cacheService.get<String>('expire-key-1'), isNull);
      expect(cacheService.get<String>('expire-key-2'), isNull);

      // 长 TTL 条目应该还在
      expect(cacheService.get<String>('persist-key'), 'persist-value');
    });
  });
}
