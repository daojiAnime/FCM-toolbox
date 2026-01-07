import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../common/colors.dart';
import '../models/message.dart';
import '../models/payload/payload.dart';
import '../models/session.dart';
import '../providers/messages_provider.dart';
import '../providers/session_provider.dart';
import '../services/interaction_service.dart';
import '../widgets/message_card/message_card.dart';
import '../widgets/session_card.dart';
import 'settings_page.dart';
import 'session_page.dart';
import 'message_detail_page.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('CC Monitor'),
        actions: [
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
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _MessagesTab(),
          _SessionsTab(),
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
        ],
      ),
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
        // TODO: 从服务器刷新消息
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
            onApprove: message.payload is InteractivePayload
                ? () => _handleInteraction(context, ref, message, true)
                : null,
            onDeny: message.payload is InteractivePayload
                ? () => _handleInteraction(context, ref, message, false)
                : null,
          ).animate().fadeIn(
            duration: const Duration(milliseconds: 300),
            delay: Duration(milliseconds: index * 30),
          ).slideX(
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
      final success = approved
          ? await interactionService.approve(payload.requestId)
          : await interactionService.deny(payload.requestId);

      // 关闭加载指示器
      if (context.mounted) Navigator.pop(context);

      if (success) {
        // 更新消息状态为已处理
        // TODO: 更新消息的 pending 状态
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(approved ? '已批准' : '已拒绝'),
              backgroundColor: approved ? MessageColors.complete : MessageColors.error,
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
    final activeSessions = sessions
        .where((s) => s.status != SessionStatus.completed)
        .toList();
    final completedSessions = sessions
        .where((s) => s.status == SessionStatus.completed)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: 从服务器刷新会话
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
                delay: Duration(milliseconds: (activeSessions.length + index) * 50),
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
