import 'package:dio/dio.dart';
import 'hapi_api_client.dart';

/// Permission 相关 API
class PermissionApi {
  PermissionApi(this._client);

  final HapiApiClient _client;

  /// 批准权限请求
  Future<bool> approvePermission({
    required String sessionId,
    required String requestId,
    String? mode,
    List<String>? allowTools,
    String? decision,
    Map<String, List<String>>? answers,
  }) async {
    try {
      final response = await _client.dio.post(
        _client.apiUrl('/sessions/$sessionId/permissions/$requestId/approve'),
        data: {
          if (mode != null) 'mode': mode,
          if (allowTools != null) 'allowTools': allowTools,
          if (decision != null) 'decision': decision,
          if (answers != null) 'answers': answers,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 拒绝权限请求
  Future<bool> denyPermission({
    required String sessionId,
    required String requestId,
    String? decision,
  }) async {
    try {
      final response = await _client.dio.post(
        _client.apiUrl('/sessions/$sessionId/permissions/$requestId/deny'),
        data: {if (decision != null) 'decision': decision},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 响应权限请求 (兼容方法)
  @Deprecated('Use approvePermission or denyPermission instead')
  Future<bool> respondPermission({
    required String sessionId,
    required String requestId,
    required bool approved,
  }) async {
    if (approved) {
      return approvePermission(sessionId: sessionId, requestId: requestId);
    } else {
      return denyPermission(sessionId: sessionId, requestId: requestId);
    }
  }
}
