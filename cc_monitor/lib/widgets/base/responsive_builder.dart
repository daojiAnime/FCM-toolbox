import 'package:flutter/material.dart';
import '../../common/constants.dart';

/// 响应式参数值集合 (Builder 模式产物)
/// 包含所有响应式布局需要的参数，避免在每个组件中重复计算
class ResponsiveValues {
  const ResponsiveValues({
    required this.isCompact,
    required this.screenWidth,
    required this.cardBorderRadius,
    required this.cardPadding,
    required this.cardMarginH,
    required this.cardMarginV,
    required this.titleIconGap,
    required this.contentGap,
    required this.timestampTopGap,
    required this.statusLabelPaddingH,
    required this.statusLabelPaddingV,
    required this.statusLabelBorderRadius,
  });

  /// 是否为紧凑模式（移动端）
  final bool isCompact;

  /// 屏幕宽度
  final double screenWidth;

  /// 卡片圆角
  final double cardBorderRadius;

  /// 卡片内边距
  final double cardPadding;

  /// 卡片水平外边距
  final double cardMarginH;

  /// 卡片垂直外边距
  final double cardMarginV;

  /// 标题与图标间距
  final double titleIconGap;

  /// 内容间距
  final double contentGap;

  /// 时间戳顶部间距
  final double timestampTopGap;

  /// 状态标签水平内边距
  final double statusLabelPaddingH;

  /// 状态标签垂直内边距
  final double statusLabelPaddingV;

  /// 状态标签圆角
  final double statusLabelBorderRadius;

  /// 获取卡片圆角 BorderRadius
  BorderRadius get cardBorderRadiusGeometry =>
      BorderRadius.circular(cardBorderRadius);

  /// 获取卡片内边距 EdgeInsets
  EdgeInsets get cardPaddingGeometry => EdgeInsets.all(cardPadding);

  /// 获取卡片外边距 EdgeInsets
  EdgeInsets get cardMarginGeometry =>
      EdgeInsets.symmetric(horizontal: cardMarginH, vertical: cardMarginV);

  /// 获取状态标签内边距 EdgeInsets
  EdgeInsets get statusLabelPadding => EdgeInsets.symmetric(
    horizontal: statusLabelPaddingH,
    vertical: statusLabelPaddingV,
  );

  /// 获取状态标签圆角 BorderRadius
  BorderRadius get statusLabelBorderRadiusGeometry =>
      BorderRadius.circular(statusLabelBorderRadius);

  /// 计算最大气泡宽度
  double maxBubbleWidth([double ratio = 0.85]) => screenWidth * ratio;
}

/// 响应式参数构建器 (Builder 模式)
/// 根据屏幕宽度计算所有响应式参数
class ResponsiveBuilder {
  ResponsiveBuilder._();

  /// 根据 BuildContext 构建响应式参数
  static ResponsiveValues of(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return fromWidth(screenWidth);
  }

  /// 根据屏幕宽度构建响应式参数
  static ResponsiveValues fromWidth(double screenWidth) {
    final isCompact = screenWidth < AppConstants.compactBreakpoint;

    return ResponsiveValues(
      isCompact: isCompact,
      screenWidth: screenWidth,
      cardBorderRadius:
          isCompact
              ? AppConstants.cardBorderRadiusCompact
              : AppConstants.cardBorderRadius,
      cardPadding:
          isCompact
              ? AppConstants.cardPaddingCompact
              : AppConstants.cardPadding,
      cardMarginH:
          isCompact
              ? AppConstants.cardMarginHCompact
              : AppConstants.cardMarginH,
      cardMarginV:
          isCompact
              ? AppConstants.cardMarginVCompact
              : AppConstants.cardMarginV,
      titleIconGap:
          isCompact
              ? AppConstants.titleIconGapCompact
              : AppConstants.titleIconGap,
      contentGap:
          isCompact ? AppConstants.contentGapCompact : AppConstants.contentGap,
      timestampTopGap:
          isCompact
              ? AppConstants.timestampTopGapCompact
              : AppConstants.timestampTopGap,
      statusLabelPaddingH:
          isCompact
              ? AppConstants.statusLabelPaddingHCompact
              : AppConstants.statusLabelPaddingH,
      statusLabelPaddingV:
          isCompact
              ? AppConstants.statusLabelPaddingVCompact
              : AppConstants.statusLabelPaddingV,
      statusLabelBorderRadius:
          isCompact
              ? AppConstants.statusLabelBorderRadiusCompact
              : AppConstants.statusLabelBorderRadius,
    );
  }
}

/// ResponsiveValues 扩展 - 提供便捷的工厂方法
extension ResponsiveValuesExtension on BuildContext {
  /// 获取当前上下文的响应式参数
  ResponsiveValues get responsive => ResponsiveBuilder.of(this);
}
