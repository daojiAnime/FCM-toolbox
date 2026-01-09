import 'package:flutter/material.dart';
import '../../common/constants.dart';
import '../../common/colors.dart';
import '../../models/payload/payload.dart';
import 'base_card.dart';

/// 交互消息卡片
class InteractiveMessageCard extends StatelessWidget {
  const InteractiveMessageCard({
    super.key,
    required this.title,
    required this.timestamp,
    required this.message,
    required this.requestId,
    required this.interactiveType,
    this.summary,
    this.metadata,
    this.onApprove,
    this.onDeny,
    this.onTap,
    this.isRead = false,
    this.isPending = true,
  });

  final String title;
  final DateTime timestamp;
  final String message;
  final String requestId;
  final InteractiveType interactiveType;
  final String? summary;
  final Map<String, dynamic>? metadata;
  final VoidCallback? onApprove;
  final VoidCallback? onDeny;
  final VoidCallback? onTap;
  final bool isRead;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LegacyMessageCard(
      type: AppConstants.messageInteractive,
      title: title,
      timestamp: timestamp,
      subtitle: message,
      summary: summary,
      onTap: onTap,
      isRead: isRead,
      child:
          isPending
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 工具信息 (如果有)
                  if (metadata != null &&
                      metadata!.containsKey('toolName')) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.terminal,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              metadata!['toolName'] as String,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // 操作按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onDeny,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('拒绝'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MessageColors.error,
                          side: const BorderSide(color: MessageColors.error),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('允许'),
                        style: FilledButton.styleFrom(
                          backgroundColor: MessageColors.complete,
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : _buildStatusBadge(context),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);
    // 已处理状态
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: MessageColors.complete.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: MessageColors.complete,
          ),
          const SizedBox(width: 4),
          Text(
            '已处理',
            style: theme.textTheme.bodySmall?.copyWith(
              color: MessageColors.complete,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
