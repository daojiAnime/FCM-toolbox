import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/logger.dart';
import '../../../models/session.dart';
import '../../../providers/session_provider.dart';
import '../../../utils/timing/debouncer.dart';
import '../buffer_manager.dart';
import '../hapi_api_service.dart';
import '../hapi_sse_service.dart';
import 'event_handler.dart';
import 'message_parser.dart';

/// 会话事件处理器
/// 处理 sessionUpdate、sessionCreated、sessionEnded 等会话相关事件
class SessionEventHandler extends EventHandler {
  SessionEventHandler(this._ref, this._bufferManager, this._parser) {
    // 会话更新防抖器 - 防止频繁的会话更新导致 UI 抖动
    _sessionUpdateDebouncer = Debouncer(
      delay: const Duration(milliseconds: 150),
    );
  }

  final Ref _ref;
  final BufferManager _bufferManager;
  final HapiMessageParser _parser;

  late final Debouncer _sessionUpdateDebouncer;

  static final _handledTypes = {
    HapiSseEventType.sessionUpdate,
    HapiSseEventType.sessionCreated,
    HapiSseEventType.sessionEnded,
    HapiSseEventType.sessionAdded,
    HapiSseEventType.sessionUpdated,
    HapiSseEventType.sessionRemoved,
  };

  @override
  bool canHandle(HapiSseEvent event) {
    return _handledTypes.contains(event.type);
  }

  @override
  void doHandle(HapiSseEvent event) {
    Log.d('SessionHandler', 'Handling ${event.type}');

    switch (event.type) {
      case HapiSseEventType.sessionUpdate:
        _handleSessionUpdate(event);
      case HapiSseEventType.sessionCreated:
        _handleSessionCreated(event);
      case HapiSseEventType.sessionEnded:
        _handleSessionEnded(event);
      case HapiSseEventType.sessionAdded:
      case HapiSseEventType.sessionUpdated:
      case HapiSseEventType.sessionRemoved:
        loadSessions();
      default:
        Log.w('SessionHandler', 'Unhandled event type: ${event.type}');
    }
  }

  /// 处理会话更新事件（带防抖）
  void _handleSessionUpdate(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    final sessionId = data['id'] as String?;
    if (sessionId == null) return;

    // 累积更新 (使用 BufferManager)
    _bufferManager.addPendingSessionUpdate(sessionId, data);

    // 使用防抖批量处理
    _sessionUpdateDebouncer.run(_flushSessionUpdates);
  }

  /// 批量刷新会话更新
  void _flushSessionUpdates() {
    // 使用 BufferManager 获取并清空待处理更新
    final updates = _bufferManager.consumePendingSessionUpdates();
    if (updates.isEmpty) return;

    final sessions = _ref.read(sessionsProvider);

    for (final entry in updates.entries) {
      try {
        final newSession = _parser.parseHapiSession(entry.value);
        if (newSession != null) {
          // 保留现有 session 的 contextSize（如果新数据中为 null）
          // 因为 contextSize 通常来自消息的 usage 数据，而不是 session update 事件
          final existingSession = sessions.firstWhereOrNull(
            (s) => s.id == newSession.id,
          );
          final mergedSession =
              existingSession != null && newSession.contextSize == null
                  ? newSession.copyWith(
                    contextSize: existingSession.contextSize,
                  )
                  : newSession;
          _ref.read(sessionsProvider.notifier).upsertSession(mergedSession);
        }
      } catch (e) {
        Log.e('SessionHandler', 'Failed to update session ${entry.key}', e);
      }
    }
  }

  /// 处理会话创建事件
  void _handleSessionCreated(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    try {
      final newSession = _parser.parseHapiSession(data);
      if (newSession != null) {
        // 保留现有 session 的 contextSize（如果新数据中为 null）
        final sessions = _ref.read(sessionsProvider);
        final existingSession = sessions.firstWhereOrNull(
          (s) => s.id == newSession.id,
        );
        final mergedSession =
            existingSession != null && newSession.contextSize == null
                ? newSession.copyWith(contextSize: existingSession.contextSize)
                : newSession;
        _ref.read(sessionsProvider.notifier).upsertSession(mergedSession);
      }
    } catch (e) {
      Log.e('SessionHandler', 'Failed to create session', e);
    }
  }

  /// 处理会话结束事件
  void _handleSessionEnded(HapiSseEvent event) {
    final sessionId = event.sessionId ?? event.data?['id'] as String?;
    if (sessionId == null) return;

    _ref
        .read(sessionsProvider.notifier)
        .updateStatus(sessionId, SessionStatus.completed);
  }

  /// 初始加载所有会话
  Future<void> loadSessions() async {
    final apiService = _ref.read(hapiApiServiceProvider);
    if (apiService == null) return;

    try {
      final sessionsData = await apiService.getSessions();
      for (final data in sessionsData) {
        final session = _parser.parseHapiSession(data);
        if (session != null) {
          _ref.read(sessionsProvider.notifier).upsertSession(session);
        }
      }
      Log.i('SessionHandler', 'Loaded ${sessionsData.length} sessions');
    } catch (e) {
      Log.e('SessionHandler', 'Failed to load sessions', e);
    }
  }

  /// 释放资源
  void dispose() {
    // 刷新剩余的会话更新
    _flushSessionUpdates();
    _sessionUpdateDebouncer.dispose();
  }
}
