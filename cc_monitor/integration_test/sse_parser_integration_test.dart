import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cc_monitor/services/hapi/sse_parser.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SSE Parser Integration', () {
    late SseParser parser;

    setUp(() {
      parser = SseParser();
    });

    test('Parse simple SSE event', () {
      // 模拟 SSE 流
      final lines = [
        'event: session-created',
        'data: {"id":"sess-123"}',
        '', // 空行表示事件结束
      ];

      SseParseResult? result;
      for (final line in lines) {
        result = parser.parseLine(line);
        if (result != null && result.hasEvent) break;
      }

      expect(result, isNotNull);
      expect(result!.hasEvent, isTrue);
      expect(result.eventType, 'session-created');
      expect(result.data, '{"id":"sess-123"}');
    });

    test('Parse multi-line data event', () {
      // 多行数据
      final lines = [
        'event: message-received',
        'data: {"sessionId":"sess-123",',
        'data: "message":{"role":"assistant"}}',
        '',
      ];

      SseParseResult? result;
      for (final line in lines) {
        result = parser.parseLine(line);
        if (result != null && result.hasEvent) break;
      }

      expect(result, isNotNull);
      expect(result!.hasEvent, isTrue);
      expect(result.eventType, 'message-received');
      expect(result.data, contains('sess-123'));
      expect(result.data, contains('assistant'));
    });

    test('Parse retry directive', () {
      // retry 指令
      final lines = ['retry: 3000', ''];

      SseParseResult? retryResult;
      for (final line in lines) {
        final result = parser.parseLine(line);
        if (result != null && result.retryDelay != null) {
          retryResult = result;
          break;
        }
      }

      expect(retryResult, isNotNull);
      expect(retryResult!.retryDelay, equals(Duration(milliseconds: 3000)));
    });

    test('Parse event with id', () {
      final lines = [
        'event: test-event',
        'id: event-123',
        'data: test data',
        '',
      ];

      SseParseResult? result;
      for (final line in lines) {
        result = parser.parseLine(line);
        if (result != null && result.hasEvent) break;
      }

      expect(result, isNotNull);
      expect(result!.eventId, 'event-123');
      expect(result.data, 'test data');
    });

    test('Default event type is "message"', () {
      final lines = ['data: simple message without event type', ''];

      SseParseResult? result;
      for (final line in lines) {
        result = parser.parseLine(line);
        if (result != null && result.hasEvent) break;
      }

      expect(result, isNotNull);
      expect(result!.eventType, 'message');
      expect(result.data, 'simple message without event type');
    });

    test('Ignore comment lines', () {
      final lines = [
        ': this is a comment',
        'event: test-event',
        ': another comment',
        'data: test data',
        '',
      ];

      SseParseResult? result;
      for (final line in lines) {
        result = parser.parseLine(line);
        if (result != null && result.hasEvent) break;
      }

      expect(result, isNotNull);
      expect(result!.eventType, 'test-event');
      expect(result.data, 'test data');
    });

    test('Parse multiple events in sequence', () {
      final lines = [
        'event: event1',
        'data: data1',
        '',
        'event: event2',
        'data: data2',
        '',
        'event: event3',
        'data: data3',
        '',
      ];

      final events = <SseParseResult>[];
      for (final line in lines) {
        final result = parser.parseLine(line);
        if (result != null && result.hasEvent) {
          events.add(result);
        }
      }

      expect(events.length, 3);
      expect(events[0].eventType, 'event1');
      expect(events[1].eventType, 'event2');
      expect(events[2].eventType, 'event3');
    });

    test('Handle empty data lines', () {
      final lines = ['event: test', 'data:', ''];

      SseParseResult? result;
      for (final line in lines) {
        final parsed = parser.parseLine(line);
        if (parsed != null && parsed.hasEvent) {
          result = parsed;
          break;
        }
      }

      expect(result, isNotNull);
      // 空 data 行会生成空字符串
      expect(result!.data, isNotNull);
    });

    test('Strip leading space from data value', () {
      // SSE 规范：data: 后的首个空格会被移除
      final lines = ['event: test', 'data: test data with leading space', ''];

      SseParseResult? result;
      for (final line in lines) {
        result = parser.parseLine(line);
        if (result != null && result.hasEvent) break;
      }

      expect(result, isNotNull);
      expect(result!.data, 'test data with leading space');
    });
  });

  group('SSE Stream Parser Integration', () {
    late List<Map<String, String?>> events;
    late List<Duration> retryDelays;
    late List<String> errors;

    test('Stream parser processes SSE lines', () async {
      events = [];
      retryDelays = [];

      final streamParser = SseStreamParser(
        onEvent: (type, data, id) {
          events.add({'type': type, 'data': data, 'id': id});
        },
        onRetryDelay: (delay) => retryDelays.add(delay),
      );

      final lines = [
        'event: session-created',
        'data: {"id":"sess-123"}',
        '',
        'event: message-received',
        'data: {"sessionId":"sess-123"}',
        '',
      ];

      await streamParser.parse(Stream.fromIterable(lines)).toList();

      expect(events.length, 2);
      expect(events[0]['type'], 'session-created');
      expect(events[1]['type'], 'message-received');
    });

    test('Stream parser handles retry directive', () async {
      events = [];
      retryDelays = [];

      final streamParser = SseStreamParser(
        onEvent: (type, data, id) {
          events.add({'type': type, 'data': data, 'id': id});
        },
        onRetryDelay: (delay) => retryDelays.add(delay),
      );

      final lines = ['retry: 5000', '', 'event: test', 'data: test', ''];

      await streamParser.parse(Stream.fromIterable(lines)).toList();

      expect(retryDelays.length, 1);
      expect(retryDelays[0], equals(Duration(milliseconds: 5000)));
      expect(events.length, 1);
    });

    test('Stream parser processes chunked multi-line data', () async {
      events = [];

      final streamParser = SseStreamParser(
        onEvent: (type, data, id) {
          events.add({'type': type, 'data': data, 'id': id});
        },
      );

      final lines = [
        'event: large-message',
        'data: {"part1": "value1",',
        'data: "part2": "value2",',
        'data: "part3": "value3"}',
        '',
      ];

      await streamParser.parse(Stream.fromIterable(lines)).toList();

      expect(events.length, 1);
      expect(events[0]['data'], contains('part1'));
      expect(events[0]['data'], contains('part2'));
      expect(events[0]['data'], contains('part3'));
    });

    test('Stream parser with custom default event type', () async {
      events = [];

      final customParser = SseStreamParser(
        defaultEventType: 'custom-default',
        onEvent: (type, data, id) {
          events.add({'type': type, 'data': data, 'id': id});
        },
      );

      final lines = ['data: no explicit event type', ''];

      await customParser.parse(Stream.fromIterable(lines)).toList();

      expect(events.length, 1);
      expect(events[0]['type'], 'custom-default');
    });
  });

  group('SSE Parser Factory', () {
    test('Create standard parser', () {
      final standardParser = SseParserFactory.createStandard();
      expect(standardParser, isNotNull);

      final result = standardParser.parseLine('data: test');
      expect(result, isNull); // 未完成

      final finalResult = standardParser.parseLine('');
      expect(finalResult, isNotNull);
      expect(finalResult!.hasEvent, isTrue);
    });
  });

  group('SSE Parser Performance', () {
    test('Parse large event data efficiently', () {
      final parser = SseParser();
      final largeData = 'x' * 10000; // 10KB 数据

      final stopwatch = Stopwatch()..start();

      parser.parseLine('event: large-event');
      parser.parseLine('data: $largeData');
      final result = parser.parseLine('');

      stopwatch.stop();

      expect(result, isNotNull);
      expect(result!.data, equals(largeData));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Parsing should be fast',
      );
    });

    test('Process many events quickly', () async {
      final events = <Map<String, String?>>[];

      final streamParser = SseStreamParser(
        onEvent: (type, data, id) {
          events.add({'type': type, 'data': data, 'id': id});
        },
      );

      final stopwatch = Stopwatch()..start();

      // 生成 1000 个小事件
      final lines = <String>[];
      for (int i = 0; i < 1000; i++) {
        lines.addAll(['event: event-$i', 'data: data-$i', '']);
      }

      await streamParser.parse(Stream.fromIterable(lines)).toList();

      stopwatch.stop();

      expect(events.length, 1000);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Should process 1000 events in < 1s',
      );
    });
  });
}
