import 'package:flutter/material.dart';

/// 气泡样式共享（Flyweight 模式）
/// 集中管理气泡组件的共享样式常量，避免重复定义
class BubbleStyles {
  BubbleStyles._(); // 私有构造函数，防止实例化

  // ==================== 尺寸常量 ====================

  /// 气泡最大宽度比例（相对屏幕宽度）
  static const double maxWidthRatio = 0.85;

  /// 紧凑模式水平内边距
  static const double compactHPadding = 12.0;

  /// 紧凑模式垂直内边距
  static const double compactVPadding = 10.0;

  /// 正常模式水平内边距
  static const double normalHPadding = 14.0;

  /// 正常模式垂直内边距
  static const double normalVPadding = 12.0;

  /// 紧凑模式外边距
  static const double compactMargin = 12.0;

  /// 正常模式外边距
  static const double normalMargin = 16.0;

  /// 紧凑模式气泡间距
  static const double compactSpacing = 4.0;

  /// 正常模式气泡间距
  static const double normalSpacing = 6.0;

  /// 头像大小（紧凑）
  static const double compactAvatarSize = 28.0;

  /// 头像大小（正常）
  static const double normalAvatarSize = 32.0;

  /// 头像与气泡间距（紧凑）
  static const double compactAvatarSpacing = 8.0;

  /// 头像与气泡间距（正常）
  static const double normalAvatarSpacing = 10.0;

  // ==================== 圆角常量 ====================

  /// 圆角半径 - 小
  static const double smallRadius = 4.0;

  /// 圆角半径 - 正常
  static const double normalRadius = 16.0;

  /// 用户气泡圆角（右对齐，右下角小圆角）
  static const BorderRadius userBubbleBorderRadius = BorderRadius.only(
    topLeft: Radius.circular(normalRadius),
    topRight: Radius.circular(normalRadius),
    bottomLeft: Radius.circular(normalRadius),
    bottomRight: Radius.circular(smallRadius),
  );

  /// AI 助手气泡圆角（左对齐，左上角小圆角）
  static const BorderRadius assistantBubbleBorderRadius = BorderRadius.only(
    topLeft: Radius.circular(smallRadius),
    topRight: Radius.circular(normalRadius),
    bottomLeft: Radius.circular(normalRadius),
    bottomRight: Radius.circular(normalRadius),
  );

  // ==================== 边框样式 ====================

  /// 边框宽度
  static const double borderWidth = 1.0;

  /// 边框透明度
  static const double borderAlpha = 0.1;

  // ==================== 动画常量 ====================

  /// 淡入动画时长
  static const Duration fadeInDuration = Duration(milliseconds: 200);

  /// 滑动动画时长
  static const Duration slideDuration = Duration(milliseconds: 200);

  /// 滑动起始偏移
  static const double slideBegin = 0.05;

  /// 滑动结束偏移
  static const double slideEnd = 0.0;

  // ==================== 工具方法 ====================

  /// 获取气泡内边距（响应式）
  static EdgeInsets getPadding(bool isCompact) {
    return EdgeInsets.symmetric(
      horizontal: isCompact ? compactHPadding : normalHPadding,
      vertical: isCompact ? compactVPadding : normalVPadding,
    );
  }

  /// 获取气泡外边距（响应式）
  static EdgeInsets getMargin(bool isCompact) {
    return EdgeInsets.symmetric(
      horizontal: isCompact ? compactMargin : normalMargin,
      vertical: isCompact ? compactSpacing : normalSpacing,
    );
  }

  /// 获取头像大小（响应式）
  static double getAvatarSize(bool isCompact) {
    return isCompact ? compactAvatarSize : normalAvatarSize;
  }

  /// 获取头像与气泡间距（响应式）
  static double getAvatarSpacing(bool isCompact) {
    return isCompact ? compactAvatarSpacing : normalAvatarSpacing;
  }

  /// 获取最大气泡宽度
  static double getMaxBubbleWidth(double screenWidth) {
    return screenWidth * maxWidthRatio;
  }

  /// 创建气泡边框
  static Border createBorder(Color outlineColor) {
    return Border.all(
      color: outlineColor.withValues(alpha: borderAlpha),
      width: borderWidth,
    );
  }

  /// 创建气泡装饰（用户）
  static BoxDecoration createUserBubbleDecoration(Color backgroundColor) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: userBubbleBorderRadius,
    );
  }

  /// 创建气泡装饰（助手）
  static BoxDecoration createAssistantBubbleDecoration({
    required Color backgroundColor,
    required Color outlineColor,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: assistantBubbleBorderRadius,
      border: createBorder(outlineColor),
    );
  }
}

/// 气泡样式配置（可选，用于运行时自定义）
class BubbleStyleConfig {
  const BubbleStyleConfig({
    this.maxWidthRatio = BubbleStyles.maxWidthRatio,
    this.compactHPadding = BubbleStyles.compactHPadding,
    this.compactVPadding = BubbleStyles.compactVPadding,
    this.normalHPadding = BubbleStyles.normalHPadding,
    this.normalVPadding = BubbleStyles.normalVPadding,
  });

  final double maxWidthRatio;
  final double compactHPadding;
  final double compactVPadding;
  final double normalHPadding;
  final double normalVPadding;

  /// 默认配置
  static const BubbleStyleConfig defaultConfig = BubbleStyleConfig();

  /// 紧凑配置
  static const BubbleStyleConfig compactConfig = BubbleStyleConfig(
    maxWidthRatio: 0.75,
    compactHPadding: 10.0,
    compactVPadding: 8.0,
    normalHPadding: 12.0,
    normalVPadding: 10.0,
  );

  /// 宽松配置
  static const BubbleStyleConfig relaxedConfig = BubbleStyleConfig(
    maxWidthRatio: 0.9,
    compactHPadding: 14.0,
    compactVPadding: 12.0,
    normalHPadding: 16.0,
    normalVPadding: 14.0,
  );
}
