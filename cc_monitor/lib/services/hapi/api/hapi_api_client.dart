import 'dart:async';

import '../../../common/logger.dart';
import 'package:dio/dio.dart';

import '../../../models/hapi/hapi.dart';
import '../hapi_config_service.dart';
import '../../error_recovery_service.dart';
import '../../cache_service.dart';

/// HAPI 基础 API 客户端
/// 封装 Dio、JWT 管理、重试逻辑和错误处理
class HapiApiClient {
  HapiApiClient(this.config, [this.errorRecoveryService, this.cacheService]) {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    // 添加拦截器
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 跳过 /api/auth 端点的认证（用于获取 JWT）
          if (options.path.endsWith('/auth')) {
            Log.i('HapiCli', '${options.method} ${options.uri} (auth request)');
            return handler.next(options);
          }

          // 确保有有效的 JWT token
          final jwtToken = await ensureValidJwt();
          if (jwtToken != null) {
            options.headers['Authorization'] = 'Bearer $jwtToken';
          } else {
            Log.i('HapiCli', 'WARNING: No valid JWT token!');
          }
          Log.i('HapiCli', '${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          Log.i('HapiCli', 'Response: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          // 如果是 401 错误，尝试刷新 token 并重试（最多 3 次）
          final retryCount =
              error.requestOptions.extra['_retryCount'] as int? ?? 0;
          final isRefreshing = _refreshCompleter != null;
          if (error.response?.statusCode == 401 &&
              retryCount < 3 &&
              !isRefreshing) {
            Log.i(
              'HapiCli',
              '401 error (attempt ${retryCount + 1}/3), refreshing JWT...',
            );
            _jwtToken = null;
            _jwtExpiry = null;

            // 指数退避：100ms, 200ms, 400ms
            if (retryCount > 0) {
              await Future.delayed(
                Duration(milliseconds: 100 * (1 << retryCount)),
              );
            }

            final newToken = await ensureValidJwt();
            if (newToken != null) {
              // 重试请求
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newToken';
              opts.extra['_retryCount'] = retryCount + 1;
              try {
                final response = await dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                Log.i('HapiCli', 'Retry failed: $e');
                return handler.next(error);
              }
            }
          }
          Log.i('HapiCli', 'Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  final HapiConfig config;
  final ErrorRecoveryService? errorRecoveryService;
  final CacheService? cacheService;
  late final Dio dio;

  // JWT token 管理 (Singleton 模式 - 并发安全)
  String? _jwtToken;
  DateTime? _jwtExpiry;
  Completer<String?>? _refreshCompleter; // 使用 Completer 确保并发安全

  /// 确保有有效的 JWT token
  Future<String?> ensureValidJwt() async {
    // 如果 token 有效且未过期（提前 1 分钟刷新）
    if (_jwtToken != null &&
        _jwtExpiry != null &&
        _jwtExpiry!.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return _jwtToken;
    }

    // 需要获取新的 JWT
    return _refreshJwt();
  }

  /// 获取有效的 JWT token（供 SSE 服务等外部使用）
  Future<String?> getJwtToken() async {
    return ensureValidJwt();
  }

  /// 用 CLI_API_TOKEN 换取 JWT (并发安全)
  /// 使用 Completer 确保多个并发请求共享同一个刷新结果
  Future<String?> _refreshJwt() async {
    // 如果已有正在进行的刷新，等待其完成
    if (_refreshCompleter != null) {
      Log.i('HapiCli', 'JWT refresh already in progress, waiting...');
      return _refreshCompleter!.future;
    }

    if (config.apiToken.isEmpty) {
      Log.i('HapiCli', 'Cannot refresh JWT: no API token configured');
      return null;
    }

    // 创建新的 Completer，所有后续请求都会等待这个结果
    _refreshCompleter = Completer<String?>();

    try {
      Log.i('HapiCli', 'Refreshing JWT token...');
      final response = await dio.post(
        apiUrl('/auth'),
        data: {'accessToken': config.apiToken},
      );

      if (response.statusCode == 200 && response.data is Map) {
        _jwtToken = response.data['token'] as String?;
        // JWT 有效期 15 分钟
        _jwtExpiry = DateTime.now().add(const Duration(minutes: 15));
        Log.i('HapiCli', 'JWT refreshed successfully');
        _refreshCompleter!.complete(_jwtToken);
        return _jwtToken;
      }
      // 请求成功但格式不对
      _refreshCompleter!.complete(null);
      return null;
    } on DioException catch (e) {
      Log.i('HapiCli', 'Failed to refresh JWT: ${e.message}');
      if (e.response?.statusCode == 401) {
        Log.i('HapiCli', 'CLI_API_TOKEN is invalid');
      }
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      // 重置 Completer，允许下一次刷新
      _refreshCompleter = null;
    }
  }

  /// 获取完整 API URL
  String apiUrl(String path) {
    var baseUrl = config.serverUrl;
    if (baseUrl.isEmpty) {
      throw HapiApiException('Server URL not configured');
    }
    // 移除尾部斜杠，避免双斜杠问题
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return '$baseUrl/api$path';
  }

  /// 带重试的请求包装器
  Future<T> withRetry<T>({
    required Future<T> Function() action,
    required String operationName,
    RetryConfig config = RetryConfig.apiDefault,
  }) async {
    if (errorRecoveryService == null) {
      // 没有重试服务，直接执行
      return action();
    }

    final result = await errorRecoveryService!.executeWithRetry(
      action: action,
      operationName: operationName,
      config: config,
    );

    if (result.success) {
      return result.data as T;
    } else {
      throw HapiApiException(
        result.error?.message ?? 'Request failed',
        statusCode: result.error?.statusCode,
        originalError: result.error?.originalError,
        isRetryable: false, // 已经重试过了
      );
    }
  }

  /// 处理 Dio 错误
  HapiApiException handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return HapiApiException(
          '连接超时',
          statusCode: null,
          originalError: e,
          isRetryable: true,
          userAction: '请检查网络连接',
        );

      case DioExceptionType.connectionError:
        return HapiApiException(
          '无法连接到服务器',
          statusCode: null,
          originalError: e,
          isRetryable: true,
          userAction: '请检查服务器地址和网络连接',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        String message;
        String? userAction;
        bool isRetryable = true;

        switch (statusCode) {
          case 401:
            message = 'API Token 无效';
            userAction = '请检查 hapi 配置中的 Token';
            isRetryable = false;
            break;
          case 403:
            message = '访问被拒绝';
            userAction = '请检查 API Token 权限';
            isRetryable = false;
            break;
          case 404:
            message = '资源不存在';
            isRetryable = false;
            break;
          case 429:
            message = '请求过于频繁';
            userAction = '请稍后重试';
            isRetryable = true;
            break;
          case 500:
          case 502:
          case 503:
            message = '服务器错误';
            userAction = '请稍后重试或检查服务器状态';
            isRetryable = true;
            break;
          default:
            message = '请求失败: ${e.response?.statusMessage}';
            isRetryable = statusCode == null || statusCode >= 500;
        }
        return HapiApiException(
          message,
          statusCode: statusCode,
          originalError: e,
          isRetryable: isRetryable,
          userAction: userAction,
        );

      case DioExceptionType.cancel:
        return HapiApiException('请求已取消', originalError: e, isRetryable: false);

      default:
        return HapiApiException(
          e.message ?? '未知错误',
          originalError: e,
          isRetryable: true,
        );
    }
  }
}
