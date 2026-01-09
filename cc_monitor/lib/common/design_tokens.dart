/// 全局设计令牌 (Design Tokens)
/// 集中管理应用的设计常量，确保视觉一致性
class DesignTokens {
  const DesignTokens._();

  // --------------------
  // 响应式断点 (Breakpoints)
  // --------------------
  static const double compactBreakpoint = 600;
  static const double mediumBreakpoint = 840;
  static const double expandedBreakpoint = 1200;

  // --------------------
  // 间距 (Spacing)
  // --------------------
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  // --------------------
  // 圆角 (Radii)
  // --------------------
  static const double radiusXS = 4;
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;
  static const double radiusFull = 999;

  // --------------------
  // 动画时长 (Durations)
  // --------------------
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // --------------------
  // 阴影高度 (Elevation)
  // --------------------
  static const double elevationNone = 0;
  static const double elevationLow = 1;
  static const double elevationMedium = 3;
  static const double elevationHigh = 6;
}
