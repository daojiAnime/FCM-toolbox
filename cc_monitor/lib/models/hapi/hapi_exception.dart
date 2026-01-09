/// HAPI API 异常
class HapiApiException implements Exception {
  HapiApiException(
    this.message, {
    this.statusCode,
    this.originalError,
    this.isRetryable = true,
    this.userAction,
  });

  final String message;
  final int? statusCode;
  final Object? originalError;
  final bool isRetryable;
  final String? userAction; // 用户可以执行的恢复操作

  /// 获取用户友好的错误消息
  String get userMessage {
    if (userAction != null) {
      return '$message。$userAction';
    }
    return message;
  }

  @override
  String toString() => 'HapiApiException: $message (code: $statusCode)';
}
