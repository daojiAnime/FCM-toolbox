import '../common/logger.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hapi/hapi_config_service.dart';
import 'hapi/hapi_api_service.dart';

/// 交互响应状态
enum InteractionStatus { approved, denied }

/// 抽象交互服务接口
abstract class BaseInteractionService {
  Future<bool> approve(String requestId, {Map<String, dynamic>? response});
  Future<bool> deny(String requestId, {Map<String, dynamic>? response});
  Future<bool> sendMessage(String sessionId, String message);
}

/// 交互服务 Provider - 根据 hapi 配置选择实现
final interactionServiceProvider = Provider<BaseInteractionService>((ref) {
  final hapiConfig = ref.watch(hapiConfigProvider);
  final hapiApiService = ref.watch(hapiApiServiceProvider);

  // 如果 hapi 已启用且已配置，优先使用 hapi
  if (hapiConfig.enabled && hapiConfig.isConfigured && hapiApiService != null) {
    Log.i('Interact', 'Using hapi service');
    return HapiInteractionService(hapiApiService);
  }

  // 回退到 Firebase Functions
  Log.i('Interact', 'Using Firebase service');
  return FirebaseInteractionService();
});

/// Firebase 交互服务实现
class FirebaseInteractionService implements BaseInteractionService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// 响应交互请求
  Future<bool> _respondInteraction({
    required String requestId,
    required InteractionStatus status,
    Map<String, dynamic>? response,
  }) async {
    try {
      final callable = _functions.httpsCallable('respondInteraction');
      final result = await callable.call<Map<String, dynamic>>({
        'requestId': requestId,
        'status': status.name,
        'response': response ?? {},
      });

      Log.i(
        'Interact',
        '[Firebase] Interaction response: $requestId -> ${status.name}',
      );
      return result.data['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      Log.i(
        'Interact',
        '[Firebase] Failed to respond interaction: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      Log.i('Interact', 'Failed to respond interaction: $e');
      rethrow;
    }
  }

  @override
  Future<bool> approve(String requestId, {Map<String, dynamic>? response}) {
    return _respondInteraction(
      requestId: requestId,
      status: InteractionStatus.approved,
      response: response,
    );
  }

  @override
  Future<bool> deny(String requestId, {Map<String, dynamic>? response}) {
    return _respondInteraction(
      requestId: requestId,
      status: InteractionStatus.denied,
      response: response,
    );
  }

  @override
  Future<bool> sendMessage(String sessionId, String message) async {
    // Firebase 不支持双向消息发送
    Log.i('Interact', 'sendMessage not supported');
    return false;
  }

  /// 获取交互请求状态
  Future<Map<String, dynamic>?> getInteraction(String requestId) async {
    try {
      final callable = _functions.httpsCallable('getInteraction');
      final result = await callable.call<Map<String, dynamic>>({
        'requestId': requestId,
      });
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      Log.i(
        'Interact',
        '[Firebase] Failed to get interaction: ${e.code} - ${e.message}',
      );
      return null;
    }
  }
}

/// hapi 交互服务实现
class HapiInteractionService implements BaseInteractionService {
  HapiInteractionService(this._apiService);

  final HapiApiService _apiService;

  // 缓存 sessionId，从 requestId 解析或通过 API 获取
  final Map<String, String> _requestSessionMap = {};

  @override
  Future<bool> approve(
    String requestId, {
    Map<String, dynamic>? response,
  }) async {
    try {
      final sessionId = await _getSessionIdForRequest(requestId);
      if (sessionId == null) {
        Log.e('Interact', 'Cannot find session for request: $requestId');
        return false;
      }

      // 提取高级参数
      final mode = response?['mode'] as String?;
      final allowTools =
          (response?['allowTools'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList();
      final decision = response?['decision'] as String?;
      final answers = response?['answers'] as Map<String, List<String>>?;

      return await _apiService.approvePermission(
        sessionId: sessionId,
        requestId: requestId,
        mode: mode,
        allowTools: allowTools,
        decision: decision,
        answers: answers,
      );
    } catch (e) {
      Log.e('Interact', 'Failed to approve: $e');
      rethrow;
    }
  }

  @override
  Future<bool> deny(String requestId, {Map<String, dynamic>? response}) async {
    try {
      final sessionId = await _getSessionIdForRequest(requestId);
      if (sessionId == null) {
        Log.e('Interact', 'Cannot find session for request: $requestId');
        return false;
      }

      return await _apiService.denyPermission(
        sessionId: sessionId,
        requestId: requestId,
        decision: response?['decision'] as String?,
      );
    } catch (e) {
      Log.e('Interact', 'Failed to deny: $e');
      rethrow;
    }
  }

  @override
  Future<bool> sendMessage(String sessionId, String message) async {
    try {
      return await _apiService.sendMessage(sessionId, message);
    } catch (e) {
      Log.e('Interact', 'Failed to send message: $e');
      rethrow;
    }
  }

  /// 从 requestId 获取关联的 sessionId
  /// requestId 格式通常为: {sessionId}_{timestamp} 或直接存储映射
  Future<String?> _getSessionIdForRequest(String requestId) async {
    // 先检查缓存
    if (_requestSessionMap.containsKey(requestId)) {
      return _requestSessionMap[requestId];
    }

    // 尝试从 requestId 解析 sessionId (假设格式为 sessionId_xxx)
    final parts = requestId.split('_');
    if (parts.isNotEmpty && parts[0].length > 10) {
      _requestSessionMap[requestId] = parts[0];
      return parts[0];
    }

    // 如果无法解析，遍历会话查找
    try {
      final sessions = await _apiService.getSessions();
      for (final session in sessions) {
        final sessionId = session['id'] as String?;
        if (sessionId != null) {
          // 检查会话中是否有此权限请求
          final permissions = session['pendingPermissions'] as List?;
          if (permissions != null) {
            for (final perm in permissions) {
              if (perm['id'] == requestId) {
                _requestSessionMap[requestId] = sessionId;
                return sessionId;
              }
            }
          }
        }
      }
    } catch (e) {
      Log.e('Interact', 'Failed to search sessions: $e');
    }

    return null;
  }

  /// 注册 requestId 和 sessionId 的映射（从 SSE 事件获取时调用）
  void registerRequestSession(String requestId, String sessionId) {
    _requestSessionMap[requestId] = sessionId;
  }
}
