import 'package:flutter/material.dart';

/// 紧凑型输入指示器 - 三点脉冲动画
///
/// 设计原则：
/// - 内联显示，不占用额外空间
/// - 最小化视觉干扰
/// - 平滑的脉冲动画
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    this.color,
    this.size = 4.0,
    this.spacing = 3.0,
  });

  /// 点的颜色，默认使用主题色
  final Color? color;

  /// 点的大小
  final double size;

  /// 点之间的间距
  final double spacing;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _animations =
        _controllers.map((controller) {
          return Tween<double>(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          );
        }).toList();

    // 错开动画启动
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? Theme.of(context).colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder:
              (context, child) => Container(
                margin: EdgeInsets.only(right: i < 2 ? widget.spacing : 0),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor.withValues(alpha: _animations[i].value),
                ),
              ),
        );
      }),
    );
  }
}

/// 带文字的输入指示器
class TypingIndicatorWithText extends StatelessWidget {
  const TypingIndicatorWithText({super.key, this.text = '正在输入', this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = color ?? theme.colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TypingIndicator(color: textColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// 闪烁光标 - 用于代码块
class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({
    super.key,
    this.color,
    this.width = 2.0,
    this.height = 16.0,
  });

  final Color? color;
  final double width;
  final double height;

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cursorColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder:
          (context, child) => Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: cursorColor.withValues(alpha: _animation.value),
              borderRadius: BorderRadius.circular(1),
              boxShadow: [
                BoxShadow(
                  color: cursorColor.withValues(alpha: _animation.value * 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
    );
  }
}
