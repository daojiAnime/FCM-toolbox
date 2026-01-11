import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'common/logger.dart';
import 'common/theme.dart';
import 'common/constants.dart';
import 'common/navigator_key.dart';
import 'pages/home_page.dart';
import 'providers/settings_provider.dart';
import 'services/hapi/hapi_sse_service.dart';
import 'services/toast_service.dart';

/// CC Monitor 应用
class CCMonitorApp extends ConsumerStatefulWidget {
  const CCMonitorApp({super.key});

  @override
  ConsumerState<CCMonitorApp> createState() => _CCMonitorAppState();
}

class _CCMonitorAppState extends ConsumerState<CCMonitorApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _updateVisibility(state);
  }

  /// 根据应用生命周期更新服务可见性
  void _updateVisibility(AppLifecycleState state) {
    final isVisible = state == AppLifecycleState.resumed;
    Log.d('App', 'Lifecycle changed: $state (visible: $isVisible)');

    // 应用进入后台时,可以考虑断开 SSE 连接以节省资源
    // 应用恢复时重新连接
    if (!isVisible) {
      try {
        final sseService = ref.read(hapiSseServiceProvider);
        sseService?.disconnect();
        Log.d('App', 'SSE disconnected (app in background)');
      } catch (e) {
        Log.w('App', 'Failed to disconnect SSE', e);
      }
    } else {
      try {
        final sseService = ref.read(hapiSseServiceProvider);
        if (sseService != null && !sseService.isConnected) {
          sseService.connect();
          Log.d('App', 'SSE reconnected (app resumed)');
        }
      } catch (e) {
        Log.w('App', 'Failed to reconnect SSE', e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const HomePage(),
    );
  }
}
