import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';

/// 会话列表状态
class SessionsNotifier extends StateNotifier<List<Session>> {
  SessionsNotifier() : super([]);

  /// 添加或更新会话
  void upsertSession(Session session) {
    final index = state.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        session,
        ...state.sublist(index + 1),
      ];
    } else {
      state = [session, ...state];
    }
  }

  /// 更新会话状态
  void updateStatus(String id, SessionStatus status) {
    state = state.map((session) {
      if (session.id == id) {
        return session.copyWith(status: status);
      }
      return session;
    }).toList();
  }

  /// 更新会话进度
  void updateProgress(String id, SessionProgress progress) {
    state = state.map((session) {
      if (session.id == id) {
        return session.copyWith(progress: progress);
      }
      return session;
    }).toList();
  }

  /// 增加工具调用计数
  void incrementToolCallCount(String id) {
    state = state.map((session) {
      if (session.id == id) {
        return session.copyWith(toolCallCount: session.toolCallCount + 1);
      }
      return session;
    }).toList();
  }

  /// 删除会话
  void removeSession(String id) {
    state = state.where((s) => s.id != id).toList();
  }

  /// 获取活跃会话
  List<Session> get activeSessions {
    return state.where((s) => s.status != SessionStatus.completed).toList();
  }

  /// 获取已完成会话
  List<Session> get completedSessions {
    return state.where((s) => s.status == SessionStatus.completed).toList();
  }
}

/// 会话列表 Provider
final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, List<Session>>((ref) {
  return SessionsNotifier();
});

/// 当前选中的会话 ID
final selectedSessionIdProvider = StateProvider<String?>((ref) => null);

/// 当前选中的会话
final selectedSessionProvider = Provider<Session?>((ref) {
  final sessionId = ref.watch(selectedSessionIdProvider);
  if (sessionId == null) return null;

  final sessions = ref.watch(sessionsProvider);
  try {
    return sessions.firstWhere((s) => s.id == sessionId);
  } catch (_) {
    return null;
  }
});

/// 活跃会话数量
final activeSessionCountProvider = Provider<int>((ref) {
  return ref
      .watch(sessionsProvider)
      .where((s) => s.status != SessionStatus.completed)
      .length;
});
