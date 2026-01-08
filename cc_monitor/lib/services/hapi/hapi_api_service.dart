import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hapi_config_service.dart';
import '../error_recovery_service.dart';
import '../cache_service.dart';

/// hapi API 服务 - 与 hapi server REST API 交互
class HapiApiService {
  HapiApiService(
    this._config, [
    this._errorRecoveryService,
    this._cacheService,
  ]) {
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
  final ErrorRecoveryService? _errorRecoveryService;
  final CacheService? _cacheService;
  late final Dio _dio;

  /// 获取完整 API URL
  String _apiUrl(String path) {
    final baseUrl = _config.serverUrl;
    if (baseUrl.isEmpty) {
      throw HapiApiException('Server URL not configured');
    }
    return '$baseUrl/api$path';
  }

  /// 带重试的请求包装器
  Future<T> _withRetry<T>({
    required Future<T> Function() action,
    required String operationName,
    RetryConfig config = RetryConfig.apiDefault,
  }) async {
    if (_errorRecoveryService == null) {
      // 没有重试服务，直接执行
      return action();
    }

    final result = await _errorRecoveryService.executeWithRetry(
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

  /// 获取会话列表（带重试和缓存）
  Future<List<Map<String, dynamic>>> getSessions({
    bool forceRefresh = false,
  }) async {
    // 尝试从缓存获取
    if (!forceRefresh && _cacheService != null) {
      final cached = _cacheService.get<List<Map<String, dynamic>>>(
        CacheKeys.sessions,
      );
      if (cached != null) {
        return cached;
      }
    }

    final result = await _withRetry(
      operationName: 'getSessions',
      action: () async {
        try {
          final response = await _dio.get(_apiUrl('/sessions'));
          if (response.data is List) {
            return List<Map<String, dynamic>>.from(response.data);
          }
          return <Map<String, dynamic>>[];
        } on DioException catch (e) {
          throw _handleDioError(e);
        }
      },
    );

    // 缓存结果（短 TTL，因为会话状态变化频繁）
    _cacheService?.set(
      CacheKeys.sessions,
      result,
      ttl: const Duration(seconds: 30),
    );
    return result;
  }

  /// 使会话缓存失效
  void invalidateSessionsCache() {
    _cacheService?.clearPrefix('session');
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

  /// 创建新会话
  Future<Map<String, dynamic>?> createSession({
    String? directory,
    String? model,
    bool? agent,
    bool? yolo,
    String? sessionType,
  }) async {
    try {
      final response = await _dio.post(
        _apiUrl('/sessions'),
        data: {
          if (directory != null) 'directory': directory,
          if (model != null) 'model': model,
          if (agent != null) 'agent': agent,
          if (yolo != null) 'yolo': yolo,
          if (sessionType != null) 'sessionType': sessionType,
        },
      );
      invalidateSessionsCache();
      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 切换到指定会话
  Future<bool> switchSession(String sessionId) async {
    try {
      final response = await _dio.post(_apiUrl('/sessions/$sessionId/switch'));
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 中止会话
  Future<bool> abortSession(String sessionId) async {
    try {
      final response = await _dio.post(_apiUrl('/sessions/$sessionId/abort'));
      invalidateSessionsCache();
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 归档会话
  Future<bool> archiveSession(String sessionId) async {
    try {
      final response = await _dio.post(_apiUrl('/sessions/$sessionId/archive'));
      invalidateSessionsCache();
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 删除会话
  Future<bool> deleteSession(String sessionId) async {
    try {
      final response = await _dio.delete(_apiUrl('/sessions/$sessionId'));
      invalidateSessionsCache();
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 重命名会话
  Future<bool> renameSession(String sessionId, String name) async {
    try {
      final response = await _dio.patch(
        _apiUrl('/sessions/$sessionId'),
        data: {'name': name},
      );
      invalidateSessionsCache();
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 设置权限模式
  /// [mode] 可选值: 'default', 'plan', 'auto-edit', 'full-auto', 'none'
  Future<bool> setPermissionMode(String sessionId, String mode) async {
    try {
      final response = await _dio.post(
        _apiUrl('/sessions/$sessionId/permission-mode'),
        data: {'mode': mode},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 设置模型
  /// [model] 可选值: 'sonnet', 'opus', 'haiku'
  Future<bool> setModel(String sessionId, String model) async {
    try {
      final response = await _dio.post(
        _apiUrl('/sessions/$sessionId/model'),
        data: {'model': model},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 获取 Slash 命令列表
  Future<List<Map<String, dynamic>>> getSlashCommands(String sessionId) async {
    try {
      final response = await _dio.get(
        _apiUrl('/sessions/$sessionId/slash-commands'),
      );
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 发送消息到会话
  Future<bool> sendMessage(
    String sessionId,
    String text, {
    String? localId,
  }) async {
    try {
      final response = await _dio.post(
        _apiUrl('/sessions/$sessionId/messages'),
        data: {'text': text, if (localId != null) 'localId': localId},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 批准权限请求
  Future<bool> approvePermission({
    required String sessionId,
    required String requestId,
  }) async {
    try {
      final response = await _dio.post(
        _apiUrl('/sessions/$sessionId/permissions/$requestId/approve'),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 拒绝权限请求
  Future<bool> denyPermission({
    required String sessionId,
    required String requestId,
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        _apiUrl('/sessions/$sessionId/permissions/$requestId/deny'),
        data: {if (reason != null) 'reason': reason},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 响应权限请求 (兼容方法)
  @Deprecated('Use approvePermission or denyPermission instead')
  Future<bool> respondPermission({
    required String sessionId,
    required String requestId,
    required bool approved,
    String? reason,
  }) async {
    if (approved) {
      return approvePermission(sessionId: sessionId, requestId: requestId);
    } else {
      return denyPermission(
        sessionId: sessionId,
        requestId: requestId,
        reason: reason,
      );
    }
  }

  /// 获取机器列表（带重试和缓存）
  Future<List<Map<String, dynamic>>> getMachines({
    bool forceRefresh = false,
  }) async {
    // 尝试从缓存获取
    if (!forceRefresh && _cacheService != null) {
      final cached = _cacheService.get<List<Map<String, dynamic>>>(
        CacheKeys.machines,
      );
      if (cached != null) {
        return cached;
      }
    }

    final result = await _withRetry(
      operationName: 'getMachines',
      action: () async {
        try {
          final response = await _dio.get(_apiUrl('/machines'));
          if (response.data is List) {
            return List<Map<String, dynamic>>.from(response.data);
          }
          return <Map<String, dynamic>>[];
        } on DioException catch (e) {
          throw _handleDioError(e);
        }
      },
    );

    // 缓存结果（机器列表变化不频繁，可以用较长 TTL）
    _cacheService?.set(
      CacheKeys.machines,
      result,
      ttl: const Duration(minutes: 2),
    );
    return result;
  }

  /// 使机器缓存失效
  void invalidateMachinesCache() {
    _cacheService?.remove(CacheKeys.machines);
  }

  /// 检查路径是否存在
  Future<Map<String, bool>> checkPathsExist(
    String machineId,
    List<String> paths,
  ) async {
    try {
      final response = await _dio.post(
        _apiUrl('/machines/$machineId/paths/exists'),
        data: {'paths': paths},
      );
      if (response.data is Map) {
        return Map<String, bool>.from(response.data);
      }
      return {};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 远程启动会话
  Future<Map<String, dynamic>?> spawnSession({
    required String machineId,
    String? directory,
    String? model,
    bool? agent,
    bool? yolo,
    String? sessionType,
    String? worktreeName,
  }) async {
    try {
      final response = await _dio.post(
        _apiUrl('/machines/$machineId/spawn'),
        data: {
          if (directory != null) 'directory': directory,
          if (model != null) 'model': model,
          if (agent != null) 'agent': agent,
          if (yolo != null) 'yolo': yolo,
          if (sessionType != null) 'sessionType': sessionType,
          if (worktreeName != null) 'worktreeName': worktreeName,
        },
      );
      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 获取会话文件列表
  Future<List<HapiFile>> getSessionFiles(
    String sessionId, {
    String? path,
  }) async {
    try {
      final response = await _dio.get(
        _apiUrl('/sessions/$sessionId/files'),
        queryParameters: {if (path != null) 'path': path},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => HapiFile.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 获取文件内容
  Future<String> getFileContent(String sessionId, String filePath) async {
    try {
      final response = await _dio.get(
        _apiUrl('/sessions/$sessionId/files/content'),
        queryParameters: {'path': filePath},
      );
      return response.data['content'] as String? ?? '';
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 获取 Git 状态
  Future<Map<String, dynamic>?> getGitStatus(String sessionId) async {
    try {
      final response = await _dio.get(
        _apiUrl('/sessions/$sessionId/git-status'),
      );
      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 获取 Git Diff 统计
  Future<List<HapiDiff>> getGitDiffNumstat(String sessionId) async {
    try {
      final response = await _dio.get(
        _apiUrl('/sessions/$sessionId/git-diff-numstat'),
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => HapiDiff.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 获取单个文件的 Git Diff
  Future<String> getFileDiff(
    String sessionId,
    String path, {
    bool staged = false,
  }) async {
    try {
      final response = await _dio.get(
        _apiUrl('/sessions/$sessionId/git-diff-file'),
        queryParameters: {'path': path, if (staged) 'staged': true},
      );
      return response.data['diff'] as String? ?? '';
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 获取会话 Git Diff (兼容方法)
  @Deprecated('Use getGitDiffNumstat instead')
  Future<List<HapiDiff>> getSessionDiff(String sessionId) async {
    return getGitDiffNumstat(sessionId);
  }

  /// 获取终端 WebSocket URL
  String getTerminalWsUrl(String sessionId) {
    final baseUrl = _config.serverUrl;
    final wsUrl = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$wsUrl/api/sessions/$sessionId/terminal?token=${_config.apiToken}';
  }

  /// 处理 Dio 错误
  HapiApiException _handleDioError(DioException e) {
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

/// hapi API 异常
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

/// 文件信息
class HapiFile {
  HapiFile({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.modifiedAt,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? modifiedAt;

  factory HapiFile.fromJson(Map<String, dynamic> json) {
    return HapiFile(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      isDirectory: json['isDirectory'] as bool? ?? json['type'] == 'directory',
      size: json['size'] as int?,
      modifiedAt:
          json['modifiedAt'] != null
              ? DateTime.tryParse(json['modifiedAt'] as String)
              : null,
    );
  }
}

/// Git Diff 信息
class HapiDiff {
  HapiDiff({
    required this.filePath,
    required this.status,
    this.additions,
    this.deletions,
    this.patch,
  });

  final String filePath;
  final String status; // 'added', 'modified', 'deleted', 'renamed'
  final int? additions;
  final int? deletions;
  final String? patch;

  factory HapiDiff.fromJson(Map<String, dynamic> json) {
    return HapiDiff(
      filePath:
          json['filePath'] as String? ??
          json['path'] as String? ??
          json['filename'] as String? ??
          '',
      status: json['status'] as String? ?? 'modified',
      additions: json['additions'] as int?,
      deletions: json['deletions'] as int?,
      patch: json['patch'] as String? ?? json['diff'] as String?,
    );
  }

  /// 获取状态图标
  String get statusIcon => switch (status) {
    'added' => '+',
    'deleted' => '-',
    'modified' => '~',
    'renamed' => '→',
    _ => '?',
  };
}

/// 机器信息
class HapiMachine {
  HapiMachine({
    required this.id,
    required this.name,
    this.hostname,
    this.platform,
    this.isOnline = false,
    this.lastSeenAt,
  });

  final String id;
  final String name;
  final String? hostname;
  final String? platform;
  final bool isOnline;
  final DateTime? lastSeenAt;

  factory HapiMachine.fromJson(Map<String, dynamic> json) {
    return HapiMachine(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['hostname'] as String? ?? 'Unknown',
      hostname: json['hostname'] as String?,
      platform: json['platform'] as String?,
      isOnline: json['isOnline'] as bool? ?? json['online'] as bool? ?? false,
      lastSeenAt:
          json['lastSeenAt'] != null
              ? DateTime.tryParse(json['lastSeenAt'] as String)
              : null,
    );
  }
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
  final errorRecoveryService = ref.watch(errorRecoveryServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  return HapiApiService(config, errorRecoveryService, cacheService);
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
