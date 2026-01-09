import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pages/terminal_page.dart';
import '../../services/hapi/hapi_api_service.dart';
import '../../services/hapi/hapi_sse_service.dart';
import '../../services/toast_service.dart';
import 'rainbow_text.dart';
import 'session_settings_sheet.dart';

/// Slash 命令数据结构
class SlashCommand {
  final String name;
  final String description;
  final String source;

  const SlashCommand({
    required this.name,
    required this.description,
    this.source = 'builtin',
  });
}

/// 内置命令列表 (按 agent 类型分类)
const _builtinCommandsByAgent = <String, List<SlashCommand>>{
  'claude': [
    SlashCommand(
      name: 'clear',
      description: 'Clear conversation history and free up context',
    ),
    SlashCommand(
      name: 'compact',
      description: 'Clear conversation history but keep a summary in context',
    ),
    SlashCommand(
      name: 'context',
      description: 'Visualize current context usage as a colored grid',
    ),
    SlashCommand(
      name: 'cost',
      description: 'Show the total cost and duration of the current session',
    ),
    SlashCommand(
      name: 'doctor',
      description:
          'Diagnose and verify your Claude Code installation and settings',
    ),
    SlashCommand(
      name: 'plan',
      description: 'View or open the current session plan',
    ),
    SlashCommand(
      name: 'stats',
      description: 'Show your Claude Code usage statistics and activity',
    ),
    SlashCommand(
      name: 'status',
      description:
          'Show Claude Code status including version, model, account, and API connectivity',
    ),
  ],
  'codex': [
    SlashCommand(
      name: 'review',
      description: 'Review current changes and find issues',
    ),
    SlashCommand(
      name: 'new',
      description: 'Start a new chat during a conversation',
    ),
    SlashCommand(
      name: 'compat',
      description:
          'Summarize conversation to prevent hitting the context limit',
    ),
    SlashCommand(name: 'undo', description: 'Ask Codex to undo a turn'),
    SlashCommand(
      name: 'diff',
      description: 'Show git diff including untracked files',
    ),
    SlashCommand(
      name: 'status',
      description: 'Show current session configuration and token usage',
    ),
  ],
  'gemini': [
    SlashCommand(name: 'about', description: 'Show version info'),
    SlashCommand(
      name: 'clear',
      description: 'Clear the screen and conversation history',
    ),
    SlashCommand(
      name: 'compress',
      description: 'Compress the context by replacing it with a summary',
    ),
    SlashCommand(name: 'stats', description: 'Check session stats'),
  ],
};

/// 默认使用 claude 命令列表
const _defaultBuiltinCommands = <SlashCommand>[
  SlashCommand(
    name: 'clear',
    description: 'Clear conversation history and free up context',
  ),
  SlashCommand(
    name: 'compact',
    description: 'Clear conversation history but keep a summary in context',
  ),
  SlashCommand(
    name: 'context',
    description: 'Visualize current context usage as a colored grid',
  ),
  SlashCommand(
    name: 'cost',
    description: 'Show the total cost and duration of the current session',
  ),
  SlashCommand(
    name: 'doctor',
    description:
        'Diagnose and verify your Claude Code installation and settings',
  ),
  SlashCommand(
    name: 'plan',
    description: 'View or open the current session plan',
  ),
  SlashCommand(
    name: 'stats',
    description: 'Show your Claude Code usage statistics and activity',
  ),
  SlashCommand(
    name: 'status',
    description:
        'Show Claude Code status including version, model, account, and API connectivity',
  ),
];

/// 聊天输入框组件 - 极致现代化的 AI 交互体验 (1:1 还原 hapi web)
class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
    this.sessionId,
    this.sessionName,
    this.enabled = true,
    this.isRunning = false,
    this.hintText = 'Ask anything',
    this.agentType = 'claude',
    this.controlledByUser = false,
    this.isSwitching = false,
    this.onSwitchToRemote,
    this.contextSize,
    this.maxContextSize = 190000,
    this.hasPendingPermission = false,
    this.permissionMode,
    this.onPermissionModeChange,
  });

  final void Function(String message) onSend;
  final String? sessionId;
  final String? sessionName;
  final bool enabled;

  /// 会话是否正在运行 (用于显示 abort 按钮)
  final bool isRunning;
  final String hintText;

  /// Agent 类型: claude, codex, gemini
  final String agentType;

  /// 会话是否由本地终端控制 (与 web 对齐)
  final bool controlledByUser;

  /// 是否正在切换到远程模式
  final bool isSwitching;

  /// 切换到远程模式回调
  final VoidCallback? onSwitchToRemote;

  /// 上下文大小 (用于计算剩余百分比)
  final int? contextSize;

  /// 最大上下文大小 (默认 190000, 留 10k headroom)
  final int maxContextSize;

  /// 是否有待处理的权限请求
  final bool hasPendingPermission;

  /// 当前权限模式
  final String? permissionMode;

  /// 权限模式切换回调 (Shift+Tab 快捷键)
  final void Function(String mode)? onPermissionModeChange;

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

/// 权限模式循环列表 (与 Web 版 @hapi/protocol 对齐)
/// API 值: default, plan, acceptEdits, bypassPermissions
/// 注意：不同 flavor 支持不同模式
const _permissionModesByFlavor = <String, List<String>>{
  'claude': ['plan', 'acceptEdits', 'bypassPermissions'],
  'codex': ['plan', 'acceptEdits', 'bypassPermissions'],
  'gemini': ['plan', 'acceptEdits'],
};
const _defaultPermissionModes = ['plan', 'acceptEdits', 'bypassPermissions'];

class _ChatInputState extends ConsumerState<ChatInput>
    with SingleTickerProviderStateMixin {
  final _controller = RainbowTextEditingController(); // 支持彩虹效果
  final _focusNode = FocusNode();
  final _keyboardFocusNode = FocusNode(); // 用于 KeyboardListener
  bool _isSending = false;
  bool _isAborting = false;
  bool _showContinueHint = false; // 切换后显示 "Type 'continue'..." 提示

  // Slash 命令相关状态
  List<SlashCommand> _allCommands = [];
  bool _isLoadingCommands = false;

  // 命令列表导航状态
  final _scrollController = ScrollController();
  final _itemHeight = 44.0; // 列表项高度

  late AnimationController _pulseController;
  final _random = math.Random();
  String _vibingMessage = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _updateVibingMessage();

    // 监听文本变化以更新发送按钮状态
    _controller.addListener(_onTextChanged);

    // 初始化命令列表 (根据 agent 类型)
    _allCommands = List.from(
      _builtinCommandsByAgent[widget.agentType] ?? _defaultBuiltinCommands,
    );
    _loadSlashCommands();
  }

  void _onTextChanged() {
    // 触发 rebuild 以更新发送按钮状态
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sessionId != oldWidget.sessionId ||
        widget.agentType != oldWidget.agentType) {
      // 重置内置命令列表
      _allCommands = List.from(
        _builtinCommandsByAgent[widget.agentType] ?? _defaultBuiltinCommands,
      );
      _loadSlashCommands();
    }
    // 监听 isRunning 变化，恢复 isAborting 状态
    if (oldWidget.isRunning && !widget.isRunning) {
      _checkAbortingState();
    }
    // 跟踪 controlledByUser: true -> false 时显示 continue 提示 (与 web 对齐)
    if (oldWidget.controlledByUser && !widget.controlledByUser) {
      setState(() => _showContinueHint = true);
    }
    if (widget.controlledByUser) {
      setState(() => _showContinueHint = false);
    }
  }

  /// 加载 Slash 命令 (内置 + API)
  Future<void> _loadSlashCommands() async {
    if (_isLoadingCommands || widget.sessionId == null) return;

    setState(() => _isLoadingCommands = true);

    final builtinCommands =
        _builtinCommandsByAgent[widget.agentType] ?? _defaultBuiltinCommands;

    try {
      final api = ref.read(hapiApiServiceProvider);
      final userCommands = await api?.getSlashCommands(widget.sessionId!);

      if (mounted) {
        setState(() {
          _allCommands = [
            ...builtinCommands,
            if (userCommands != null)
              ...userCommands.map(
                (c) => SlashCommand(
                  name: c['name'] as String? ?? '',
                  description: c['description'] as String? ?? '',
                  source: 'user',
                ),
              ),
          ];
        });
      }
    } catch (e) {
      // 失败时只使用内置命令
      if (mounted) {
        setState(() => _allCommands = List.from(builtinCommands));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCommands = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateVibingMessage() {
    const vibingMessages = [
      "Accomplishing",
      "Actioning",
      "Actualizing",
      "Baking",
      "Booping",
      "Brewing",
      "Calculating",
      "Cerebrating",
      "Channelling",
      "Churning",
      "Clauding",
      "Coalescing",
      "Cogitating",
      "Computing",
      "Combobulating",
      "Concocting",
      "Conjuring",
      "Considering",
      "Contemplating",
      "Cooking",
      "Crafting",
      "Creating",
      "Crunching",
      "Deciphering",
      "Deliberating",
      "Determining",
      "Discombobulating",
      "Divining",
      "Doing",
      "Effecting",
      "Elucidating",
      "Enchanting",
      "Envisioning",
      "Finagling",
      "Flibbertigibbeting",
      "Forging",
      "Forming",
      "Frolicking",
      "Generating",
      "Germinating",
      "Hatching",
      "Herding",
      "Honking",
      "Ideating",
      "Imagining",
      "Incubating",
      "Inferring",
      "Manifesting",
      "Marinating",
      "Meandering",
      "Moseying",
      "Mulling",
      "Mustering",
      "Musing",
      "Noodling",
      "Percolating",
      "Perusing",
      "Philosophising",
      "Pontificating",
      "Pondering",
      "Processing",
      "Puttering",
      "Puzzling",
      "Reticulating",
      "Ruminating",
      "Scheming",
      "Schlepping",
      "Shimmying",
      "Simmering",
      "Smooshing",
      "Spelunking",
      "Spinning",
      "Stewing",
      "Sussing",
      "Synthesizing",
      "Thinking",
      "Tinkering",
      "Transmuting",
      "Unfurling",
      "Unravelling",
      "Vibing",
      "Wandering",
      "Whirring",
      "Wibbling",
      "Wizarding",
      "Working",
      "Wrangling",
    ];
    setState(() {
      _vibingMessage =
          '${vibingMessages[_random.nextInt(vibingMessages.length)].toLowerCase()}…';
    });
  }

  /// 处理键盘事件 (Escape 中止 + Shift+Tab 切换权限模式)
  /// 注意：命令导航由 RawAutocomplete 内部处理
  KeyEventResult _handleKeyEvent(KeyEvent event) {
    // 处理按下和长按重复事件
    if (event is! KeyDownEvent && event is! KeyRepeatEvent)
      return KeyEventResult.ignored;

    // Escape 键：当会话运行中时触发中止
    // 注意：RawAutocomplete 会先处理 Escape 关闭菜单
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (widget.isRunning && !_isAborting) {
        _handleAbort();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Shift+Tab：循环切换权限模式 (与 Web 版 HappyComposer 对齐)
    if (event.logicalKey == LogicalKeyboardKey.tab &&
        HardwareKeyboard.instance.isShiftPressed &&
        widget.onPermissionModeChange != null) {
      final modes =
          _permissionModesByFlavor[widget.agentType] ?? _defaultPermissionModes;
      if (modes.isNotEmpty) {
        final currentMode = widget.permissionMode ?? 'default';
        final currentIndex = modes.indexOf(currentMode);
        final nextIndex = (currentIndex + 1) % modes.length;
        final nextMode = modes[nextIndex];
        widget.onPermissionModeChange!(nextMode);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    // Slash command 作为普通消息发送，由后端 HAPI 处理（与 Web 版本一致）
    setState(() => _isSending = true);
    widget.onSend(text);
    _controller.clear();
    setState(() => _isSending = false);
    _updateVibingMessage();
  }

  Future<void> _handleAbort() async {
    if (_isAborting) return; // 防止重复触发

    final sessionId = widget.sessionId;
    if (sessionId == null) {
      ToastService().warning('无法中止：未指定会话');
      return;
    }

    final apiService = ref.read(hapiApiServiceProvider);
    if (apiService == null) {
      ToastService().warning('无法中止：API 服务不可用');
      return;
    }

    setState(() => _isAborting = true);

    try {
      await apiService.abortSession(sessionId);
      // 不手动设置 _isSending = false，由 isRunning 变化驱动
    } catch (e) {
      ToastService().error('中止失败: $e');
      if (mounted) setState(() => _isAborting = false);
    }
  }

  /// 监听 isRunning 变化，恢复 isAborting 状态 (与 web 对齐)
  void _checkAbortingState() {
    if (_isAborting && !widget.isRunning) {
      setState(() => _isAborting = false);
    }
  }

  /// 显示会话设置面板
  void _showSettingsSheet() {
    if (widget.sessionId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SessionSettingsSheet(sessionId: widget.sessionId!),
    );
  }

  /// 打开终端页面
  void _openTerminal() {
    if (widget.sessionId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => TerminalPage(
              sessionId: widget.sessionId!,
              sessionName: widget.sessionName,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final connectionStateAsync = ref.watch(hapiConnectionStateProvider);
    // 当禁用时（只读模式）强制显示 offline
    final isConnected =
        widget.enabled &&
        connectionStateAsync.maybeWhen(
          data: (state) => state.isConnected,
          orElse: () => false,
        );

    // thinking 状态：发送中或流式传输中 (与 web session.thinking 对齐)
    final isThinking = _isSending || widget.isRunning;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: colorScheme.surface),
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // StatusBar (1:1 还原)
            _buildStatusBar(isConnected, isThinking),

            const SizedBox(height: 4),

            // 核心输入容器 (使用 RawAutocomplete)
            Container(
              decoration: BoxDecoration(
                color:
                    colorScheme.brightness == Brightness.light
                        ? const Color(0xFFF3F4F6) // var(--app-secondary-bg)
                        : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // RawAutocomplete 包裹输入框
                  RawAutocomplete<SlashCommand>(
                    textEditingController: _controller,
                    focusNode: _focusNode,
                    optionsBuilder: (textEditingValue) {
                      final text = textEditingValue.text;
                      // 清除 continue 提示
                      if (text.isNotEmpty && _showContinueHint) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted)
                            setState(() => _showContinueHint = false);
                        });
                      }
                      // 只在 / 开头时显示命令列表
                      if (!text.startsWith('/')) {
                        return const Iterable<SlashCommand>.empty();
                      }
                      final filter = text.substring(1).toLowerCase();
                      return _allCommands.where(
                        (cmd) => cmd.name.toLowerCase().startsWith(filter),
                      );
                    },
                    displayStringForOption: (cmd) => '/${cmd.name} ',
                    onSelected: (cmd) {
                      // 选择后光标移到末尾
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _controller.selection = TextSelection.collapsed(
                          offset: _controller.text.length,
                        );
                      });
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return _buildOptionsView(
                        context,
                        onSelected,
                        options.toList(),
                      );
                    },
                    fieldViewBuilder: (
                      context,
                      controller,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: widget.enabled && !_isSending,
                        maxLines: 5,
                        minLines: 1,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                        decoration: InputDecoration(
                          hintText:
                              _showContinueHint
                                  ? "Type 'continue' to resume..."
                                  : widget.hintText,
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _handleSubmit(),
                      );
                    },
                  ),

                  // ComposerButtons (1:1 还原)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Row(
                      children: [
                        _buildIconButton(
                          icon: Icons.settings_outlined,
                          onTap:
                              widget.enabled && widget.sessionId != null
                                  ? _showSettingsSheet
                                  : null,
                          tooltip: 'Settings',
                        ),
                        const SizedBox(width: 4),
                        _buildIconButton(
                          icon: Icons.terminal_outlined,
                          onTap:
                              widget.enabled && widget.sessionId != null
                                  ? _openTerminal
                                  : null,
                          tooltip: 'Terminal',
                        ),
                        const SizedBox(width: 4),
                        // Abort 按钮：始终显示，运行中可点击 (与 web 对齐)
                        _buildAbortButton(),
                        // Switch to Remote 按钮：仅当 controlledByUser=true 且有回调时显示
                        if (widget.controlledByUser &&
                            widget.onSwitchToRemote != null) ...[
                          const SizedBox(width: 4),
                          _buildSwitchButton(),
                        ],
                        const Spacer(),
                        _buildSendButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Autocomplete 选项视图 (向上弹出，支持滚动跟随)
  Widget _buildOptionsView(
    BuildContext context,
    AutocompleteOnSelected<SlashCommand> onSelected,
    List<SlashCommand> options,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxVisibleItems = 5;
    final listHeight =
        math.min(options.length, maxVisibleItems) * _itemHeight +
        8; // 8 for vertical padding

    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          child: SizedBox(
            height: _isLoadingCommands ? 48 : listHeight,
            width: 400,
            child:
                _isLoadingCommands
                    ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                    : _SlashCommandList(
                      options: options,
                      onSelected: onSelected,
                      scrollController: _scrollController,
                      itemHeight: _itemHeight,
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(bool isConnected, bool isThinking) {
    // 状态优先级判断 (与 Web 版一致)
    String statusText;
    Color dotColor;
    Color textColor;
    bool shouldPulse;

    if (!isConnected) {
      // 优先级 1: 离线 (不脉冲，与 Web 版一致)
      statusText = 'offline';
      dotColor = textColor = const Color(0xFF999999);
      shouldPulse = false;
    } else if (widget.hasPendingPermission) {
      // 优先级 2: 权限请求
      statusText = 'permission required';
      dotColor = textColor = const Color(0xFFFF9500);
      shouldPulse = true;
    } else if (isThinking) {
      // 优先级 3: 思考中
      statusText = _vibingMessage;
      dotColor = textColor = const Color(0xFF007AFF);
      shouldPulse = true;
    } else {
      // 优先级 4: 在线
      statusText = 'online';
      dotColor = textColor = const Color(0xFF34C759);
      shouldPulse = false;
    }

    // 计算上下文百分比
    double? percentRemaining;
    Color? contextColor;
    if (widget.contextSize != null && widget.contextSize! > 0) {
      percentRemaining = (100 -
              (widget.contextSize! / widget.maxContextSize * 100))
          .clamp(0.0, 100.0);
      if (percentRemaining <= 5) {
        contextColor = Colors.red;
      } else if (percentRemaining <= 10) {
        contextColor = Colors.amber;
      }
      // 调试日志
      debugPrint(
        '[ChatInput] Context: ${widget.contextSize}/${widget.maxContextSize}, ${percentRemaining.toStringAsFixed(1)}% remaining',
      );
    } else {
      debugPrint(
        '[ChatInput] No context size data (contextSize=${widget.contextSize})',
      );
    }

    // 获取权限模式显示配置
    final permissionDisplay = _getPermissionModeDisplay(widget.permissionMode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：状态指示 + 上下文百分比
          Row(
            children: [
              // 脉冲指示点
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Opacity(
                    opacity:
                        shouldPulse
                            ? (0.4 + 0.6 * _pulseController.value)
                            : 1.0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6), // gap-1.5 = 6px
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
              // 上下文百分比 (左侧，状态文字后)
              if (percentRemaining != null) ...[
                const SizedBox(width: 12),
                Text(
                  '${percentRemaining.round()}% left',
                  style: TextStyle(
                    fontSize: 10,
                    color: contextColor ?? const Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
          // 右侧：权限模式标签
          if (permissionDisplay != null)
            Text(
              permissionDisplay.label,
              style: TextStyle(
                fontSize: 12,
                color: permissionDisplay.color,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }

  /// 获取权限模式显示配置 (与 Web 版 @hapi/protocol 对齐)
  /// API 值: default, plan, acceptEdits, bypassPermissions
  ({String label, Color color})? _getPermissionModeDisplay(String? mode) {
    if (mode == null || mode == 'default') return null;

    return switch (mode) {
      'plan' => (label: '计划', color: const Color(0xFF007AFF)),
      'acceptEdits' => (label: '自动编辑', color: const Color(0xFFFF9500)),
      'bypassPermissions' => (label: '完全自动', color: const Color(0xFFFF3B30)),
      _ => (label: mode, color: const Color(0xFF999999)),
    };
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onTap,
    Color? color,
    String? tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 20,
        color: color ?? colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(hoverColor: colorScheme.surface),
    );
  }

  /// Abort 按钮 (与 web 对齐: 始终显示，运行中可点击，中止中显示旋转)
  Widget _buildAbortButton() {
    final colorScheme = Theme.of(context).colorScheme;
    final canAbort = widget.isRunning && !_isAborting;
    final isDisabled = !widget.isRunning;

    return IconButton(
      onPressed: canAbort ? _handleAbort : null,
      icon:
          _isAborting
              ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.red.withValues(alpha: 0.8),
                ),
              )
              : Icon(
                Icons.stop_circle_outlined,
                size: 20,
                color:
                    isDisabled
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.8),
              ),
      tooltip: 'Abort (Esc)',
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(hoverColor: colorScheme.surface),
    );
  }

  /// Switch to Remote 按钮 (与 web 对齐)
  Widget _buildSwitchButton() {
    final colorScheme = Theme.of(context).colorScheme;
    final disabled = !widget.enabled || widget.isSwitching;

    return IconButton(
      onPressed: disabled ? null : widget.onSwitchToRemote,
      icon:
          widget.isSwitching
              ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue.withValues(alpha: 0.8),
                ),
              )
              : Icon(
                Icons.phonelink_outlined,
                size: 20,
                color:
                    disabled
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                        : Colors.blue,
              ),
      tooltip: 'Switch to remote',
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(hoverColor: colorScheme.surface),
    );
  }

  Widget _buildSendButton() {
    final hasText = _controller.text.trim().isNotEmpty;
    final canSend = hasText && !(_isSending);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: canSend ? Colors.black : const Color(0xFFC0C0C0),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: canSend ? _handleSubmit : null,
        icon: const Icon(Icons.arrow_upward, size: 18, color: Colors.white),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

/// Slash 命令列表组件（支持滚动跟随高亮）
class _SlashCommandList extends StatefulWidget {
  const _SlashCommandList({
    required this.options,
    required this.onSelected,
    required this.scrollController,
    required this.itemHeight,
  });

  final List<SlashCommand> options;
  final AutocompleteOnSelected<SlashCommand> onSelected;
  final ScrollController scrollController;
  final double itemHeight;

  @override
  State<_SlashCommandList> createState() => _SlashCommandListState();
}

class _SlashCommandListState extends State<_SlashCommandList> {
  int _lastHighlightedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: widget.options.length,
      itemExtent: widget.itemHeight,
      itemBuilder: (context, index) {
        final cmd = widget.options[index];
        final highlightedIndex = AutocompleteHighlightedOption.of(context);
        final isHighlighted = highlightedIndex == index;

        // 当高亮项变化时，滚动到可见区域
        if (highlightedIndex != _lastHighlightedIndex) {
          _lastHighlightedIndex = highlightedIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToHighlighted(highlightedIndex);
          });
        }

        return InkWell(
          onTap: () => widget.onSelected(cmd),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isHighlighted ? colorScheme.primaryContainer : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Text(
                  '/${cmd.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cmd.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (cmd.source == 'user')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'user',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 滚动到高亮项使其可见
  void _scrollToHighlighted(int index) {
    if (!widget.scrollController.hasClients || index < 0) return;

    final scrollPosition = widget.scrollController.position;
    final itemTop = index * widget.itemHeight;
    final itemBottom = itemTop + widget.itemHeight;
    final viewportTop = scrollPosition.pixels;
    final viewportBottom = viewportTop + scrollPosition.viewportDimension;

    // 如果高亮项在视口外，滚动到可见位置
    if (itemTop < viewportTop) {
      widget.scrollController.animateTo(
        itemTop,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    } else if (itemBottom > viewportBottom) {
      widget.scrollController.animateTo(
        itemBottom - scrollPosition.viewportDimension,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }
}
