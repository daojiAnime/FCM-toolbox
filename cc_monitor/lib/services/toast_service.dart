import '../common/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Toast 类型
enum ToastType { info, success, warning, error }

/// Toast 消息
class ToastMessage {
  final String message;
  final ToastType type;
  final Duration duration;

  const ToastMessage({
    required this.message,
    this.type = ToastType.info,
    this.duration = const Duration(seconds: 3),
  });

  Color get backgroundColor => switch (type) {
    ToastType.info => Colors.blueGrey,
    ToastType.success => Colors.green.shade700,
    ToastType.warning => Colors.orange.shade700,
    ToastType.error => Colors.red.shade700,
  };

  IconData get icon => switch (type) {
    ToastType.info => Icons.info_outline,
    ToastType.success => Icons.check_circle_outline,
    ToastType.warning => Icons.warning_amber_outlined,
    ToastType.error => Icons.error_outline,
  };
}

/// 全局 ScaffoldMessengerKey
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Toast 服务 - 全局通知管理
class ToastService {
  static final ToastService _instance = ToastService._();
  factory ToastService() => _instance;
  ToastService._();

  void show(
    String message, {
    ToastType type = ToastType.info,
    Duration? duration,
  }) {
    final toast = ToastMessage(
      message: message,
      type: type,
      duration: duration ?? const Duration(seconds: 3),
    );
    _showSnackBar(toast);
  }

  void info(String message) => show(message, type: ToastType.info);
  void success(String message) => show(message, type: ToastType.success);
  void warning(String message) => show(message, type: ToastType.warning);
  void error(String message) => show(message, type: ToastType.error);

  void _showSnackBar(ToastMessage toast) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      Log.w(
        'Toast',
        '[ToastService] ScaffoldMessenger not available: ${toast.message}',
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(toast.icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(toast.message)),
          ],
        ),
        backgroundColor: toast.backgroundColor,
        duration: toast.duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

/// Provider - 提供单例访问
final toastServiceProvider = Provider<ToastService>((ref) => ToastService());
