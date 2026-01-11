import 'package:dio/dio.dart';
import '../../cache_service.dart';
import 'cached_repository.dart';
import 'hapi_api_client.dart';

/// Machine 相关 API
class MachineApi {
  MachineApi(this._client)
    : _cacheRepo = CachedRepository(_client.cacheService);

  final HapiApiClient _client;
  final CachedRepository _cacheRepo;

  /// 获取机器列表（带重试和缓存）
  Future<List<Map<String, dynamic>>> getMachines({
    bool forceRefresh = false,
  }) async {
    return _cacheRepo.fetch(
      key: CacheKeys.machines,
      ttl: const Duration(minutes: 2),
      forceRefresh: forceRefresh,
      fetcher:
          () async => _client.withRetry(
            operationName: 'getMachines',
            action: () async {
              try {
                final response = await _client.dio.get(
                  _client.apiUrl('/machines'),
                );
                if (response.data is Map && response.data['machines'] is List) {
                  return List<Map<String, dynamic>>.from(
                    response.data['machines'],
                  );
                }
                if (response.data is List) {
                  return List<Map<String, dynamic>>.from(response.data);
                }
                return <Map<String, dynamic>>[];
              } on DioException catch (e) {
                throw _client.handleDioError(e);
              }
            },
          ),
    );
  }

  /// 使机器缓存失效
  void invalidateMachinesCache() {
    _cacheRepo.invalidate(CacheKeys.machines);
  }

  /// 检查路径是否存在
  Future<Map<String, bool>> checkPathsExist(
    String machineId,
    List<String> paths,
  ) async {
    try {
      final response = await _client.dio.post(
        _client.apiUrl('/machines/$machineId/paths/exists'),
        data: {'paths': paths},
      );
      if (response.data is Map) {
        return Map<String, bool>.from(response.data);
      }
      return {};
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// 远程启动会话
  Future<Map<String, dynamic>?> spawnSession({
    required String machineId,
    String? directory,
    String? agent,
    bool? yolo,
    String? sessionType,
    String? worktreeName,
  }) async {
    try {
      final response = await _client.dio.post(
        _client.apiUrl('/machines/$machineId/spawn'),
        data: {
          if (directory != null) 'directory': directory,
          if (agent != null) 'agent': agent,
          if (yolo != null) 'yolo': yolo,
          if (sessionType != null) 'sessionType': sessionType,
          if (worktreeName != null) 'worktreeName': worktreeName,
        },
      );
      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }
}
