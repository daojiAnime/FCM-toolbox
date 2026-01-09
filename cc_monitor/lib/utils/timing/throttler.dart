import 'dart:async';
import 'dart:ui';

/// 节流器 - 限制执行频率，在间隔时间内只执行一次
class Throttler {
  Throttler({this.interval = const Duration(milliseconds: 100)});

  final Duration interval;
  DateTime? _lastRun;
  Timer? _timer;
  VoidCallback? _pendingAction;

  /// 执行节流操作
  void run(VoidCallback action) {
    final now = DateTime.now();

    if (_lastRun == null || now.difference(_lastRun!) >= interval) {
      // 可以立即执行
      _lastRun = now;
      action();
    } else {
      // 保存待执行的操作
      _pendingAction = action;
      _timer?.cancel();
      _timer = Timer(interval - now.difference(_lastRun!), () {
        _lastRun = DateTime.now();
        _pendingAction?.call();
        _pendingAction = null;
      });
    }
  }

  /// 释放资源
  void dispose() {
    _timer?.cancel();
  }
}
