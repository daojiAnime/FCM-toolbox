import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'hapi_config_service.dart';

/// SSE 事件类型
enum HapiSseEventType {
  sessionUpdate,
  sessionCreated,
  sessionEnded,
  message,
  permissionRequest,
  todoUpdate,
  machineUpdate,
  connected,
  error,
  unknown,
}

/// SSE 事件
class HapiSseEvent {
  const HapiSseEvent({required this.type, this.data, this.sessionId, this.raw});

  final HapiSseEventType type;
  final Map<String, dynamic>? data;
  final String? sessionId;
  final String? raw;

  factory HapiSseEvent.fromRaw(String eventType, String data) {
    Map<String, dynamic>? parsedData;
    String? sessionId;

    try {
      if (data.isNotEmpty) {
        parsedData = jsonDecode(data) as Map<String, dynamic>?;
        sessionId = parsedData?['sessionId'] as String?;
      }
    } catch (e) {
      debugPrint('[SSE] Failed to parse event data: $e');
    }

    final type = _parseEventType(eventType);

    return HapiSseEvent(
      type: type,
      data: parsedData,
      sessionId: sessionId,
      raw: data,
    );
  }

  static HapiSseEventType _parseEventType(String eventType) {
    switch (eventType) {
      case 'session_update':
      case 'sessionUpdate':
        return HapiSseEventType.sessionUpdate;
      case 'session_created':
      case 'sessionCreated':
        return HapiSseEventType.sessionCreated;
      case 'session_ended':
      case 'sessionEnded':
        return HapiSseEventType.sessionEnded;
      case 'message':
        return HapiSseEventType.message;
      case 'permission_request':
      case 'permissionRequest':
        return HapiSseEventType.permissionRequest;
      case 'todo_update':
      case 'todoUpdate':
        return HapiSseEventType.todoUpdate;
      case 'machine_update':
      case 'machineUpdate':
        return HapiSseEventType.machineUpdate;
      case 'connected':
        return HapiSseEventType.connected;
      case 'error':
        return HapiSseEventType.error;
      default:
        return HapiSseEventType.unknown;
    }
  }

  @override
  String toString() => 'HapiSseEvent(type: $type, sessionId: $sessionId)';
}

/// hapi 连接状态
enum HapiConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// hapi 连接状态详情
class HapiConnectionState {
  const HapiConnectionState({
    this.status = HapiConnectionStatus.disconnected,
    this.errorMessage,
    this.lastConnectedAt,
    this.reconnectAttempts = 0,
  });

  final HapiConnectionStatus status;
  final String? errorMessage;
  final DateTime? lastConnectedAt;
  final int reconnectAttempts;

  bool get isConnected => status == HapiConnectionStatus.connected;

  HapiConnectionState copyWith({
    HapiConnectionStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    DateTime? lastConnectedAt,
    int? reconnectAttempts,
  }) {
    return HapiConnectionState(
      status: status ?? this.status,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }
}

/// hapi SSE 服务 - 管理与 hapi server 的实时连接
class HapiSseService {
  HapiSseService(this._config);

  final HapiConfig _config;

  http.Client? _client;
  StreamSubscription<String>? _subscription;
  Timer? _reconnectTimer;

  // SSE 断线续传支持
  String? _lastEventId;
  Duration? _serverRetryDelay;

  // 事件流控制器
  final _eventController = StreamController<HapiSseEvent>.broadcast();
  final _connectionStateController =
      StreamController<HapiConnectionState>.broadcast();

  // 当前状态
  HapiConnectionState _currentState = const HapiConnectionState();

  // 重连配置
  static const _maxReconnectAttempts = 10;
  static const _initialReconnectDelay = Duration(seconds: 1);
  static const _maxReconnectDelay = Duration(seconds: 30);

  /// 事件流
  Stream<HapiSseEvent> get events => _eventController.stream;

  /// 连接状态流
  Stream<HapiConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// 当前连接状态
  HapiConnectionState get currentState => _currentState;

  /// 是否已连接
  bool get isConnected => _currentState.isConnected;

  /// 连接到 SSE 端点
  Future<void> connect() async {
    if (!_config.isConfigured || !_config.enabled) {
      debugPrint('[SSE] hapi not configured or disabled');
      return;
    }

    if (_currentState.status == HapiConnectionStatus.connecting ||
        _currentState.status == HapiConnectionStatus.connected) {
      debugPrint('[SSE] Already connecting or connected');
      return;
    }

    _updateState(
      _currentState.copyWith(
        status: HapiConnectionStatus.connecting,
        errorMessage: null,
      ),
    );

    await _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      _client?.close();
      _client = http.Client();

      final url = '${_config.serverUrl}/api/sse';
      debugPrint('[SSE] Connecting to $url');

      final request = http.Request('GET', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer ${_config.apiToken}';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      // 断线续传：发送上次收到的事件 ID
      if (_lastEventId != null) {
        request.headers['Last-Event-ID'] = _lastEventId!;
        debugPrint('[SSE] Resuming from event ID: $_lastEventId');
      }

      final response = await _client!.send(request);

      if (response.statusCode != 200) {
        throw Exception('SSE connection failed: ${response.statusCode}');
      }

      debugPrint('[SSE] Connected, streaming events...');

      _updateState(
        _currentState.copyWith(
          status: HapiConnectionStatus.connected,
          lastConnectedAt: DateTime.now(),
          reconnectAttempts: 0,
          errorMessage: null,
        ),
      );

      // 发送连接成功事件
      _eventController.add(
        const HapiSseEvent(type: HapiSseEventType.connected),
      );

      // 解析 SSE 流
      _subscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleLine,
            onError: _handleError,
            onDone: _handleDone,
            cancelOnError: false,
          );
    } catch (e) {
      debugPrint('[SSE] Connection error: $e');
      _handleError(e);
    }
  }

  // SSE 行解析状态
  String _currentEventType = 'message';
  StringBuffer _currentData = StringBuffer();

  void _handleLine(String line) {
    if (line.isEmpty) {
      // 空行表示事件结束
      if (_currentData.isNotEmpty) {
        final event = HapiSseEvent.fromRaw(
          _currentEventType,
          _currentData.toString().trim(),
        );
        debugPrint('[SSE] Event: ${event.type}');
        _eventController.add(event);
      }
      // 重置状态
      _currentEventType = 'message';
      _currentData = StringBuffer();
      return;
    }

    if (line.startsWith('event:')) {
      _currentEventType = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      if (_currentData.isNotEmpty) {
        _currentData.write('\n');
      }
      _currentData.write(line.substring(5).trim());
    } else if (line.startsWith('id:')) {
      // 记录 lastEventId 用于断线续传
      _lastEventId = line.substring(3).trim();
    } else if (line.startsWith('retry:')) {
      // 使用服务器建议的重连时间
      final retryMs = int.tryParse(line.substring(6).trim());
      if (retryMs != null && retryMs > 0) {
        _serverRetryDelay = Duration(milliseconds: retryMs);
        debugPrint(
          '[SSE] Server retry delay: ${_serverRetryDelay!.inMilliseconds}ms',
        );
      }
    } else if (line.startsWith(':')) {
      // 注释，忽略
    }
  }

  void _handleError(Object error) {
    debugPrint('[SSE] Error: $error');

    _updateState(
      _currentState.copyWith(
        status: HapiConnectionStatus.error,
        errorMessage: error.toString(),
      ),
    );

    _eventController.add(
      HapiSseEvent(
        type: HapiSseEventType.error,
        data: {'error': error.toString()},
      ),
    );

    _scheduleReconnect();
  }

  void _handleDone() {
    debugPrint('[SSE] Connection closed');

    if (_currentState.status == HapiConnectionStatus.connected) {
      _updateState(
        _currentState.copyWith(status: HapiConnectionStatus.disconnected),
      );
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_currentState.reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[SSE] Max reconnect attempts reached');
      _updateState(
        _currentState.copyWith(
          status: HapiConnectionStatus.error,
          errorMessage: 'Max reconnect attempts reached',
        ),
      );
      return;
    }

    // 优先使用服务器建议的重连时间，否则使用指数退避
    final Duration delay;
    if (_serverRetryDelay != null) {
      delay = _serverRetryDelay!;
    } else {
      // 指数退避
      delay = Duration(
        milliseconds: (_initialReconnectDelay.inMilliseconds *
                (1 << _currentState.reconnectAttempts))
            .clamp(
              _initialReconnectDelay.inMilliseconds,
              _maxReconnectDelay.inMilliseconds,
            ),
      );
    }

    debugPrint(
      '[SSE] Reconnecting in ${delay.inSeconds}s (attempt ${_currentState.reconnectAttempts + 1})',
    );

    _updateState(
      _currentState.copyWith(
        status: HapiConnectionStatus.reconnecting,
        reconnectAttempts: _currentState.reconnectAttempts + 1,
      ),
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_config.enabled) {
        _doConnect();
      }
    });
  }

  void _updateState(HapiConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  /// 断开连接
  void disconnect() {
    debugPrint('[SSE] Disconnecting...');
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _client?.close();
    _client = null;

    _updateState(
      const HapiConnectionState(status: HapiConnectionStatus.disconnected),
    );
  }

  /// 重新连接
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 100));
    await connect();
  }

  /// 重置重连计数并立即重连
  /// 用于用户手动触发重连（例如达到最大重连次数后）
  Future<void> resetAndReconnect() async {
    debugPrint('[SSE] Reset and reconnect requested');
    disconnect();
    // 清除 SSE 断线续传状态，从头开始
    _lastEventId = null;
    _serverRetryDelay = null;
    _updateState(
      const HapiConnectionState(
        status: HapiConnectionStatus.disconnected,
        reconnectAttempts: 0,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 100));
    await connect();
  }

  /// 是否已达到最大重连次数
  bool get hasReachedMaxReconnectAttempts =>
      _currentState.reconnectAttempts >= _maxReconnectAttempts;

  /// 释放资源
  void dispose() {
    disconnect();
    _eventController.close();
    _connectionStateController.close();
  }
}

/// hapi SSE 服务 Provider
final hapiSseServiceProvider = Provider<HapiSseService?>((ref) {
  final config = ref.watch(hapiConfigProvider);
  if (!config.isConfigured) {
    return null;
  }

  final service = HapiSseService(config);

  // 自动连接（如果已启用）
  if (config.enabled) {
    service.connect();
  }

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// hapi 连接状态 Provider
final hapiConnectionStateProvider = StreamProvider<HapiConnectionState>((
  ref,
) async* {
  final sseService = ref.watch(hapiSseServiceProvider);
  if (sseService == null) {
    yield const HapiConnectionState(status: HapiConnectionStatus.disconnected);
    return;
  }

  // 先发送当前状态
  yield sseService.currentState;

  // 然后监听变化
  await for (final state in sseService.connectionState) {
    yield state;
  }
});

/// hapi SSE 事件流 Provider
final hapiSseEventsProvider = StreamProvider<HapiSseEvent>((ref) async* {
  final sseService = ref.watch(hapiSseServiceProvider);
  if (sseService == null) {
    return;
  }

  await for (final event in sseService.events) {
    yield event;
  }
});

/// hapi 是否已连接 Provider
final hapiIsConnectedProvider = Provider<bool>((ref) {
  final connectionState = ref.watch(hapiConnectionStateProvider);
  return connectionState.maybeWhen(
    data: (state) => state.isConnected,
    orElse: () => false,
  );
});
