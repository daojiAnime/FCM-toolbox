import 'package:flutter/material.dart';
import '../../models/message.dart';

/// 可折叠的消息列表 - 用于聚合多个工具消息
class CollapsibleMessageList extends StatefulWidget {
  const CollapsibleMessageList({
    super.key,
    required this.messages,
    required this.messageBuilder,
  });

  final List<Message> messages;
  final Widget Function(Message) messageBuilder;

  @override
  State<CollapsibleMessageList> createState() => _CollapsibleMessageListState();
}

class _CollapsibleMessageListState extends State<CollapsibleMessageList> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.messages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 汇总条
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  'Task details (${widget.messages.length})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 展开的内容
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  widget.messages.map((m) => widget.messageBuilder(m)).toList(),
            ),
          ),
      ],
    );
  }
}
