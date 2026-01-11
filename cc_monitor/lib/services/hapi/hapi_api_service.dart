import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/hapi/hapi.dart';
import 'hapi_config_service.dart';
import '../error_recovery_strategy.dart';
import '../cache_service.dart';
import 'api/api.dart';

// 重新导出模型和 API 模块
export '../../models/hapi/hapi.dart';
export 'api/api.dart';

/// hapi API 服务 - Facade 模式
/// 聚合所有 API 模块，提供统一接口
class HapiApiService {
  HapiApiService(
    HapiConfig config, [
    ErrorRecoveryStrategy? recoveryStrategy,
    CacheService? cacheService,
  ]) {
    _client = HapiApiClient(config, recoveryStrategy, cacheService);
    _sessionApi = SessionApi(_client);
    _machineApi = MachineApi(_client);
    _permissionApi = PermissionApi(_client);
    _fileApi = FileApi(_client);
  }

  late final HapiApiClient _client;
  late final SessionApi _sessionApi;
  late final MachineApi _machineApi;
  late final PermissionApi _permissionApi;
  late final FileApi _fileApi;

  // ==================== JWT ====================

  /// 获取有效的 JWT token（供 SSE 服务等外部使用）
  Future<String?> getJwtToken() => _client.getJwtToken();

  // ==================== Session API ====================

  /// 测试连接
  Future<HapiHealthResponse> testConnection() => _sessionApi.testConnection();

  /// 获取会话列表
  Future<List<Map<String, dynamic>>> getSessions({bool forceRefresh = false}) =>
      _sessionApi.getSessions(forceRefresh: forceRefresh);

  /// 使会话缓存失效
  void invalidateSessionsCache() => _sessionApi.invalidateSessionsCache();

  /// 获取会话详情
  Future<Map<String, dynamic>?> getSession(String sessionId) =>
      _sessionApi.getSession(sessionId);

  /// 创建新会话
  Future<Map<String, dynamic>?> createSession({
    String? directory,
    String? model,
    bool? agent,
    bool? yolo,
    String? sessionType,
  }) => _sessionApi.createSession(
    directory: directory,
    model: model,
    agent: agent,
    yolo: yolo,
    sessionType: sessionType,
  );

  /// 切换到指定会话
  Future<bool> switchSession(String sessionId) =>
      _sessionApi.switchSession(sessionId);

  /// 中止会话
  Future<bool> abortSession(String sessionId) =>
      _sessionApi.abortSession(sessionId);

  /// 归档会话
  Future<bool> archiveSession(String sessionId) =>
      _sessionApi.archiveSession(sessionId);

  /// 恢复归档会话
  Future<bool> unarchiveSession(String sessionId) =>
      _sessionApi.unarchiveSession(sessionId);

  /// 删除会话
  Future<bool> deleteSession(String sessionId) =>
      _sessionApi.deleteSession(sessionId);

  /// 重命名会话
  Future<bool> renameSession(String sessionId, String name) =>
      _sessionApi.renameSession(sessionId, name);

  /// 设置权限模式
  Future<bool> setPermissionMode(String sessionId, String mode) =>
      _sessionApi.setPermissionMode(sessionId, mode);

  /// 设置模型
  Future<bool> setModel(String sessionId, String model) =>
      _sessionApi.setModel(sessionId, model);

  /// 获取 Slash 命令列表
  Future<List<Map<String, dynamic>>> getSlashCommands(String sessionId) =>
      _sessionApi.getSlashCommands(sessionId);

  /// 获取会话消息历史
  Future<Map<String, dynamic>> getMessages(
    String sessionId, {
    int? limit,
    int? beforeSeq,
  }) => _sessionApi.getMessages(sessionId, limit: limit, beforeSeq: beforeSeq);

  /// 发送消息到会话
  Future<bool> sendMessage(String sessionId, String text, {String? localId}) =>
      _sessionApi.sendMessage(sessionId, text, localId: localId);

  // ==================== Machine API ====================

  /// 获取机器列表
  Future<List<Map<String, dynamic>>> getMachines({bool forceRefresh = false}) =>
      _machineApi.getMachines(forceRefresh: forceRefresh);

  /// 使机器缓存失效
  void invalidateMachinesCache() => _machineApi.invalidateMachinesCache();

  /// 检查路径是否存在
  Future<Map<String, bool>> checkPathsExist(
    String machineId,
    List<String> paths,
  ) => _machineApi.checkPathsExist(machineId, paths);

  /// 远程启动会话
  Future<Map<String, dynamic>?> spawnSession({
    required String machineId,
    String? directory,
    String? agent,
    bool? yolo,
    String? sessionType,
    String? worktreeName,
  }) => _machineApi.spawnSession(
    machineId: machineId,
    directory: directory,
    agent: agent,
    yolo: yolo,
    sessionType: sessionType,
    worktreeName: worktreeName,
  );

  // ==================== Permission API ====================

  /// 批准权限请求
  Future<bool> approvePermission({
    required String sessionId,
    required String requestId,
    String? mode,
    List<String>? allowTools,
    String? decision,
    Map<String, List<String>>? answers,
  }) => _permissionApi.approvePermission(
    sessionId: sessionId,
    requestId: requestId,
    mode: mode,
    allowTools: allowTools,
    decision: decision,
    answers: answers,
  );

  /// 拒绝权限请求
  Future<bool> denyPermission({
    required String sessionId,
    required String requestId,
    String? decision,
  }) => _permissionApi.denyPermission(
    sessionId: sessionId,
    requestId: requestId,
    decision: decision,
  );

  // ==================== File API ====================

  /// 获取会话文件列表
  Future<List<HapiFile>> getSessionFiles(
    String sessionId, {
    String? path,
    String? query,
    int? limit,
  }) => _fileApi.getSessionFiles(
    sessionId,
    path: path,
    query: query,
    limit: limit,
  );

  /// 获取文件内容
  Future<String> getFileContent(String sessionId, String filePath) =>
      _fileApi.getFileContent(sessionId, filePath);

  /// 获取 Git 状态
  Future<Map<String, dynamic>?> getGitStatus(String sessionId) =>
      _fileApi.getGitStatus(sessionId);

  /// 获取 Git Diff 统计
  Future<List<HapiDiff>> getGitDiffNumstat(
    String sessionId, {
    bool staged = false,
  }) => _fileApi.getGitDiffNumstat(sessionId, staged: staged);

  /// 获取单个文件的 Git Diff
  Future<String> getFileDiff(
    String sessionId,
    String path, {
    bool staged = false,
  }) => _fileApi.getFileDiff(sessionId, path, staged: staged);

  /// 设置 SSE 客户端可见性
  Future<bool> setVisibility(bool visible, {String? subscriptionId}) =>
      _fileApi.setVisibility(visible, subscriptionId: subscriptionId);

  /// 获取终端 WebSocket URL
  Future<String> getTerminalWsUrl(String sessionId) =>
      _fileApi.getTerminalWsUrl(sessionId);
}

/// hapi API 服务 Provider
final hapiApiServiceProvider = Provider<HapiApiService?>((ref) {
  final config = ref.watch(hapiConfigProvider);
  if (!config.isConfigured) {
    return null;
  }
  final cacheService = ref.watch(cacheServiceProvider);
  return HapiApiService(config, null, cacheService);
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
