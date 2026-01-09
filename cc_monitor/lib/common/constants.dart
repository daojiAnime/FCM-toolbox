/// 应用常量
class AppConstants {
  AppConstants._();

  // 应用信息
  static const String appName = 'CC Monitor';
  static const String appVersion = '1.0.0';

  // 动画时长
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // 响应式断点
  static const double compactBreakpoint = 600.0;

  // 卡片设计 - 紧凑风格（桌面端）
  static const double cardBorderRadius = 12.0;
  static const double cardPadding = 12.0;
  static const double cardMarginH = 12.0;
  static const double cardMarginV = 4.0;

  // 卡片设计 - 超紧凑风格（移动端）
  static const double cardBorderRadiusCompact = 10.0;
  static const double cardPaddingCompact = 10.0;
  static const double cardMarginHCompact = 8.0;
  static const double cardMarginVCompact = 3.0;

  // 间距系统 - 紧凑
  static const double titleIconGap = 8.0;
  static const double contentGap = 4.0;
  static const double timestampTopGap = 8.0;

  // 间距系统 - 超紧凑（移动端）
  static const double titleIconGapCompact = 6.0;
  static const double contentGapCompact = 3.0;
  static const double timestampTopGapCompact = 6.0;

  // 状态标签配置 - 紧凑
  static const double statusLabelPaddingH = 8.0;
  static const double statusLabelPaddingV = 3.0;
  static const double statusLabelBorderRadius = 10.0;

  // 状态标签配置 - 超紧凑（移动端）
  static const double statusLabelPaddingHCompact = 6.0;
  static const double statusLabelPaddingVCompact = 2.0;
  static const double statusLabelBorderRadiusCompact = 8.0;

  // Firestore 集合名称
  static const String sessionsCollection = 'sessions';
  static const String messagesCollection = 'messages';
  static const String commandsCollection = 'commands';

  // Hook 事件类型
  static const String hookSessionStart = 'SessionStart';
  static const String hookSessionEnd = 'SessionEnd';
  static const String hookPreToolUse = 'PreToolUse';
  static const String hookPostToolUse = 'PostToolUse';
  static const String hookStop = 'Stop';
  static const String hookSubagentStop = 'SubagentStop';
  static const String hookNotification = 'Notification';
  static const String hookPermissionRequest = 'PermissionRequest';

  // 消息类型
  static const String messageProgress = 'progress';
  static const String messageComplete = 'complete';
  static const String messageError = 'error';
  static const String messageWarning = 'warning';
  static const String messageCode = 'code';
  static const String messageMarkdown = 'markdown';
  static const String messageImage = 'image';
  static const String messageInteractive = 'interactive';

  // 会话状态
  static const String sessionRunning = 'running';
  static const String sessionWaiting = 'waiting';
  static const String sessionCompleted = 'completed';

  // 指令状态
  static const String commandPending = 'pending';
  static const String commandApproved = 'approved';
  static const String commandDenied = 'denied';
  static const String commandExpired = 'expired';
}
