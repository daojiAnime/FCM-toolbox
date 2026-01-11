import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../common/logger.dart';
import 'connection_state.dart';
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
  bool _hasInitializedDataSource = false; // 追踪是否已完成初始数据源判断
  // 注：ref.listen 在 Riverpod 中会自动管理生命周期，无需手动取消

  // State 模式：状态机管理器
  late ConnectionStateMachine _stateMachine;

  // 降级后尝试恢复 hapi 的间隔
  static const _recoveryCheckInterval = Duration(minutes: 2);
  // 切换防抖时间（避免频繁切换）
  static const _switchDebounceTime = Duration(seconds: 30);

  void _init() {
    // 初始化状态机（默认为 FirebaseOnly 状态）
    _stateMachine = ConnectionStateMachine(const FirebaseOnlyState());

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

    // 注意：不在此处立即调用 _determineDataSource()
    // 因为此时 hapiConfigProvider 可能还未完成 init()
    // 数据源判断会在 _onHapiConfigChanged 首次触发时执行
  }

  /// 创建连接上下文
  ConnectionContext _createContext() {
    final hapiConfig = _ref.read(hapiConfigProvider);
    return ConnectionContext(
      isOnline: state.isOnline,
      hapiConfigured: hapiConfig.isConfigured,
      hapiEnabled: hapiConfig.enabled,
      startFirestore: _startFirestoreListening,
      stopFirestore: _stopFirestoreListening,
      reconnectHapi: () {
        final sseService = _ref.read(hapiSseServiceProvider);
        sseService?.reconnect();
      },
    );
  }

  /// 同步状态机状态到 ConnectionManagerState
  ///
  /// [fallbackReason] 可选的降级原因，与状态机同步合并为原子操作
  /// [clearFallbackReason] 是否清除降级原因
  void _syncStateFromStateMachine({
    String? fallbackReason,
    bool clearFallbackReason = false,
  }) {
    final currentState = _stateMachine.currentState;
    // 合并状态机同步和附加字段更新为单次原子操作
    state = state.copyWith(
      dataSource: currentState.dataSourceType,
      fallbackReason:
          clearFallbackReason ? null : (fallbackReason ?? state.fallbackReason),
    );
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

  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
    final wasOnline = state.isOnline;

    Log.i(
      'ConnMgr',
      'Connectivity changed: $results, online: $isOnline (was: $wasOnline)',
    );

    // 更新 ConnectionManagerState
    state = state.copyWith(isOnline: isOnline);

    // 使用状态机处理网络状态变化
    if (isOnline && !wasOnline) {
      // 网络恢复
      await _stateMachine.handleNetworkOnline(_createContext());
      _syncStateFromStateMachine();
    } else if (!isOnline && wasOnline) {
      // 网络断开
      await _stateMachine.handleNetworkOffline(_createContext());
      _syncStateFromStateMachine();
    }
  }

  void _onHapiConfigChanged(HapiConfig config) async {
    Log.i('ConnMgr', 'hapi config changed: enabled=${config.enabled}');

    // 首次调用时必须执行数据源判断（无论配置是否完整）
    if (!_hasInitializedDataSource) {
      _hasInitializedDataSource = true;
      Log.d('ConnMgr', 'First config load, determining data source');
      _determineDataSource();
      return;
    }

    // 后续配置变化：如果 hapi 被禁用，使用状态机处理
    if (!config.enabled || !config.isConfigured) {
      await _stateMachine.handleHapiDisabled(_createContext());
      _syncStateFromStateMachine();
    } else {
      // hapi 重新启用，重新确定数据源
      _determineDataSource();
    }
  }

  void _onHapiConnectionStateChanged(HapiConnectionState hapiState) async {
    final wasConnected = state.hapiConnected;
    final isConnected = hapiState.isConnected;
    final isReconnecting =
        hapiState.status == HapiConnectionStatus.reconnecting;

    // 更新连接状态（独立于状态机）
    state = state.copyWith(
      hapiConnected: isConnected,
      hapiReconnecting: isReconnecting,
      lastHapiError: hapiState.errorMessage,
    );

    // 使用状态机处理连接状态变化
    if (isConnected && !wasConnected) {
      // hapi 连接成功
      final hapiConfig = _ref.read(hapiConfigProvider);
      if (hapiConfig.isConfigured && hapiConfig.enabled) {
        Log.i('ConnMgr', 'SSE connected, switching to hapi mode');
        _fallbackTimer?.cancel();
        await _stateMachine.handleHapiConnected(_createContext());
        // 原子更新：同步状态机 + 清除降级原因
        _syncStateFromStateMachine(clearFallbackReason: true);
      }
    } else if (!isConnected && wasConnected) {
      // hapi 连接断开
      if (!isReconnecting) {
        final reason = hapiState.errorMessage ?? 'hapi 连接断开';
        await _stateMachine.handleHapiDisconnected(_createContext(), reason);
        // 原子更新：同步状态机 + 设置降级原因
        _syncStateFromStateMachine(fallbackReason: reason);
        _scheduleRecoveryCheck();
      }
    } else if (hapiState.status == HapiConnectionStatus.error) {
      // hapi 错误
      final reason = hapiState.errorMessage ?? 'hapi 连接错误';
      await _stateMachine.handleHapiError(_createContext(), reason);
      // 原子更新：同步状态机 + 设置降级原因
      _syncStateFromStateMachine(fallbackReason: reason);
      _scheduleRecoveryCheck();
    }
  }

  void _determineDataSource() async {
    final hapiConfig = _ref.read(hapiConfigProvider);

    if (!hapiConfig.isConfigured || !hapiConfig.enabled) {
      // hapi 未配置或已禁用，使用 Firebase
      await _stateMachine.handleHapiDisabled(_createContext());
      // 原子更新：同步状态机 + 清除降级原因
      _syncStateFromStateMachine(clearFallbackReason: true);
      Log.i('ConnMgr', 'Using Firebase only (hapi not configured)');
      return;
    }

    // hapi 已配置，检查连接状态
    if (state.hapiConnected) {
      await _stateMachine.handleHapiConnected(_createContext());
      // 原子更新：同步状态机 + 清除降级原因
      _syncStateFromStateMachine(clearFallbackReason: true);
      Log.i('ConnMgr', 'Using hapi as primary');
    } else {
      // hapi 配置了但未连接
      final reason = state.lastHapiError ?? '等待 hapi 连接';
      await _stateMachine.handleHapiDisconnected(_createContext(), reason);
      // 原子更新：同步状态机 + 设置降级原因
      _syncStateFromStateMachine(fallbackReason: reason);
      Log.i('ConnMgr', 'Using Firebase fallback');
      _scheduleRecoveryCheck();
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

  void _attemptHapiRecovery() async {
    final hapiConfig = _ref.read(hapiConfigProvider);
    if (!hapiConfig.isConfigured || !hapiConfig.enabled) return;

    final sseService = _ref.read(hapiSseServiceProvider);
    if (sseService == null) return;

    // 只有在完全断开且不在重连过程中时才尝试恢复
    final currentStatus = sseService.currentState.status;
    if (currentStatus == HapiConnectionStatus.disconnected ||
        currentStatus == HapiConnectionStatus.error) {
      Log.i('ConnMgr', 'Attempting hapi recovery (status: $currentStatus)...');

      // 使用状态机处理恢复尝试
      await _stateMachine.handleAttemptRecovery(_createContext());
      _syncStateFromStateMachine();
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
  Future<void> forceFallback() async {
    final hapiConfig = _ref.read(hapiConfigProvider);
    if (!hapiConfig.isConfigured || !hapiConfig.enabled) {
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

    const reason = '用户手动切换';
    Log.i('ConnMgr', '开始切换到 Firebase 降级模式: $reason');

    // 使用状态机处理降级
    await _stateMachine.handleHapiDisconnected(_createContext(), reason);
    // 原子更新：同步状态机 + 设置降级原因
    _syncStateFromStateMachine(fallbackReason: reason);

    _lastSwitchTime = DateTime.now();
    Log.i('ConnMgr', '✅ 成功切换到 Firebase 降级模式');

    _scheduleRecoveryCheck();
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
