import 'package:flutter/material.dart';
import '../../common/colors.dart';
import '../../models/payload/payload.dart';
import '../base/responsive_builder.dart';
import '../streaming/streaming_markdown.dart';
import 'base_card.dart';

/// Markdown 消息卡片 - 继承 BaseMessageCard，使用 Template Method 模式
class MarkdownMessageCard extends BaseMessageCard {
  const MarkdownMessageCard({
    super.key,
    required this.title,
    required this.content,
    required super.timestamp,
    this.messageId,
    this.streamingStatus = StreamingStatus.complete,
    super.isRead,
  });

  final String title;
  final String content;
  final String? messageId;
  final StreamingStatus streamingStatus;

  // ==================== 实现抽象方法 ====================

  @override
  IconData getHeaderIcon() => Icons.article_outlined;

  @override
  String getHeaderTitle() => title;

  @override
  Color getHeaderColor(BuildContext context) =>
      MessageColors.fromType('markdown');

  // ==================== 实现钩子方法 ====================

  @override
  Widget buildContent(BuildContext context, ResponsiveValues r) {
    return StreamingMarkdown(
      content: content,
      streamingStatus: streamingStatus,
      messageId: messageId,
    );
  }
}
