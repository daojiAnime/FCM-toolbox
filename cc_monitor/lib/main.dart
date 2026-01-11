import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'common/logger.dart';
import 'common/navigator_key.dart';
import 'firebase_options.dart';
import 'pages/message_detail_page.dart';
import 'providers/settings_provider.dart';
import 'providers/messages_provider.dart';
import 'services/fcm_service.dart';
import 'services/firestore_message_service.dart';
import 'services/hapi/hapi_config_service.dart';
import 'services/hapi/hapi_event_handler.dart';
import 'services/connection_manager.dart';
import 'services/database_service.dart' as db_service;

/// 全局 ProviderContainer 引用，用于消息处理
late ProviderContainer _container;

/// 检查是否支持 Firebase 和 FCM（Android、iOS、macOS）
bool get _isFirebaseSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// 检查是否为移动平台（Android/iOS）
bool get _isMobilePlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志服务（轻量级操作）
  await Log.init(enableFileLogging: !kIsWeb);

  // 创建 ProviderContainer
  _container = ProviderContainer();

  // 预加载配置（在 UI 渲染前完成，避免"未配置"状态闪烁）
  try {
    await _container.read(hapiConfigProvider.notifier).init();
    Log.d('Init', 'HAPI config preloaded');
  } catch (e) {
    Log.e('Init', 'Failed to preload config: $e');
  }

  // 启动应用
  runApp(
    UncontrolledProviderScope(
      container: _container,
      child: const CCMonitorApp(),
    ),
  );

  // 延迟初始化其他服务：在首帧渲染后执行
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeServicesAsync();
  });
}

/// 异步初始化所有服务（首帧渲染后执行）
Future<void> _initializeServicesAsync() async {
  try {
    // 1. 初始化设置
    await _container.read(settingsProvider.notifier).init();
    Log.d('Init', 'Settings initialized');

    // 2. 初始化 hapi 事件监听（配置已在 main() 中预加载）
    _container.read(hapiEventInitProvider);
    Log.d('Init', 'HAPI event handler initialized');

    // 3. 初始化连接管理器（自动处理 hapi/Firebase 切换）
    _container.read(connectionManagerProvider);
    Log.d('Init', 'Connection manager initialized');

    // 4. 异步清理旧数据（不阻塞）
    _cleanupOldDataAsync(_container);

    // 5. 在支持的平台初始化 Firebase 和 FCM
    if (_isFirebaseSupported) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        Log.i('Firebase', 'Initialized successfully');

        // 注册后台消息处理器（仅 Android/iOS 需要）
        if (_isMobilePlatform) {
          FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler,
          );
        }

        // 初始化 FCM 并获取 token
        await _initializeFcm(_container);
      } catch (e) {
        Log.e('Firebase', 'Initialization failed', e);
      }
    } else {
      Log.d('Firebase', 'Platform not supported');
    }

    Log.i('Init', 'All services initialized successfully');
  } catch (e, stackTrace) {
    Log.e('Init', 'Service initialization failed', e, stackTrace);
  }
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
    Log.w('FCM', 'Permission request failed, switching to Firestore', e);
    await _initializeFirestoreMode(container);
    return;
  }

  if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional) {
    // 获取 FCM Token
    final token = await messaging.getToken();
    if (token != null) {
      Log.v('FCM', 'Token: $token');
      await settingsNotifier.setFcmToken(token);
    }

    // 监听 Token 刷新
    messaging.onTokenRefresh.listen((newToken) async {
      Log.v('FCM', 'Token refreshed');
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

    // 处理缓存的后台消息
    await _processCachedBackgroundMessages(container);

    Log.i('FCM', 'Initialized successfully');
  } else {
    Log.w(
      'FCM',
      'Permission denied: ${settings.authorizationStatus}, switching to Firestore',
    );
    await _initializeFirestoreMode(container);
  }
}

/// 初始化 Firestore 实时监听模式
Future<void> _initializeFirestoreMode(ProviderContainer container) async {
  final firestoreService = container.read(firestoreMessageServiceProvider);
  await firestoreService.initialize();
  Log.i('Firestore', 'Realtime mode enabled');
}

/// 处理前台消息
void _handleForegroundMessage(RemoteMessage remoteMessage) {
  // 解析消息
  final message = FcmService.parseMessage(remoteMessage);
  if (message != null) {
    _container.read(messagesProvider.notifier).addMessage(message);
  }
}

/// 处理用户点击通知打开 App
void _handleMessageOpenedApp(RemoteMessage remoteMessage) {
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

/// 异步清理旧数据
/// 在 App 启动时异步执行，不阻塞启动流程
void _cleanupOldDataAsync(ProviderContainer container) {
  Future(() async {
    try {
      final db = container.read(db_service.databaseProvider);
      await db.cleanupOldData();
      Log.d('Database', 'Cleanup completed');
    } catch (e) {
      Log.e('Database', 'Cleanup failed', e);
    }
  });
}

/// 处理缓存的后台消息
/// 在 App 启动时调用，将 SharedPreferences 中缓存的消息添加到消息列表
Future<void> _processCachedBackgroundMessages(
  ProviderContainer container,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final backgroundMessagesJson = prefs.getString('background_messages');

    if (backgroundMessagesJson == null || backgroundMessagesJson.isEmpty) {
      return;
    }

    // 解析缓存的消息列表
    final List<dynamic> cachedMessages =
        jsonDecode(backgroundMessagesJson) as List<dynamic>;
    Log.d('FCM', 'Processing ${cachedMessages.length} cached messages');

    int processedCount = 0;
    int failedCount = 0;

    // 逐条处理消息
    for (final cachedMessage in cachedMessages) {
      try {
        final data = cachedMessage as Map<String, dynamic>;

        // 构造 RemoteMessage 对象来复用现有的解析逻辑
        // 注意：这里我们直接使用 data['data'] 中的信息
        final messageData = data['data'] as Map<String, dynamic>? ?? {};

        // 创建一个模拟的 RemoteMessage 用于解析
        final remoteMessage = RemoteMessage(
          messageId: data['messageId'] as String,
          data: messageData,
        );

        // 使用现有的 parseMessage 方法解析消息
        final message = FcmService.parseMessage(remoteMessage);

        if (message != null) {
          container.read(messagesProvider.notifier).addMessage(message);
          processedCount++;
        } else {
          Log.w('FCM', 'Failed to parse cached message: ${data['messageId']}');
          failedCount++;
        }
      } catch (e) {
        Log.w('FCM', 'Error processing cached message', e);
        failedCount++;
      }
    }

    Log.d('FCM', 'Cached messages: $processedCount ok, $failedCount failed');

    // 清空已处理的缓存消息
    await prefs.remove('background_messages');
  } catch (e) {
    Log.e('FCM', 'Failed to process cached background messages', e);
  }
}
