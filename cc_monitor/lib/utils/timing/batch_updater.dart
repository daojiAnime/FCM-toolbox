import 'dart:async';

/// 批量更新收集器
/// 收集多个更新操作，批量执行以减少重绘
class BatchUpdater<T> {
  BatchUpdater({
    required this.onFlush,
    this.maxBatchSize = 50,
    this.flushDelay = const Duration(milliseconds: 100),
  });

  final void Function(List<T> items) onFlush;
  final int maxBatchSize;
  final Duration flushDelay;

  final List<T> _pendingItems = [];
  Timer? _flushTimer;

  /// 添加项目到批次
  void add(T item) {
    _pendingItems.add(item);

    if (_pendingItems.length >= maxBatchSize) {
      // 批次已满，立即刷新
      flush();
    } else {
      // 延迟刷新
      _scheduleFlush();
    }
  }

  /// 添加多个项目
  void addAll(Iterable<T> items) {
    for (final item in items) {
      add(item);
    }
  }

  /// 立即刷新所有待处理项目
  void flush() {
    if (_pendingItems.isEmpty) return;

    _flushTimer?.cancel();
    final items = List<T>.from(_pendingItems);
    _pendingItems.clear();

    onFlush(items);
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(flushDelay, flush);
  }

  /// 释放资源
  void dispose() {
    flush(); // 确保所有待处理项目都被处理
    _flushTimer?.cancel();
  }
}
