import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'common/logger.dart';
import 'common/theme.dart';
import 'common/constants.dart';
import 'common/navigator_key.dart';
import 'pages/home_page.dart';
import 'providers/settings_provider.dart';
import 'services/hapi/hapi_api_service.dart';
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
    // 初始化时设置为可见
    _updateVisibility(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _updateVisibility(true);
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _updateVisibility(false);
    }
  }

  /// 更新 hapi 服务器的可见性状态
  void _updateVisibility(bool visible) {
    final apiService = ref.read(hapiApiServiceProvider);
    final sseService = ref.read(hapiSseServiceProvider);
    if (apiService != null && sseService != null) {
      final subscriptionId = sseService.subscriptionId;
      apiService
          .setVisibility(visible, subscriptionId: subscriptionId)
          .catchError((e) {
            Log.e('App', 'Failed to update visibility: $e');
            return false;
          });
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
