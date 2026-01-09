import 'dart:async';
import 'dart:math';
import '../common/logger.dart';

/// 错误恢复策略接口 (Strategy 模式)
/// 定义不同的重试和恢复策略
abstract class ErrorRecoveryStrategy {
  /// 执行操作并处理错误恢复
  Future<T> execute<T>(Future<T> Function() operation);

  /// 是否应该重试
  bool shouldRetry(Object error, int attempt);
}

/// 指数退避策略
/// 每次重试等待时间呈指数增长，带有随机抖动
class ExponentialBackoffStrategy implements ErrorRecoveryStrategy {
  ExponentialBackoffStrategy({
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.multiplier = 2.0,
    this.jitterFactor = 0.25,
    this.retryableErrors,
  });

  /// 初始延迟
  final Duration initialDelay;

  /// 最大延迟
  final Duration maxDelay;

  /// 最大重试次数
  final int maxRetries;

  /// 延迟增长倍数
  final double multiplier;

  /// 抖动因子 (0-1)
  final double jitterFactor;

  /// 可重试的错误类型
  final Set<Type>? retryableErrors;

  final _random = Random();

  @override
  Future<T> execute<T>(Future<T> Function() operation) async {
    var attempt = 0;
    Object? lastError;

    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        lastError = e;
        attempt++;

        if (!shouldRetry(e, attempt)) {
          Log.w('ExpBackoff', 'Not retrying: $e (attempt $attempt)');
          rethrow;
        }

        if (attempt > maxRetries) {
          Log.e('ExpBackoff', 'Max retries exceeded', e, stackTrace);
          rethrow;
        }

        final delay = _calculateDelay(attempt);
        Log.w(
          'ExpBackoff',
          'Retry $attempt/$maxRetries in ${delay.inMilliseconds}ms',
        );
        await Future<void>.delayed(delay);
      }
    }

    // 理论上不应该到达这里
    throw lastError ?? StateError('Unexpected state in retry loop');
  }

  @override
  bool shouldRetry(Object error, int attempt) {
    if (attempt > maxRetries) return false;
    if (retryableErrors == null) return true;
    return retryableErrors!.contains(error.runtimeType);
  }

  Duration _calculateDelay(int attempt) {
    // 指数增长
    final exponentialDelay =
        initialDelay.inMilliseconds * pow(multiplier, attempt - 1);

    // 添加随机抖动
    final jitter =
        exponentialDelay * jitterFactor * (2 * _random.nextDouble() - 1);
    final delayMs = (exponentialDelay + jitter).toInt();

    // 限制最大延迟
    return Duration(milliseconds: min(delayMs, maxDelay.inMilliseconds));
  }
}

/// 立即重试策略
/// 立即重试，不等待
class ImmediateRetryStrategy implements ErrorRecoveryStrategy {
  ImmediateRetryStrategy({this.maxRetries = 1, this.retryableErrors});

  final int maxRetries;
  final Set<Type>? retryableErrors;

  @override
  Future<T> execute<T>(Future<T> Function() operation) async {
    var attempt = 0;

    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        attempt++;

        if (!shouldRetry(e, attempt)) {
          rethrow;
        }

        if (attempt > maxRetries) {
          Log.e('ImmediateRetry', 'Max retries exceeded', e, stackTrace);
          rethrow;
        }

        Log.w('ImmediateRetry', 'Retry $attempt/$maxRetries');
      }
    }

    throw StateError('Unexpected state in retry loop');
  }

  @override
  bool shouldRetry(Object error, int attempt) {
    if (attempt > maxRetries) return false;
    if (retryableErrors == null) return true;
    return retryableErrors!.contains(error.runtimeType);
  }
}

/// 无重试策略
/// 直接执行，不进行任何重试
class NoRetryStrategy implements ErrorRecoveryStrategy {
  const NoRetryStrategy();

  @override
  Future<T> execute<T>(Future<T> Function() operation) => operation();

  @override
  bool shouldRetry(Object error, int attempt) => false;
}

/// 预设策略工厂
class RecoveryStrategies {
  RecoveryStrategies._();

  /// API 请求默认策略
  static ErrorRecoveryStrategy get apiDefault => ExponentialBackoffStrategy(
    initialDelay: const Duration(milliseconds: 500),
    maxRetries: 3,
  );

  /// 连接重试策略
  static ErrorRecoveryStrategy get connection => ExponentialBackoffStrategy(
    initialDelay: const Duration(seconds: 1),
    maxDelay: const Duration(seconds: 30),
    maxRetries: 10,
  );

  /// 快速重试策略
  static ErrorRecoveryStrategy get quick => ExponentialBackoffStrategy(
    initialDelay: const Duration(milliseconds: 100),
    maxRetries: 2,
  );

  /// 无重试策略
  static ErrorRecoveryStrategy get none => const NoRetryStrategy();
}
