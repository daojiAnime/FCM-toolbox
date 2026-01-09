import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../common/colors.dart';
import '../common/design_tokens.dart';
import '../models/session.dart';
import '../providers/messages_provider.dart';
import '../providers/session_provider.dart';
import '../services/hapi/hapi_sse_service.dart';
import '../widgets/message_card/message_card.dart';
import 'chat_session_page.dart';
import 'machines_page.dart';
import 'session_management_page.dart';
import 'hapi_settings_page.dart';
import 'log_viewer_page.dart';

/// 首页 - 全新的卡片流式布局
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  // 底部导航项
  static const _navItems = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: '概览',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: '会话',
    ),
    NavigationDestination(
      icon: Icon(Icons.computer_outlined),
      selectedIcon: Icon(Icons.computer),
      label: '机器',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // 获取未读消息数
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _HomeOverviewTab(), // 概览页 (消息流 + 活跃会话)
          SessionManagementPage(), // 会话管理
          MachinesPage(), // 机器管理
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          // 概览 tab 显示未读红点
          if (unreadCount > 0)
            NavigationDestination(
              icon: Badge(
                label: Text('$unreadCount'),
                child: const Icon(Icons.dashboard_outlined),
              ),
              selectedIcon: Badge(
                label: Text('$unreadCount'),
                child: const Icon(Icons.dashboard),
              ),
              label: '概览',
            )
          else
            _navItems[0],
          _navItems[1],
          _navItems[2],
        ],
      ),
    );
  }
}

/// 概览标签页
class _HomeOverviewTab extends ConsumerWidget {
  const _HomeOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部应用栏
          SliverAppBar.large(
            title: const Text('CC Monitor'),
            centerTitle: false,
            actions: [
              // hapi 状态指示器
              const _HapiStatusButton(),
              // 日志查看器按钮
              IconButton(
                icon: const Icon(Icons.article_outlined),
                tooltip: '日志查看器',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogViewerPage()),
                  );
                },
              ),
              // 设置按钮
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HapiSettingsPage()),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // 活跃会话轮播区
          SliverToBoxAdapter(child: _ActiveSessionsSection()),

          // 消息流标题
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spacingL,
                DesignTokens.spacingL,
                DesignTokens.spacingL,
                DesignTokens.spacingS,
              ),
              child: Row(
                children: [
                  Text(
                    '最近消息',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  // 清空按钮
                  TextButton.icon(
                    onPressed: () {
                      ref.read(messagesProvider.notifier).clearAll();
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('清空'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 消息列表
          const _MessageFeedList(),

          // 底部留白，防止被导航栏遮挡
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      // 快速回到顶部按钮
      floatingActionButton: _ScrollToTopButton(),
    );
  }
}

/// 活跃会话区域
class _ActiveSessionsSection extends ConsumerWidget {
  const _ActiveSessionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);

    // 筛选活跃会话 (最近24小时有活动，且状态不为 completed)
    // 这里简单取前5个作为"活跃"示例
    final activeSessions = sessions.take(5).toList();

    if (activeSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingL,
            vertical: DesignTokens.spacingS,
          ),
          child: Text(
            '活跃会话',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          height: 160, // 卡片高度
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingL,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: activeSessions.length,
            separatorBuilder:
                (context, index) =>
                    const SizedBox(width: DesignTokens.spacingM),
            itemBuilder: (context, index) {
              final s = activeSessions[index];
              return _ActiveSessionCard(session: s);
            },
          ),
        ),
      ],
    );
  }
}

/// 活跃会话卡片
class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatSessionPage(sessionId: session.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部：项目名 + 状态
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusS,
                        ),
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        size: 18,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        session.projectName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusBadge(status: session.status),
                  ],
                ),

                const Spacer(),

                // 描述信息
                if (session.currentTask != null)
                  Text(
                    session.currentTask!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    '无描述',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                const SizedBox(height: DesignTokens.spacingM),

                // 底部信息：最后更新时间
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(session.lastUpdatedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${time.month}/${time.day}';
  }
}

/// 状态徽章
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SessionStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (label, color, bgColor) = switch (status) {
      SessionStatus.running => (
        '进行中',
        Colors.green.shade700,
        Colors.green.shade50,
      ),
      SessionStatus.waiting => (
        '等待中',
        Colors.orange.shade700,
        Colors.orange.shade50,
      ),
      SessionStatus.completed => (
        '已完成',
        colorScheme.outline,
        colorScheme.surfaceContainerHighest,
      ),
      SessionStatus.error => ('错误', Colors.red.shade700, Colors.red.shade50),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// 消息流列表
class _MessageFeedList extends ConsumerWidget {
  const _MessageFeedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider);

    if (messages.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                '暂无消息',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final message = messages[index];
        return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingL,
                vertical: DesignTokens.spacingXS,
              ),
              child: MessageCard(
                key: ValueKey(message.id),
                message: message,
                // 首页消息卡片可以简化一些，不需要太过详细的交互
              ),
            )
            .animate()
            .fadeIn(duration: DesignTokens.durationFast)
            .slideY(begin: 0.1, end: 0);
      }, childCount: messages.length),
    );
  }
}

/// HAPI 状态指示器按钮
class _HapiStatusButton extends ConsumerWidget {
  const _HapiStatusButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStateAsync = ref.watch(hapiConnectionStateProvider);

    return connectionStateAsync.when(
      data: (state) {
        final (icon, color, tooltip) = _getStatusDisplay(state);
        return IconButton(
          icon: Icon(icon, size: 20),
          onPressed: () => _navigateToHapiSettings(context),
          tooltip: tooltip,
          color: color,
        );
      },
      loading:
          () => const SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      error:
          (error, stack) => IconButton(
            icon: const Icon(Icons.cloud_off, size: 20),
            onPressed: () => _navigateToHapiSettings(context),
            color: MessageColors.error,
          ),
    );
  }

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

  void _navigateToHapiSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HapiSettingsPage()),
    );
  }
}

/// 回到顶部按钮
class _ScrollToTopButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 简单实现：使用 PrimaryScrollController
    // 实际项目中可能需要监听滚动位置来控制显示/隐藏
    return FloatingActionButton.small(
      heroTag: 'home_scroll_to_top',
      onPressed: () {
        final controller = PrimaryScrollController.of(context);
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      },
      child: const Icon(Icons.arrow_upward),
    );
  }
}
