import 'package:flutter/material.dart';

/// 彩虹关键词列表 - 来自 Web 版 LazyRainbowText.tsx
const rainbowWords = [
  'ultrathink',
  'fuck',
  'step by step',
  'ELI5',
  'lgtm',
  'impl it',
  'pls fix',
  'stop changing',
  '用中文',
  '我说了',
  '别又',
  '为什么又',
  '根本不',
  '还是报错',
  '大哥',
  '求你',
  '就改这里',
  '弱智',
];

/// 彩虹颜色列表
const _rainbowColors = [
  Color(0xFFFF5555), // 红
  Color(0xFFFFAA00), // 橙
  Color(0xFFFFFF55), // 黄
  Color(0xFF55FF55), // 绿
  Color(0xFF55FFFF), // 青
  Color(0xFF5555FF), // 蓝
  Color(0xFFFF55FF), // 品红
];

/// 快速检查文本是否包含彩虹关键词
bool hasRainbowWord(String text) {
  final lowerText = text.toLowerCase();
  return rainbowWords.any((word) => lowerText.contains(word.toLowerCase()));
}

/// 构建匹配正则表达式
RegExp _buildPattern() {
  final escaped = rainbowWords.map((w) => RegExp.escape(w)).join('|');
  return RegExp('($escaped)', caseSensitive: false);
}

final _rainbowPattern = _buildPattern();

/// 彩虹文本组件 - 将文本中的关键词渲染为彩虹动画
class RainbowText extends StatelessWidget {
  const RainbowText({super.key, required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    // 快速检查，无关键词直接返回普通文本
    if (!hasRainbowWord(text)) {
      return SelectableText(text, style: style);
    }

    // 解析文本，分离普通文本和彩虹词
    final parts = <InlineSpan>[];
    var lastIndex = 0;

    for (final match in _rainbowPattern.allMatches(text)) {
      // 添加匹配前的普通文本
      if (match.start > lastIndex) {
        parts.add(
          TextSpan(text: text.substring(lastIndex, match.start), style: style),
        );
      }

      // 添加彩虹词
      parts.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: _RainbowWord(
            word: match.group(0)!,
            baseKey: match.start,
            style: style,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // 添加剩余文本
    if (lastIndex < text.length) {
      parts.add(TextSpan(text: text.substring(lastIndex), style: style));
    }

    return SelectableText.rich(TextSpan(children: parts));
  }
}

/// 单个彩虹词组件 - 每个字母独立动画
class _RainbowWord extends StatefulWidget {
  const _RainbowWord({required this.word, required this.baseKey, this.style});

  final String word;
  final int baseKey;
  final TextStyle? style;

  @override
  State<_RainbowWord> createState() => _RainbowWordState();
}

class _RainbowWordState extends State<_RainbowWord>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4), // 减缓50%: 2s -> 4s
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.word.split('');
    final totalLetters = letters.length;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalLetters, (i) {
              // 每个字母根据位置计算颜色偏移，形成波浪效果
              final colorOffset = (i / totalLetters) + _controller.value;
              final colorIndex =
                  (colorOffset * _rainbowColors.length).floor() %
                  _rainbowColors.length;

              // 闪烁效果：基于位置的亮度波动
              final sparklePhase =
                  (_controller.value * 2 + i / totalLetters) % 1.0;
              final brightness = 0.7 + 0.3 * (1 - (sparklePhase * 2 - 1).abs());

              final color =
                  HSLColor.fromColor(_rainbowColors[colorIndex])
                      .withLightness(
                        (HSLColor.fromColor(
                                  _rainbowColors[colorIndex],
                                ).lightness *
                                brightness)
                            .clamp(0.0, 1.0),
                      )
                      .toColor();

              return Text(
                letters[i] == ' ' ? '\u00A0' : letters[i],
                style: (widget.style ?? const TextStyle()).copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// 彩虹输入控制器 - 在 TextField 中实时显示彩虹效果
class RainbowTextEditingController extends TextEditingController {
  RainbowTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;

    // 快速检查，无关键词直接返回普通文本
    if (!hasRainbowWord(text)) {
      return TextSpan(text: text, style: style);
    }

    // 解析文本，分离普通文本和彩虹词
    final spans = <InlineSpan>[];
    var lastIndex = 0;

    for (final match in _rainbowPattern.allMatches(text)) {
      // 添加匹配前的普通文本
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(text: text.substring(lastIndex, match.start), style: style),
        );
      }

      // 添加彩虹词 - 使用 WidgetSpan 包裹动画组件
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: _RainbowWord(
            word: match.group(0)!,
            baseKey: match.start,
            style: style,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // 添加剩余文本
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: style));
    }

    return TextSpan(children: spans, style: style);
  }
}

/// 简化版彩虹文本 - 用于输入框预览（不可选择）
class RainbowPreview extends StatelessWidget {
  const RainbowPreview({super.key, required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    // 快速检查，无关键词直接返回普通文本
    if (!hasRainbowWord(text)) {
      return Text(text, style: style);
    }

    // 解析文本，分离普通文本和彩虹词
    final parts = <InlineSpan>[];
    var lastIndex = 0;

    for (final match in _rainbowPattern.allMatches(text)) {
      // 添加匹配前的普通文本
      if (match.start > lastIndex) {
        parts.add(
          TextSpan(text: text.substring(lastIndex, match.start), style: style),
        );
      }

      // 添加彩虹词
      parts.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: _RainbowWord(
            word: match.group(0)!,
            baseKey: match.start,
            style: style,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // 添加剩余文本
    if (lastIndex < text.length) {
      parts.add(TextSpan(text: text.substring(lastIndex), style: style));
    }

    return Text.rich(TextSpan(children: parts));
  }
}
