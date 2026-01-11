import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cc_monitor/services/hapi/sse_parser.dart';

void main() {
  group('SseParser', () {
    late SseParser parser;

    setUp(() {
      parser = SseParser();
    });

    test('Parses simple event', () {
      final result1 = parser.parseLine('data: Hello');
      final result2 = parser.parseLine('');

      expect(result1, isNull); // 未完成
      expect(result2, isA<SseParseResult>());
      expect(result2!.hasEvent, true);
      expect(result2.data, 'Hello');
      expect(result2.eventType, 'message'); // 默认类型
    });

    test('Parses custom event type', () {
      parser.parseLine('event: custom');
      parser.parseLine('data: payload');
      final result = parser.parseLine('');

      expect(result, isNotNull);
      expect(result!.eventType, 'custom');
      expect(result.data, 'payload');
    });

    test('Handles multi-line data', () {
      parser.parseLine('data: line1');
      parser.parseLine('data: line2');
      parser.parseLine('data: line3');
      final result = parser.parseLine('');

      expect(result, isNotNull);
      expect(result!.data, 'line1\nline2\nline3');
    });

    test('Parses event ID', () {
      parser.parseLine('id: 12345');
      parser.parseLine('data: test');
      final result = parser.parseLine('');

      expect(result, isNotNull);
      expect(result!.eventId, '12345');
      expect(parser.lastEventId, '12345');
    });

    test('Parses retry delay', () {
      final result = parser.parseLine('retry: 5000');

      expect(result, isA<SseParseResult>());
      expect(result!.retryDelay, const Duration(milliseconds: 5000));
      expect(result.hasEvent, false);
    });

    test('Ignores comment lines', () {
      parser.parseLine(': This is a comment');
      parser.parseLine('data: actual data');
      final result = parser.parseLine('');

      expect(result, isNotNull);
      expect(result!.data, 'actual data');
    });

    test('Strips leading space after colon', () {
      parser.parseLine('data:  spaces'); // 两个空格
      final result = parser.parseLine('');

      expect(result, isNotNull);
      expect(result!.data, ' spaces'); // 只保留一个空格
    });

    test('Handles field without colon', () {
      final result = parser.parseLine('data');
      expect(result, isNull); // 空值，不会产生事件
    });

    test('Ignores unknown fields', () {
      parser.parseLine('unknown: value');
      parser.parseLine('data: test');
      final result = parser.parseLine('');

      expect(result, isNotNull);
      expect(result!.data, 'test');
    });

    test('Empty id does not update lastEventId', () {
      parser.parseLine('id: 123');
      parser.parseLine('data: test1');
      parser.parseLine('');

      expect(parser.lastEventId, '123');

      parser.parseLine('id: '); // 空 id
      parser.parseLine('data: test2');
      parser.parseLine('');

      expect(parser.lastEventId, '123'); // 保持不变
    });

    test('Invalid retry value is ignored', () {
      final result1 = parser.parseLine('retry: invalid');
      final result2 = parser.parseLine('retry: -100');
      final result3 = parser.parseLine('retry: 0');

      expect(result1, isNull);
      expect(result2, isNull);
      expect(result3, isNull);
    });

    test('Event type resets to default after emission', () {
      parser.parseLine('event: custom');
      parser.parseLine('data: test1');
      parser.parseLine('');

      // 下一个事件应该使用默认类型
      parser.parseLine('data: test2');
      final result = parser.parseLine('');

      expect(result, isNotNull);
      expect(result!.eventType, 'message');
    });

    test('Reset clears parser state', () {
      parser.parseLine('event: custom');
      parser.parseLine('data: partial');
      parser.parseLine('id: 999');

      parser.reset();

      expect(parser.bufferSize, 0);
      expect(parser.lastEventId, null);

      parser.parseLine('data: new');
      final result = parser.parseLine('');

      expect(result, isNotNull);
      expect(result!.eventType, 'message');
      expect(result.data, 'new');
      expect(result.eventId, null);
    });

    test('bufferSize reflects data buffer length', () {
      expect(parser.bufferSize, 0);

      parser.parseLine('data: test');
      expect(parser.bufferSize, 4);

      parser.parseLine('data: more');
      expect(parser.bufferSize, 9); // "test\nmore"

      parser.parseLine('');
      expect(parser.bufferSize, 0); // 重置
    });

    test('Empty line without data does not emit event', () {
      final result = parser.parseLine('');
      expect(result, isNull);
    });

    test('Multiple events in sequence', () {
      // Event 1
      parser.parseLine('event: type1');
      parser.parseLine('data: data1');
      final result1 = parser.parseLine('');
      expect(result1!.eventType, 'type1');
      expect(result1.data, 'data1');

      // Event 2
      parser.parseLine('event: type2');
      parser.parseLine('data: data2');
      final result2 = parser.parseLine('');
      expect(result2!.eventType, 'type2');
      expect(result2.data, 'data2');

      // Event 3 (default type)
      parser.parseLine('data: data3');
      final result3 = parser.parseLine('');
      expect(result3!.eventType, 'message');
      expect(result3.data, 'data3');
    });

    test('Custom default event type', () {
      final customParser = SseParser(defaultEventType: 'custom-default');

      customParser.parseLine('data: test');
      final result = customParser.parseLine('');

      expect(result, isNotNull);
      expect(result!.eventType, 'custom-default');
    });
  });

  group('SseStreamParser', () {
    test('Processes stream of lines', () async {
      final events = <SseParseResult>[];
      final parser = SseStreamParser(
        onEvent: (type, data, id) {
          // 回调被触发
        },
      );

      final controller = StreamController<String>();
      final stream = parser.parse(controller.stream);

      stream.listen((result) {
        if (result.hasEvent) {
          events.add(result);
        }
      });

      controller.add('event: test');
      controller.add('data: line1');
      controller.add('data: line2');
      controller.add('');
      controller.add('data: another');
      controller.add('');

      await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events.length, 2);
      expect(events[0].eventType, 'test');
      expect(events[0].data, 'line1\nline2');
      expect(events[1].eventType, 'message');
      expect(events[1].data, 'another');
    });

    test('onEvent callback is called', () async {
      final receivedEvents = <Map<String, dynamic>>[];

      final parser = SseStreamParser(
        onEvent: (type, data, id) {
          receivedEvents.add({'type': type, 'data': data, 'id': id});
        },
      );

      final controller = StreamController<String>();
      parser.parse(controller.stream).listen((_) {});

      controller.add('id: 123');
      controller.add('data: test');
      controller.add('');

      await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(receivedEvents.length, 1);
      expect(receivedEvents[0]['type'], 'message');
      expect(receivedEvents[0]['data'], 'test');
      expect(receivedEvents[0]['id'], '123');
    });

    test('onRetryDelay callback is called', () async {
      Duration? receivedDelay;

      final parser = SseStreamParser(
        onRetryDelay: (delay) {
          receivedDelay = delay;
        },
      );

      final controller = StreamController<String>();
      parser.parse(controller.stream).listen((_) {});

      controller.add('retry: 3000');

      await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(receivedDelay, const Duration(milliseconds: 3000));
    });

    test('onError callback is called on error', () async {
      Object? receivedError;

      final parser = SseStreamParser(
        onError: (error, stackTrace) {
          receivedError = error;
        },
      );

      final controller = StreamController<String>();
      parser
          .parse(controller.stream)
          .listen(
            (_) {},
            onError: (_) {}, // 忽略错误
          );

      controller.addError(Exception('Test error'));

      await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(receivedError, isA<Exception>());
    });

    test('Emits partial event on stream close', () async {
      final events = <SseParseResult>[];
      final parser = SseStreamParser();

      final controller = StreamController<String>();
      final stream = parser.parse(controller.stream);

      stream.listen((result) {
        if (result.hasEvent) {
          events.add(result);
        }
      });

      controller.add('data: incomplete event');
      // 不发送空行，直接关闭流

      await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events.length, 1);
      expect(events[0].data, 'incomplete event');
    });

    test('Reset clears parser state', () async {
      final parser = SseStreamParser();

      // 第一个流 - 添加 partial 数据然后 reset
      final controller1 = StreamController<String>();
      parser.parse(controller1.stream).listen((_) {});

      controller1.add('data: partial');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      parser.reset();
      await controller1.close();

      // 第二个流 - reset 后应该从干净状态开始
      final controller2 = StreamController<String>();
      final events = <SseParseResult>[];

      parser.parse(controller2.stream).listen((result) {
        if (result.hasEvent) {
          events.add(result);
        }
      });

      controller2.add('data: new');
      controller2.add('');

      await controller2.close();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Reset 应该清空之前的缓冲，所以只有一个事件
      expect(events.length, 1);
      expect(events[0].data, 'new');
    });
  });

  group('SseParseResult', () {
    test('empty constant has correct values', () {
      const result = SseParseResult.empty;
      expect(result.hasEvent, false);
      expect(result.eventType, null);
      expect(result.data, null);
      expect(result.eventId, null);
      expect(result.retryDelay, null);
    });

    test('event factory creates correct result', () {
      final result = SseParseResult.event(
        eventType: 'test',
        data: 'test data',
        eventId: '123',
      );

      expect(result.hasEvent, true);
      expect(result.eventType, 'test');
      expect(result.data, 'test data');
      expect(result.eventId, '123');
      expect(result.retryDelay, null);
    });

    test('retry factory creates correct result', () {
      final result = SseParseResult.retry(const Duration(seconds: 5));

      expect(result.hasEvent, false);
      expect(result.retryDelay, const Duration(seconds: 5));
      expect(result.eventType, null);
      expect(result.data, null);
    });
  });

  group('SseParserFactory', () {
    test('createStandard returns SseParser', () {
      final parser = SseParserFactory.createStandard();
      expect(parser, isA<SseParser>());
    });

    test('createStreamParser returns SseStreamParser', () {
      final parser = SseParserFactory.createStreamParser();
      expect(parser, isA<SseStreamParser>());
    });

    test('createStreamParser with callbacks', () {
      var eventCalled = false;
      var retryCalled = false;
      var errorCalled = false;

      final parser = SseParserFactory.createStreamParser(
        onEvent: (type, data, id) => eventCalled = true,
        onRetryDelay: (delay) => retryCalled = true,
        onError: (error, stackTrace) => errorCalled = true,
      );

      expect(parser, isA<SseStreamParser>());
    });

    test('createStreamParser with custom default event type', () async {
      final events = <String>[];

      final parser = SseParserFactory.createStreamParser(
        defaultEventType: 'custom',
        onEvent: (type, data, id) => events.add(type),
      );

      final controller = StreamController<String>();
      parser.parse(controller.stream).listen((_) {});

      controller.add('data: test');
      controller.add('');

      await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events, contains('custom'));
    });
  });

  group('W3C SSE Spec Compliance', () {
    late SseParser parser;

    setUp(() {
      parser = SseParser();
    });

    test('Event stream interpretation - Example 1', () {
      // From W3C spec: simple message
      parser.parseLine('data: This is the first message.');
      final result = parser.parseLine('');

      expect(result, isNotNull);
      expect(result!.data, 'This is the first message.');
    });

    test('Event stream interpretation - Example 2', () {
      // Multi-line data
      parser.parseLine('data: first line');
      parser.parseLine('data: second line');
      final result = parser.parseLine('');

      expect(result, isNotNull);
      expect(result!.data, 'first line\nsecond line');
    });

    test('Event stream interpretation - Example 3', () {
      // Named event
      parser.parseLine('event: userconnect');
      parser.parseLine('data: {"username": "bobby"}');
      final result = parser.parseLine('');

      expect(result, isNotNull);
      expect(result!.eventType, 'userconnect');
      expect(result.data, '{"username": "bobby"}');
    });

    test('Event stream interpretation - Example 4', () {
      // With id and retry
      parser.parseLine('id: msg1');
      parser.parseLine('retry: 10000');
      parser.parseLine('data: hello world');
      final result = parser.parseLine('');

      expect(result, isNotNull);
      expect(result!.eventId, 'msg1');
      expect(result.data, 'hello world');
      expect(parser.lastEventId, 'msg1');
    });

    test('Event stream interpretation - Example 5', () {
      // Comment lines
      parser.parseLine(': test stream');
      parser.parseLine('data: first event');
      parser.parseLine('id: 1');
      final result = parser.parseLine('');

      expect(result, isNotNull);
      expect(result!.data, 'first event');
      expect(result.eventId, '1');
    });
  });
}
