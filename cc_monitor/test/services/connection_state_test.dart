import 'package:flutter_test/flutter_test.dart';
import 'package:cc_monitor/services/connection_state.dart';
import 'package:cc_monitor/services/connection_manager.dart';

void main() {
  group('ConnectionStateMachine', () {
    late ConnectionStateMachine machine;
    late ConnectionContext context;

    setUp(() {
      machine = ConnectionStateMachine(const FirebaseOnlyState());
      context = const ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
      );
    });

    test('Initial state is FirebaseOnlyState', () {
      expect(machine.currentState, isA<FirebaseOnlyState>());
    });

    test('State transition changes state', () async {
      await machine.transitionTo(const HapiConnectedState(), context);
      expect(machine.currentState, isA<HapiConnectedState>());
    });

    test('Same state transition is ignored', () async {
      await machine.transitionTo(const FirebaseOnlyState(), context);
      expect(machine.currentState, isA<FirebaseOnlyState>());
    });

    test('Network offline transitions to DisconnectedState', () async {
      await machine.handleNetworkOffline(context);
      expect(machine.currentState, isA<DisconnectedState>());
    });

    test('Hapi connected transitions to HapiConnectedState', () async {
      await machine.handleHapiConnected(context);
      expect(machine.currentState, isA<HapiConnectedState>());
    });

    test('Hapi disconnected transitions to FirebaseFallbackState', () async {
      await machine.transitionTo(const HapiConnectedState(), context);
      await machine.handleHapiDisconnected(context, 'Test error');

      expect(machine.currentState, isA<FirebaseFallbackState>());
      final fallback = machine.currentState as FirebaseFallbackState;
      expect(fallback.reason, 'Test error');
    });

    test('Hapi error transitions to FirebaseFallbackState', () async {
      await machine.transitionTo(const HapiConnectedState(), context);
      await machine.handleHapiError(context, 'Connection error');

      expect(machine.currentState, isA<FirebaseFallbackState>());
      final fallback = machine.currentState as FirebaseFallbackState;
      expect(fallback.reason, 'Connection error');
    });

    test('Hapi disabled transitions to FirebaseOnlyState', () async {
      await machine.transitionTo(const HapiConnectedState(), context);
      await machine.handleHapiDisabled(context);

      expect(machine.currentState, isA<FirebaseOnlyState>());
    });

    test(
      'Complete state flow: offline -> online -> hapi -> fallback',
      () async {
        // 1. 网络离线
        await machine.handleNetworkOffline(context);
        expect(machine.currentState, isA<DisconnectedState>());

        // 2. 网络恢复
        await machine.handleNetworkOnline(context);
        expect(machine.currentState, isA<ReconnectingState>());

        // 3. Hapi 连接成功
        await machine.handleHapiConnected(context);
        expect(machine.currentState, isA<HapiConnectedState>());

        // 4. Hapi 断开，降级
        await machine.handleHapiDisconnected(context, 'Connection lost');
        expect(machine.currentState, isA<FirebaseFallbackState>());
      },
    );

    test('Attempt recovery from fallback state', () async {
      await machine.transitionTo(const FirebaseFallbackState('Test'), context);
      await machine.handleAttemptRecovery(context);

      expect(machine.currentState, isA<ReconnectingState>());
    });
  });

  group('FirebaseOnlyState', () {
    test('Has correct state name and data source', () {
      const state = FirebaseOnlyState();
      expect(state.stateName, 'FirebaseOnly');
      expect(state.dataSourceType, DataSourceType.firebaseOnly);
    });

    test('Hapi connected transitions when available', () {
      const state = FirebaseOnlyState();
      final context = const ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      final newState = state.onHapiConnected(context);
      expect(newState, isA<HapiConnectedState>());
    });

    test('Hapi connected stays in state when unavailable', () {
      const state = FirebaseOnlyState();
      final context = const ConnectionContext(
        isOnline: true,
        hapiConfigured: false,
        hapiEnabled: false,
      );

      final newState = state.onHapiConnected(context);
      expect(newState, isA<FirebaseOnlyState>());
    });

    test('Network offline transitions to DisconnectedState', () {
      const state = FirebaseOnlyState();
      final context = const ConnectionContext(
        isOnline: false,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      final newState = state.onNetworkOffline(context);
      expect(newState, isA<DisconnectedState>());
    });
  });

  group('HapiConnectedState', () {
    test('Has correct state name and data source', () {
      const state = HapiConnectedState();
      expect(state.stateName, 'HapiConnected');
      expect(state.dataSourceType, DataSourceType.hapiPrimary);
    });

    test('Network offline transitions to DisconnectedState', () {
      const state = HapiConnectedState();
      final context = const ConnectionContext(
        isOnline: false,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      final newState = state.onNetworkOffline(context);
      expect(newState, isA<DisconnectedState>());
    });

    test('Hapi disconnected transitions to FirebaseFallbackState', () {
      const state = HapiConnectedState();
      final context = const ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      final newState = state.onHapiDisconnected(context, 'Connection lost');
      expect(newState, isA<FirebaseFallbackState>());
    });

    test('Hapi disabled transitions to FirebaseOnlyState', () {
      const state = HapiConnectedState();
      final context = const ConnectionContext(
        isOnline: true,
        hapiConfigured: false,
        hapiEnabled: false,
      );

      final newState = state.onHapiDisabled(context);
      expect(newState, isA<FirebaseOnlyState>());
    });

    test('onEnter calls stopFirestore', () async {
      const state = HapiConnectedState();
      var stopCalled = false;
      final context = ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
        stopFirestore: () => stopCalled = true,
      );

      await state.onEnter(context);
      expect(stopCalled, true);
    });
  });

  group('FirebaseFallbackState', () {
    test('Has correct state name and data source', () {
      const state = FirebaseFallbackState('Test reason');
      expect(state.stateName, 'FirebaseFallback');
      expect(state.dataSourceType, DataSourceType.firebaseFallback);
      expect(state.reason, 'Test reason');
    });

    test('Network online transitions to ReconnectingState', () {
      const state = FirebaseFallbackState('Test');
      final context = const ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      final newState = state.onNetworkOnline(context);
      expect(newState, isA<ReconnectingState>());
    });

    test('Attempt recovery transitions to ReconnectingState', () {
      const state = FirebaseFallbackState('Test');
      var reconnectCalled = false;
      final context = ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
        reconnectHapi: () => reconnectCalled = true,
      );

      final newState = state.onAttemptRecovery(context);
      expect(newState, isA<ReconnectingState>());
      expect(reconnectCalled, true);
    });

    test('Attempt recovery stays in state when offline', () {
      const state = FirebaseFallbackState('Test');
      final context = const ConnectionContext(
        isOnline: false,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      final newState = state.onAttemptRecovery(context);
      expect(newState, isA<FirebaseFallbackState>());
    });

    test('Hapi disabled transitions to FirebaseOnlyState', () {
      const state = FirebaseFallbackState('Test');
      final context = const ConnectionContext(
        isOnline: true,
        hapiConfigured: false,
        hapiEnabled: false,
      );

      final newState = state.onHapiDisabled(context);
      expect(newState, isA<FirebaseOnlyState>());
    });

    test('onEnter calls startFirestore', () async {
      const state = FirebaseFallbackState('Test');
      var startCalled = false;
      final context = ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
        startFirestore: () async => startCalled = true,
      );

      await state.onEnter(context);
      expect(startCalled, true);
    });
  });

  group('ReconnectingState', () {
    test('Has correct state name and data source', () {
      const state = ReconnectingState('Previous error');
      expect(state.stateName, 'Reconnecting');
      expect(state.dataSourceType, DataSourceType.firebaseFallback);
      expect(state.previousReason, 'Previous error');
    });

    test('Hapi connected transitions to HapiConnectedState', () {
      const state = ReconnectingState('Test');
      final context = const ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      final newState = state.onHapiConnected(context);
      expect(newState, isA<HapiConnectedState>());
    });

    test('Hapi error transitions to FirebaseFallbackState', () {
      const state = ReconnectingState('Previous');
      final context = const ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      final newState = state.onHapiError(context, 'New error');
      expect(newState, isA<FirebaseFallbackState>());
      final fallback = newState as FirebaseFallbackState;
      expect(fallback.reason, 'New error');
    });

    test('Network offline transitions to DisconnectedState', () {
      const state = ReconnectingState('Test');
      final context = const ConnectionContext(
        isOnline: false,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      final newState = state.onNetworkOffline(context);
      expect(newState, isA<DisconnectedState>());
    });

    test('onEnter calls reconnectHapi when available', () async {
      const state = ReconnectingState('Test');
      var reconnectCalled = false;
      final context = ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
        reconnectHapi: () => reconnectCalled = true,
      );

      await state.onEnter(context);
      expect(reconnectCalled, true);
    });
  });

  group('DisconnectedState', () {
    test('Has correct state name and data source', () {
      const state = DisconnectedState();
      expect(state.stateName, 'Disconnected');
      expect(state.dataSourceType, DataSourceType.firebaseOnly);
    });

    test(
      'Network online transitions to ReconnectingState when hapi available',
      () {
        const state = DisconnectedState();
        final context = const ConnectionContext(
          isOnline: true,
          hapiConfigured: true,
          hapiEnabled: true,
        );

        final newState = state.onNetworkOnline(context);
        expect(newState, isA<ReconnectingState>());
      },
    );

    test(
      'Network online transitions to FirebaseOnlyState when hapi unavailable',
      () {
        const state = DisconnectedState();
        final context = const ConnectionContext(
          isOnline: true,
          hapiConfigured: false,
          hapiEnabled: false,
        );

        final newState = state.onNetworkOnline(context);
        expect(newState, isA<FirebaseOnlyState>());
      },
    );

    test('Hapi connected is ignored in disconnected state', () {
      const state = DisconnectedState();
      final context = const ConnectionContext(
        isOnline: false,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      final newState = state.onHapiConnected(context);
      expect(newState, isA<DisconnectedState>());
    });

    test('Hapi disconnected stays in disconnected state', () {
      const state = DisconnectedState();
      final context = const ConnectionContext(
        isOnline: false,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      final newState = state.onHapiDisconnected(context, 'Error');
      expect(newState, isA<DisconnectedState>());
    });
  });

  group('ConnectionContext', () {
    test('hapiAvailable returns true when configured and enabled', () {
      const context = ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
      );

      expect(context.hapiAvailable, true);
    });

    test('hapiAvailable returns false when not configured', () {
      const context = ConnectionContext(
        isOnline: true,
        hapiConfigured: false,
        hapiEnabled: true,
      );

      expect(context.hapiAvailable, false);
    });

    test('hapiAvailable returns false when not enabled', () {
      const context = ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: false,
      );

      expect(context.hapiAvailable, false);
    });

    test('Callbacks can be provided', () async {
      var startCalled = false;
      var stopCalled = false;
      var reconnectCalled = false;

      final context = ConnectionContext(
        isOnline: true,
        hapiConfigured: true,
        hapiEnabled: true,
        startFirestore: () async => startCalled = true,
        stopFirestore: () => stopCalled = true,
        reconnectHapi: () => reconnectCalled = true,
      );

      await context.startFirestore?.call();
      context.stopFirestore?.call();
      context.reconnectHapi?.call();

      expect(startCalled, true);
      expect(stopCalled, true);
      expect(reconnectCalled, true);
    });
  });
}
