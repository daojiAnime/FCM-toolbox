import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:uuid/uuid.dart';

import '../common/logger.dart';
import 'hapi/hapi_api_service.dart';
import 'hapi/hapi_config_service.dart';

/// 终端连接状态
enum TerminalConnectionStatus {
  idle,
  connecting,
  connected,
  disconnected,
  error,
}

/// 终端连接状态数据
class TerminalConnectionState {
  const TerminalConnectionState({
    this.status = TerminalConnectionStatus.idle,
    this.errorMessage,
  });

  final TerminalConnectionStatus status;
  final String? errorMessage;

  bool get isConnected => status == TerminalConnectionStatus.connected;
  bool get isConnecting => status == TerminalConnectionStatus.connecting;

  TerminalConnectionState copyWith({
    TerminalConnectionStatus? status,
    String? errorMessage,
  }) {
    return TerminalConnectionState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

/// 终端服务 - 管理 Socket.IO 连接
class TerminalService {
  TerminalService(this._ref);

  final Ref _ref;
  io.Socket? _socket;
  String? _currentSessionId;
  String? _terminalId;

  final _stateController =
      StreamController<TerminalConnectionState>.broadcast();
  final _outputController = StreamController<String>.broadcast();

  TerminalConnectionState _currentState = const TerminalConnectionState();

  /// 连接状态流
  Stream<TerminalConnectionState> get stateStream => _stateController.stream;

  /// 终端输出流
  Stream<String> get outputStream => _outputController.stream;

  /// 当前状态
  TerminalConnectionState get currentState => _currentState;

  /// 连接到终端
  Future<bool> connect(String sessionId, {int cols = 80, int rows = 24}) async {
    if (_currentState.isConnected && _currentSessionId == sessionId) {
      return true;
    }

    // 断开旧连接
    await disconnect();
    _currentSessionId = sessionId;
    _terminalId = const Uuid().v4();

    _updateState(
      const TerminalConnectionState(
        status: TerminalConnectionStatus.connecting,
      ),
    );

    try {
      // 获取配置
      final config = _ref.read(hapiConfigProvider);
      if (!config.isConfigured) {
        throw Exception('hapi 未配置');
      }

      // 获取 JWT token
      final api = _ref.read(hapiApiServiceProvider);
      if (api == null) {
        throw Exception('API 服务不可用');
      }

      final token = await api.getJwtToken();
      if (token == null || token.isEmpty) {
        throw Exception('无法获取认证 token');
      }

      // 构建 Socket.IO URL
      final serverUrl = config.serverUrl;
      Log.i('TermSvc', 'Connecting to: $serverUrl/terminal');

      // 创建 Socket.IO 连接
      _socket = io.io(
        '$serverUrl/terminal',
        io.OptionBuilder()
            .setTransports(['polling', 'websocket'])
            .setPath('/socket.io/')
            .setAuth({'token': token})
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(999999)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .build(),
      );

      // 设置事件监听
      _setupEventListeners(cols, rows);

      // 手动连接
      _socket!.connect();

      // 等待连接或错误
      final completer = Completer<bool>();
      Timer? timeout;

      void onConnected(_) {
        timeout?.cancel();
        if (!completer.isCompleted) {
          // 连接成功后发送 terminal:create
          _emitCreate(cols, rows);
        }
      }

      void onReady(dynamic data) {
        final terminalId = data['terminalId'] as String?;
        if (terminalId == _terminalId && !completer.isCompleted) {
          completer.complete(true);
        }
      }

      void onError(dynamic error) {
        timeout?.cancel();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }

      _socket!.onConnect(onConnected);
      _socket!.on('terminal:ready', onReady);
      _socket!.onConnectError(onError);
      _socket!.onError(onError);

      timeout = Timer(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          completer.complete(false);
          _updateState(
            const TerminalConnectionState(
              status: TerminalConnectionStatus.error,
              errorMessage: '连接超时',
            ),
          );
        }
      });

      return await completer.future;
    } catch (e) {
      Log.i('TermSvc', 'Connection error: $e');
      _updateState(
        TerminalConnectionState(
          status: TerminalConnectionStatus.error,
          errorMessage: e.toString(),
        ),
      );
      return false;
    }
  }

  void _setupEventListeners(int cols, int rows) {
    final socket = _socket;
    if (socket == null) return;

    socket.onConnect((_) {
      Log.i('TermSvc', 'Socket connected');
    });

    socket.on('terminal:ready', (data) {
      final terminalId = data['terminalId'] as String?;
      if (terminalId != _terminalId) return;

      Log.i('TermSvc', 'Terminal ready');
      _updateState(
        const TerminalConnectionState(
          status: TerminalConnectionStatus.connected,
        ),
      );
    });

    socket.on('terminal:output', (data) {
      final terminalId = data['terminalId'] as String?;
      if (terminalId != _terminalId) return;

      final output = data['data'] as String?;
      if (output != null) {
        _outputController.add(output);
      }
    });

    socket.on('terminal:exit', (data) {
      final terminalId = data['terminalId'] as String?;
      if (terminalId != _terminalId) return;

      final code = data['code'];
      final signal = data['signal'];
      Log.i('TermSvc', 'Terminal exited: code=$code, signal=$signal');
      _updateState(
        const TerminalConnectionState(
          status: TerminalConnectionStatus.error,
          errorMessage: '终端已退出',
        ),
      );
    });

    socket.on('terminal:error', (data) {
      final terminalId = data['terminalId'] as String?;
      if (terminalId != _terminalId) return;

      final message = data['message'] as String? ?? '未知错误';
      Log.i('TermSvc', 'Terminal error: $message');
      _updateState(
        TerminalConnectionState(
          status: TerminalConnectionStatus.error,
          errorMessage: message,
        ),
      );
    });

    socket.onConnectError((error) {
      Log.i('TermSvc', 'Connect error: $error');
      _updateState(
        TerminalConnectionState(
          status: TerminalConnectionStatus.error,
          errorMessage: error.toString(),
        ),
      );
    });

    socket.onDisconnect((reason) {
      Log.i('TermSvc', 'Disconnected: $reason');
      if (reason == 'io client disconnect') {
        _updateState(
          const TerminalConnectionState(status: TerminalConnectionStatus.idle),
        );
      } else {
        _updateState(
          TerminalConnectionState(
            status: TerminalConnectionStatus.error,
            errorMessage: '连接断开: $reason',
          ),
        );
      }
    });

    socket.onError((error) {
      Log.i('TermSvc', 'Socket error: $error');
    });
  }

  void _emitCreate(int cols, int rows) {
    final socket = _socket;
    if (socket == null || _currentSessionId == null || _terminalId == null)
      return;

    Log.i('TermSvc', 'Emitting terminal:create');
    socket.emit('terminal:create', {
      'sessionId': _currentSessionId,
      'terminalId': _terminalId,
      'cols': cols,
      'rows': rows,
    });
  }

  /// 发送输入数据
  void write(String data) {
    final socket = _socket;
    if (socket == null || !_currentState.isConnected || _terminalId == null)
      return;

    socket.emit('terminal:write', {'terminalId': _terminalId, 'data': data});
  }

  /// 调整终端大小
  void resize(int cols, int rows) {
    final socket = _socket;
    if (socket == null || !_currentState.isConnected || _terminalId == null)
      return;

    socket.emit('terminal:resize', {
      'terminalId': _terminalId,
      'cols': cols,
      'rows': rows,
    });
    Log.i('TermSvc', 'Resized to ${cols}x$rows');
  }

  /// 断开连接
  Future<void> disconnect() async {
    final socket = _socket;
    if (socket != null) {
      socket.clearListeners();
      socket.disconnect();
      socket.dispose();
    }
    _socket = null;
    _currentSessionId = null;
    _terminalId = null;

    _updateState(
      const TerminalConnectionState(
        status: TerminalConnectionStatus.disconnected,
      ),
    );

    Log.i('TermSvc', 'Disconnected');
  }

  void _updateState(TerminalConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _stateController.close();
    _outputController.close();
  }
}

/// 终端服务 Provider
final terminalServiceProvider = Provider<TerminalService>((ref) {
  final service = TerminalService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

/// 终端连接状态 Provider
final terminalConnectionStateProvider = StreamProvider<TerminalConnectionState>(
  (ref) {
    final service = ref.watch(terminalServiceProvider);
    return service.stateStream;
  },
);
