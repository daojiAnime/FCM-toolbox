import '../common/logger.dart';
import 'dart:async';
import 'dart:math' show pow;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 错误类型分类
enum ErrorCategory {
  /// 网络错误 - 可重试
  network,

  /// 认证错误 - 需要用户介入
  auth,

  /// 服务器错误 - 可重试（有限次数）
  server,

  /// 客户端错误 - 不可重试
  client,

  /// 超时错误 - 可重试
  timeout,

  /// 未知错误
  unknown,
}

/// 可恢复的错误
class RecoverableError {
  const RecoverableError({
    required this.category,
    required this.message,
    this.originalError,
    this.statusCode,
    this.canRetry = true,
    this.retryDelay,
    this.userAction,
  });

  final ErrorCategory category;
  final String message;
  final Object? originalError;
  final int? statusCode;
  final bool canRetry;
  final Duration? retryDelay;
  final String? userAction; // 用户可执行的恢复操作提示

  /// 从状态码和错误信息推断错误类型
  factory RecoverableError.fromStatusCode(
    int? statusCode,
    String message, [
    Object? originalError,
  ]) {
    switch (statusCode) {
      case 401:
      case 403:
        return RecoverableError(
          category: ErrorCategory.auth,
          message: statusCode == 401 ? 'API Token 无效' : '访问被拒绝',
          statusCode: statusCode,
          originalError: originalError,
          canRetry: false,
          userAction: '请检查 hapi 配置中的 API Token',
        );
      case 404:
        return RecoverableError(
          category: ErrorCategory.client,
          message: '资源不存在',
          statusCode: statusCode,
          originalError: originalError,
          canRetry: false,
        );
      case 408:
      case 504:
        return RecoverableError(
          category: ErrorCategory.timeout,
          message: '请求超时',
          statusCode: statusCode,
          originalError: originalError,
          canRetry: true,
          retryDelay: const Duration(seconds: 2),
        );
      case 429:
        return RecoverableError(
          category: ErrorCategory.server,
          message: '请求过于频繁',
          statusCode: statusCode,
          originalError: originalError,
          canRetry: true,
          retryDelay: const Duration(seconds: 10),
          userAction: '请稍后重试',
        );
      case 500:
      case 502:
      case 503:
        return RecoverableError(
          category: ErrorCategory.server,
          message: '服务器错误',
          statusCode: statusCode,
          originalError: originalError,
          canRetry: true,
          retryDelay: const Duration(seconds: 3),
        );
      case null:
        // 网络错误（无状态码）
        return RecoverableError(
          category: ErrorCategory.network,
          message: message,
          originalError: originalError,
          canRetry: true,
          retryDelay: const Duration(seconds: 1),
          userAction: '请检查网络连接',
        );
      default:
        // default case 中 statusCode 不会是 null（已在 case null 处理）
        return RecoverableError(
          category: ErrorCategory.unknown,
          message: message,
          statusCode: statusCode,
          originalError: originalError,
          canRetry: statusCode >= 500,
        );
    }
  }

  @override
  String toString() => 'RecoverableError($category): $message';
}

/// 重试配置
class RetryConfig {
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.retryIf,
  });

  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool Function(Object error)? retryIf;

  /// 默认 API 调用重试配置
  static const apiDefault = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 10),
  );

  /// 连接类重试配置（更长的间隔）
  static const connectionDefault = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 60),
  );

  /// 计算指定尝试次数的延迟（指数退避）
  Duration delayForAttempt(int attempt) {
    final delay =
        (initialDelay.inMilliseconds * pow(backoffMultiplier, attempt - 1))
            .toInt();
    return Duration(
      milliseconds: delay.clamp(
        initialDelay.inMilliseconds,
        maxDelay.inMilliseconds,
      ),
    );
  }
}

/// 重试结果
class RetryResult<T> {
  const RetryResult._({
    required this.success,
    this.data,
    this.error,
    this.attempts = 0,
  });

  factory RetryResult.success(T data, int attempts) {
    return RetryResult._(success: true, data: data, attempts: attempts);
  }

  factory RetryResult.failure(RecoverableError error, int attempts) {
    return RetryResult._(success: false, error: error, attempts: attempts);
  }

  final bool success;
  final T? data;
  final RecoverableError? error;
  final int attempts;
}

/// 错误恢复服务
class ErrorRecoveryService {
  ErrorRecoveryService();

  /// 带重试的执行
  Future<RetryResult<T>> executeWithRetry<T>({
    required Future<T> Function() action,
    required String operationName,
    RetryConfig config = RetryConfig.apiDefault,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    int attempt = 0;
    Object? lastError;

    while (attempt < config.maxAttempts) {
      attempt++;

      try {
        final result = await action();
        return RetryResult.success(result, attempt);
      } catch (e) {
        lastError = e;
        Log.w(
          'Retry',
          '[$operationName] Attempt $attempt failed: ${e.toString().split('\n').first}',
        );

        // 检查是否应该重试
        final recoverableError = _categorizeError(e);
        if (!recoverableError.canRetry) {
          Log.w('Retry', '[$operationName] Error is not retryable');
          return RetryResult.failure(recoverableError, attempt);
        }

        // 检查自定义重试条件
        if (config.retryIf != null && !config.retryIf!(e)) {
          Log.w('Retry', '[$operationName] Custom retry condition not met');
          return RetryResult.failure(recoverableError, attempt);
        }

        // 还有重试机会
        if (attempt < config.maxAttempts) {
          final delay =
              recoverableError.retryDelay ?? config.delayForAttempt(attempt);
          Log.d(
            'Retry',
            '[$operationName] Retrying in ${delay.inSeconds}s (attempt ${attempt + 1}/${config.maxAttempts})',
          );

          onRetry?.call(attempt, e);
          await Future.delayed(delay);
        }
      }
    }

    // 所有重试都失败
    final finalError = _categorizeError(lastError!);
    Log.e(
      'Retry',
      '[$operationName] All $attempt attempts failed: ${finalError.message}',
    );
    return RetryResult.failure(finalError, attempt);
  }

  /// 分类错误
  RecoverableError _categorizeError(Object error) {
    // 检查是否已经是 RecoverableError
    if (error is RecoverableError) {
      return error;
    }

    final errorString = error.toString().toLowerCase();

    // 网络相关错误
    if (errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('host not found') ||
        errorString.contains('no internet')) {
      return RecoverableError(
        category: ErrorCategory.network,
        message: '网络连接失败',
        originalError: error,
        canRetry: true,
        userAction: '请检查网络连接',
      );
    }

    // 超时相关
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return RecoverableError(
        category: ErrorCategory.timeout,
        message: '连接超时',
        originalError: error,
        canRetry: true,
      );
    }

    // SSL/TLS 错误
    if (errorString.contains('ssl') ||
        errorString.contains('certificate') ||
        errorString.contains('handshake')) {
      return RecoverableError(
        category: ErrorCategory.network,
        message: 'SSL 连接错误',
        originalError: error,
        canRetry: false,
        userAction: '请检查服务器 SSL 证书',
      );
    }

    // 默认未知错误
    return RecoverableError(
      category: ErrorCategory.unknown,
      message: error.toString(),
      originalError: error,
      canRetry: true,
    );
  }
}

/// 错误恢复状态
class ErrorRecoveryState {
  const ErrorRecoveryState({
    this.lastError,
    this.lastErrorTime,
    this.isRecovering = false,
    this.recoveryAttempts = 0,
  });

  final RecoverableError? lastError;
  final DateTime? lastErrorTime;
  final bool isRecovering;
  final int recoveryAttempts;

  ErrorRecoveryState copyWith({
    RecoverableError? lastError,
    DateTime? lastErrorTime,
    bool? isRecovering,
    int? recoveryAttempts,
  }) {
    return ErrorRecoveryState(
      lastError: lastError ?? this.lastError,
      lastErrorTime: lastErrorTime ?? this.lastErrorTime,
      isRecovering: isRecovering ?? this.isRecovering,
      recoveryAttempts: recoveryAttempts ?? this.recoveryAttempts,
    );
  }

  /// 清除错误状态
  ErrorRecoveryState cleared() {
    return const ErrorRecoveryState();
  }
}

/// 全局错误恢复状态管理
class ErrorRecoveryNotifier extends StateNotifier<ErrorRecoveryState> {
  ErrorRecoveryNotifier() : super(const ErrorRecoveryState());

  final _service = ErrorRecoveryService();

  /// 记录错误
  void recordError(RecoverableError error) {
    state = state.copyWith(lastError: error, lastErrorTime: DateTime.now());
  }

  /// 清除错误
  void clearError() {
    state = state.cleared();
  }

  /// 开始恢复
  void startRecovery() {
    state = state.copyWith(
      isRecovering: true,
      recoveryAttempts: state.recoveryAttempts + 1,
    );
  }

  /// 结束恢复
  void endRecovery({bool success = true}) {
    state = state.copyWith(
      isRecovering: false,
      recoveryAttempts: success ? 0 : state.recoveryAttempts,
      lastError: success ? null : state.lastError,
    );
  }

  /// 带重试执行操作
  Future<RetryResult<T>> executeWithRetry<T>({
    required Future<T> Function() action,
    required String operationName,
    RetryConfig config = RetryConfig.apiDefault,
  }) async {
    startRecovery();

    final result = await _service.executeWithRetry(
      action: action,
      operationName: operationName,
      config: config,
      onRetry: (attempt, error) {
        state = state.copyWith(recoveryAttempts: attempt);
      },
    );

    if (result.success) {
      endRecovery(success: true);
    } else {
      recordError(result.error!);
      endRecovery(success: false);
    }

    return result;
  }
}

/// 错误恢复服务 Provider
final errorRecoveryServiceProvider = Provider<ErrorRecoveryService>((ref) {
  return ErrorRecoveryService();
});

/// 错误恢复状态 Provider
final errorRecoveryProvider =
    StateNotifierProvider<ErrorRecoveryNotifier, ErrorRecoveryState>((ref) {
      return ErrorRecoveryNotifier();
    });

/// 最后一个错误 Provider
final lastErrorProvider = Provider<RecoverableError?>((ref) {
  return ref.watch(errorRecoveryProvider).lastError;
});

/// 是否正在恢复 Provider
final isRecoveringProvider = Provider<bool>((ref) {
  return ref.watch(errorRecoveryProvider).isRecovering;
});
