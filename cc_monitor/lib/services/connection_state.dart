import '../common/logger.dart';
import 'connection_manager.dart';

/// 连接状态接口 (State 模式)
/// 封装不同连接状态下的行为逻辑
abstract class ConnectionState {
  const ConnectionState();

  /// 状态名称（用于日志）
  String get stateName;

  /// 当前数据源类型
  DataSourceType get dataSourceType;

  /// 处理网络连接恢复
  ConnectionState onNetworkOnline(ConnectionContext context) {
    Log.i('ConnState', '[$stateName] Network online');
    return this; // 默认不改变状态
  }

  /// 处理网络连接断开
  ConnectionState onNetworkOffline(ConnectionContext context) {
    Log.w('ConnState', '[$stateName] Network offline');
    return const DisconnectedState();
  }

  /// 处理 hapi 连接成功
  ConnectionState onHapiConnected(ConnectionContext context) {
    Log.i('ConnState', '[$stateName] hapi connected');
    return const HapiConnectedState();
  }

  /// 处理 hapi 连接断开
  ConnectionState onHapiDisconnected(
    ConnectionContext context,
    String? reason,
  ) {
    Log.w('ConnState', '[$stateName] hapi disconnected: $reason');
    return FirebaseFallbackState(reason ?? 'hapi 连接断开');
  }

  /// 处理 hapi 连接错误
  ConnectionState onHapiError(ConnectionContext context, String error) {
    Log.e('ConnState', '[$stateName] hapi error: $error');
    return FirebaseFallbackState(error);
  }

  /// 处理 hapi 配置禁用
  ConnectionState onHapiDisabled(ConnectionContext context) {
    Log.i('ConnState', '[$stateName] hapi disabled');
    return const FirebaseOnlyState();
  }

  /// 尝试恢复 hapi 连接
  ConnectionState onAttemptRecovery(ConnectionContext context) {
    Log.i('ConnState', '[$stateName] Attempting recovery');
    return this; // 默认不改变状态
  }

  /// 进入状态时的操作（钩子方法）
  Future<void> onEnter(ConnectionContext context) async {
    Log.d('ConnState', 'Entering state: $stateName');
  }

  /// 离开状态时的操作（钩子方法）
  Future<void> onExit(ConnectionContext context) async {
    Log.d('ConnState', 'Exiting state: $stateName');
  }
}

/// 连接上下文 - 提供状态转换所需的依赖
class ConnectionContext {
  const ConnectionContext({
    required this.isOnline,
    required this.hapiConfigured,
    required this.hapiEnabled,
    this.startFirestore,
    this.stopFirestore,
    this.reconnectHapi,
  });

  final bool isOnline;
  final bool hapiConfigured;
  final bool hapiEnabled;
  final Future<void> Function()? startFirestore;
  final void Function()? stopFirestore;
  final void Function()? reconnectHapi;

  bool get hapiAvailable => hapiConfigured && hapiEnabled;
}

// ==================== 具体状态实现 ====================

/// Firebase 单一模式（hapi 未配置或已禁用）
class FirebaseOnlyState extends ConnectionState {
  const FirebaseOnlyState();

  @override
  String get stateName => 'FirebaseOnly';

  @override
  DataSourceType get dataSourceType => DataSourceType.firebaseOnly;

  @override
  ConnectionState onHapiConnected(ConnectionContext context) {
    if (context.hapiAvailable) {
      return const HapiConnectedState();
    }
    return this; // hapi 不可用，保持当前状态
  }
}

/// hapi 已连接状态（主要模式）
class HapiConnectedState extends ConnectionState {
  const HapiConnectedState();

  @override
  String get stateName => 'HapiConnected';

  @override
  DataSourceType get dataSourceType => DataSourceType.hapiPrimary;

  @override
  Future<void> onEnter(ConnectionContext context) async {
    await super.onEnter(context);
    // 进入 hapi 模式时停止 Firestore 监听
    context.stopFirestore?.call();
  }

  @override
  ConnectionState onNetworkOffline(ConnectionContext context) {
    // 网络断开，切换到断开状态
    return const DisconnectedState();
  }

  @override
  ConnectionState onHapiDisabled(ConnectionContext context) {
    return const FirebaseOnlyState();
  }
}

/// Firebase 降级模式（hapi 配置了但连接失败）
class FirebaseFallbackState extends ConnectionState {
  const FirebaseFallbackState(this.reason);

  final String reason;

  @override
  String get stateName => 'FirebaseFallback';

  @override
  DataSourceType get dataSourceType => DataSourceType.firebaseFallback;

  @override
  Future<void> onEnter(ConnectionContext context) async {
    await super.onEnter(context);
    // 进入降级模式时启动 Firestore 监听
    await context.startFirestore?.call();
  }

  @override
  ConnectionState onNetworkOnline(ConnectionContext context) {
    // 网络恢复，尝试重连 hapi
    return ReconnectingState(reason);
  }

  @override
  ConnectionState onAttemptRecovery(ConnectionContext context) {
    if (context.isOnline && context.hapiAvailable) {
      context.reconnectHapi?.call();
      return ReconnectingState(reason);
    }
    return this;
  }

  @override
  ConnectionState onHapiDisabled(ConnectionContext context) {
    return const FirebaseOnlyState();
  }
}

/// 正在重连 hapi 状态
class ReconnectingState extends ConnectionState {
  const ReconnectingState(this.previousReason);

  final String previousReason;

  @override
  String get stateName => 'Reconnecting';

  @override
  DataSourceType get dataSourceType => DataSourceType.firebaseFallback;

  @override
  Future<void> onEnter(ConnectionContext context) async {
    await super.onEnter(context);
    // 确保 Firestore 监听处于活动状态
    if (context.hapiAvailable) {
      context.reconnectHapi?.call();
    }
  }

  @override
  ConnectionState onHapiError(ConnectionContext context, String error) {
    // 重连失败，返回降级模式
    return FirebaseFallbackState(error);
  }

  @override
  ConnectionState onNetworkOffline(ConnectionContext context) {
    return const DisconnectedState();
  }
}

/// 完全断开状态（无网络）
class DisconnectedState extends ConnectionState {
  const DisconnectedState();

  @override
  String get stateName => 'Disconnected';

  @override
  DataSourceType get dataSourceType => DataSourceType.firebaseOnly;

  @override
  ConnectionState onNetworkOnline(ConnectionContext context) {
    // 网络恢复
    if (context.hapiAvailable) {
      return const ReconnectingState('Network restored');
    }
    return const FirebaseOnlyState();
  }

  @override
  ConnectionState onHapiConnected(ConnectionContext context) {
    // 不应该在断网状态下收到连接事件，保持当前状态
    Log.w('ConnState', '[Disconnected] Unexpected hapi connected event');
    return this;
  }

  @override
  ConnectionState onHapiDisconnected(
    ConnectionContext context,
    String? reason,
  ) {
    // 已经断开，保持当前状态
    return this;
  }
}

/// 状态机管理器（可选）
/// 管理状态转换并调用钩子方法
class ConnectionStateMachine {
  ConnectionStateMachine(ConnectionState initialState)
    : _currentState = initialState;

  ConnectionState _currentState;

  ConnectionState get currentState => _currentState;

  /// 转换到新状态
  Future<void> transitionTo(
    ConnectionState newState,
    ConnectionContext context,
  ) async {
    if (newState.runtimeType == _currentState.runtimeType) {
      Log.d('StateMachine', 'Already in state: ${newState.stateName}');
      return;
    }

    Log.i(
      'StateMachine',
      'State transition: ${_currentState.stateName} → ${newState.stateName}',
    );

    await _currentState.onExit(context);
    _currentState = newState;
    await _currentState.onEnter(context);
  }

  /// 处理事件并自动转换状态
  Future<void> handleNetworkOnline(ConnectionContext context) async {
    final newState = _currentState.onNetworkOnline(context);
    await transitionTo(newState, context);
  }

  Future<void> handleNetworkOffline(ConnectionContext context) async {
    final newState = _currentState.onNetworkOffline(context);
    await transitionTo(newState, context);
  }

  Future<void> handleHapiConnected(ConnectionContext context) async {
    final newState = _currentState.onHapiConnected(context);
    await transitionTo(newState, context);
  }

  Future<void> handleHapiDisconnected(
    ConnectionContext context,
    String? reason,
  ) async {
    final newState = _currentState.onHapiDisconnected(context, reason);
    await transitionTo(newState, context);
  }

  Future<void> handleHapiError(ConnectionContext context, String error) async {
    final newState = _currentState.onHapiError(context, error);
    await transitionTo(newState, context);
  }

  Future<void> handleHapiDisabled(ConnectionContext context) async {
    final newState = _currentState.onHapiDisabled(context);
    await transitionTo(newState, context);
  }

  Future<void> handleAttemptRecovery(ConnectionContext context) async {
    final newState = _currentState.onAttemptRecovery(context);
    await transitionTo(newState, context);
  }
}
