import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../common/colors.dart';
import '../models/session.dart';
import '../providers/session_provider.dart';
import '../providers/messages_provider.dart';
import '../widgets/message_card/message_card.dart';

/// 会话详情页面
class SessionPage extends ConsumerWidget {
  const SessionPage({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    final session = sessions.where((s) => s.id == sessionId).firstOrNull;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('会话详情')),
        body: const Center(
          child: Text('会话不存在'),
        ),
      );
    }

    final messages = ref.watch(messagesProvider)
        .where((m) => m.sessionId == sessionId)
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 折叠 AppBar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                session.projectName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: _buildSessionHeader(context, session),
            ),
          ),

          // 会话状态卡片
          SliverToBoxAdapter(
            child: _buildStatusCard(context, session),
          ),

          // 进度信息
          if (session.progress != null && session.progress!.total > 0)
            SliverToBoxAdapter(
              child: _buildProgressCard(context, session),
            ),

          // 消息列表标题
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Text(
                    '消息记录',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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
                      '${messages.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 消息列表
          if (messages.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无消息',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final message = messages[index];
                  return MessageCard(
                    message: message,
                    onTap: () {
                      // TODO: 导航到消息详情
                    },
                  ).animate().fadeIn(
                    duration: const Duration(milliseconds: 300),
                    delay: Duration(milliseconds: index * 50),
                  );
                },
                childCount: messages.length,
              ),
            ),

          // 底部间距
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHeader(BuildContext context, Session session) {
    final statusColor = switch (session.status) {
      SessionStatus.running => MessageColors.progress,
      SessionStatus.waiting => MessageColors.warning,
      SessionStatus.completed => MessageColors.complete,
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.3),
            statusColor.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(session.status),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, Session session) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatItem(
                  context,
                  icon: Icons.build_outlined,
                  label: '工具调用',
                  value: '${session.toolCallCount}',
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  context,
                  icon: Icons.timer_outlined,
                  label: '持续时间',
                  value: _formatDuration(session.duration),
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  context,
                  icon: Icons.schedule,
                  label: '开始时间',
                  value: _formatTime(session.startedAt),
                ),
              ],
            ),
            if (session.currentTask != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.currentTask!,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, Session session) {
    final theme = Theme.of(context);
    final progress = session.progress!;
    final percent = session.progressPercent;

    final statusColor = switch (session.status) {
      SessionStatus.running => MessageColors.progress,
      SessionStatus.waiting => MessageColors.warning,
      SessionStatus.completed => MessageColors.complete,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '任务进度',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${progress.current}/${progress.total}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 8,
                backgroundColor: statusColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            if (progress.currentStep != null) ...[
              const SizedBox(height: 8),
              Text(
                progress.currentStep!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusText(SessionStatus status) {
    return switch (status) {
      SessionStatus.running => '运行中',
      SessionStatus.waiting => '等待响应',
      SessionStatus.completed => '已完成',
    };
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}秒';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}分钟';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return minutes > 0 ? '$hours小时$minutes分钟' : '$hours小时';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
