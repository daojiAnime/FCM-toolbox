import 'package:flutter_test/flutter_test.dart';
import 'package:cc_monitor/services/hapi/buffer_manager.dart';

void main() {
  group('BufferManager', () {
    late BufferManager manager;

    setUp(() {
      manager = BufferManager.instance;
      manager.clearAll();
    });

    tearDown(() {
      manager.clearAll();
    });

    test('Singleton pattern - returns same instance', () {
      final instance1 = BufferManager.instance;
      final instance2 = BufferManager.instance;
      expect(identical(instance1, instance2), true);
    });

    test('Streaming buffer - add and retrieve', () {
      manager.initStreamingBuffer('msg1', {'type': 'markdown'});
      manager.appendStreamingContent('msg1', 'Hello');
      manager.appendStreamingContent('msg1', ' World');

      expect(manager.getStreamingContent('msg1'), 'Hello World');
      expect(manager.getStreamingMetadata('msg1')?['type'], 'markdown');
    });

    test('Streaming buffer - check existence', () {
      manager.initStreamingBuffer('msg1', {});
      expect(manager.hasStreamingBuffer('msg1'), true);
      expect(manager.hasStreamingBuffer('msg2'), false);
    });

    test('Streaming buffer - remove buffer', () {
      manager.initStreamingBuffer('msg1', {});
      manager.appendStreamingContent('msg1', 'test');

      expect(manager.hasStreamingBuffer('msg1'), true);
      manager.removeStreamingBuffer('msg1');
      expect(manager.hasStreamingBuffer('msg1'), false);
      expect(manager.getStreamingContent('msg1'), null);
    });

    test('TTL expiration - removes old buffers', () async {
      manager.initStreamingBuffer('msg1', {});
      manager.appendStreamingContent('msg1', 'content');

      // 等待一段时间
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // 使用很短的 TTL 清理
      manager.cleanup(ttl: const Duration(milliseconds: 50));

      expect(manager.hasStreamingBuffer('msg1'), false);
    });

    test('TTL expiration - preserves recent buffers', () async {
      manager.initStreamingBuffer('msg1', {});
      manager.appendStreamingContent('msg1', 'content');

      // 等待一小段时间
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // 使用较长的 TTL 清理
      manager.cleanup(ttl: const Duration(seconds: 1));

      expect(manager.hasStreamingBuffer('msg1'), true);
    });

    test('LRU eviction - removes oldest when limit exceeded', () {
      // 添加超过限制的条目
      for (var i = 0; i < 1050; i++) {
        manager.initStreamingBuffer('msg$i', {});
        manager.appendStreamingContent('msg$i', 'x' * 100);
      }

      final stats = manager.getStats();
      expect(stats.streamingBufferCount, lessThanOrEqualTo(1000));
      expect(manager.hasStreamingBuffer('msg0'), false); // 最旧的应被驱逐
      expect(manager.hasStreamingBuffer('msg1049'), true); // 最新的应该存在
    });

    test('Pending tool result - add and retrieve', () {
      final result = {'status': 'success', 'data': 'test'};
      manager.addPendingToolResult('tool1', result);

      final retrieved = manager.getPendingToolResult('tool1');
      expect(retrieved, isNotNull);
      expect(retrieved?['status'], 'success');
      expect(retrieved?['data'], 'test');
    });

    test('Pending tool result - remove', () {
      manager.addPendingToolResult('tool1', {'data': 'test'});
      expect(manager.hasPendingToolResults(), true);

      manager.removePendingToolResult('tool1');
      expect(manager.getPendingToolResult('tool1'), null);
      expect(manager.hasPendingToolResults(), false);
    });

    test('Pending tool result - get all', () {
      manager.addPendingToolResult('tool1', {'value': 1});
      manager.addPendingToolResult('tool2', {'value': 2});

      final all = manager.getAllPendingToolResults();
      expect(all.length, 2);
      expect(all['tool1']?['value'], 1);
      expect(all['tool2']?['value'], 2);
    });

    test('Pending tool result - clear all', () {
      manager.addPendingToolResult('tool1', {'data': 'test1'});
      manager.addPendingToolResult('tool2', {'data': 'test2'});

      expect(manager.hasPendingToolResults(), true);
      manager.clearPendingToolResults();
      expect(manager.hasPendingToolResults(), false);
    });

    test('Pending session update - add and consume', () {
      manager.addPendingSessionUpdate('session1', {'status': 'active'});
      manager.addPendingSessionUpdate('session2', {'status': 'idle'});

      expect(manager.hasPendingSessionUpdates(), true);

      final updates = manager.consumePendingSessionUpdates();
      expect(updates.length, 2);
      expect(updates['session1']?['status'], 'active');
      expect(updates['session2']?['status'], 'idle');

      // 消费后应该被清空
      expect(manager.hasPendingSessionUpdates(), false);
      expect(manager.consumePendingSessionUpdates().isEmpty, true);
    });

    test('Statistics accuracy', () {
      manager.initStreamingBuffer('msg1', {'key': 'value'});
      manager.appendStreamingContent('msg1', 'Hello World');
      manager.addPendingToolResult('tool1', {'result': 'ok'});
      manager.addPendingSessionUpdate('session1', {'status': 'active'});

      final stats = manager.getStats();
      expect(stats.streamingBufferCount, 1);
      expect(stats.metadataCount, 1);
      expect(stats.pendingToolResultCount, 1);
      expect(stats.pendingSessionUpdateCount, 1);
      expect(stats.totalCount, 4);
      expect(stats.estimatedSize, greaterThan(0));
    });

    test('Statistics - formatted size', () {
      final stats = BufferStats(
        streamingBufferCount: 1,
        metadataCount: 1,
        pendingToolResultCount: 0,
        pendingSessionUpdateCount: 0,
        estimatedSize: 500,
      );
      expect(stats.formattedSize, contains('B'));

      final statsKB = BufferStats(
        streamingBufferCount: 1,
        metadataCount: 1,
        pendingToolResultCount: 0,
        pendingSessionUpdateCount: 0,
        estimatedSize: 2048,
      );
      expect(statsKB.formattedSize, contains('KB'));

      final statsMB = BufferStats(
        streamingBufferCount: 1,
        metadataCount: 1,
        pendingToolResultCount: 0,
        pendingSessionUpdateCount: 0,
        estimatedSize: 2 * 1024 * 1024,
      );
      expect(statsMB.formattedSize, contains('MB'));
    });

    test('clearAll - removes all buffers', () {
      manager.initStreamingBuffer('msg1', {});
      manager.appendStreamingContent('msg1', 'content');
      manager.addPendingToolResult('tool1', {'data': 'test'});
      manager.addPendingSessionUpdate('session1', {'status': 'active'});

      final statsBefore = manager.getStats();
      expect(statsBefore.totalCount, greaterThan(0));

      manager.clearAll();

      final statsAfter = manager.getStats();
      expect(statsAfter.totalCount, 0);
      expect(manager.hasStreamingBuffer('msg1'), false);
      expect(manager.hasPendingToolResults(), false);
      expect(manager.hasPendingSessionUpdates(), false);
    });

    test('Multiple buffers - independent management', () {
      manager.initStreamingBuffer('msg1', {'type': 'code'});
      manager.initStreamingBuffer('msg2', {'type': 'markdown'});

      manager.appendStreamingContent('msg1', 'code content');
      manager.appendStreamingContent('msg2', 'markdown content');

      expect(manager.getStreamingContent('msg1'), 'code content');
      expect(manager.getStreamingContent('msg2'), 'markdown content');
      expect(manager.getStreamingMetadata('msg1')?['type'], 'code');
      expect(manager.getStreamingMetadata('msg2')?['type'], 'markdown');

      manager.removeStreamingBuffer('msg1');
      expect(manager.hasStreamingBuffer('msg1'), false);
      expect(manager.hasStreamingBuffer('msg2'), true);
    });
  });

  group('BufferEntry', () {
    test('isExpired - returns true for old entries', () async {
      final entry = BufferEntry('test');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(entry.isExpired(const Duration(milliseconds: 50)), true);
    });

    test('isExpired - returns false for recent entries', () {
      final entry = BufferEntry('test');

      expect(entry.isExpired(const Duration(seconds: 1)), false);
    });
  });
}
