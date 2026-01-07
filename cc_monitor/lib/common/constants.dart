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

  // 卡片设计
  static const double cardBorderRadius = 16.0;
  static const double cardIndicatorWidth = 4.0;
  static const double cardPadding = 16.0;

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
