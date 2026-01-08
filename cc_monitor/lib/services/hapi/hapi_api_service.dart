import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hapi_config_service.dart';

/// hapi API 服务 - 与 hapi server REST API 交互
class HapiApiService {
  HapiApiService(this._config) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    // 添加拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 添加认证 header
          if (_config.apiToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${_config.apiToken}';
          }
          debugPrint('[HAPI] ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('[HAPI] Response: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('[HAPI] Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  final HapiConfig _config;
  late final Dio _dio;

  /// 获取完整 API URL
  String _apiUrl(String path) {
    final baseUrl = _config.serverUrl;
    if (baseUrl.isEmpty) {
      throw HapiApiException('Server URL not configured');
    }
    return '$baseUrl/api$path';
  }

  /// 测试连接
  /// 返回服务器信息或抛出异常
  Future<HapiHealthResponse> testConnection() async {
    try {
      // 尝试获取 sessions 列表来验证连接
      final response = await _dio.get(_apiUrl('/sessions'));

      if (response.statusCode == 200) {
        return HapiHealthResponse(
          success: true,
          message: 'Connected to hapi server',
          data: response.data,
        );
      } else {
        throw HapiApiException(
          'Unexpected status code: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 获取会话列表
  Future<List<Map<String, dynamic>>> getSessions() async {
    try {
      final response = await _dio.get(_apiUrl('/sessions'));
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 获取会话详情
  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    try {
      final response = await _dio.get(_apiUrl('/sessions/$sessionId'));
      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 发送消息到会话
  Future<bool> sendMessage(String sessionId, String message) async {
    try {
      final response = await _dio.post(
        _apiUrl('/sessions/$sessionId/message'),
        data: {'message': message},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 响应权限请求
  Future<bool> respondPermission({
    required String sessionId,
    required String requestId,
    required bool approved,
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        _apiUrl('/sessions/$sessionId/permissions/$requestId'),
        data: {'approved': approved, if (reason != null) 'reason': reason},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 获取机器列表
  Future<List<Map<String, dynamic>>> getMachines() async {
    try {
      final response = await _dio.get(_apiUrl('/machines'));
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 远程启动会话
  Future<Map<String, dynamic>?> spawnSession({
    required String machineId,
    String? projectPath,
    String? model,
  }) async {
    try {
      final response = await _dio.post(
        _apiUrl('/machines/$machineId/spawn'),
        data: {
          if (projectPath != null) 'projectPath': projectPath,
          if (model != null) 'model': model,
        },
      );
      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 处理 Dio 错误
  HapiApiException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return HapiApiException(
          'Connection timeout. Please check your network.',
          statusCode: null,
          originalError: e,
        );

      case DioExceptionType.connectionError:
        return HapiApiException(
          'Cannot connect to server. Please check the URL.',
          statusCode: null,
          originalError: e,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        String message;
        switch (statusCode) {
          case 401:
            message = 'Invalid API token';
            break;
          case 403:
            message = 'Access denied';
            break;
          case 404:
            message = 'Resource not found';
            break;
          case 500:
            message = 'Server error';
            break;
          default:
            message = 'Request failed: ${e.response?.statusMessage}';
        }
        return HapiApiException(
          message,
          statusCode: statusCode,
          originalError: e,
        );

      case DioExceptionType.cancel:
        return HapiApiException('Request cancelled', originalError: e);

      default:
        return HapiApiException(e.message ?? 'Unknown error', originalError: e);
    }
  }
}

/// hapi API 异常
class HapiApiException implements Exception {
  HapiApiException(this.message, {this.statusCode, this.originalError});

  final String message;
  final int? statusCode;
  final Object? originalError;

  @override
  String toString() => 'HapiApiException: $message (code: $statusCode)';
}

/// 健康检查响应
class HapiHealthResponse {
  HapiHealthResponse({required this.success, required this.message, this.data});

  final bool success;
  final String message;
  final dynamic data;
}

/// hapi API 服务 Provider
final hapiApiServiceProvider = Provider<HapiApiService?>((ref) {
  final config = ref.watch(hapiConfigProvider);
  if (!config.isConfigured) {
    return null;
  }
  return HapiApiService(config);
});

/// 连接测试 Provider
final hapiConnectionTestProvider =
    FutureProvider.autoDispose<HapiHealthResponse>((ref) async {
      final apiService = ref.watch(hapiApiServiceProvider);
      if (apiService == null) {
        throw HapiApiException('hapi not configured');
      }
      return apiService.testConnection();
    });
