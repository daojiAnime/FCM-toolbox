import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/logger.dart';
import '../services/hapi/hapi_api_service.dart';
import '../services/hapi/hapi_config_service.dart';

/// 机器列表 Provider
/// 自动从 hapi 服务器获取机器列表
final machinesProvider = FutureProvider.autoDispose<List<HapiMachine>>((
  ref,
) async {
  final hapiConfig = ref.watch(hapiConfigProvider);
  final apiService = ref.watch(hapiApiServiceProvider);

  // 未启用 hapi 或未配置时返回空列表
  if (!hapiConfig.enabled || !hapiConfig.isConfigured || apiService == null) {
    return [];
  }

  try {
    final machinesData = await apiService.getMachines();
    return machinesData.map((data) => HapiMachine.fromJson(data)).toList();
  } catch (e) {
    Log.e('MachProv', 'Failed to load machines: $e');
    rethrow;
  }
});

/// 在线机器数量
final onlineMachineCountProvider = Provider<int>((ref) {
  final machinesAsync = ref.watch(machinesProvider);
  return machinesAsync.whenOrNull(
        data: (machines) => machines.where((m) => m.isOnline).length,
      ) ??
      0;
});

/// 选中的机器 ID
final selectedMachineIdProvider = StateProvider<String?>((ref) => null);

/// 选中的机器
final selectedMachineProvider = Provider<HapiMachine?>((ref) {
  final machineId = ref.watch(selectedMachineIdProvider);
  if (machineId == null) return null;

  final machinesAsync = ref.watch(machinesProvider);
  return machinesAsync.whenOrNull(
    data: (machines) {
      try {
        return machines.firstWhere((m) => m.id == machineId);
      } catch (_) {
        return null;
      }
    },
  );
});

/// 远程启动会话状态
class SpawnSessionState {
  const SpawnSessionState({
    this.isSpawning = false,
    this.error,
    this.lastSpawnedSessionId,
  });

  final bool isSpawning;
  final String? error;
  final String? lastSpawnedSessionId;

  SpawnSessionState copyWith({
    bool? isSpawning,
    String? error,
    String? lastSpawnedSessionId,
  }) {
    return SpawnSessionState(
      isSpawning: isSpawning ?? this.isSpawning,
      error: error,
      lastSpawnedSessionId: lastSpawnedSessionId ?? this.lastSpawnedSessionId,
    );
  }
}

/// 远程启动会话 Notifier
class SpawnSessionNotifier extends StateNotifier<SpawnSessionState> {
  SpawnSessionNotifier(this._ref) : super(const SpawnSessionState());

  final Ref _ref;

  /// 在指定机器上启动新会话
  /// [agent] 代理类型: 'claude', 'codex', 'gemini' (默认 'claude')
  Future<bool> spawnSession({
    required String machineId,
    String? projectPath,
    String? agent,
    bool? yolo,
    String? sessionType,
    String? worktreeName,
  }) async {
    final apiService = _ref.read(hapiApiServiceProvider);
    if (apiService == null) {
      state = state.copyWith(error: 'hapi 服务未配置');
      return false;
    }

    state = state.copyWith(isSpawning: true, error: null);

    try {
      final result = await apiService.spawnSession(
        machineId: machineId,
        directory: projectPath,
        agent: agent,
        yolo: yolo,
        sessionType: sessionType,
        worktreeName: worktreeName,
      );

      final sessionId =
          result?['id'] as String? ?? result?['sessionId'] as String?;
      state = state.copyWith(
        isSpawning: false,
        lastSpawnedSessionId: sessionId,
      );

      Log.i('SpawnSess', 'Session spawned: $sessionId');
      return true;
    } catch (e) {
      Log.e('SpawnSess', 'Failed to spawn session: $e');
      state = state.copyWith(isSpawning: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// 远程启动会话 Provider
final spawnSessionProvider =
    StateNotifierProvider<SpawnSessionNotifier, SpawnSessionState>((ref) {
      return SpawnSessionNotifier(ref);
    });
