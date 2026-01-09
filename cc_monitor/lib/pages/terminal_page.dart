import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../providers/settings_provider.dart';
import '../services/terminal_service.dart';

/// 终端页面 - 类似 iTerm2 风格
class TerminalPage extends ConsumerStatefulWidget {
  const TerminalPage({super.key, required this.sessionId, this.sessionName});

  final String sessionId;
  final String? sessionName;

  @override
  ConsumerState<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends ConsumerState<TerminalPage> {
  late final Terminal _terminal;
  late final TerminalController _terminalController;
  late final TerminalService _terminalService;
  final _focusNode = FocusNode();
  StreamSubscription? _outputSubscription;
  StreamSubscription? _stateSubscription;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _errorMessage;

  // 快捷键
  static const _quickKeys = [
    ('Esc', '\x1b'),
    ('Tab', '\t'),
    ('Ctrl+C', '\x03'),
    ('Ctrl+D', '\x04'),
    ('Ctrl+Z', '\x1a'),
    ('↑', '\x1b[A'),
    ('↓', '\x1b[B'),
  ];

  @override
  void initState() {
    super.initState();
    _terminalService = ref.read(terminalServiceProvider);
    _initTerminal();
    _connect();
  }

  void _initTerminal() {
    _terminal = Terminal(maxLines: 10000);

    _terminalController = TerminalController();

    // 监听用户输入
    _terminal.onOutput = (data) {
      final service = _terminalService;
      service.write(data);
    };

    // 监听终端大小变化
    _terminal.onResize = (w, h, pw, ph) {
      _handleResize(w, h);
    };
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    final service = _terminalService;

    // 监听输出
    _outputSubscription?.cancel();
    _outputSubscription = service.outputStream.listen((data) {
      _terminal.write(data);
    });

    // 监听状态
    _stateSubscription?.cancel();
    _stateSubscription = service.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isConnected = state.isConnected;
        _isConnecting = state.isConnecting;
        _errorMessage = state.errorMessage;
      });
    });

    // 连接
    final success = await service.connect(widget.sessionId);
    if (mounted) {
      setState(() {
        _isConnected = success;
        _isConnecting = false;
      });

      if (success) {
        // 发送初始化命令（可选）
        _terminal.write('\x1b[2J\x1b[H'); // 清屏
        _terminal.write('\x1b[32m● Connected to session\x1b[0m\r\n\r\n');
      }
    }
  }

  Future<void> _disconnect() async {
    final service = _terminalService;
    await service.disconnect();
  }

  void _handleResize(int cols, int rows) {
    final service = _terminalService;
    service.resize(cols, rows);
  }

  void _sendQuickKey(String data) {
    final service = _terminalService;
    service.write(data);
    // 聚焦终端
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _outputSubscription?.cancel();
    _stateSubscription?.cancel();
    _focusNode.dispose();
    _disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // iTerm2 风格深色背景
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _disconnect();
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            // 连接状态指示器
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _isConnected
                        ? Colors.green
                        : _isConnecting
                        ? Colors.amber
                        : Colors.grey,
              ),
            ),
            Expanded(
              child: Text(
                widget.sessionName ?? 'Terminal',
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // 重连按钮
          if (!_isConnected && !_isConnecting)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重新连接',
              onPressed: _connect,
            ),
          // 清屏按钮
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: '清屏',
            onPressed: () {
              _terminal.write('\x1b[2J\x1b[H');
            },
          ),
          // 字体设置按钮
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: '字体设置',
            onPressed: () => _showFontSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 错误提示
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(onPressed: _connect, child: const Text('重试')),
                ],
              ),
            ),

          // 终端视图
          Expanded(
            child:
                _isConnecting
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white54),
                          SizedBox(height: 16),
                          Text(
                            '正在连接...',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    )
                    : _buildTerminalView(),
          ),

          // 快捷键栏
          Container(
            color: const Color(0xFF2D2D2D),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children:
                      _quickKeys.map((key) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _QuickKeyButton(
                            label: key.$1,
                            onTap: () => _sendQuickKey(key.$2),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TerminalTheme _buildTerminalTheme() {
    // iTerm2 风格配色
    return const TerminalTheme(
      cursor: Color(0xFFFFFFFF),
      selection: Color(0x80FFFFFF),
      foreground: Color(0xFFD4D4D4),
      background: Color(0xFF1E1E1E),
      black: Color(0xFF000000),
      red: Color(0xFFCD3131),
      green: Color(0xFF0DBC79),
      yellow: Color(0xFFE5E510),
      blue: Color(0xFF2472C8),
      magenta: Color(0xFFBC3FBC),
      cyan: Color(0xFF11A8CD),
      white: Color(0xFFE5E5E5),
      brightBlack: Color(0xFF666666),
      brightRed: Color(0xFFF14C4C),
      brightGreen: Color(0xFF23D18B),
      brightYellow: Color(0xFFF5F543),
      brightBlue: Color(0xFF3B8EEA),
      brightMagenta: Color(0xFFD670D6),
      brightCyan: Color(0xFF29B8DB),
      brightWhite: Color(0xFFFFFFFF),
      searchHitBackground: Color(0xFFFFDF5D),
      searchHitBackgroundCurrent: Color(0xFFFF9632),
      searchHitForeground: Color(0xFF000000),
    );
  }

  Widget _buildTerminalView() {
    final fontFamily = ref.watch(terminalFontProvider);
    final fontSize = ref.watch(terminalFontSizeProvider);

    return TerminalView(
      _terminal,
      controller: _terminalController,
      focusNode: _focusNode,
      autofocus: true,
      backgroundOpacity: 0,
      theme: _buildTerminalTheme(),
      textStyle: TerminalStyle(
        fontSize: fontSize,
        fontFamily: fontFamily.fontFamily,
      ),
      padding: const EdgeInsets.all(8),
    );
  }

  void _showFontSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _FontSettingsSheet(),
    );
  }
}

/// 字体设置面板
class _FontSettingsSheet extends ConsumerWidget {
  const _FontSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFont = ref.watch(terminalFontProvider);
    final currentSize = ref.watch(terminalFontSizeProvider);
    final settings = ref.read(settingsProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.text_fields, color: Colors.white70),
                const SizedBox(width: 8),
                const Text(
                  '终端字体设置',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 字体选择
            const Text(
              '字体',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  TerminalFontFamily.values.map((font) {
                    final isSelected = font == currentFont;
                    return ChoiceChip(
                      label: Text(
                        font.displayName,
                        style: TextStyle(
                          fontFamily: font.fontFamily,
                          color: isSelected ? Colors.black : Colors.white70,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.white,
                      backgroundColor: const Color(0xFF3D3D3D),
                      onSelected: (_) => settings.setTerminalFont(font),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),

            // 字号调节
            Row(
              children: [
                const Text(
                  '字号',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '${currentSize.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.white70,
                  onPressed:
                      currentSize > 10
                          ? () => settings.setTerminalFontSize(currentSize - 1)
                          : null,
                ),
                Expanded(
                  child: Slider(
                    value: currentSize,
                    min: 10,
                    max: 24,
                    divisions: 14,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                    onChanged: (value) => settings.setTerminalFontSize(value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.white70,
                  onPressed:
                      currentSize < 24
                          ? () => settings.setTerminalFontSize(currentSize + 1)
                          : null,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 预览
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '预览: AaBbCc 123 →  \$ echo "Hello"',
                style: TextStyle(
                  fontFamily: currentFont.fontFamily,
                  fontSize: currentSize,
                  color: const Color(0xFFD4D4D4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 快捷键按钮
class _QuickKeyButton extends StatelessWidget {
  const _QuickKeyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3D3D3D),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}
