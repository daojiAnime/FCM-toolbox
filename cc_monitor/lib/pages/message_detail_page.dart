import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import '../common/colors.dart';
import '../models/message.dart';
import '../models/payload/payload.dart';
import '../providers/messages_provider.dart';

/// 消息详情页面
class MessageDetailPage extends ConsumerWidget {
  const MessageDetailPage({
    super.key,
    required this.messageId,
  });

  final String messageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider);
    final message = messages.where((m) => m.id == messageId).firstOrNull;

    if (message == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('消息详情')),
        body: const Center(
          child: Text('消息不存在'),
        ),
      );
    }

    // 标记为已读
    Future.microtask(() {
      if (!message.isRead) {
        ref.read(messagesProvider.notifier).markAsRead(messageId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(message.payload)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _showDeleteConfirmation(context, ref);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 消息头部
            _buildHeader(context, message),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // 消息内容
            _buildContent(context, message),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Message message) {
    final theme = Theme.of(context);
    final type = _getType(message.payload);
    final color = MessageColors.fromType(type);

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

  Widget _buildContent(BuildContext context, Message message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return switch (message.payload) {
      ProgressPayload payload => _buildProgressContent(context, payload),
      CompletePayload payload => _buildCompleteContent(context, payload),
      ErrorPayload payload => _buildErrorContent(context, payload),
      WarningPayload payload => _buildWarningContent(context, payload),
      CodePayload payload => _buildCodeContent(context, payload, isDark),
      MarkdownPayload payload => _buildMarkdownContent(context, payload),
      ImagePayload payload => _buildImageContent(context, payload),
      InteractivePayload payload => _buildInteractiveContent(context, payload),
    };
  }

  Widget _buildProgressContent(BuildContext context, ProgressPayload payload) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (payload.description != null) ...[
          Text(
            payload.description!,
            style: theme.textTheme.bodyLarge,
          ),
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
          children: [
            Text('$current / $total'),
            Text('$percent%'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: current / total,
            minHeight: 8,
            backgroundColor: MessageColors.progress.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(MessageColors.progress),
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
          Text(
            payload.summary!,
            style: theme.textTheme.bodyLarge,
          ),
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
            border: Border.all(color: MessageColors.error.withValues(alpha: 0.3)),
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
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                ),
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
            child: Text(
              payload.message,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeContent(BuildContext context, CodePayload payload, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (payload.filename != null) ...[
          Row(
            children: [
              const Icon(Icons.insert_drive_file_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  payload.filename!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: payload.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('代码已复制')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: HighlightView(
            payload.code,
            language: payload.language ?? 'plaintext',
            theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
            padding: const EdgeInsets.all(16),
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarkdownContent(BuildContext context, MarkdownPayload payload) {
    return MarkdownBody(
      data: payload.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
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
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48),
                ),
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

  Widget _buildInteractiveContent(BuildContext context, InteractivePayload payload) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          payload.message,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        if (payload.metadata != null && payload.metadata!.containsKey('toolName')) ...[
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
                    payload.metadata!['toolName'] as String,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                // TODO: 发送拒绝指令
              },
              icon: const Icon(Icons.close, size: 18),
              label: const Text('拒绝'),
              style: OutlinedButton.styleFrom(
                foregroundColor: MessageColors.error,
                side: const BorderSide(color: MessageColors.error),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () {
                // TODO: 发送允许指令
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('允许'),
              style: FilledButton.styleFrom(
                backgroundColor: MessageColors.complete,
              ),
            ),
          ],
        ),
      ],
    );
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
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
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
      ImagePayload p => p.title,
      InteractivePayload p => p.title,
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
      ImagePayload _ => 'image',
      InteractivePayload _ => 'interactive',
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
      builder: (context) => AlertDialog(
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
