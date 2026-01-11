import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/logger.dart';
import 'hapi_config_service.dart';
import 'hapi_api_service.dart';
import 'sse_parser.dart';
import '../error_recovery_strategy.dart';

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
  HapiSseService(
    this._config,
    this._apiService, [
    ErrorRecoveryStrategy? recoveryStrategy,
  ]) : _recoveryStrategy = recoveryStrategy ?? RecoveryStrategies.connection;

  HapiConfig _config; // 可变，允许配置更新
  HapiApiService? _apiService; // 可变，允许 API service 更新
  // ignore: unused_field - 保留用于未来扩展，与 ErrorRecoveryStrategy 保持一致
  final ErrorRecoveryStrategy _recoveryStrategy;

  Dio? _dio;
  CancelToken? _cancelToken;
  StreamSubscription<SseParseResult>? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  // SSE 解析器
  SseStreamParser? _sseParser;

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

  // 重连标志（防止循环）
  bool _isReconnecting = false;

  // 重连配置
  static const _maxReconnectAttempts = 10;

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

  /// 更新配置（由 Provider 在配置变化时调用）
  void updateConfig(HapiConfig config) {
    _config = config;
  }

  /// 更新 API Service（由 Provider 在配置变化时调用）
  void updateApiService(HapiApiService? apiService) {
    if (_apiService != apiService) {
      Log.d(
        'SSE',
        'Updating API Service: ${apiService != null ? "available" : "null"}',
      );
      _apiService = apiService;
    }
  }

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

      // 获取 JWT token
      final apiService = _apiService;
      if (apiService == null) {
        throw Exception('API Service not available for SSE connection');
      }

      final jwtToken = await apiService.getJwtToken();
      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception('Failed to get JWT token for SSE connection');
      }

      Log.d('SSE', 'JWT token obtained for connection');

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

      // 创建 SSE 解析器
      _sseParser = SseParserFactory.createStreamParser(
        defaultEventType: 'message',
        onEvent: _handleSseEvent,
        onRetryDelay: _handleRetryDelay,
        onError: (error, stackTrace) {
          Log.e('SSE', 'Parser error', error, stackTrace);
        },
      );

      // 使用 SSE 解析器处理流
      final lineStream = stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      _subscription = _sseParser!
          .parse(lineStream)
          .listen(
            _handleParseResult,
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

  /// 处理 SSE 事件（从解析器回调触发）
  void _handleSseEvent(String eventType, String data, String? eventId) {
    _lastEventTime = DateTime.now();

    // 更新 lastEventId
    if (eventId != null) {
      _lastEventId = eventId;
    }

    // 创建 HapiSseEvent
    final event = HapiSseEvent.fromRaw(eventType, data);

    // 提取 subscriptionId
    if (event.type == HapiSseEventType.connectionChanged) {
      final eventData = event.data;
      if (eventData != null && eventData['data'] is Map) {
        _subscriptionId =
            (eventData['data'] as Map<String, dynamic>)['subscriptionId']
                as String?;
      }
    }

    // 发送事件
    _eventController.add(event);
  }

  /// 处理服务器重试延迟指令
  void _handleRetryDelay(Duration delay) {
    _serverRetryDelay = delay;
    Log.i('SSE', 'Server suggested retry delay: ${delay.inMilliseconds}ms');
  }

  /// 处理解析结果（可选，用于调试）
  void _handleParseResult(SseParseResult result) {
    // 解析结果已通过回调处理，此处仅用于日志或调试
    if (result.hasEvent) {
      Log.v('SSE', 'Event parsed: ${result.eventType}');
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

    // 使用与 ErrorRecoveryStrategy 一致的延迟计算逻辑
    final delay = _calculateReconnectDelay(_currentState.reconnectAttempts + 1);

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

  /// 计算重连延迟（与 ErrorRecoveryStrategy 一致的算法）
  /// 使用指数退避 + 随机抖动，防止雷鸣群效应
  Duration _calculateReconnectDelay(int attempt) {
    // 优先使用服务器建议的延迟
    if (_serverRetryDelay != null) {
      return _serverRetryDelay!;
    }

    // 使用与 RecoveryStrategies.connection 相同的参数
    // initialDelay: 1s, maxDelay: 30s, multiplier: 2.0, jitterFactor: 0.25
    const initialDelayMs = 1000;
    const maxDelayMs = 30000;
    const multiplier = 2.0;
    const jitterFactor = 0.25;

    // 指数增长: initialDelay * multiplier^(attempt-1)
    final exponentialDelayMs = initialDelayMs * pow(multiplier, attempt - 1);

    // 添加随机抖动: ±25%
    final random = Random();
    final jitter =
        exponentialDelayMs * jitterFactor * (2 * random.nextDouble() - 1);
    final delayMs = (exponentialDelayMs + jitter).toInt();

    // 限制最大延迟
    final clampedDelayMs = delayMs.clamp(initialDelayMs, maxDelayMs);
    return Duration(milliseconds: clampedDelayMs);
  }

  void _updateState(HapiConnectionState state) {
    _currentState = state;

    // 在重连期间跳过状态广播，避免触发 ConnectionManager 的循环处理
    if (!_isReconnecting) {
      _connectionStateController.add(state);
    }
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
    _sseParser = null;
    _updateState(
      const HapiConnectionState(status: HapiConnectionStatus.disconnected),
    );
  }

  Future<void> reconnect() async {
    // 设置重连标志，防止状态更新触发循环
    _isReconnecting = true;

    try {
      disconnect();
      await Future.delayed(const Duration(milliseconds: 100));
      await connect();
    } finally {
      // 重连完成，恢复状态广播
      _isReconnecting = false;

      // 手动广播最终状态
      _connectionStateController.add(_currentState);
    }
  }

  Future<void> resetAndReconnect() async {
    // 设置重连标志，防止状态更新触发循环
    _isReconnecting = true;

    try {
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
    } finally {
      // 重连完成，恢复状态广播
      _isReconnecting = false;

      // 手动广播最终状态
      _connectionStateController.add(_currentState);
    }
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

  // 注意：总是创建 service，即使配置未就绪
  // 这样可以避免初始化时序问题（配置可能还在加载中）
  final apiService = ref.read(hapiApiServiceProvider);
  final service = HapiSseService(config, apiService);

  // 只有配置已就绪且启用时才初始连接
  if (config.enabled && config.isConfigured) {
    Log.i('SSE', 'Initial connect (config ready)');
    service.connect();
  } else {
    Log.d('SSE', 'Skip initial connect (config not ready or disabled)');
  }

  // 监听配置变化，动态调整连接状态（而非重建服务）
  ref.listen<HapiConfig>(hapiConfigProvider, (previous, next) {
    // 先更新service的配置引用
    service.updateConfig(next);

    // 同时更新 API Service（配置变化时可能重新创建）
    final newApiService = ref.read(hapiApiServiceProvider);
    service.updateApiService(newApiService);

    // 处理配置首次加载完成的情况
    final wasConfigured = previous?.isConfigured ?? false;
    final isConfigured = next.isConfigured;

    if (!wasConfigured && isConfigured && next.enabled) {
      // 配置首次加载完成且启用，建立连接
      Log.i('SSE', 'Config loaded, connecting...');
      service.connect();
      return;
    }

    if (!isConfigured) {
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
