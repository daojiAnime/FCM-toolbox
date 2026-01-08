import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:xterm/xterm.dart';
import '../services/hapi/hapi_api_service.dart';

/// 远程终端页面
class TerminalPage extends ConsumerStatefulWidget {
  const TerminalPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends ConsumerState<TerminalPage> {
  late Terminal _terminal;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  bool _isConnecting = false;
  bool _isConnected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 10000);
    _terminal.onOutput = _onTerminalOutput;
    _connect();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  void _onTerminalOutput(String data) {
    // 发送用户输入到服务器
    _channel?.sink.add(jsonEncode({'type': 'input', 'data': data}));
  }

  Future<void> _connect() async {
    final apiService = ref.read(hapiApiServiceProvider);
    if (apiService == null) {
      setState(() => _error = 'hapi 服务未配置');
      return;
    }

    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      final wsUrl = apiService.getTerminalWsUrl(widget.sessionId);
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // 等待连接建立
      await _channel!.ready;

      setState(() {
        _isConnecting = false;
        _isConnected = true;
      });

      // 监听服务器消息
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // 发送终端大小
      _sendResize();

      // 写入欢迎信息
      _terminal.write(
        '\r\n\x1B[32m[Connected to session ${widget.sessionId}]\x1B[0m\r\n\r\n',
      );
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _error = e.toString();
      });
    }
  }

  void _onMessage(dynamic message) {
    try {
      if (message is String) {
        final data = jsonDecode(message);
        if (data['type'] == 'output') {
          _terminal.write(data['data'] as String);
        } else if (data['type'] == 'exit') {
          _terminal.write('\r\n\x1B[33m[Session ended]\x1B[0m\r\n');
          setState(() => _isConnected = false);
        }
      }
    } catch (e) {
      // 如果不是 JSON，直接写入终端
      if (message is String) {
        _terminal.write(message);
      }
    }
  }

  void _onError(Object error) {
    setState(() {
      _isConnected = false;
      _error = error.toString();
    });
    _terminal.write('\r\n\x1B[31m[Error: $error]\x1B[0m\r\n');
  }

  void _onDone() {
    setState(() => _isConnected = false);
    _terminal.write('\r\n\x1B[33m[Disconnected]\x1B[0m\r\n');
  }

  void _sendResize() {
    // 发送终端大小
    _channel?.sink.add(jsonEncode({'type': 'resize', 'cols': 80, 'rows': 24}));
  }

  void _reconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('远程终端'),
        actions: [
          // 连接状态
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  _isConnected
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isConnected ? '已连接' : '未连接',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // 重连按钮
          if (!_isConnected && !_isConnecting)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reconnect,
              tooltip: '重新连接',
            ),
          // 清屏按钮
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              _terminal.write('\x1B[2J\x1B[H');
            },
            tooltip: '清屏',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isConnecting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在连接终端...'),
          ],
        ),
      );
    }

    if (_error != null && !_isConnected) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('连接失败', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _reconnect,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF1E1E1E),
      child: TerminalView(
        _terminal,
        textStyle: const TerminalStyle(fontSize: 14, fontFamily: 'monospace'),
        padding: const EdgeInsets.all(8),
        autofocus: true,
        backgroundOpacity: 1.0,
        shortcuts: {
          // Ctrl+C
          const SingleActivator(LogicalKeyboardKey.keyC, control: true):
              _TerminalCopyIntent(),
          // Ctrl+V
          const SingleActivator(LogicalKeyboardKey.keyV, control: true):
              _TerminalPasteIntent(),
        },
        keyboardType: TextInputType.text,
      ),
    );
  }
}

/// 复制意图
class _TerminalCopyIntent extends Intent {
  const _TerminalCopyIntent();
}

/// 粘贴意图
class _TerminalPasteIntent extends Intent {
  const _TerminalPasteIntent();
}
