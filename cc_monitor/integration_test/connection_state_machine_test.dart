import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cc_monitor/services/connection_state.dart';
import 'package:cc_monitor/services/connection_manager.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Connection State Machine Integration', () {
    late ConnectionStateMachine stateMachine;
    late ConnectionContext mockContext;

    setUp(() {
      // 创建状态机，初始状态为 FirebaseOnly
      stateMachine = ConnectionStateMachine(const FirebaseOnlyState());

      // 创建模拟上下文
      mockContext = const ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
      );
    });

    test('Initial state is FirebaseOnly', () {
      expect(stateMachine.currentState, isA<FirebaseOnlyState>());
      expect(
        stateMachine.currentState.dataSourceType,
        DataSourceType.firebaseOnly,
      );
    });

    test('FirebaseOnly → HapiConnected when hapi connects', () async {
      // 初始状态: FirebaseOnly
      expect(stateMachine.currentState, isA<FirebaseOnlyState>());

      // 触发 hapi 连接成功
      await stateMachine.handleHapiConnected(mockContext);

      // 验证状态转换到 HapiConnected
      expect(stateMachine.currentState, isA<HapiConnectedState>());
      expect(
        stateMachine.currentState.dataSourceType,
        DataSourceType.hapiPrimary,
      );
    });

    test('HapiConnected → FirebaseFallback when hapi disconnects', () async {
      // 先切换到 HapiConnected 状态
      await stateMachine.handleHapiConnected(mockContext);
      expect(stateMachine.currentState, isA<HapiConnectedState>());

      // 触发 hapi 断开
      await stateMachine.handleHapiDisconnected(
        mockContext,
        'Connection timeout',
      );

      // 验证状态转换到 FirebaseFallback
      expect(stateMachine.currentState, isA<FirebaseFallbackState>());
      expect(
        stateMachine.currentState.dataSourceType,
        DataSourceType.firebaseFallback,
      );

      // 验证降级原因
      final fallbackState = stateMachine.currentState as FirebaseFallbackState;
      expect(fallbackState.reason, 'Connection timeout');
    });

    test('Network offline → Disconnected state', () async {
      // 任意初始状态
      await stateMachine.handleHapiConnected(mockContext);
      expect(stateMachine.currentState, isA<HapiConnectedState>());

      // 触发网络离线
      final offlineContext = const ConnectionContext(
        isOnline: false,
        hapiConfigured: true,
        hapiEnabled: true,
      );
      await stateMachine.handleNetworkOffline(offlineContext);

      // 验证状态转换到 Disconnected
      expect(stateMachine.currentState, isA<DisconnectedState>());
    });

    test('Network online triggers recovery from Disconnected', () async {
      // 先进入 Disconnected 状态
      final offlineContext = const ConnectionContext(
        isOnline: false,
        hapiConfigured: true,
        hapiEnabled: true,
      );
      await stateMachine.handleNetworkOffline(offlineContext);
      expect(stateMachine.currentState, isA<DisconnectedState>());

      // 模拟网络恢复
      await stateMachine.handleNetworkOnline(mockContext);

      // 验证状态转换（应该尝试重连 hapi）
      // 由于没有实际的 hapi 连接，可能回到 FirebaseOnly 或 FirebaseFallback
      expect(
        stateMachine.currentState.dataSourceType,
        anyOf(DataSourceType.firebaseOnly, DataSourceType.firebaseFallback),
      );
    });

    test('Hapi disabled → FirebaseOnly from any state', () async {
      // 先进入 HapiConnected 状态
      await stateMachine.handleHapiConnected(mockContext);
      expect(stateMachine.currentState, isA<HapiConnectedState>());

      // 禁用 hapi
      final disabledContext = const ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: false,
      );
      await stateMachine.handleHapiDisabled(disabledContext);

      // 验证状态回到 FirebaseOnly
      expect(stateMachine.currentState, isA<FirebaseOnlyState>());
    });

    test('Hapi error triggers fallback with error message', () async {
      // 先进入 HapiConnected 状态
      await stateMachine.handleHapiConnected(mockContext);
      expect(stateMachine.currentState, isA<HapiConnectedState>());

      // 触发 hapi 错误
      await stateMachine.handleHapiError(mockContext, 'Network error: 500');

      // 验证状态转换到 FirebaseFallback
      expect(stateMachine.currentState, isA<FirebaseFallbackState>());
      final fallbackState = stateMachine.currentState as FirebaseFallbackState;
      expect(fallbackState.reason, contains('500'));
    });

    test('State transition calls onEnter/onExit hooks', () async {
      final hookCalls = <String>[];

      // 创建自定义上下文，追踪钩子调用
      final trackingContext = ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
        startFirestore: () async {
          hookCalls.add('startFirestore');
        },
        stopFirestore: () {
          hookCalls.add('stopFirestore');
        },
        reconnectHapi: () {
          hookCalls.add('reconnectHapi');
        },
      );

      // 执行状态转换: FirebaseOnly → HapiConnected
      await stateMachine.handleHapiConnected(trackingContext);

      // HapiConnected 的 onEnter 应该调用 stopFirestore
      expect(hookCalls, contains('stopFirestore'));

      // 执行状态转换: HapiConnected → FirebaseFallback
      hookCalls.clear();
      await stateMachine.handleHapiDisconnected(
        trackingContext,
        'Test disconnect',
      );

      // FirebaseFallback 的 onEnter 应该调用 startFirestore
      expect(hookCalls, contains('startFirestore'));
    });

    test('FirebaseFallback recovery attempt', () async {
      // 先进入 FirebaseFallback 状态
      await stateMachine.handleHapiConnected(mockContext);
      await stateMachine.handleHapiDisconnected(mockContext, 'Test fallback');
      expect(stateMachine.currentState, isA<FirebaseFallbackState>());

      // 模拟恢复尝试
      final recoveryContext = ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
        reconnectHapi: () {
          // 模拟重连尝试
        },
      );
      await stateMachine.handleAttemptRecovery(recoveryContext);

      // FirebaseFallback 状态应该尝试重连（但状态暂时不变）
      expect(stateMachine.currentState, isA<FirebaseFallbackState>());
    });

    test('Multiple rapid state transitions are handled correctly', () async {
      // 快速执行多次状态转换
      await stateMachine.handleHapiConnected(mockContext);
      expect(stateMachine.currentState, isA<HapiConnectedState>());

      await stateMachine.handleHapiDisconnected(mockContext, 'Transition 1');
      expect(stateMachine.currentState, isA<FirebaseFallbackState>());

      await stateMachine.handleHapiConnected(mockContext);
      expect(stateMachine.currentState, isA<HapiConnectedState>());

      await stateMachine.handleHapiDisconnected(mockContext, 'Transition 2');
      expect(stateMachine.currentState, isA<FirebaseFallbackState>());

      // 最终应该停留在正确的状态
      final finalState = stateMachine.currentState as FirebaseFallbackState;
      expect(finalState.reason, 'Transition 2');
    });

    test('State machine handles hapi unavailable context', () async {
      // 创建 hapi 不可用的上下文
      final unavailableContext = const ConnectionContext(
        isOnline: true,
        hapiConfigured: false,
        hapiEnabled: false,
      );

      // 尝试连接 hapi
      await stateMachine.handleHapiConnected(unavailableContext);

      // 应该保持在 FirebaseOnly 状态（因为 hapi 不可用）
      expect(stateMachine.currentState, isA<FirebaseOnlyState>());
    });

    test('Disconnected state handles network online recovery', () async {
      // 进入 Disconnected 状态
      final offlineContext = const ConnectionContext(
        isOnline: false,
        hapiConfigured: true,
        hapiEnabled: true,
      );
      await stateMachine.handleNetworkOffline(offlineContext);
      expect(stateMachine.currentState, isA<DisconnectedState>());

      // 网络恢复，且 hapi 可用
      final onlineContext = ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
        reconnectHapi: () {
          // 应该尝试重连 hapi
        },
      );
      await stateMachine.handleNetworkOnline(onlineContext);

      // 验证状态已转换（具体状态取决于恢复逻辑）
      expect(stateMachine.currentState, isNot(isA<DisconnectedState>()));
    });
  });

  group('Connection State Lifecycle', () {
    test('FirebaseOnlyState lifecycle', () async {
      final stateMachine = ConnectionStateMachine(const FirebaseOnlyState());
      final context = const ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      // 验证初始状态
      expect(stateMachine.currentState, isA<FirebaseOnlyState>());

      // 测试状态方法
      expect(stateMachine.currentState.stateName, 'FirebaseOnly');
      expect(
        stateMachine.currentState.dataSourceType,
        DataSourceType.firebaseOnly,
      );

      // 测试状态转换
      await stateMachine.handleHapiConnected(context);
      expect(stateMachine.currentState, isA<HapiConnectedState>());
    });

    test('HapiConnectedState lifecycle', () async {
      final stateMachine = ConnectionStateMachine(const FirebaseOnlyState());
      final context = const ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      // 切换到 HapiConnected
      await stateMachine.handleHapiConnected(context);
      expect(stateMachine.currentState, isA<HapiConnectedState>());

      // 验证状态属性
      expect(stateMachine.currentState.stateName, 'HapiConnected');
      expect(
        stateMachine.currentState.dataSourceType,
        DataSourceType.hapiPrimary,
      );
    });

    test('FirebaseFallbackState lifecycle', () async {
      final stateMachine = ConnectionStateMachine(const FirebaseOnlyState());
      final context = const ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      // 切换到 HapiConnected 再到 FirebaseFallback
      await stateMachine.handleHapiConnected(context);
      await stateMachine.handleHapiDisconnected(context, 'Test reason');

      expect(stateMachine.currentState, isA<FirebaseFallbackState>());

      // 验证状态属性
      expect(stateMachine.currentState.stateName, 'FirebaseFallback');
      expect(
        stateMachine.currentState.dataSourceType,
        DataSourceType.firebaseFallback,
      );

      // 验证原因字段
      final fallbackState = stateMachine.currentState as FirebaseFallbackState;
      expect(fallbackState.reason, 'Test reason');
    });
  });
}
