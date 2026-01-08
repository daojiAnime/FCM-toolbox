import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 交互服务 Provider
final interactionServiceProvider = Provider<InteractionService>((ref) {
  return InteractionService();
});

/// 交互响应状态
enum InteractionStatus { approved, denied }

/// 交互服务 - 处理与 Firebase Functions 的双向通信
class InteractionService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// 响应交互请求
  ///
  /// [requestId] - 交互请求 ID
  /// [status] - 响应状态 (approved/denied)
  /// [response] - 可选的响应数据
  Future<bool> respondInteraction({
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

      debugPrint('Interaction response sent: $requestId -> ${status.name}');
      return result.data['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Failed to respond interaction: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Failed to respond interaction: $e');
      rethrow;
    }
  }

  /// 批准交互请求
  Future<bool> approve(String requestId, {Map<String, dynamic>? response}) {
    return respondInteraction(
      requestId: requestId,
      status: InteractionStatus.approved,
      response: response,
    );
  }

  /// 拒绝交互请求
  Future<bool> deny(String requestId, {Map<String, dynamic>? response}) {
    return respondInteraction(
      requestId: requestId,
      status: InteractionStatus.denied,
      response: response,
    );
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
      debugPrint('Failed to get interaction: ${e.code} - ${e.message}');
      return null;
    }
  }
}
