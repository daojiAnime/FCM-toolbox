import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../common/colors.dart';
import '../models/message.dart';
import '../models/payload/payload.dart';
import '../models/session.dart';
import '../providers/messages_provider.dart';
import '../providers/session_provider.dart';
import '../providers/machines_provider.dart';
import '../services/interaction_service.dart';
import '../services/firestore_message_service.dart';
import '../services/hapi/hapi_config_service.dart';
import '../services/hapi/hapi_sse_service.dart';
import '../services/connection_manager.dart';
import '../widgets/message_card/message_card.dart';
import '../widgets/session_card.dart';
import 'settings_page.dart';
import 'session_page.dart';
import 'message_detail_page.dart';
import 'hapi_settings_page.dart';
import 'machines_page.dart';
import 'session_management_page.dart';

/// 首页 - 消息列表
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider);
    final activeSessionCount = ref.watch(activeSessionCountProvider);
    final messages = ref.watch(messagesProvider);
    final hapiConfig = ref.watch(hapiConfigProvider);
    final onlineMachineCount = ref.watch(onlineMachineCountProvider);
    final showMachinesTab = hapiConfig.enabled && hapiConfig.isConfigured;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CC Monitor'),
        actions: [
          // 清空消息按钮（仅在消息列表页且有消息时显示）
          if (_selectedIndex == 0 && messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _showClearMessagesDialog(context),
              tooltip: '清空消息',
            ),
          // 未读消息标记
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Badge(
                label: Text('$unreadCount'),
                child: IconButton(
                  icon: const Icon(Icons.mark_email_read_outlined),
                  onPressed: () {
                    ref.read(messagesProvider.notifier).markAllAsRead();
                  },
                  tooltip: '全部标记已读',
                ),
              ),
            ),
          // 会话管理按钮（仅在会话标签页且 hapi 已启用时显示）
          if (_selectedIndex == 1 && showMachinesTab)
            IconButton(
              icon: const Icon(Icons.settings_applications_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SessionManagementPage(),
                  ),
                );
              },
              tooltip: '会话管理',
            ),
          // hapi 连接状态指示器
          _buildHapiStatusIndicator(context, ref),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 降级模式横幅
          _FallbackBanner(),
          // 主内容
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                const _MessagesTab(),
                const _SessionsTab(),
                if (showMachinesTab) const MachinesPage(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.message_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.message),
            ),
            label: '消息',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: activeSessionCount > 0,
              label: Text('$activeSessionCount'),
              child: const Icon(Icons.terminal_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: activeSessionCount > 0,
              label: Text('$activeSessionCount'),
              child: const Icon(Icons.terminal),
            ),
            label: '会话',
          ),
          // 机器列表标签页（仅在 hapi 启用时显示）
          if (showMachinesTab)
            NavigationDestination(
              icon: Badge(
                isLabelVisible: onlineMachineCount > 0,
                label: Text('$onlineMachineCount'),
                child: const Icon(Icons.computer_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: onlineMachineCount > 0,
                label: Text('$onlineMachineCount'),
                child: const Icon(Icons.computer),
              ),
              label: '机器',
            ),
        ],
      ),
    );
  }

  /// 显示清空消息确认对话框
  void _showClearMessagesDialog(BuildContext context) {
    final messageCount = ref.read(messagesProvider).length;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: const Icon(Icons.delete_sweep, color: MessageColors.error),
            title: const Text('清空消息'),
            content: Text('确定要删除全部 $messageCount 条消息吗？\n此操作无法撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(messagesProvider.notifier).clearAll();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('消息已清空')));
                },
                style: FilledButton.styleFrom(
                  backgroundColor: MessageColors.error,
                ),
                child: const Text('清空'),
              ),
            ],
          ),
    );
  }

  /// 构建 hapi 连接状态指示器
  Widget _buildHapiStatusIndicator(BuildContext context, WidgetRef ref) {
    final hapiConfig = ref.watch(hapiConfigProvider);

    // 如果未配置 hapi，不显示指示器
    if (!hapiConfig.isConfigured) {
      return const SizedBox.shrink();
    }

    // 如果已配置但未启用，显示禁用状态
    if (!hapiConfig.enabled) {
      return IconButton(
        icon: const Icon(Icons.cloud_off_outlined),
        onPressed: () => _navigateToHapiSettings(context),
        tooltip: 'hapi 已禁用',
        color: Theme.of(context).colorScheme.outline,
      );
    }

    // 监听连接状态
    final connectionStateAsync = ref.watch(hapiConnectionStateProvider);

    return connectionStateAsync.when(
      data: (state) {
        final (icon, color, tooltip) = _getStatusDisplay(state);
        return IconButton(
          icon: Icon(icon),
          onPressed: () => _navigateToHapiSettings(context),
          tooltip: tooltip,
          color: color,
        );
      },
      loading:
          () => IconButton(
            icon: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            onPressed: () => _navigateToHapiSettings(context),
            tooltip: 'hapi 连接中...',
          ),
      error:
          (error, stack) => IconButton(
            icon: const Icon(Icons.cloud_off),
            onPressed: () => _navigateToHapiSettings(context),
            tooltip: 'hapi 连接错误',
            color: MessageColors.error,
          ),
    );
  }

  /// 获取连接状态显示配置
  (IconData, Color, String) _getStatusDisplay(HapiConnectionState state) {
    return switch (state.status) {
      HapiConnectionStatus.connected => (
        Icons.cloud_done,
        Colors.green,
        'hapi 已连接',
      ),
      HapiConnectionStatus.connecting => (
        Icons.cloud_sync,
        Colors.amber,
        'hapi 连接中...',
      ),
      HapiConnectionStatus.reconnecting => (
        Icons.cloud_sync,
        Colors.orange,
        'hapi 重连中 (${state.reconnectAttempts})',
      ),
      HapiConnectionStatus.disconnected => (
        Icons.cloud_off_outlined,
        Colors.grey,
        'hapi 已断开',
      ),
      HapiConnectionStatus.error => (
        Icons.cloud_off,
        MessageColors.error,
        'hapi 错误: ${state.errorMessage ?? "未知错误"}',
      ),
    };
  }

  /// 导航到 hapi 设置页面
  void _navigateToHapiSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HapiSettingsPage()),
    );
  }
}

/// 消息列表标签页
class _MessagesTab extends ConsumerWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider);

    if (messages.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(firestoreMessageServiceProvider).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return MessageCard(
                message: message,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessageDetailPage(messageId: message.id),
                    ),
                  );
                },
                onApprove:
                    message.payload is InteractivePayload
                        ? () => _handleInteraction(context, ref, message, true)
                        : null,
                onDeny:
                    message.payload is InteractivePayload
                        ? () => _handleInteraction(context, ref, message, false)
                        : null,
              )
              .animate()
              .fadeIn(
                duration: const Duration(milliseconds: 300),
                delay: Duration(milliseconds: index * 30),
              )
              .slideX(
                begin: 0.1,
                end: 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
        },
      ),
    );
  }

  /// 处理交互响应
  Future<void> _handleInteraction(
    BuildContext context,
    WidgetRef ref,
    Message message,
    bool approved,
  ) async {
    final payload = message.payload as InteractivePayload;
    final interactionService = ref.read(interactionServiceProvider);

    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success =
          approved
              ? await interactionService.approve(payload.requestId)
              : await interactionService.deny(payload.requestId);

      // 关闭加载指示器
      if (context.mounted) Navigator.pop(context);

      if (success) {
        // 更新消息状态为已处理（标记为已读）
        ref.read(messagesProvider.notifier).markAsRead(message.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(approved ? '已批准' : '已拒绝'),
              backgroundColor:
                  approved ? MessageColors.complete : MessageColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // 关闭加载指示器
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: MessageColors.error,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无消息',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '等待 Claude Code 推送消息...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 32),
          // 消息类型预览
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTypeChip(context, 'progress', MessageColors.progress),
              _buildTypeChip(context, 'complete', MessageColors.complete),
              _buildTypeChip(context, 'error', MessageColors.error),
              _buildTypeChip(context, 'warning', MessageColors.warning),
              _buildTypeChip(context, 'code', MessageColors.code),
              _buildTypeChip(context, 'markdown', MessageColors.markdown),
              _buildTypeChip(context, 'image', MessageColors.image),
              _buildTypeChip(context, 'interactive', MessageColors.interactive),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, String type, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          MessageColors.emojiFromType(type),
          style: const TextStyle(fontSize: 12),
        ),
      ),
      label: Text(type),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }
}

/// 会话列表标签页
class _SessionsTab extends ConsumerWidget {
  const _SessionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);

    if (sessions.isEmpty) {
      return _buildEmptyState(context);
    }

    // 分离活跃和已完成会话
    final activeSessions =
        sessions.where((s) => s.status != SessionStatus.completed).toList();
    final completedSessions =
        sessions.where((s) => s.status == SessionStatus.completed).toList();

    return RefreshIndicator(
      onRefresh: () async {
        // 使用 Firestore 实时订阅，手动刷新消息即可同步会话状态
        await ref.read(firestoreMessageServiceProvider).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 活跃会话
          if (activeSessions.isNotEmpty) ...[
            _buildSectionHeader(context, '活跃会话', activeSessions.length),
            ...activeSessions.asMap().entries.map((entry) {
              final index = entry.key;
              final session = entry.value;
              return SessionCard(
                session: session,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionPage(sessionId: session.id),
                    ),
                  );
                },
              ).animate().fadeIn(
                duration: const Duration(milliseconds: 300),
                delay: Duration(milliseconds: index * 50),
              );
            }),
          ],
          // 已完成会话
          if (completedSessions.isNotEmpty) ...[
            _buildSectionHeader(context, '已完成', completedSessions.length),
            ...completedSessions.asMap().entries.map((entry) {
              final index = entry.key;
              final session = entry.value;
              return SessionCard(
                session: session,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionPage(sessionId: session.id),
                    ),
                  );
                },
              ).animate().fadeIn(
                duration: const Duration(milliseconds: 300),
                delay: Duration(
                  milliseconds: (activeSessions.length + index) * 50,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.terminal_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无活跃会话',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当 Claude Code 启动时会显示会话',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// 降级模式横幅
class _FallbackBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionManagerProvider);
    final hapiConnectionState = ref.watch(hapiConnectionStateProvider);
    final theme = Theme.of(context);

    // 检查 SSE 是否达到最大重连次数
    final sseMaxReconnectReached = hapiConnectionState.maybeWhen(
      data:
          (state) =>
              state.status == HapiConnectionStatus.error &&
              state.errorMessage?.contains('Max reconnect') == true,
      orElse: () => false,
    );

    // 仅在降级模式下或 SSE 达到最大重连次数时显示
    if (!connectionState.isFallbackMode && !sseMaxReconnectReached) {
      return const SizedBox.shrink();
    }

    // 根据状态选择颜色
    final isError =
        sseMaxReconnectReached ||
        connectionState.lastHapiError?.isNotEmpty == true;
    final bannerColor = isError ? MessageColors.error : MessageColors.warning;

    return Material(
          color: bannerColor.withValues(alpha: 0.1),
          child: SafeArea(
            bottom: false,
            child: InkWell(
              onTap: () {
                // 点击尝试重连 hapi
                if (sseMaxReconnectReached) {
                  // 重置并重连
                  ref.read(hapiSseServiceProvider)?.resetAndReconnect();
                } else {
                  ref
                      .read(connectionManagerProvider.notifier)
                      .forceReconnectHapi();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // 状态图标
                    Icon(
                      sseMaxReconnectReached
                          ? Icons.error_outline
                          : connectionState.hapiReconnecting
                          ? Icons.sync
                          : Icons.cloud_off_outlined,
                      size: 18,
                      color: bannerColor,
                    ),
                    const SizedBox(width: 8),
                    // 状态文字
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            sseMaxReconnectReached
                                ? '连接失败，已达最大重试次数'
                                : connectionState.hapiReconnecting
                                ? '正在重连 hapi...'
                                : 'hapi 已断开，使用 Firebase 模式',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: bannerColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (connectionState.fallbackReason != null &&
                              !connectionState.hapiReconnecting)
                            Text(
                              connectionState.fallbackReason!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: bannerColor.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // 重连按钮
                    if (!connectionState.hapiReconnecting)
                      TextButton.icon(
                        onPressed: () {
                          if (sseMaxReconnectReached) {
                            // 重置并重连
                            ref
                                .read(hapiSseServiceProvider)
                                ?.resetAndReconnect();
                          } else {
                            ref
                                .read(connectionManagerProvider.notifier)
                                .forceReconnectHapi();
                          }
                        },
                        icon: Icon(
                          sseMaxReconnectReached
                              ? Icons.restart_alt
                              : Icons.refresh,
                          size: 16,
                        ),
                        label: Text(sseMaxReconnectReached ? '重试' : '重连'),
                        style: TextButton.styleFrom(
                          foregroundColor: bannerColor,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                    else
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(bannerColor),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 200))
        .slideY(begin: -1, end: 0, duration: const Duration(milliseconds: 200));
  }
}
