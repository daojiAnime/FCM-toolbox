import '../../../common/logger.dart';
import 'package:dio/dio.dart';

import '../../../models/hapi/hapi.dart';
import '../../cache_service.dart';
import 'hapi_api_client.dart';

/// Session 相关 API
class SessionApi {
  SessionApi(this._client);

  final HapiApiClient _client;

  /// 测试连接
  Future<HapiHealthResponse> testConnection() async {
    try {
      final response = await _client.dio.get(_client.apiUrl('/sessions'));
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
      throw _client.handleDioError(e);
    }
  }

  /// 获取会话列表（带重试和缓存）
  Future<List<Map<String, dynamic>>> getSessions({
    bool forceRefresh = false,
  }) async {
    // 尝试从缓存获取
    if (!forceRefresh && _client.cacheService != null) {
      final cached = _client.cacheService!.get<List<Map<String, dynamic>>>(
        CacheKeys.sessions,
      );
      if (cached != null) return cached;
    }

    final result = await _client.withRetry(
      operationName: 'getSessions',
      action: () async {
        try {
          final response = await _client.dio.get(_client.apiUrl('/sessions'));
          if (response.data is Map && response.data['sessions'] is List) {
            return List<Map<String, dynamic>>.from(response.data['sessions']);
          }
          if (response.data is List) {
            return List<Map<String, dynamic>>.from(response.data);
          }
          return <Map<String, dynamic>>[];
        } on DioException catch (e) {
          throw _client.handleDioError(e);
        }
      },
    );

    _client.cacheService?.set(
      CacheKeys.sessions,
      result,
      ttl: const Duration(seconds: 30),
    );
    return result;
  }

  /// 使会话缓存失效
  void invalidateSessionsCache() {
    _client.cacheService?.clearPrefix('session');
  }

  /// 获取会话详情
  /// API 返回结构: { session: {...} }
  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    try {
      final response = await _client.dio.get(
        _client.apiUrl('/sessions/$sessionId'),
      );
      final data = response.data as Map<String, dynamic>?;
      // Web 版本返回 { session: {...} } 结构，需要解包
      if (data != null && data['session'] is Map<String, dynamic>) {
        return data['session'] as Map<String, dynamic>;
      }
      return data;
    } on DioException catch (e) {
      throw _client.handleDioError(e);
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
      final response = await _client.dio.post(
        _client.apiUrl('/sessions'),
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
      throw _client.handleDioError(e);
    }
  }

  /// 切换到指定会话
  /// 409 Conflict 表示会话不存在或状态冲突，静默返回 false
  Future<bool> switchSession(String sessionId) async {
    try {
      final response = await _client.dio.post(
        _client.apiUrl('/sessions/$sessionId/switch'),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      // 409 Conflict: 会话不存在或状态冲突，静默处理
      if (e.response?.statusCode == 409) {
        Log.i(
          'SessApi',
          ' Switch failed (409): session $sessionId may not exist',
        );
        return false;
      }
      throw _client.handleDioError(e);
    }
  }

  /// 中止会话
  Future<bool> abortSession(String sessionId) async {
    try {
      final response = await _client.dio.post(
        _client.apiUrl('/sessions/$sessionId/abort'),
      );
      invalidateSessionsCache();
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 归档会话
  Future<bool> archiveSession(String sessionId) async {
    try {
      final response = await _client.dio.post(
        _client.apiUrl('/sessions/$sessionId/archive'),
      );
      invalidateSessionsCache();
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 恢复归档会话
  Future<bool> unarchiveSession(String sessionId) async {
    try {
      final response = await _client.dio.post(
        _client.apiUrl('/sessions/$sessionId/unarchive'),
      );
      invalidateSessionsCache();
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 删除会话
  Future<bool> deleteSession(String sessionId) async {
    try {
      final response = await _client.dio.delete(
        _client.apiUrl('/sessions/$sessionId'),
      );
      invalidateSessionsCache();
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 重命名会话
  Future<bool> renameSession(String sessionId, String name) async {
    try {
      final response = await _client.dio.patch(
        _client.apiUrl('/sessions/$sessionId'),
        data: {'name': name},
      );
      invalidateSessionsCache();
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 设置权限模式
  Future<bool> setPermissionMode(String sessionId, String mode) async {
    Log.i('SessApi', ' setPermissionMode: sessionId=$sessionId, mode=$mode');
    try {
      final response = await _client.dio.post(
        _client.apiUrl('/sessions/$sessionId/permission-mode'),
        data: {'mode': mode},
      );
      // Web 版使用 res.ok (200-299)，保持一致
      final statusCode = response.statusCode ?? 0;
      Log.i('SessApi', ' setPermissionMode response: $statusCode');
      return statusCode >= 200 && statusCode < 300;
    } on DioException catch (e) {
      Log.i(
        'SessApi',
        ' setPermissionMode error: ${e.response?.statusCode} - ${e.response?.data}',
      );
      throw _client.handleDioError(e);
    }
  }

  /// 设置模型
  Future<bool> setModel(String sessionId, String model) async {
    try {
      final response = await _client.dio.post(
        _client.apiUrl('/sessions/$sessionId/model'),
        data: {'model': model},
      );
      // Web 版使用 res.ok (200-299)，保持一致
      final statusCode = response.statusCode ?? 0;
      return statusCode >= 200 && statusCode < 300;
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 获取 Slash 命令列表
  Future<List<Map<String, dynamic>>> getSlashCommands(String sessionId) async {
    try {
      final response = await _client.dio.get(
        _client.apiUrl('/sessions/$sessionId/slash-commands'),
      );
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 获取会话消息历史
  Future<Map<String, dynamic>> getMessages(
    String sessionId, {
    int? limit,
    int? beforeSeq,
  }) async {
    try {
      final response = await _client.dio.get(
        _client.apiUrl('/sessions/$sessionId/messages'),
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (beforeSeq != null) 'beforeSeq': beforeSeq,
        },
      );
      return response.data as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 发送消息到会话
  Future<bool> sendMessage(
    String sessionId,
    String text, {
    String? localId,
  }) async {
    try {
      final response = await _client.dio.post(
        _client.apiUrl('/sessions/$sessionId/messages'),
        data: {'text': text, if (localId != null) 'localId': localId},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }
}
