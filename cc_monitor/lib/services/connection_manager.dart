import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  // 注：ref.listen 在 Riverpod 中会自动管理生命周期，无需手动取消

  // 降级后尝试恢复 hapi 的间隔
  static const _recoveryCheckInterval = Duration(minutes: 2);

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
      final result = await Connectivity().checkConnectivity();
      _onConnectivityChanged(result);
    } catch (e) {
      debugPrint('[ConnectionManager] Failed to check connectivity: $e');
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    debugPrint(
      '[ConnectionManager] Connectivity changed: $results, online: $isOnline',
    );

    state = state.copyWith(isOnline: isOnline);

    if (isOnline) {
      // 网络恢复，尝试重新连接 hapi
      _attemptHapiRecovery();
    } else {
      // 网络断开，切换到离线模式
      _switchToFallback('网络已断开');
    }
  }

  void _onHapiConfigChanged(HapiConfig config) {
    debugPrint(
      '[ConnectionManager] hapi config changed: enabled=${config.enabled}',
    );
    _determineDataSource();
  }

  void _onHapiConnectionStateChanged(HapiConnectionState hapiState) {
    debugPrint('[ConnectionManager] hapi state changed: ${hapiState.status}');

    final wasConnected = state.hapiConnected;
    final isConnected = hapiState.isConnected;
    final isReconnecting =
        hapiState.status == HapiConnectionStatus.reconnecting;

    state = state.copyWith(
      hapiConnected: isConnected,
      hapiReconnecting: isReconnecting,
      lastHapiError: hapiState.errorMessage,
    );

    if (isConnected && !wasConnected) {
      // hapi 连接成功，切换回 hapi 模式
      _switchToHapi();
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
      debugPrint(
        '[ConnectionManager] Using Firebase only (hapi not configured)',
      );
      return;
    }

    // hapi 已配置，检查连接状态
    if (state.hapiConnected) {
      state = state.copyWith(
        dataSource: DataSourceType.hapiPrimary,
        fallbackReason: null,
      );
      debugPrint('[ConnectionManager] Using hapi as primary');
    } else {
      // hapi 配置了但未连接
      state = state.copyWith(
        dataSource: DataSourceType.firebaseFallback,
        fallbackReason: state.lastHapiError ?? '等待 hapi 连接',
      );
      debugPrint('[ConnectionManager] Using Firebase fallback');
      _scheduleRecoveryCheck();
    }
  }

  void _switchToHapi() {
    final hapiConfig = _ref.read(hapiConfigProvider);
    if (!hapiConfig.isConfigured || !hapiConfig.enabled) return;

    debugPrint('[ConnectionManager] Switching to hapi');
    _fallbackTimer?.cancel();

    state = state.copyWith(
      dataSource: DataSourceType.hapiPrimary,
      fallbackReason: null,
    );

    // 停止 Firestore 实时监听（节省资源）
    _stopFirestoreListening();
  }

  void _switchToFallback(String reason) {
    final hapiConfig = _ref.read(hapiConfigProvider);
    if (!hapiConfig.isConfigured || !hapiConfig.enabled) {
      // hapi 本来就没启用，不需要降级
      return;
    }

    debugPrint('[ConnectionManager] Switching to Firebase fallback: $reason');

    state = state.copyWith(
      dataSource: DataSourceType.firebaseFallback,
      fallbackReason: reason,
    );

    // 启动 Firestore 实时监听
    _startFirestoreListening();

    // 安排定期恢复检查
    _scheduleRecoveryCheck();
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
    if (sseService != null && !sseService.isConnected) {
      debugPrint('[ConnectionManager] Attempting hapi recovery...');
      sseService.reconnect();
    }
  }

  void _startFirestoreListening() {
    try {
      final firestoreService = _ref.read(firestoreMessageServiceProvider);
      firestoreService.initialize();
      debugPrint('[ConnectionManager] Started Firestore listening');
    } catch (e) {
      debugPrint('[ConnectionManager] Failed to start Firestore: $e');
    }
  }

  void _stopFirestoreListening() {
    try {
      final firestoreService = _ref.read(firestoreMessageServiceProvider);
      firestoreService.dispose();
      debugPrint('[ConnectionManager] Stopped Firestore listening');
    } catch (e) {
      debugPrint('[ConnectionManager] Failed to stop Firestore: $e');
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
