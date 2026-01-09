import 'dart:async';
import 'dart:ui';

/// 防抖器 - 延迟执行，多次调用只执行最后一次
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  Timer? _timer;

  /// 执行防抖操作
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// 立即执行并取消待处理的操作
  void runNow(VoidCallback action) {
    _timer?.cancel();
    action();
  }

  /// 取消待处理的操作
  void cancel() {
    _timer?.cancel();
  }

  /// 释放资源
  void dispose() {
    _timer?.cancel();
  }
}
