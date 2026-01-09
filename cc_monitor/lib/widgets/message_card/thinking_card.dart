import 'package:flutter/material.dart';
import '../../models/payload/payload.dart';
import '../base/responsive_builder.dart';
import '../streaming/streaming_markdown.dart';
import 'stateful_base_card.dart';

/// 思维链卡片 - 可折叠显示 AI 的推理过程
/// 次要消息，使用低调的灰色斜体风格
/// 继承 StatefulBaseMessageCard，使用 Template Method 模式
class ThinkingCard extends StatefulBaseMessageCard {
  const ThinkingCard({
    super.key,
    required this.content,
    required super.timestamp,
    this.messageId,
    this.streamingStatus = StreamingStatus.complete,
    super.isRead,
    this.initiallyExpanded = false,
  });

  final String content;
  final String? messageId;
  final StreamingStatus streamingStatus;
  final bool initiallyExpanded;

  @override
  State<ThinkingCard> createState() => _ThinkingCardState();
}

class _ThinkingCardState extends StatefulBaseMessageCardState<ThinkingCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;

  static final Animatable<double> _easeInTween = CurveTween(
    curve: Curves.easeIn,
  );
  static final Animatable<double> _halfTween = Tween<double>(
    begin: 0.0,
    end: 0.5,
  );

  @override
  void initState() {
    super.initState();
    // 流式时自动展开
    _isExpanded =
        widget.initiallyExpanded ||
        widget.streamingStatus == StreamingStatus.streaming;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = _controller.drive(_halfTween.chain(_easeInTween));
    _heightFactor = _controller.drive(_easeInTween);

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ThinkingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 流式开始时自动展开
    if (widget.streamingStatus == StreamingStatus.streaming &&
        oldWidget.streamingStatus != StreamingStatus.streaming) {
      _setExpanded(true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setExpanded(bool expanded) {
    setState(() {
      _isExpanded = expanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  // ==================== 实现抽象方法 ====================

  @override
  IconData getHeaderIcon() => Icons.psychology_outlined;

  @override
  String getHeaderTitle() => 'Thinking';

  @override
  Color getHeaderColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
  }

  // ==================== 覆盖钩子方法 ====================

  /// 覆盖容器样式：使用左边框而非卡片
  @override
  Widget buildContainer(
    BuildContext context,
    ResponsiveValues r, {
    required Widget child,
  }) {
    final thinkingColor = getHeaderColor(context);
    return Container(
      margin: r.cardMarginGeometry,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: thinkingColor, width: 2)),
      ),
      child: child,
    );
  }

  /// 覆盖卡片内容：自定义可折叠布局
  @override
  Widget buildCardContent(BuildContext context, ResponsiveValues r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 可点击的标题栏
        buildHeader(context, r),
        // 可折叠的内容区域
        ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Align(
                alignment: Alignment.topCenter,
                heightFactor: _heightFactor.value,
                child: child,
              );
            },
            child: Padding(
              padding: EdgeInsets.only(
                left: r.cardPadding + 8, // 额外缩进
                right: r.cardPadding,
                bottom: r.cardPadding,
              ),
              child: buildContent(context, r),
            ),
          ),
        ),
      ],
    );
  }

  /// 覆盖头部：添加展开/折叠交互
  @override
  Widget buildHeader(BuildContext context, ResponsiveValues r) {
    final theme = Theme.of(context);
    final thinkingColor = getHeaderColor(context);

    return InkWell(
      onTap: () => _setExpanded(!_isExpanded),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: r.cardPadding,
          vertical: r.isCompact ? 6 : 8,
        ),
        child: Row(
          children: [
            // 展开/折叠图标
            RotationTransition(
              turns: _iconTurns,
              child: Icon(
                Icons.expand_more,
                size: r.isCompact ? 16 : 18,
                color: thinkingColor,
              ),
            ),
            const SizedBox(width: 6),
            // 标题 - 斜体灰色
            Expanded(
              child: Text(
                'Thinking',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: r.isCompact ? 12 : 13,
                  color: thinkingColor,
                ),
              ),
            ),
            // 流式状态指示
            if (widget.streamingStatus == StreamingStatus.streaming)
              _buildStreamingIndicator(context, r),
          ],
        ),
      ),
    );
  }

  /// 实现内容构建：Markdown 内容
  @override
  Widget buildContent(BuildContext context, ResponsiveValues r) {
    final colorScheme = Theme.of(context).colorScheme;
    return StreamingMarkdown(
      content: widget.content,
      streamingStatus: widget.streamingStatus,
      messageId: widget.messageId,
      textColor: colorScheme.onSurface.withValues(alpha: 0.5),
    );
  }

  // ==================== 辅助方法 ====================

  Widget _buildStreamingIndicator(BuildContext context, ResponsiveValues r) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: SizedBox(
        width: r.isCompact ? 10 : 12,
        height: r.isCompact ? 10 : 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
