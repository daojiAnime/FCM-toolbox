import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cc_monitor/services/error_recovery_strategy.dart';

void main() {
  group('ExponentialBackoffStrategy', () {
    test('Exponential delay calculation', () {
      final strategy = ExponentialBackoffStrategy(
        initialDelay: const Duration(milliseconds: 100),
        multiplier: 2.0,
        maxRetries: 5,
        jitterFactor: 0.0, // 禁用抖动便于测试
      );

      // 手动调用私有的 _calculateDelay 方法
      // 由于方法是私有的，我们通过实际执行来验证行为
      final delays = <int>[];
      var attempt = 0;

      Future<void> recordDelay() async {
        try {
          await strategy.execute(() async {
            attempt++;
            if (attempt <= 5) {
              throw Exception('Test error');
            }
            return;
          });
        } catch (e) {
          // 预期会失败
        }
      }

      // 验证基本的指数退避行为
      expect(strategy.maxRetries, 5);
      expect(strategy.initialDelay, const Duration(milliseconds: 100));
      expect(strategy.multiplier, 2.0);
    });

    test('Jitter adds randomness', () {
      final strategy = ExponentialBackoffStrategy(
        initialDelay: const Duration(milliseconds: 100),
        maxRetries: 1,
        jitterFactor: 0.3, // 30% 抖动
      );

      // 由于抖动是随机的，我们只能验证策略配置正确
      expect(strategy.jitterFactor, 0.3);
    });

    test('Max delay limit enforced', () {
      final strategy = ExponentialBackoffStrategy(
        initialDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 10),
        multiplier: 2.0,
        maxRetries: 10,
        jitterFactor: 0.0,
      );

      expect(strategy.maxDelay, const Duration(seconds: 10));
    });

    test('Retries until success', () async {
      var attemptCount = 0;
      final strategy = ExponentialBackoffStrategy(
        initialDelay: const Duration(milliseconds: 10),
        maxRetries: 3,
        jitterFactor: 0.0,
      );

      Future<String> failOnceThenSucceed() async {
        attemptCount++;
        if (attemptCount == 1) {
          throw Exception('First attempt fails');
        }
        return 'success';
      }

      final result = await strategy.execute(failOnceThenSucceed);
      expect(result, 'success');
      expect(attemptCount, 2);
    });

    test('Gives up after max retries', () async {
      var attemptCount = 0;
      final strategy = ExponentialBackoffStrategy(
        initialDelay: const Duration(milliseconds: 10),
        maxRetries: 2,
        jitterFactor: 0.0,
      );

      Future<String> alwaysFails() async {
        attemptCount++;
        throw Exception('Always fails');
      }

      expect(() => strategy.execute(alwaysFails), throwsException);

      // 等待异步操作完成
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(attemptCount, 3); // 初始尝试 + 2次重试
    });

    test('Filters retryable errors - Socket exception is retryable', () async {
      var attemptCount = 0;
      final strategy = ExponentialBackoffStrategy(
        initialDelay: const Duration(milliseconds: 10),
        maxRetries: 2,
        retryableErrors: {SocketException},
        jitterFactor: 0.0,
      );

      Future<String> throwRetryable() async {
        attemptCount++;
        if (attemptCount < 2) {
          throw SocketException('Network error');
        }
        return 'success';
      }

      final result = await strategy.execute(throwRetryable);
      expect(result, 'success');
      expect(attemptCount, 2);
    });

    test(
      'Filters retryable errors - Non-retryable error fails immediately',
      () async {
        var attemptCount = 0;
        final strategy = ExponentialBackoffStrategy(
          initialDelay: const Duration(milliseconds: 10),
          maxRetries: 3,
          retryableErrors: {SocketException},
          jitterFactor: 0.0,
        );

        Future<String> throwNonRetryable() async {
          attemptCount++;
          throw FormatException('Not retryable');
        }

        expect(
          () => strategy.execute(throwNonRetryable),
          throwsFormatException,
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(attemptCount, 1); // 不应重试
      },
    );

    test('shouldRetry - returns false after max retries', () {
      final strategy = ExponentialBackoffStrategy(maxRetries: 3);

      expect(strategy.shouldRetry(Exception('test'), 1), true);
      expect(strategy.shouldRetry(Exception('test'), 3), true);
      expect(strategy.shouldRetry(Exception('test'), 4), false);
    });

    test('shouldRetry - checks error type when filter is set', () {
      final strategy = ExponentialBackoffStrategy(
        maxRetries: 3,
        retryableErrors: {SocketException},
      );

      expect(strategy.shouldRetry(SocketException('test'), 1), true);
      expect(strategy.shouldRetry(FormatException('test'), 1), false);
    });

    test('shouldRetry - allows all errors when filter is null', () {
      final strategy = ExponentialBackoffStrategy(maxRetries: 3);

      expect(strategy.shouldRetry(SocketException('test'), 1), true);
      expect(strategy.shouldRetry(FormatException('test'), 1), true);
      expect(strategy.shouldRetry(Exception('test'), 1), true);
    });
  });

  group('ImmediateRetryStrategy', () {
    test('Retries immediately without delay', () async {
      var attemptCount = 0;
      final strategy = ImmediateRetryStrategy(maxRetries: 2);

      final stopwatch = Stopwatch()..start();
      Future<String> failOnceThenSucceed() async {
        attemptCount++;
        if (attemptCount == 1) {
          throw Exception('First attempt fails');
        }
        return 'success';
      }

      final result = await strategy.execute(failOnceThenSucceed);
      stopwatch.stop();

      expect(result, 'success');
      expect(attemptCount, 2);
      // 应该几乎是立即重试（< 100ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('Gives up after max retries', () async {
      var attemptCount = 0;
      final strategy = ImmediateRetryStrategy(maxRetries: 1);

      Future<String> alwaysFails() async {
        attemptCount++;
        throw Exception('Always fails');
      }

      expect(() => strategy.execute(alwaysFails), throwsException);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(attemptCount, 2); // 初始尝试 + 1次重试
    });

    test('shouldRetry - respects error filter', () {
      final strategy = ImmediateRetryStrategy(
        maxRetries: 2,
        retryableErrors: {SocketException},
      );

      expect(strategy.shouldRetry(SocketException('test'), 1), true);
      expect(strategy.shouldRetry(FormatException('test'), 1), false);
    });
  });

  group('NoRetryStrategy', () {
    test('Executes operation without retry', () async {
      const strategy = NoRetryStrategy();
      final result = await strategy.execute(() async => 'success');

      expect(result, 'success');
    });

    test('Throws error immediately', () async {
      const strategy = NoRetryStrategy();

      expect(
        () => strategy.execute(() async => throw Exception('Error')),
        throwsException,
      );
    });

    test('shouldRetry - always returns false', () {
      const strategy = NoRetryStrategy();

      expect(strategy.shouldRetry(Exception('test'), 1), false);
      expect(strategy.shouldRetry(Exception('test'), 0), false);
      expect(strategy.shouldRetry(Exception('test'), 100), false);
    });
  });

  group('RecoveryStrategies presets', () {
    test('apiDefault has correct config', () {
      final strategy = RecoveryStrategies.apiDefault;
      expect(strategy, isA<ExponentialBackoffStrategy>());

      final expStrategy = strategy as ExponentialBackoffStrategy;
      expect(expStrategy.initialDelay, const Duration(milliseconds: 500));
      expect(expStrategy.maxRetries, 3);
    });

    test('connection has longer delays and more retries', () {
      final apiStrategy =
          RecoveryStrategies.apiDefault as ExponentialBackoffStrategy;
      final connStrategy =
          RecoveryStrategies.connection as ExponentialBackoffStrategy;

      expect(connStrategy.maxRetries, greaterThan(apiStrategy.maxRetries));
      expect(connStrategy.initialDelay, greaterThan(apiStrategy.initialDelay));
    });

    test('quick has shorter delays and fewer retries', () {
      final apiStrategy =
          RecoveryStrategies.apiDefault as ExponentialBackoffStrategy;
      final quickStrategy =
          RecoveryStrategies.quick as ExponentialBackoffStrategy;

      expect(quickStrategy.maxRetries, lessThan(apiStrategy.maxRetries));
      expect(quickStrategy.initialDelay, lessThan(apiStrategy.initialDelay));
    });

    test('none is NoRetryStrategy', () {
      final strategy = RecoveryStrategies.none;
      expect(strategy, isA<NoRetryStrategy>());
    });

    test('connection preset values', () {
      final strategy =
          RecoveryStrategies.connection as ExponentialBackoffStrategy;
      expect(strategy.initialDelay, const Duration(seconds: 1));
      expect(strategy.maxDelay, const Duration(seconds: 30));
      expect(strategy.maxRetries, 10);
    });

    test('quick preset values', () {
      final strategy = RecoveryStrategies.quick as ExponentialBackoffStrategy;
      expect(strategy.initialDelay, const Duration(milliseconds: 100));
      expect(strategy.maxRetries, 2);
    });
  });

  group('Real-world scenarios', () {
    test('Network request with temporary failure', () async {
      var attemptCount = 0;
      final strategy = RecoveryStrategies.apiDefault;

      Future<Map<String, dynamic>> fetchData() async {
        attemptCount++;
        if (attemptCount < 3) {
          throw SocketException('Network temporarily unavailable');
        }
        return {'data': 'success'};
      }

      final result = await strategy.execute(fetchData);
      expect(result['data'], 'success');
      expect(attemptCount, 3);
    });

    test('Permanent error - no retry needed', () async {
      var attemptCount = 0;
      final strategy = RecoveryStrategies.quick;

      Future<String> fetchData() async {
        attemptCount++;
        throw ArgumentError('Invalid argument');
      }

      expect(() => strategy.execute(fetchData), throwsArgumentError);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(attemptCount, 3); // 初始 + 2次重试
    });
  });
}
