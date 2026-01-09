import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/logger.dart';
import 'hapi_config_service.dart';
import 'hapi_api_service.dart';

/// SSE 事件类型 (与 hapi web 保持一致)
enum HapiSseEventType {
  // 会话事件
  sessionUpdate,
  sessionCreated,
  sessionEnded,
  sessionAdded, // hapi: session-added
  sessionUpdated, // hapi: session-updated
  sessionRemoved, // hapi: session-removed
  // 消息事件
  message, // hapi: message-received
  permissionRequest,
  todoUpdate,

  // 机器事件
  machineUpdate,
  machineUpdated, // hapi: machine-updated
  // 连接事件
  connectionChanged, // hapi: connection-changed (包含 subscriptionId)
  connected,

  // 流式内容
  streamingContent,
  streamingComplete,

  // 其他
  toast, // hapi: toast
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

  factory HapiSseEvent.fromRaw(String sseEventType, String data) {
    Map<String, dynamic>? parsedData;
    String? sessionId;
    String actualEventType = sseEventType;

    try {
      if (data.isNotEmpty) {
        parsedData = jsonDecode(data) as Map<String, dynamic>?;

        // hapi SSE 结构: 所有事件都通过 SSE "message" 发送
        // 真正的事件类型在数据的 type 字段中: { type: 'connection-changed', data: {...} }
        // 或 { type: 'message-received', sessionId: 'xxx', message: {...} }
        final dataType = parsedData?['type'] as String?;
        if (dataType != null && dataType.isNotEmpty) {
          actualEventType = dataType;
        }

        sessionId = parsedData?['sessionId'] as String?;
      }
    } catch (e) {
      Log.e('SSE', 'Failed to parse event data', e);
    }

    final type = _parseEventType(actualEventType);

    return HapiSseEvent(
      type: type,
      data: parsedData,
      sessionId: sessionId,
      raw: data,
    );
  }

  static HapiSseEventType _parseEventType(String eventType) {
    switch (eventType) {
      // 会话事件
      case 'session_update':
      case 'sessionUpdate':
        return HapiSseEventType.sessionUpdate;
      case 'session_created':
      case 'sessionCreated':
        return HapiSseEventType.sessionCreated;
      case 'session_ended':
      case 'sessionEnded':
        return HapiSseEventType.sessionEnded;
      case 'session-added':
      case 'sessionAdded':
        return HapiSseEventType.sessionAdded;
      case 'session-updated':
      case 'sessionUpdated':
        return HapiSseEventType.sessionUpdated;
      case 'session-removed':
      case 'sessionRemoved':
        return HapiSseEventType.sessionRemoved;

      // 消息事件 (hapi 使用 message-received)
      case 'message-received':
      case 'messageReceived':
        return HapiSseEventType.message;
      case 'permission_request':
      case 'permissionRequest':
        return HapiSseEventType.permissionRequest;
      case 'todo_update':
      case 'todoUpdate':
        return HapiSseEventType.todoUpdate;

      // 机器事件
      case 'machine_update':
      case 'machineUpdate':
        return HapiSseEventType.machineUpdate;
      case 'machine-updated':
      case 'machineUpdated':
        return HapiSseEventType.machineUpdated;

      // 连接事件
      case 'connection-changed':
      case 'connectionChanged':
        return HapiSseEventType.connectionChanged;
      case 'connected':
        return HapiSseEventType.connected;

      // 流式内容
      case 'streaming_content':
      case 'streamingContent':
      case 'content_chunk':
      case 'contentChunk':
        return HapiSseEventType.streamingContent;
      case 'streaming_complete':
      case 'streamingComplete':
      case 'content_complete':
      case 'contentComplete':
        return HapiSseEventType.streamingComplete;

      // 其他
      case 'toast':
        return HapiSseEventType.toast;
      case 'error':
        return HapiSseEventType.error;
      default:
        Log.w('SSE', 'Unknown event type: $eventType');
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
  HapiSseService(this._config, this._apiService);

  final HapiConfig _config;
  final HapiApiService? _apiService;

  Dio? _dio;
  CancelToken? _cancelToken;
  StreamSubscription<String>? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  // SSE 断线续传支持
  String? _lastEventId;
  Duration? _serverRetryDelay;

  // SSE 订阅 ID (用于 visibility API)
  String? _subscriptionId;

  // 心跳检测 - SSE 服务器通常每 15-30 秒发送一次心跳
  DateTime? _lastEventTime;
  static const _heartbeatCheckInterval = Duration(seconds: 15);
  static const _heartbeatTimeout = Duration(seconds: 45);

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

  /// SSE 订阅 ID (用于 visibility API)
  String? get subscriptionId => _subscriptionId;

  /// 连接到 SSE 端点
  Future<void> connect() async {
    if (!_config.isConfigured || !_config.enabled) {
      Log.i('SSE', 'Not configured or disabled');
      return;
    }

    if (_currentState.status == HapiConnectionStatus.connecting ||
        _currentState.status == HapiConnectionStatus.connected) {
      Log.w('SSE', 'Already connecting or connected');
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
      _cancelToken?.cancel();
      _dio?.close();

      _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: Duration.zero,
          headers: {
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
        ),
      );
      _cancelToken = CancelToken();

      String? jwtToken;
      if (_apiService != null) {
        jwtToken = await _apiService.getJwtToken();
      }
      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception('Failed to get JWT token for SSE connection');
      }

      final queryParams = <String, String>{
        'token': jwtToken,
        'visibility': 'visible',
      };
      if (_lastEventId != null) {
        queryParams['lastEventId'] = _lastEventId!;
      }

      final url = '${_config.serverUrl}/api/events';
      Log.i('SSE', 'Connecting to $url');

      final response = await _dio!.get<ResponseBody>(
        url,
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer $jwtToken',
            if (_lastEventId != null) 'Last-Event-ID': _lastEventId!,
          },
        ),
        cancelToken: _cancelToken,
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Authentication failed: ${response.statusCode}');
      }
      if (response.statusCode != 200) {
        throw Exception('SSE connection failed: ${response.statusCode}');
      }

      Log.i('SSE', 'Connected');
      _updateState(
        _currentState.copyWith(
          status: HapiConnectionStatus.connected,
          lastConnectedAt: DateTime.now(),
          reconnectAttempts: 0,
          errorMessage: null,
        ),
      );
      _eventController.add(
        const HapiSseEvent(type: HapiSseEventType.connected),
      );
      _startHeartbeatCheck();

      final stream = response.data?.stream;
      if (stream == null) {
        throw Exception('No stream in response');
      }

      _subscription = stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleLine,
            onError: _handleError,
            onDone: _handleDone,
            cancelOnError: false,
          );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      Log.e('SSE', 'Dio error', e);
      _handleError(e);
    } catch (e) {
      Log.e('SSE', 'Connection error', e);
      _handleError(e);
    }
  }

  String _currentEventType = 'message';
  StringBuffer _currentData = StringBuffer();

  void _handleLine(String line) {
    _lastEventTime = DateTime.now();

    if (line.isEmpty) {
      if (_currentData.isNotEmpty) {
        final event = HapiSseEvent.fromRaw(
          _currentEventType,
          _currentData.toString().trim(),
        );
        if (event.type == HapiSseEventType.connectionChanged) {
          final data = event.data;
          if (data != null && data['data'] is Map) {
            _subscriptionId =
                (data['data'] as Map<String, dynamic>)['subscriptionId']
                    as String?;
          }
        }
        _eventController.add(event);
      }
      _currentEventType = 'message';
      _currentData = StringBuffer();
      return;
    }

    if (line.startsWith('event:')) {
      _currentEventType = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      if (_currentData.isNotEmpty) _currentData.write('\n');
      _currentData.write(line.substring(5).trim());
    } else if (line.startsWith('id:')) {
      _lastEventId = line.substring(3).trim();
    } else if (line.startsWith('retry:')) {
      final retryMs = int.tryParse(line.substring(6).trim());
      if (retryMs != null && retryMs > 0) {
        _serverRetryDelay = Duration(milliseconds: retryMs);
      }
    }
  }

  void _handleError(Object error) {
    final errorStr = error.toString();
    final isRecoverableError =
        errorStr.contains('Connection closed') ||
        errorStr.contains('Connection reset') ||
        errorStr.contains('Connection refused') ||
        errorStr.contains('Network is unreachable') ||
        errorStr.contains('SocketException');

    if (isRecoverableError) {
      Log.w('SSE', 'Recoverable error: $errorStr');
    } else {
      Log.e('SSE', 'Error', error);
    }
    _stopHeartbeatCheck();
    _updateState(
      _currentState.copyWith(
        status: HapiConnectionStatus.error,
        errorMessage: errorStr,
      ),
    );

    if (!isRecoverableError) {
      _eventController.add(
        HapiSseEvent(type: HapiSseEventType.error, data: {'error': errorStr}),
      );
    }
    _scheduleReconnect();
  }

  void _handleDone() {
    Log.i('SSE', 'Connection closed');
    _stopHeartbeatCheck();

    final shouldReconnect =
        _currentState.status == HapiConnectionStatus.connected ||
        _currentState.status == HapiConnectionStatus.connecting ||
        _currentState.status == HapiConnectionStatus.reconnecting;

    if (shouldReconnect && _config.enabled) {
      _updateState(
        _currentState.copyWith(status: HapiConnectionStatus.disconnected),
      );
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_currentState.reconnectAttempts >= _maxReconnectAttempts) {
      Log.e('SSE', 'Max reconnect attempts reached');
      _updateState(
        _currentState.copyWith(
          status: HapiConnectionStatus.error,
          errorMessage: 'Max reconnect attempts reached',
        ),
      );
      return;
    }

    // 指数退避 + 随机抖动 (±25%)，防止 thundering herd
    final baseDelayMs =
        _serverRetryDelay?.inMilliseconds ??
        (_initialReconnectDelay.inMilliseconds *
                (1 << _currentState.reconnectAttempts))
            .clamp(
              _initialReconnectDelay.inMilliseconds,
              _maxReconnectDelay.inMilliseconds,
            );
    final jitterFactor = 0.75 + Random().nextDouble() * 0.5; // 0.75 ~ 1.25
    final delay = Duration(milliseconds: (baseDelayMs * jitterFactor).round());

    Log.i(
      'SSE',
      'Reconnecting in ${delay.inSeconds}s (attempt ${_currentState.reconnectAttempts + 1})',
    );
    _updateState(
      _currentState.copyWith(
        status: HapiConnectionStatus.reconnecting,
        reconnectAttempts: _currentState.reconnectAttempts + 1,
      ),
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_config.enabled) _doConnect();
    });
  }

  void _updateState(HapiConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  void _startHeartbeatCheck() {
    _stopHeartbeatCheck();
    _lastEventTime = DateTime.now();
    _heartbeatTimer = Timer.periodic(_heartbeatCheckInterval, (timer) {
      final lastEvent = _lastEventTime;
      if (lastEvent == null) return;
      final timeSinceLastEvent = DateTime.now().difference(lastEvent);
      if (timeSinceLastEvent > _heartbeatTimeout) {
        Log.w('SSE', 'Heartbeat timeout: ${timeSinceLastEvent.inSeconds}s');
        _handleError(Exception('Heartbeat timeout'));
      }
    });
  }

  void _stopHeartbeatCheck() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _lastEventTime = null;
  }

  void disconnect() {
    _stopHeartbeatCheck();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _cancelToken?.cancel();
    _dio?.close();
    _cancelToken = null;
    _dio = null;
    _updateState(
      const HapiConnectionState(status: HapiConnectionStatus.disconnected),
    );
  }

  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 100));
    await connect();
  }

  Future<void> resetAndReconnect() async {
    disconnect();
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

  bool get hasReachedMaxReconnectAttempts =>
      _currentState.reconnectAttempts >= _maxReconnectAttempts;

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionStateController.close();
  }
}

/// SSE 服务单例 Provider
///
/// 注意：使用 keepAlive 防止 Provider 重建导致的连接抖动。
/// 配置变化时通过 listen 处理，而不是重建整个服务。
final hapiSseServiceProvider = Provider<HapiSseService?>((ref) {
  // 保持 Provider 存活，防止因依赖变化导致重建
  ref.keepAlive();

  // 初始读取配置（不使用 watch 避免重建）
  final config = ref.read(hapiConfigProvider);
  if (!config.isConfigured) return null;

  final apiService = ref.read(hapiApiServiceProvider);
  final service = HapiSseService(config, apiService);

  // 初始连接
  if (config.enabled) service.connect();

  // 监听配置变化，动态调整连接状态（而非重建服务）
  ref.listen<HapiConfig>(hapiConfigProvider, (previous, next) {
    if (!next.isConfigured) {
      service.disconnect();
      return;
    }

    final wasEnabled = previous?.enabled ?? false;
    final isEnabled = next.enabled;

    if (isEnabled && !wasEnabled) {
      // 配置启用，建立连接
      Log.i('SSE', 'Config enabled, connecting...');
      service.connect();
    } else if (!isEnabled && wasEnabled) {
      // 配置禁用，断开连接
      Log.i('SSE', 'Config disabled, disconnecting...');
      service.disconnect();
    }
    // URL 变化需要重连
    else if (previous?.serverUrl != next.serverUrl && isEnabled) {
      Log.i('SSE', 'Server URL changed, reconnecting...');
      service.resetAndReconnect();
    }
  });

  ref.onDispose(() => service.dispose());
  return service;
});

final hapiConnectionStateProvider = StreamProvider<HapiConnectionState>((
  ref,
) async* {
  // 使用 read 因为 hapiSseServiceProvider 已使用 keepAlive，不会重建
  final sseService = ref.read(hapiSseServiceProvider);
  if (sseService == null) {
    yield const HapiConnectionState(status: HapiConnectionStatus.disconnected);
    return;
  }
  yield sseService.currentState;
  await for (final state in sseService.connectionState) {
    yield state;
  }
});

final hapiSseEventsProvider = StreamProvider<HapiSseEvent>((ref) async* {
  // 使用 read 因为 hapiSseServiceProvider 已使用 keepAlive，不会重建
  final sseService = ref.read(hapiSseServiceProvider);
  if (sseService == null) return;
  await for (final event in sseService.events) {
    yield event;
  }
});

final hapiIsConnectedProvider = Provider<bool>((ref) {
  final connectionState = ref.watch(hapiConnectionStateProvider);
  return connectionState.maybeWhen(
    data: (state) => state.isConnected,
    orElse: () => false,
  );
});
