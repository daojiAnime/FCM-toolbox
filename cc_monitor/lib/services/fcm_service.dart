import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../common/logger.dart';
import '../models/message.dart';
import '../models/payload/payload.dart';

/// FCM 服务 Provider
final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});

/// FCM Token Provider
final fcmTokenProvider = StateProvider<String?>((ref) => null);

/// FCM 服务
class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// 初始化 FCM
  Future<void> initialize() async {
    // 请求通知权限
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 获取 Token
      final token = await _messaging.getToken();
      if (token != null) {
        _onTokenRefresh(token);
      }

      // 监听 Token 刷新
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // 配置前台消息显示
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// Token 刷新回调
  /// 注意：Token 更新现在由 main.dart 中的 _initializeFcm 直接处理
  /// 通过 settingsNotifier.setFcmToken(token) 更新状态
  void _onTokenRefresh(String token) {
    Log.i('FCM', 'Token refreshed');
  }

  /// 获取当前 Token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// 删除 Token
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
  }

  /// 订阅主题
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// 取消订阅主题
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// 解析 FCM 消息为 Message 对象
  static Message? parseMessage(RemoteMessage remoteMessage) {
    try {
      final data = remoteMessage.data;

      // 检查是否为 CC Monitor 消息
      if (!data.containsKey('type') && !data.containsKey('text')) {
        return null;
      }

      // 解析 FCM-toolbox text 格式
      if (data.containsKey('text')) {
        final textData =
            jsonDecode(data['text'] as String) as Map<String, dynamic>;
        return Message(
          id:
              remoteMessage.messageId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          sessionId: data['session_id'] ?? 'unknown',
          projectName: data['project_name'] ?? 'Unknown Project',
          projectPath: data['project_path'],
          hookEvent: data['hook_event'],
          toolName: data['tool_name'],
          createdAt: DateTime.now(),
          payload: _parsePayloadFromText(textData, data),
        );
      }

      // 解析结构化 payload
      final type = data['type'] as String;
      final payloadJson =
          data.containsKey('payload')
              ? jsonDecode(data['payload'] as String) as Map<String, dynamic>
              : data;

      return Message(
        id:
            remoteMessage.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: data['session_id'] ?? 'unknown',
        projectName: data['project_name'] ?? 'Unknown Project',
        projectPath: data['project_path'],
        hookEvent: data['hook_event'],
        toolName: data['tool_name'],
        createdAt: DateTime.now(),
        payload: _parsePayload(type, payloadJson),
      );
    } catch (e) {
      Log.e('FCM', 'Failed to parse message', e);
      return null;
    }
  }

  /// 从 text 格式解析 Payload
  static Payload _parsePayloadFromText(
    Map<String, dynamic> textData,
    Map<String, dynamic> extraData,
  ) {
    final title = textData['title'] as String? ?? 'Claude Code';
    final message = textData['message'] as String? ?? '';
    final status = extraData['status'] as String?;

    // 根据状态决定消息类型
    if (status == 'success') {
      return Payload.complete(
        title: title,
        summary: message,
        duration: int.tryParse(extraData['duration'] ?? ''),
        toolCount: int.tryParse(extraData['tool_count'] ?? ''),
      );
    } else if (status == 'failure') {
      return Payload.error(title: title, message: message);
    } else if (status == 'warning') {
      return Payload.warning(title: title, message: message);
    } else {
      // 默认为进度消息
      return Payload.progress(title: title, description: message);
    }
  }

  /// 解析 Payload
  static Payload _parsePayload(String type, Map<String, dynamic> data) {
    return switch (type) {
      'progress' => Payload.progress(
        title: data['title'] ?? 'Processing',
        description: data['description'],
        current: data['current'] ?? 0,
        total: data['total'] ?? 0,
        currentStep: data['currentStep'],
      ),
      'complete' => Payload.complete(
        title: data['title'] ?? 'Complete',
        summary: data['summary'],
        duration: data['duration'],
        toolCount: data['toolCount'],
      ),
      'error' => Payload.error(
        title: data['title'] ?? 'Error',
        message: data['message'] ?? 'Unknown error',
        stackTrace: data['stackTrace'],
        suggestion: data['suggestion'],
      ),
      'warning' => Payload.warning(
        title: data['title'] ?? 'Warning',
        message: data['message'] ?? 'Warning message',
        action: data['action'],
      ),
      'code' => Payload.code(
        title: data['title'] ?? 'Code',
        code: data['code'] ?? '',
        language: data['language'],
        filename: data['filename'],
        startLine: data['startLine'],
      ),
      'markdown' => Payload.markdown(
        title: data['title'] ?? 'Content',
        content: data['content'] ?? '',
      ),
      'image' => Payload.image(
        title: data['title'] ?? 'Image',
        url: data['url'] ?? '',
        caption: data['caption'],
        width: data['width'],
        height: data['height'],
      ),
      'interactive' => Payload.interactive(
        title: data['title'] ?? 'Action Required',
        message: data['message'] ?? '',
        requestId: data['requestId'] ?? '',
        interactiveType: InteractiveType.values.firstWhere(
          (e) => e.name == data['interactiveType'],
          orElse: () => InteractiveType.confirm,
        ),
        // metadata 从 FCM 传来时是 JSON 字符串，需要解析
        metadata:
            data['metadata'] != null
                ? (data['metadata'] is String
                    ? jsonDecode(data['metadata'] as String)
                        as Map<String, dynamic>
                    : data['metadata'] as Map<String, dynamic>)
                : null,
      ),
      _ => Payload.progress(
        title: data['title'] ?? 'Message',
        description: data['description'] ?? data['message'],
      ),
    };
  }
}

/// 后台消息处理器
/// 注意：后台处理器在独立 isolate 中运行，无法访问 Riverpod 容器
/// 使用 SharedPreferences 缓存消息，App 启动时会处理这些缓存
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // 获取 SharedPreferences 实例
    final prefs = await SharedPreferences.getInstance();

    // 准备消息数据
    final messageData = {
      'messageId':
          message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title':
          message.notification?.title ?? message.data['title'] ?? 'New Message',
      'body': message.notification?.body ?? message.data['body'] ?? '',
      'data': message.data,
      'receivedAt': DateTime.now().toIso8601String(),
    };

    // 读取现有的后台消息列表
    final backgroundMessagesJson = prefs.getString('background_messages');
    List<dynamic> backgroundMessages = [];

    if (backgroundMessagesJson != null && backgroundMessagesJson.isNotEmpty) {
      try {
        backgroundMessages =
            jsonDecode(backgroundMessagesJson) as List<dynamic>;
      } catch (e) {
        Log.e('FCM', 'Failed to parse background messages', e);
        backgroundMessages = [];
      }
    }

    // 添加新消息到列表开头
    backgroundMessages.insert(0, messageData);

    // 限制最多保存 50 条消息（FIFO）
    if (backgroundMessages.length > 50) {
      backgroundMessages = backgroundMessages.sublist(0, 50);
    }

    // 保存更新后的列表
    await prefs.setString(
      'background_messages',
      jsonEncode(backgroundMessages),
    );
  } catch (e) {
    Log.e('FCM', 'Failed to cache background message', e);
  }
}
