import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'common/navigator_key.dart';
import 'firebase_options.dart';
import 'pages/message_detail_page.dart';
import 'providers/settings_provider.dart';
import 'providers/messages_provider.dart';
import 'services/fcm_service.dart';
import 'services/firestore_message_service.dart';
import 'services/hapi/hapi_config_service.dart';

/// 全局 ProviderContainer 引用，用于消息处理
late ProviderContainer _container;

/// 检查是否支持 Firebase 和 FCM（Android、iOS、macOS）
bool get _isFirebaseSupported {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 创建 ProviderContainer 以便初始化设置
  _container = ProviderContainer();

  // 初始化设置
  await _container.read(settingsProvider.notifier).init();

  // 初始化 hapi 配置
  await _container.read(hapiConfigProvider.notifier).init();

  // 在支持的平台初始化 Firebase 和 FCM（Android、iOS、macOS）
  if (_isFirebaseSupported) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');

      // 注册后台消息处理器（仅 Android/iOS 需要）
      if (Platform.isAndroid || Platform.isIOS) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      }

      // 初始化 FCM 并获取 token
      await _initializeFcm(_container);
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  } else {
    debugPrint('Platform not supported for Firebase');
  }

  runApp(
    UncontrolledProviderScope(
      container: _container,
      child: const CCMonitorApp(),
    ),
  );
}

/// 初始化 FCM 服务，失败时切换到 Firestore 监听模式
Future<void> _initializeFcm(ProviderContainer container) async {
  final settingsNotifier = container.read(settingsProvider.notifier);
  final messaging = FirebaseMessaging.instance;

  // 请求通知权限（macOS 需要配置 APNs）
  NotificationSettings settings;
  try {
    settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  } catch (e) {
    debugPrint('FCM permission request failed: $e');
    debugPrint('Switching to Firestore realtime mode...');
    await _initializeFirestoreMode(container);
    return;
  }

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

    // 监听前台消息
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 监听用户点击通知打开 App
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 检查是否有初始消息（App 从通知启动）
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    debugPrint('FCM initialized successfully');
  } else {
    debugPrint(
      'Notification permission denied: ${settings.authorizationStatus}',
    );
    debugPrint('Switching to Firestore realtime mode...');
    await _initializeFirestoreMode(container);
  }
}

/// 初始化 Firestore 实时监听模式
Future<void> _initializeFirestoreMode(ProviderContainer container) async {
  final firestoreService = container.read(firestoreMessageServiceProvider);
  await firestoreService.initialize();
  debugPrint('Firestore realtime mode enabled');
}

/// 处理前台消息
void _handleForegroundMessage(RemoteMessage remoteMessage) {
  debugPrint('Foreground message received: ${remoteMessage.data}');

  // 解析消息
  final message = FcmService.parseMessage(remoteMessage);
  if (message != null) {
    // 添加到消息列表
    _container.read(messagesProvider.notifier).addMessage(message);
    debugPrint('Message added to list: ${message.id}');
  }
}

/// 处理用户点击通知打开 App
void _handleMessageOpenedApp(RemoteMessage remoteMessage) {
  debugPrint('Message opened app: ${remoteMessage.data}');

  // 解析并添加消息
  final message = FcmService.parseMessage(remoteMessage);
  if (message != null) {
    _container.read(messagesProvider.notifier).addMessage(message);

    // 导航到消息详情页
    // 使用 WidgetsBinding 延迟执行，确保 Navigator 已准备就绪
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => MessageDetailPage(messageId: message.id),
        ),
      );
    });
  }
}
