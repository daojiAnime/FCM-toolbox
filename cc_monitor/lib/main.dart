import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'providers/settings_provider.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 注册后台消息处理器
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 创建 ProviderContainer 以便初始化设置
  final container = ProviderContainer();

  // 初始化设置
  await container.read(settingsProvider.notifier).init();

  // 初始化 FCM 并获取 token
  await _initializeFcm(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CCMonitorApp(),
    ),
  );
}

/// 初始化 FCM 服务
Future<void> _initializeFcm(ProviderContainer container) async {
  final settingsNotifier = container.read(settingsProvider.notifier);

  // 请求通知权限
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional) {
    // 获取 FCM Token
    final token = await messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      await settingsNotifier.setFcmToken(token);
    }

    // 监听 Token 刷新
    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token refreshed: $newToken');
      await settingsNotifier.setFcmToken(newToken);
    });

    // 配置前台消息显示
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  } else {
    debugPrint('Notification permission denied: ${settings.authorizationStatus}');
  }
}
