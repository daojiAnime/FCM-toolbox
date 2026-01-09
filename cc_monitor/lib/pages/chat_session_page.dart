import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../common/design_tokens.dart';
import '../common/logger.dart';
import '../models/message.dart';
import '../models/payload/payload.dart';
import '../models/session.dart';
import '../providers/messages_provider.dart';
import '../providers/session_provider.dart';
import '../providers/streaming_provider.dart';
import '../services/hapi/hapi_api_service.dart';
import '../services/hapi/hapi_config_service.dart';
import '../services/hapi/hapi_event_handler.dart';
import '../services/hapi/hapi_sse_service.dart';
import '../services/interaction_service.dart';
import '../widgets/chat/assistant_bubble.dart';
import '../widgets/chat/chat_input.dart';
import '../widgets/chat/task_card.dart';
import '../widgets/chat/user_bubble.dart';
import '../widgets/chat/collapsible_message_list.dart';
import '../widgets/message_card/interactive_card.dart';
import '../widgets/message_card/progress_card.dart';
import '../widgets/message_card/complete_card.dart';
import '../widgets/message_card/code_card.dart';
import '../widgets/message_card/thinking_card.dart';
import '../services/message_tracer.dart';

/// 对话式会话页面 - 沉浸式聊天体验
class ChatSessionPage extends ConsumerStatefulWidget {
  const ChatSessionPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ChatSessionPage> createState() => _ChatSessionPageState();
}

class _ChatSessionPageState extends ConsumerState<ChatSessionPage> {
  final _scrollController = ScrollController();
  bool _isLoadingHistory = false;
  bool _historyLoaded = false;
  bool _autoScroll = true;
  int _previousMessageCount = 0;

  /// 是否正在切换到远程模式
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessageHistory();
      // 不再自动切换，仅观察模式
    });
  }

  /// 手动切换到远程模式 (与 web 对齐)
  Future<void> _handleSwitchToRemote() async {
    final apiService = ref.read(hapiApiServiceProvider);
    if (apiService == null) return;

    setState(() => _isSwitching = true);

    try {
      final success = await apiService
          .switchSession(widget.sessionId)
          .timeout(const Duration(seconds: 10));

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('会话切换失败'), backgroundColor: Colors.red),
        );
      }
      // 成功后 agentState.controlledByUser 会通过 SSE 更新
    } on TimeoutException {
      Log.w('ChatSess', 'Switch session timeout');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('会话切换超时'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Log.e('ChatSess', 'Switch session failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('切换失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSwitching = false);
    }
  }

  /// 切换权限模式 (Shift+Tab 快捷键回调)
  Future<void> _handlePermissionModeChange(String mode) async {
    final apiService = ref.read(hapiApiServiceProvider);
    if (apiService == null) return;

    try {
      final success = await apiService.setPermissionMode(
        widget.sessionId,
        mode,
      );
      if (success) {
        // 立即更新本地 session 状态，不等待 SSE
        final sessions = ref.read(sessionsProvider);
        final session = sessions.firstWhereOrNull(
          (s) => s.id == widget.sessionId,
        );
        if (session != null) {
          ref
              .read(sessionsProvider.notifier)
              .upsertSession(session.copyWith(permissionMode: mode));
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('权限模式切换失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Log.e('ChatSess', 'Set permission mode failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('权限模式切换失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // 如果距离底部超过 120 像素，则停止自动滚动
    final nearBottom = position.pixels >= position.maxScrollExtent - 120;
    if (_autoScroll != nearBottom) {
      setState(() => _autoScroll = nearBottom);
    }
  }

  /// 滚动到底部
  /// [force] 为 true 时强制滚动（用于按钮点击），并重新启用自动滚动
  void _scrollToBottom({bool animated = true, bool force = false}) {
    if (!_scrollController.hasClients) return;
    // 非强制模式下，只有 autoScroll 开启时才滚动
    if (!force && !_autoScroll) return;

    // 强制滚动时，重新启用自动滚动
    if (force && !_autoScroll) {
      setState(() => _autoScroll = true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          maxExtent,
          duration: DesignTokens.durationNormal,
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(maxExtent);
      }
    });
  }

  /// 加载历史消息
  Future<void> _loadMessageHistory() async {
    if (_historyLoaded || _isLoadingHistory) return;

    final hapiConfig = ref.read(hapiConfigProvider);
    if (!hapiConfig.enabled || !hapiConfig.isConfigured) return;

    setState(() => _isLoadingHistory = true);

    try {
      final eventHandler = ref.read(hapiEventHandlerProvider);
      if (eventHandler != null) {
        // 并行加载 session 详情和消息历史
        await Future.wait([
          eventHandler.loadSessionDetail(widget.sessionId),
          eventHandler.loadSessionMessages(widget.sessionId),
        ]);
        _historyLoaded = true;
      }
    } catch (e) {
      Log.e('ChatSess', 'Failed to load history: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  /// 发送消息
  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    final messageId = const Uuid().v4();

    // 创建本地用户消息
    final localMessage = Message(
      id: messageId,
      sessionId: widget.sessionId,
      payload: UserMessagePayload(content: text, isPending: true),
      projectName: _getSession()?.projectName ?? '',
      createdAt: DateTime.now(),
      role: 'user',
    );

    // 添加到列表
    ref.read(messagesProvider.notifier).addMessage(localMessage);
    _scrollToBottom();

    // 发送
    try {
      final interactionService = ref.read(interactionServiceProvider);
      final success = await interactionService.sendMessage(
        widget.sessionId,
        text,
      );

      if (!success && mounted) {
        // 发送失败，更新消息状态
        _markMessageAsFailed(messageId, '发送失败');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('消息发送失败'), backgroundColor: Colors.red),
        );
      } else if (success && mounted) {
        // 发送成功，清除 pending 状态
        _markMessageAsSent(messageId);
      }
    } catch (e) {
      // 异常，标记为失败
      _markMessageAsFailed(messageId, e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 标记消息发送成功
  void _markMessageAsSent(String messageId) {
    ref.read(messagesProvider.notifier).updateMessage(messageId, (msg) {
      if (msg.payload is UserMessagePayload) {
        return msg.copyWith(
          payload: (msg.payload as UserMessagePayload).copyWith(
            isPending: false,
          ),
        );
      }
      return msg;
    });
  }

  /// 标记消息发送失败
  void _markMessageAsFailed(String messageId, String reason) {
    ref.read(messagesProvider.notifier).updateMessage(messageId, (msg) {
      if (msg.payload is UserMessagePayload) {
        return msg.copyWith(
          payload: (msg.payload as UserMessagePayload).copyWith(
            isPending: false,
            isFailed: true,
            failureReason: reason,
          ),
        );
      }
      return msg;
    });
  }

  Session? _getSession() {
    final sessions = ref.read(sessionsProvider);

    return sessions.firstWhereOrNull((s) => s.id == widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final messages = ref.watch(sessionMessagesProvider(widget.sessionId));
    // watch sessions 以便实时响应数据变化 (permissionMode, contextSize 等)
    final sessions = ref.watch(sessionsProvider);
    final session = sessions.firstWhereOrNull((s) => s.id == widget.sessionId);
    final controlledByUser = session?.agentState?.controlledByUser ?? false;

    // 自动滚动处理
    if (_autoScroll && messages.length > _previousMessageCount) {
      _scrollToBottom();
    }
    _previousMessageCount = messages.length;

    // 消息聚合逻辑（与 hapi web 版一致）：
    // 1. 使用 MessageTracer 追踪 sidechain 消息归属
    // 2. 按 sidechainId 分组构建树
    // 3. 如果没有有效的树结构，回退到连续工具消息聚合

    final messageTree = MessageTracer.processMessages(messages);

    // 检查树是否有效（有嵌套结构）
    final hasValidTree = messageTree.any((node) => node.hasChildren);

    // 如果没有有效的树结构，使用连续消息聚合作为回退
    final List<dynamic> displayItems; // MessageNode or List<MessageNode>
    if (hasValidTree) {
      // 使用树结构
      displayItems = messageTree;
    } else {
      // 回退：将连续的工具消息聚合到一组
      displayItems = _aggregateToolMessages(messageTree);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session?.projectName ?? 'Session',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.sessionId.substring(0, 8),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: colorScheme.outline,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          // 只读模式提示 (当本地终端控制时，远程为只读)
          if (controlledByUser && !_isSwitching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility, size: 14, color: colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    '只读',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          // 连接状态指示（只读模式时强制显示断开）
          _ConnectionStatusIndicator(forceDisconnected: controlledByUser),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: Container(
              color: colorScheme.surface, // 背景色
              child:
                  _isLoadingHistory && messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingM,
                          vertical: DesignTokens.spacingM,
                        ),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          if (item is MessageNode) {
                            return _buildMessageNode(item);
                          } else if (item is List<MessageNode>) {
                            // 聚合的工具消息组
                            return CollapsibleMessageList(
                              messages: item.map((n) => n.message).toList(),
                              messageBuilder: _buildMessageItem,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
            ),
          ),

          // 底部输入栏 - 使用 Consumer 实现实时响应 permissionMode 等变化
          Consumer(
            builder: (context, ref, _) {
              final sessions = ref.watch(sessionsProvider);
              final session = sessions.firstWhereOrNull(
                (s) => s.id == widget.sessionId,
              );
              final controlledByUser =
                  session?.agentState?.controlledByUser ?? false;
              final hasPendingPermission =
                  session?.agentState?.requests.isNotEmpty ?? false;
              return ChatInput(
                onSend: _sendMessage,
                sessionId: widget.sessionId,
                sessionName: session?.projectName,
                // 当本地终端控制时，输入框禁用（需要先切换）
                enabled: !controlledByUser && !_isSwitching,
                isRunning: ref.watch(isAnyStreamingProvider),
                controlledByUser: controlledByUser,
                isSwitching: _isSwitching,
                onSwitchToRemote: _handleSwitchToRemote,
                hintText:
                    _isSwitching
                        ? '正在切换...'
                        : controlledByUser
                        ? '本地终端控制中，点击切换按钮获取控制权'
                        : 'Ask anything',
                // StatusBar 新参数
                hasPendingPermission: hasPendingPermission,
                permissionMode: session?.permissionMode,
                contextSize: session?.contextSize,
                onPermissionModeChange: _handlePermissionModeChange,
              );
            },
          ),
        ],
      ),
      // 滚动到底部按钮
      floatingActionButton:
          !_autoScroll
              ? Padding(
                padding: const EdgeInsets.only(bottom: 120),
                child: FloatingActionButton.small(
                  heroTag: 'chat_scroll_to_bottom_${widget.sessionId}',
                  onPressed: () => _scrollToBottom(force: true),
                  child: const Icon(Icons.arrow_downward),
                ),
              )
              : null,
    );
  }

  /// 判断是否为可折叠的工具消息
  /// 与 MessageNode.collapsibleChildren 逻辑保持一致
  bool _isCollapsibleToolMessage(Message message) {
    final payload = message.payload;
    // InteractivePayload 只有 status != pending 时才可折叠
    if (payload is InteractivePayload) {
      return payload.status != PermissionStatus.pending;
    }
    return payload is ProgressPayload ||
        payload is CodePayload ||
        payload is CompletePayload;
  }

  /// 将连续的工具消息聚合到一组（回退策略）
  List<dynamic> _aggregateToolMessages(List<MessageNode> nodes) {
    final result = <dynamic>[]; // MessageNode or List<MessageNode>
    List<MessageNode>? currentGroup;

    for (final node in nodes) {
      final isCollapsible = _isCollapsibleToolMessage(node.message);

      if (isCollapsible) {
        if (currentGroup == null) {
          currentGroup = [node];
          result.add(currentGroup);
        } else {
          currentGroup.add(node);
        }
      } else {
        currentGroup = null;
        result.add(node);
      }
    }

    return result;
  }

  /// 构建消息节点（支持嵌套子消息，与 hapi web 版保持一致）
  Widget _buildMessageNode(MessageNode node, {int depth = 0}) {
    final message = node.message;

    // 渲染消息本身 - 如果是 Task 类型，传递 children
    final messageWidget =
        message.payload is TaskExecutionPayload
            ? _buildTaskMessage(
              message,
              node.children.map((n) => n.message).toList(),
            )
            : _buildMessageItem(message);

    // 没有子消息，直接返回
    if (!node.hasChildren) {
      return messageWidget;
    }

    // 有子消息：分离 pending（需要展开）和 collapsible（可折叠）
    final pendingChildren = node.pendingChildren;
    final collapsibleChildren = node.collapsibleChildren;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 消息本身
        messageWidget,

        // Pending 子消息（需要用户操作，直接展开显示）
        if (pendingChildren.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  pendingChildren
                      .map(
                        (child) => _buildMessageNode(child, depth: depth + 1),
                      )
                      .toList(),
            ),
          ),

        // 可折叠的子消息
        if (collapsibleChildren.isNotEmpty)
          CollapsibleMessageList(
            messages: collapsibleChildren.map((n) => n.message).toList(),
            messageBuilder: _buildMessageItem,
          ),
      ],
    );
  }

  /// 构建 Task 类型消息（带 children 参数）
  Widget _buildTaskMessage(Message message, List<Message> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: TaskCard(
        message: message,
        children: children.isNotEmpty ? children : null,
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    final payload = message.payload;

    // 隐藏消息 - 不渲染（用于链追踪但不显示）
    if (payload is HiddenPayload) {
      return const SizedBox.shrink();
    }

    // 用户消息
    if (message.role == 'user') {
      if (payload is UserMessagePayload) {
        return SimpleUserBubble(
          content: payload.content,
          isPending: payload.isPending,
        );
      }
      return const SizedBox.shrink();
    }

    // AI 消息 / 系统消息
    // 任务执行卡片 (核心优化点)
    if (payload is TaskExecutionPayload) {
      return Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
        child: TaskCard(message: message),
      );
    }

    // Markdown 消息
    if (payload is MarkdownPayload) {
      return SimpleAssistantBubble(
        content: payload.content,
        isStreaming: payload.streamingStatus == StreamingStatus.streaming,
      );
    }

    // 思维链消息（可折叠显示）
    if (payload is ThinkingPayload) {
      return Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
        child: ThinkingCard(
          content: payload.content,
          timestamp: message.createdAt,
          messageId: payload.streamingId ?? message.id,
          streamingStatus: payload.streamingStatus,
          isRead: message.isRead,
        ),
      );
    }

    // 交互式卡片
    if (payload is InteractivePayload) {
      return Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
        child: InteractiveMessageCard(
          title: payload.title,
          timestamp: message.createdAt,
          message: payload.message,
          requestId: payload.requestId,
          interactiveType: payload.interactiveType,
          metadata: payload.metadata,
          isRead: message.isRead,
          isPending: payload.status == PermissionStatus.pending,
        ),
      );
    }

    // 进度卡片
    if (payload is ProgressPayload) {
      return Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
        child: ProgressMessageCard(
          title: payload.title,
          timestamp: message.createdAt,
          description: payload.description,
          current: payload.current,
          total: payload.total,
          currentStep: payload.currentStep,
          isRead: message.isRead,
        ),
      );
    }

    // 完成卡片
    if (payload is CompletePayload) {
      return Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
        child: CompleteMessageCard(
          title: payload.title,
          timestamp: message.createdAt,
          summary: payload.summary,
          duration: payload.duration,
          toolCount: payload.toolCount,
          isRead: message.isRead,
        ),
      );
    }

    // 代码卡片
    if (payload is CodePayload) {
      return Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
        child: CodeMessageCard(
          title: payload.title,
          timestamp: message.createdAt,
          code: payload.code,
          language: payload.language,
          filename: payload.filename,
          startLine: payload.startLine,
          isRead: message.isRead,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// 连接状态指示器
class _ConnectionStatusIndicator extends ConsumerWidget {
  const _ConnectionStatusIndicator({this.forceDisconnected = false});

  final bool forceDisconnected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(hapiConnectionStateProvider);

    return stateAsync.when(
      data: (state) {
        // 当强制断开（只读模式）或实际未连接时，显示断开状态
        final isConnected = !forceDisconnected && state.isConnected;

        if (isConnected) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Connected',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
        // 断开连接状态
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Disconnected',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
      loading:
          () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      error:
          (error, stack) =>
              const Icon(Icons.error_outline, size: 16, color: Colors.red),
    );
  }
}
