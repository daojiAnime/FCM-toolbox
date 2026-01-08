import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../common/colors.dart';
import '../models/session.dart';
import '../providers/session_provider.dart';
import '../providers/messages_provider.dart';
import '../services/hapi/hapi_config_service.dart';
import '../services/hapi/hapi_sse_service.dart';
import '../services/interaction_service.dart';
import '../widgets/message_card/message_card.dart';
import 'message_detail_page.dart';
import 'file_browser_page.dart';
import 'diff_page.dart';
import 'terminal_page.dart';

/// 会话详情页面
class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage> {
  final _messageController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final interactionService = ref.read(interactionServiceProvider);
      final success = await interactionService.sendMessage(
        widget.sessionId,
        message,
      );

      if (success && mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('消息已发送'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('发送失败，请检查 hapi 连接'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);
    final session = sessions.where((s) => s.id == widget.sessionId).firstOrNull;
    final hapiConfig = ref.watch(hapiConfigProvider);
    final hapiConnected = ref.watch(hapiIsConnectedProvider);

    // 检查是否可以发送消息（hapi 已启用且已连接）
    final canSendMessage =
        hapiConfig.enabled && hapiConfig.isConfigured && hapiConnected;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('会话详情')),
        body: const Center(child: Text('会话不存在')),
      );
    }

    final messages =
        ref
            .watch(messagesProvider)
            .where((m) => m.sessionId == widget.sessionId)
            .toList();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 折叠 AppBar
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      session.projectName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    background: _buildSessionHeader(context, session),
                  ),
                ),

                // 会话状态卡片
                SliverToBoxAdapter(child: _buildStatusCard(context, session)),

                // 进度信息
                if (session.progress != null && session.progress!.total > 0)
                  SliverToBoxAdapter(
                    child: _buildProgressCard(context, session),
                  ),

                // 快捷操作按钮（仅在 hapi 启用时显示）
                if (canSendMessage)
                  SliverToBoxAdapter(
                    child: _buildActionButtons(context, session),
                  ),

                // 消息列表标题
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          '消息记录',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${messages.length}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
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
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final message = messages[index];
                      return MessageCard(
                        message: message,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      MessageDetailPage(messageId: message.id),
                            ),
                          );
                        },
                      ).animate().fadeIn(
                        duration: const Duration(milliseconds: 300),
                        delay: Duration(milliseconds: index * 50),
                      );
                    }, childCount: messages.length),
                  ),

                // 底部间距（为消息输入框留出空间）
                SliverToBoxAdapter(
                  child: SizedBox(height: canSendMessage ? 80 : 32),
                ),
              ],
            ),
          ),
          // 消息输入栏（仅在 hapi 已连接时显示）
          if (canSendMessage) _buildMessageInputBar(context, session),
        ],
      ),
    );
  }

  /// 构建消息输入栏
  Widget _buildMessageInputBar(BuildContext context, Session session) {
    final theme = Theme.of(context);
    final isRunning = session.status == SessionStatus.running;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              enabled: isRunning && !_isSending,
              decoration: InputDecoration(
                hintText: isRunning ? '输入消息给 Claude...' : '会话未运行',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isRunning && !_isSending ? _sendMessage : null,
            icon:
                _isSending
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor:
                  isRunning
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
            ),
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

  /// 构建快捷操作按钮
  Widget _buildActionButtons(BuildContext context, Session session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 文件浏览
          Expanded(
            child: _ActionButton(
              icon: Icons.folder_outlined,
              label: '文件',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => FileBrowserPage(sessionId: widget.sessionId),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Git Diff
          Expanded(
            child: _ActionButton(
              icon: Icons.difference_outlined,
              label: '变更',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiffPage(sessionId: widget.sessionId),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // 远程终端
          Expanded(
            child: _ActionButton(
              icon: Icons.terminal,
              label: '终端',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TerminalPage(sessionId: widget.sessionId),
                  ),
                );
              },
            ),
          ),
        ],
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
          Icon(icon, size: 24, color: theme.colorScheme.primary),
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

/// 操作按钮组件
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
