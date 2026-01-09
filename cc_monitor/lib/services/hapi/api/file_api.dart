import '../../../common/logger.dart';
import 'package:dio/dio.dart';

import '../../../models/hapi/hapi.dart';
import 'hapi_api_client.dart';

/// File/Git 相关 API
class FileApi {
  FileApi(this._client);

  final HapiApiClient _client;

  /// 获取会话文件列表
  Future<List<HapiFile>> getSessionFiles(
    String sessionId, {
    String? path,
    String? query,
    int? limit,
  }) async {
    try {
      final response = await _client.dio.get(
        _client.apiUrl('/sessions/$sessionId/files'),
        queryParameters: {
          if (path != null) 'path': path,
          if (query != null) 'query': query,
          if (limit != null) 'limit': limit,
        },
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => HapiFile.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 获取文件内容
  Future<String> getFileContent(String sessionId, String filePath) async {
    try {
      final response = await _client.dio.get(
        _client.apiUrl('/sessions/$sessionId/file'),
        queryParameters: {'path': filePath},
      );
      if (response.data is Map) {
        if (response.data['success'] == false) {
          throw HapiApiException(
            response.data['error'] as String? ?? 'Failed to read file',
          );
        }
        return response.data['content'] as String? ?? '';
      }
      return response.data as String? ?? '';
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 获取 Git 状态
  Future<Map<String, dynamic>?> getGitStatus(String sessionId) async {
    try {
      final response = await _client.dio.get(
        _client.apiUrl('/sessions/$sessionId/git-status'),
      );
      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 获取 Git Diff 统计
  Future<List<HapiDiff>> getGitDiffNumstat(
    String sessionId, {
    bool staged = false,
  }) async {
    try {
      final response = await _client.dio.get(
        _client.apiUrl('/sessions/$sessionId/git-diff-numstat'),
        queryParameters: {if (staged) 'staged': true},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => HapiDiff.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 获取单个文件的 Git Diff
  Future<String> getFileDiff(
    String sessionId,
    String path, {
    bool staged = false,
  }) async {
    try {
      final response = await _client.dio.get(
        _client.apiUrl('/sessions/$sessionId/git-diff-file'),
        queryParameters: {'path': path, if (staged) 'staged': true},
      );
      return response.data['diff'] as String? ?? '';
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 获取会话 Git Diff (兼容方法)
  @Deprecated('Use getGitDiffNumstat instead')
  Future<List<HapiDiff>> getSessionDiff(String sessionId) async {
    return getGitDiffNumstat(sessionId);
  }

  /// 设置 SSE 客户端可见性
  Future<bool> setVisibility(bool visible, {String? subscriptionId}) async {
    if (subscriptionId == null || subscriptionId.isEmpty) {
      Log.i('FileApi', '[HAPI] setVisibility: no subscriptionId, skipping');
      return true;
    }

    try {
      final response = await _client.dio.post(
        _client.apiUrl('/visibility'),
        data: {
          'subscriptionId': subscriptionId,
          'visibility': visible ? 'visible' : 'hidden',
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return true;
      throw _client.handleDioError(e);
    }
  }

  /// 获取终端 WebSocket URL
  Future<String> getTerminalWsUrl(String sessionId) async {
    var baseUrl = _client.config.serverUrl;

    if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
      baseUrl = 'http://$baseUrl';
    }

    final wsUrl = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');

    final jwtToken = await _client.getJwtToken();
    if (jwtToken == null || jwtToken.isEmpty) {
      throw HapiApiException('无法获取 JWT token', isRetryable: true);
    }

    return '$wsUrl/api/sessions/$sessionId/terminal?token=$jwtToken';
  }
}
