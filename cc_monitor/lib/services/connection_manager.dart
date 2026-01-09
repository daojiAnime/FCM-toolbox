import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../common/logger.dart';
import 'hapi/hapi_config_service.dart';
import 'hapi/hapi_sse_service.dart';
import 'firestore_message_service.dart';

/// 数据源类型
enum DataSourceType {
  /// 仅使用 Firebase（hapi 未配置或已禁用）
  firebaseOnly,

  /// hapi 主要，Firebase 备用
  hapiPrimary,

  /// Firebase 降级模式（hapi 配置了但连接失败）
  firebaseFallback,
}

/// 连接状态
class ConnectionManagerState {
  const ConnectionManagerState({
    this.dataSource = DataSourceType.firebaseOnly,
    this.isOnline = true,
    this.hapiConnected = false,
    this.hapiReconnecting = false,
    this.lastHapiError,
    this.fallbackReason,
  });

  final DataSourceType dataSource;
  final bool isOnline;
  final bool hapiConnected;
  final bool hapiReconnecting;
  final String? lastHapiError;
  final String? fallbackReason;

  /// 是否处于降级模式
  bool get isFallbackMode => dataSource == DataSourceType.firebaseFallback;

  /// 是否使用 hapi 作为主要数据源
  bool get isHapiActive =>
      dataSource == DataSourceType.hapiPrimary && hapiConnected;

  ConnectionManagerState copyWith({
    DataSourceType? dataSource,
    bool? isOnline,
    bool? hapiConnected,
    bool? hapiReconnecting,
    String? lastHapiError,
    String? fallbackReason,
  }) {
    return ConnectionManagerState(
      dataSource: dataSource ?? this.dataSource,
      isOnline: isOnline ?? this.isOnline,
      hapiConnected: hapiConnected ?? this.hapiConnected,
      hapiReconnecting: hapiReconnecting ?? this.hapiReconnecting,
      lastHapiError: lastHapiError,
      fallbackReason: fallbackReason,
    );
  }

  @override
  String toString() {
    return 'ConnectionManagerState(dataSource: $dataSource, isOnline: $isOnline, '
        'hapiConnected: $hapiConnected, hapiReconnecting: $hapiReconnecting)';
  }
}

/// 连接管理器 - 管理 hapi 和 Firebase 的双通道连接
class ConnectionManager extends StateNotifier<ConnectionManagerState> {
  ConnectionManager(this._ref) : super(const ConnectionManagerState()) {
    _init();
  }

  final Ref _ref;
  StreamSubscription? _connectivitySubscription;
  Timer? _fallbackTimer;
  DateTime? _lastSwitchTime;
  // 注：ref.listen 在 Riverpod 中会自动管理生命周期，无需手动取消

  // 降级后尝试恢复 hapi 的间隔
  static const _recoveryCheckInterval = Duration(minutes: 2);
  // 切换防抖时间（避免频繁切换）
  static const _switchDebounceTime = Duration(seconds: 30);

  void _init() {
    // 监听网络连接状态
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // 初始化时检查网络状态
    _checkInitialConnectivity();

    // 监听 hapi 配置变化
    _ref.listen(hapiConfigProvider, (previous, next) {
      _onHapiConfigChanged(next);
    });

    // 监听 hapi 连接状态
    _ref.listen(hapiConnectionStateProvider, (previous, next) {
      next.whenData(_onHapiConnectionStateChanged);
    });

    // 初始化数据源
    _determineDataSource();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      // 延迟初始网络检查，让 SSE 有时间完成初始化
      // 避免与 SSE 初始连接产生竞态条件
      await Future.delayed(const Duration(milliseconds: 500));
      final result = await Connectivity().checkConnectivity();
      _onConnectivityChanged(result);
    } catch (e) {
      Log.e('ConnMgr', 'Failed to check connectivity', e);
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
    final wasOnline = state.isOnline;

    Log.i(
      'ConnMgr',
      'Connectivity changed: $results, online: $isOnline (was: $wasOnline)',
    );

    state = state.copyWith(isOnline: isOnline);

    // 只有当网络状态真正变化时才采取行动
    if (isOnline && !wasOnline) {
      // 网络恢复，尝试重新连接 hapi
      _attemptHapiRecovery();
    } else if (!isOnline && wasOnline) {
      // 网络断开，切换到离线模式
      _switchToFallback('网络已断开');
    }
  }

  void _onHapiConfigChanged(HapiConfig config) {
    Log.i('ConnMgr', 'hapi config changed: enabled=${config.enabled}');
    _determineDataSource();
  }

  void _onHapiConnectionStateChanged(HapiConnectionState hapiState) {
    final wasConnected = state.hapiConnected;
    final isConnected = hapiState.isConnected;
    final isReconnecting =
        hapiState.status == HapiConnectionStatus.reconnecting;

    // 更新连接状态
    state = state.copyWith(
      hapiConnected: isConnected,
      hapiReconnecting: isReconnecting,
      lastHapiError: hapiState.errorMessage,
    );

    if (isConnected && !wasConnected) {
      // hapi 连接成功，立即更新数据源为 hapi 模式
      // 避免 _switchToHapi 的防抖逻辑导致状态不同步
      final hapiConfig = _ref.read(hapiConfigProvider);
      if (hapiConfig.isConfigured && hapiConfig.enabled) {
        Log.i('ConnMgr', 'SSE connected, switching to hapi mode');
        _fallbackTimer?.cancel();
        state = state.copyWith(
          dataSource: DataSourceType.hapiPrimary,
          fallbackReason: null,
        );
        // 异步停止 Firestore 监听
        _stopFirestoreListening();
      }
    } else if (!isConnected && wasConnected) {
      // hapi 连接断开
      if (!isReconnecting) {
        _switchToFallback(hapiState.errorMessage ?? 'hapi 连接断开');
      }
    } else if (hapiState.status == HapiConnectionStatus.error) {
      // hapi 错误，切换到降级模式
      _switchToFallback(hapiState.errorMessage ?? 'hapi 连接错误');
    }
  }

  void _determineDataSource() {
    final hapiConfig = _ref.read(hapiConfigProvider);

    if (!hapiConfig.isConfigured || !hapiConfig.enabled) {
      // hapi 未配置或已禁用，使用 Firebase
      state = state.copyWith(
        dataSource: DataSourceType.firebaseOnly,
        fallbackReason: null,
      );
      Log.i('ConnMgr', 'Using Firebase only (hapi not configured)');
      return;
    }

    // hapi 已配置，检查连接状态
    if (state.hapiConnected) {
      state = state.copyWith(
        dataSource: DataSourceType.hapiPrimary,
        fallbackReason: null,
      );
      Log.i('ConnMgr', 'Using hapi as primary');
    } else {
      // hapi 配置了但未连接
      state = state.copyWith(
        dataSource: DataSourceType.firebaseFallback,
        fallbackReason: state.lastHapiError ?? '等待 hapi 连接',
      );
      Log.i('ConnMgr', 'Using Firebase fallback');
      _scheduleRecoveryCheck();
    }
  }

  Future<void> _switchToFallback(String reason) async {
    final hapiConfig = _ref.read(hapiConfigProvider);
    if (!hapiConfig.isConfigured || !hapiConfig.enabled) {
      // hapi 本来就没启用，不需要降级
      return;
    }

    // 防抖检查
    if (_lastSwitchTime != null) {
      final timeSinceLastSwitch = DateTime.now().difference(_lastSwitchTime!);
      if (timeSinceLastSwitch < _switchDebounceTime) {
        Log.w('ConnMgr', '切换请求被防抖拒绝 (距上次切换 ${timeSinceLastSwitch.inSeconds}秒)');
        return;
      }
    }

    Log.i('ConnMgr', '开始切换到 Firebase 降级模式: $reason');

    try {
      // 步骤 1: 先启动 Firestore 实时监听
      await _startFirestoreListening();
      Log.i('ConnMgr', 'Firestore 监听已启动');

      // 步骤 2: 等待短暂时间确保 Firestore 监听已建立
      await Future.delayed(const Duration(seconds: 1));
      Log.i('ConnMgr', 'Firestore 监听已稳定');

      // 步骤 3: 更新状态为降级模式
      state = state.copyWith(
        dataSource: DataSourceType.firebaseFallback,
        fallbackReason: reason,
      );

      // 步骤 4: 等待短暂过渡期（确保不会丢失消息）
      await Future.delayed(const Duration(seconds: 1));

      _lastSwitchTime = DateTime.now();
      Log.i('ConnMgr', '✅ 成功切换到 Firebase 降级模式');

      // 安排定期恢复检查
      _scheduleRecoveryCheck();
    } catch (e) {
      Log.e('ConnMgr', '❌ 切换到 Firebase 失败', e);
      // 切换失败，保持当前状态
    }
  }

  void _scheduleRecoveryCheck() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(_recoveryCheckInterval, (_) {
      if (state.isFallbackMode && state.isOnline) {
        _attemptHapiRecovery();
      }
    });
  }

  void _attemptHapiRecovery() {
    final hapiConfig = _ref.read(hapiConfigProvider);
    if (!hapiConfig.isConfigured || !hapiConfig.enabled) return;

    final sseService = _ref.read(hapiSseServiceProvider);
    if (sseService == null) return;

    // 只有在完全断开且不在重连过程中时才尝试恢复
    // 避免与正在进行的连接产生竞态条件
    final currentStatus = sseService.currentState.status;
    if (currentStatus == HapiConnectionStatus.disconnected ||
        currentStatus == HapiConnectionStatus.error) {
      Log.i('ConnMgr', 'Attempting hapi recovery (status: $currentStatus)...');
      sseService.reconnect();
    }
  }

  Future<void> _startFirestoreListening() async {
    try {
      final firestoreService = _ref.read(firestoreMessageServiceProvider);
      await firestoreService.initialize();
      Log.i('ConnMgr', 'Started Firestore listening');
    } catch (e) {
      Log.e('ConnMgr', 'Failed to start Firestore', e);
      rethrow;
    }
  }

  void _stopFirestoreListening() {
    try {
      final firestoreService = _ref.read(firestoreMessageServiceProvider);
      firestoreService.dispose();
      Log.i('ConnMgr', 'Stopped Firestore listening');
    } catch (e) {
      Log.e('ConnMgr', 'Failed to stop Firestore', e);
    }
  }

  /// 手动触发 hapi 重连
  void forceReconnectHapi() {
    final sseService = _ref.read(hapiSseServiceProvider);
    sseService?.reconnect();
  }

  /// 手动切换到 Firebase 模式
  void forceFallback() {
    _switchToFallback('用户手动切换');
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }
}

/// 连接管理器 Provider
final connectionManagerProvider =
    StateNotifierProvider<ConnectionManager, ConnectionManagerState>((ref) {
      return ConnectionManager(ref);
    });

/// 当前数据源 Provider
final currentDataSourceProvider = Provider<DataSourceType>((ref) {
  return ref.watch(connectionManagerProvider).dataSource;
});

/// 是否处于降级模式 Provider
final isFallbackModeProvider = Provider<bool>((ref) {
  return ref.watch(connectionManagerProvider).isFallbackMode;
});

/// 降级原因 Provider
final fallbackReasonProvider = Provider<String?>((ref) {
  return ref.watch(connectionManagerProvider).fallbackReason;
});
