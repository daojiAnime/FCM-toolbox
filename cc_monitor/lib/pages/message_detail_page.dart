import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/colors.dart';
import '../models/message.dart';
import '../models/payload/payload.dart';
import '../models/task.dart';
import '../providers/messages_provider.dart';
import '../services/interaction_service.dart';
import '../widgets/streaming/streaming_code.dart';
import '../widgets/streaming/streaming_markdown.dart';

/// 消息详情页面
class MessageDetailPage extends ConsumerWidget {
  const MessageDetailPage({super.key, required this.messageId});

  final String messageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider);
    final message = messages.where((m) => m.id == messageId).firstOrNull;

    if (message == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('消息详情')),
        body: const Center(child: Text('消息不存在')),
      );
    }

    // 标记为已读
    Future.microtask(() {
      if (!message.isRead) {
        ref.read(messagesProvider.notifier).markAsRead(messageId);
      }
    });

    // 响应式布局检测
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final padding =
        isCompact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.all(16);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(message.payload)),
        titleSpacing: isCompact ? 0 : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _showDeleteConfirmation(context, ref);
            },
            tooltip: '删除消息',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 消息头部（紧凑版）
            _buildHeader(context, message, isCompact: isCompact),
            SizedBox(height: isCompact ? 10 : 16),
            const Divider(height: 1),
            SizedBox(height: isCompact ? 10 : 16),
            // 消息内容
            _buildContent(context, ref, message, isCompact: isCompact),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Message message, {
    bool isCompact = false,
  }) {
    final theme = Theme.of(context);
    final type = _getType(message.payload);
    final color = MessageColors.fromType(type);

    // 紧凑模式：单行布局
    if (isCompact) {
      return Row(
        children: [
          // 小型图标
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                MessageColors.emojiFromType(type),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 标题 + 时间（单行）
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getTitle(message.payload),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDateTime(message.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // 紧凑标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              type.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      );
    }

    // 桌面模式：标准布局
    return Row(
      children: [
        // 类型图标
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              MessageColors.emojiFromType(type),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 标题和时间
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTitle(message.payload),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateTime(message.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        // 类型标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            type.toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Message message, {
    bool isCompact = false,
  }) {
    return switch (message.payload) {
      ProgressPayload payload => _buildProgressContent(context, payload),
      CompletePayload payload => _buildCompleteContent(context, payload),
      ErrorPayload payload => _buildErrorContent(context, payload),
      WarningPayload payload => _buildWarningContent(context, payload),
      CodePayload payload => _buildCodeContent(context, payload, message.id),
      MarkdownPayload payload => _buildMarkdownContent(
        context,
        payload,
        message.id,
      ),
      ThinkingPayload payload => _buildThinkingContent(
        context,
        payload,
        message.id,
      ),
      ImagePayload payload => _buildImageContent(context, payload),
      InteractivePayload payload => _buildInteractiveContent(
        context,
        ref,
        payload,
        isCompact: isCompact,
      ),
      UserMessagePayload payload => _buildUserMessageContent(context, payload),
      TaskExecutionPayload payload => _buildTaskExecutionContent(
        context,
        payload,
      ),
      HiddenPayload _ => const SizedBox.shrink(),
    };
  }

  Widget _buildProgressContent(BuildContext context, ProgressPayload payload) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (payload.description != null) ...[
          Text(payload.description!, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
        ],
        if (payload.total > 0) ...[
          _buildProgressBar(context, payload.current, payload.total),
          const SizedBox(height: 8),
        ],
        if (payload.currentStep != null) ...[
          Row(
            children: [
              const Icon(Icons.subdirectory_arrow_right, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  payload.currentStep!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, int current, int total) {
    final percent = (current / total * 100).round();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('$current / $total'), Text('$percent%')],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: current / total,
            minHeight: 8,
            backgroundColor: MessageColors.progress.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(
              MessageColors.progress,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteContent(BuildContext context, CompletePayload payload) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (payload.summary != null) ...[
          Text(payload.summary!, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            if (payload.duration != null)
              _buildInfoChip(
                context,
                icon: Icons.timer_outlined,
                label: '耗时',
                value: _formatDuration(payload.duration!),
              ),
            if (payload.toolCount != null)
              _buildInfoChip(
                context,
                icon: Icons.build_outlined,
                label: '工具调用',
                value: '${payload.toolCount} 次',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorContent(BuildContext context, ErrorPayload payload) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MessageColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: MessageColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: MessageColors.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  payload.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: MessageColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (payload.suggestion != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '建议',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payload.suggestion!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (payload.stackTrace != null) ...[
          const SizedBox(height: 16),
          _buildExpandableCode(context, '堆栈跟踪', payload.stackTrace!),
        ],
      ],
    );
  }

  Widget _buildWarningContent(BuildContext context, WarningPayload payload) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MessageColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MessageColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: MessageColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(payload.message, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeContent(
    BuildContext context,
    CodePayload payload,
    String messageId,
  ) {
    // 使用新的流式代码组件
    return StreamingCode(
      code: payload.code,
      streamingStatus: payload.streamingStatus,
      messageId:
          payload.streamingStatus == StreamingStatus.streaming
              ? messageId
              : null,
      language: payload.language,
      filename: payload.filename,
      startLine: payload.startLine,
    );
  }

  Widget _buildMarkdownContent(
    BuildContext context,
    MarkdownPayload payload,
    String messageId,
  ) {
    // 使用新的流式 Markdown 组件
    return StreamingMarkdown(
      content: payload.content,
      streamingStatus: payload.streamingStatus,
      messageId:
          payload.streamingStatus == StreamingStatus.streaming
              ? (payload.streamingId ?? messageId)
              : null,
      selectable: true,
    );
  }

  Widget _buildThinkingContent(
    BuildContext context,
    ThinkingPayload payload,
    String messageId,
  ) {
    final theme = Theme.of(context);
    final thinkingColor = Colors.purple.withValues(alpha: 0.7);

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: thinkingColor, width: 3)),
      ),
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, size: 16, color: thinkingColor),
              const SizedBox(width: 6),
              Text(
                'Reasoning',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: thinkingColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamingMarkdown(
            content: payload.content,
            streamingStatus: payload.streamingStatus,
            messageId:
                payload.streamingStatus == StreamingStatus.streaming
                    ? (payload.streamingId ?? messageId)
                    : null,
            selectable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, ImagePayload payload) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            payload.url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Icon(Icons.broken_image, size: 48)),
              );
            },
          ),
        ),
        if (payload.caption != null) ...[
          const SizedBox(height: 8),
          Text(
            payload.caption!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInteractiveContent(
    BuildContext context,
    WidgetRef ref,
    InteractivePayload payload, {
    bool isCompact = false,
  }) {
    final theme = Theme.of(context);
    final metadata = payload.metadata;

    // 提取 metadata 中的工具和问题信息
    final toolName = metadata?['toolName'] as String?;
    final tools = metadata?['tools'] as List<dynamic>?;
    final questions = metadata?['questions'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(payload.message, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),

        // 工具名称显示
        if (toolName != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    toolName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 工具列表显示（如果有多个）
        if (tools != null && tools.isNotEmpty) ...[
          Text(
            '请求的工具',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                tools.map((tool) {
                  return Chip(
                    label: Text(tool.toString()),
                    avatar: const Icon(Icons.build, size: 16),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // 问题显示（如果有）
        if (questions != null && questions.isNotEmpty) ...[
          Text(
            '安全问题',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...questions.map((q) {
            final question = q as Map<String, dynamic>?;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(question?['text']?.toString() ?? q.toString()),
            );
          }),
          const SizedBox(height: 8),
        ],

        // 操作按钮
        const Divider(height: 32),
        _buildActionButtons(context, ref, payload),
      ],
    );
  }

  /// 构建操作按钮组
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    InteractivePayload payload,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 主要操作按钮
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    () => _handleInteraction(
                      context,
                      ref,
                      payload.requestId,
                      decision: 'denied',
                    ),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('拒绝'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MessageColors.error,
                  side: const BorderSide(color: MessageColors.error),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    () => _handleInteraction(
                      context,
                      ref,
                      payload.requestId,
                      decision: 'approved',
                    ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('允许'),
                style: FilledButton.styleFrom(
                  backgroundColor: MessageColors.complete,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 高级操作
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed:
                    () => _handleInteraction(
                      context,
                      ref,
                      payload.requestId,
                      decision: 'abort',
                    ),
                icon: const Icon(Icons.stop, size: 18),
                label: const Text('中止任务'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton.icon(
                onPressed:
                    () => _handleInteraction(
                      context,
                      ref,
                      payload.requestId,
                      decision: 'approved_for_session',
                    ),
                icon: const Icon(Icons.lock_open, size: 18),
                label: const Text('本次会话允许'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),

        // 高级选项入口
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showAdvancedOptions(context, ref, payload),
          icon: const Icon(Icons.tune, size: 18),
          label: const Text('高级选项'),
        ),
      ],
    );
  }

  /// 显示高级选项对话框
  void _showAdvancedOptions(
    BuildContext context,
    WidgetRef ref,
    InteractivePayload payload,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => _AdvancedPermissionSheet(
            payload: payload,
            onSubmit: (decision, mode, allowTools, answers) {
              Navigator.pop(context);
              _handleInteraction(
                context,
                ref,
                payload.requestId,
                decision: decision,
                mode: mode,
                allowTools: allowTools,
                answers: answers,
              );
            },
          ),
    );
  }

  /// 处理交互响应
  Future<void> _handleInteraction(
    BuildContext context,
    WidgetRef ref,
    String requestId, {
    required String decision,
    String? mode,
    List<String>? allowTools,
    Map<String, List<String>>? answers,
  }) async {
    final interactionService = ref.read(interactionServiceProvider);

    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final isApprove =
          decision == 'approved' || decision == 'approved_for_session';
      final response = <String, dynamic>{
        'decision': decision,
        if (mode != null) 'mode': mode,
        if (allowTools != null) 'allowTools': allowTools,
        if (answers != null) 'answers': answers,
      };

      final success =
          isApprove
              ? await interactionService.approve(requestId, response: response)
              : await interactionService.deny(requestId, response: response);

      if (context.mounted) Navigator.pop(context); // 关闭加载指示器

      if (success && context.mounted) {
        // 更新消息的权限状态
        final newStatus = switch (decision) {
          'approved' || 'approved_for_session' => PermissionStatus.approved,
          'denied' => PermissionStatus.denied,
          'abort' => PermissionStatus.canceled,
          _ => PermissionStatus.approved,
        };
        ref.read(messagesProvider.notifier).updateMessage(messageId, (msg) {
          final payload = msg.payload;
          if (payload is InteractivePayload) {
            return msg.copyWith(payload: payload.copyWith(status: newStatus));
          }
          return msg;
        });

        final snackMessage = switch (decision) {
          'approved' => '已批准',
          'approved_for_session' => '已批准（本次会话）',
          'denied' => '已拒绝',
          'abort' => '已中止',
          _ => '操作完成',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackMessage),
            backgroundColor:
                isApprove ? MessageColors.complete : MessageColors.error,
          ),
        );
        Navigator.pop(context); // 返回上一页
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // 关闭加载指示器

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

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableCode(BuildContext context, String title, String code) {
    return ExpansionTile(
      title: Text(title),
      tilePadding: EdgeInsets.zero,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            code,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// 构建用户消息内容
  Widget _buildUserMessageContent(
    BuildContext context,
    UserMessagePayload payload,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态指示
          if (payload.isPending || payload.isFailed) ...[
            Row(
              children: [
                if (payload.isPending) ...[
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '发送中...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ] else if (payload.isFailed) ...[
                  const Icon(
                    Icons.error_outline,
                    size: 14,
                    color: MessageColors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    payload.failureReason ?? '发送失败',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: MessageColors.error,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          // 消息内容
          SelectableText(payload.content, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  /// 构建任务执行内容
  Widget _buildTaskExecutionContent(
    BuildContext context,
    TaskExecutionPayload payload,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 总体状态
        Row(
          children: [
            _buildTaskStatusIcon(payload.overallStatus),
            const SizedBox(width: 8),
            Text(
              _getStatusLabel(payload.overallStatus),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (payload.durationMs != null) ...[
              const Spacer(),
              Text(
                _formatDuration(payload.durationMs!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),

        // 摘要
        if (payload.summary != null) ...[
          const SizedBox(height: 12),
          Text(payload.summary!, style: theme.textTheme.bodyMedium),
        ],

        // 提示信息
        if (payload.prompt != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              payload.prompt!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],

        // 任务列表
        if (payload.tasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            '任务详情 (${payload.tasks.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...payload.tasks.map((task) => _buildTaskItem(context, task)),
        ],
      ],
    );
  }

  /// 构建任务状态图标
  Widget _buildTaskStatusIcon(TaskStatus status) {
    final (icon, color) = switch (status) {
      TaskStatus.pending => (Icons.hourglass_empty, Colors.grey),
      TaskStatus.running => (Icons.sync, Colors.blue),
      TaskStatus.completed => (Icons.check_circle, MessageColors.complete),
      TaskStatus.partial => (Icons.warning_amber, MessageColors.warning),
      TaskStatus.error => (Icons.error, MessageColors.error),
    };
    return Icon(icon, size: 20, color: color);
  }

  /// 获取状态标签
  String _getStatusLabel(TaskStatus status) {
    return switch (status) {
      TaskStatus.pending => '等待中',
      TaskStatus.running => '运行中',
      TaskStatus.completed => '已完成',
      TaskStatus.partial => '部分完成',
      TaskStatus.error => '错误',
    };
  }

  /// 构建单个任务项
  Widget _buildTaskItem(BuildContext context, TaskItem task) {
    final theme = Theme.of(context);
    final (statusIcon, statusColor) = switch (task.status) {
      TaskItemStatus.pending => ('○', Colors.grey),
      TaskItemStatus.running => ('●', Colors.blue),
      TaskItemStatus.completed => ('✓', MessageColors.complete),
      TaskItemStatus.error => ('✕', MessageColors.error),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border:
            task.hasError
                ? Border.all(color: MessageColors.error.withValues(alpha: 0.5))
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                statusIcon,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (task.durationMs != null)
                Text(
                  _formatDuration(task.durationMs!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
          if (task.filePath != null) ...[
            const SizedBox(height: 4),
            Text(
              task.filePath!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.outline,
              ),
            ),
          ],
          if (task.description != null) ...[
            const SizedBox(height: 4),
            Text(task.description!, style: theme.textTheme.bodySmall),
          ],
          if (task.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MessageColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MessageColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTitle(Payload payload) {
    return switch (payload) {
      ProgressPayload p => p.title,
      CompletePayload p => p.title,
      ErrorPayload p => p.title,
      WarningPayload p => p.title,
      CodePayload p => p.title,
      MarkdownPayload p => p.title,
      ThinkingPayload _ => 'Reasoning',
      ImagePayload p => p.title,
      InteractivePayload p => p.title,
      UserMessagePayload _ => '用户消息',
      TaskExecutionPayload p => p.title,
      HiddenPayload p => '[Hidden: ${p.reason}]',
    };
  }

  String _getType(Payload payload) {
    return switch (payload) {
      ProgressPayload _ => 'progress',
      CompletePayload _ => 'complete',
      ErrorPayload _ => 'error',
      WarningPayload _ => 'warning',
      CodePayload _ => 'code',
      MarkdownPayload _ => 'markdown',
      ThinkingPayload _ => 'thinking',
      ImagePayload _ => 'image',
      InteractivePayload _ => 'interactive',
      UserMessagePayload _ => 'userMessage',
      TaskExecutionPayload _ => 'taskExecution',
      HiddenPayload _ => 'hidden',
    };
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int ms) {
    final seconds = ms ~/ 1000;
    if (seconds < 60) return '$seconds秒';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return remainingSeconds > 0 ? '$minutes分$remainingSeconds秒' : '$minutes分钟';
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除消息'),
            content: const Text('确定要删除这条消息吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(messagesProvider.notifier).removeMessage(messageId);
                  Navigator.pop(context); // 关闭对话框
                  Navigator.pop(context); // 返回上一页
                },
                style: FilledButton.styleFrom(
                  backgroundColor: MessageColors.error,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
    );
  }
}

/// 高级权限设置 Sheet
class _AdvancedPermissionSheet extends StatefulWidget {
  const _AdvancedPermissionSheet({
    required this.payload,
    required this.onSubmit,
  });

  final InteractivePayload payload;
  final void Function(
    String decision,
    String? mode,
    List<String>? allowTools,
    Map<String, List<String>>? answers,
  )
  onSubmit;

  @override
  State<_AdvancedPermissionSheet> createState() =>
      _AdvancedPermissionSheetState();
}

class _AdvancedPermissionSheetState extends State<_AdvancedPermissionSheet> {
  String _decision = 'approved';
  String? _mode;
  final Set<String> _selectedTools = {};
  final Map<String, TextEditingController> _answerControllers = {};

  /// 可用的权限模式 (与 Web 版 @hapi/protocol 对齐)
  static const _permissionModes = [
    ('default', '默认', '使用默认权限策略'),
    ('plan', '计划模式', '仅允许读取和规划'),
    ('acceptEdits', '自动编辑', '自动批准文件编辑'),
    ('bypassPermissions', '完全自动', '自动批准所有操作'),
  ];

  // 决策选项
  static const _decisions = [
    ('approved', '批准', Icons.check_circle),
    ('approved_for_session', '本次会话批准', Icons.lock_open),
    ('denied', '拒绝', Icons.cancel),
    ('abort', '中止任务', Icons.stop_circle),
  ];

  @override
  void initState() {
    super.initState();
    // 初始化工具选择
    final tools = widget.payload.metadata?['tools'] as List<dynamic>?;
    if (tools != null) {
      _selectedTools.addAll(tools.map((e) => e.toString()));
    }
    // 初始化问题答案控制器
    final questions = widget.payload.metadata?['questions'] as List<dynamic>?;
    if (questions != null) {
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        final id = (q is Map ? q['id']?.toString() : null) ?? 'q$i';
        _answerControllers[id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tools = widget.payload.metadata?['tools'] as List<dynamic>?;
    final questions = widget.payload.metadata?['questions'] as List<dynamic>?;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 拖拽手柄
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '高级权限设置',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // 内容
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 决策选择
                    Text(
                      '决策',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _decisions.map((d) {
                            final isSelected = _decision == d.$1;
                            return ChoiceChip(
                              selected: isSelected,
                              label: Text(d.$2),
                              avatar: Icon(d.$3, size: 18),
                              onSelected:
                                  (_) => setState(() => _decision = d.$1),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 权限模式
                    Text(
                      '权限模式',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _mode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '选择权限模式（可选）',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('不指定')),
                        ..._permissionModes.map((m) {
                          return DropdownMenuItem(
                            value: m.$1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(m.$2),
                                Text(
                                  m.$3,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => _mode = v),
                    ),

                    // 工具选择（如果有）
                    if (tools != null && tools.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        '允许的工具',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            tools.map((tool) {
                              final toolName = tool.toString();
                              final isSelected = _selectedTools.contains(
                                toolName,
                              );
                              return FilterChip(
                                selected: isSelected,
                                label: Text(toolName),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedTools.add(toolName);
                                    } else {
                                      _selectedTools.remove(toolName);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedTools.addAll(
                                  tools.map((e) => e.toString()),
                                );
                              });
                            },
                            child: const Text('全选'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _selectedTools.clear());
                            },
                            child: const Text('清空'),
                          ),
                        ],
                      ),
                    ],

                    // 问题答案（如果有）
                    if (questions != null && questions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        '安全问题',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...questions.asMap().entries.map((entry) {
                        final i = entry.key;
                        final q = entry.value;
                        final question = q is Map ? q : {'text': q.toString()};
                        final id = question['id']?.toString() ?? 'q$i';
                        final text = question['text']?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(text),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _answerControllers[id],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: '输入答案',
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              // 底部按钮
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.send),
                    label: const Text('提交'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit() {
    // 收集答案
    Map<String, List<String>>? answers;
    if (_answerControllers.isNotEmpty) {
      answers = {};
      for (final entry in _answerControllers.entries) {
        final text = entry.value.text.trim();
        if (text.isNotEmpty) {
          answers[entry.key] = [text];
        }
      }
      if (answers.isEmpty) answers = null;
    }

    widget.onSubmit(
      _decision,
      _mode,
      _selectedTools.isNotEmpty ? _selectedTools.toList() : null,
      answers,
    );
  }
}
