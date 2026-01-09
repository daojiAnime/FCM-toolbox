import 'dart:async';
import 'dart:ui' show VoidCallback;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/payload/payload.dart';

part 'streaming_provider.freezed.dart';

/// 节流器 - 限制函数调用频率
class Throttler {
  Throttler({required this.interval});

  final Duration interval;
  Timer? _timer;
  bool _isThrottled = false;

  /// 执行函数，如果在节流期间则跳过
  void run(VoidCallback action) {
    if (_isThrottled) return;

    action();
    _isThrottled = true;
    _timer?.cancel();
    _timer = Timer(interval, () {
      _isThrottled = false;
    });
  }

  /// 强制执行（忽略节流）
  void runForced(VoidCallback action) {
    _timer?.cancel();
    _isThrottled = false;
    action();
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// 流式消息状态
@freezed
class StreamingMessageState with _$StreamingMessageState {
  const factory StreamingMessageState({
    required String messageId,
    required String content,
    required StreamingStatus status,
    @Default(0) int chunkCount,
    DateTime? startedAt,
    DateTime? completedAt,
  }) = _StreamingMessageState;
}

/// 流式消息状态管理
class StreamingMessagesNotifier
    extends StateNotifier<Map<String, StreamingMessageState>> {
  StreamingMessagesNotifier() : super({});

  final _throttler = Throttler(interval: const Duration(milliseconds: 50));

  /// 开始流式传输
  void startStreaming(String messageId, {String initialContent = ''}) {
    state = {
      ...state,
      messageId: StreamingMessageState(
        messageId: messageId,
        content: initialContent,
        status: StreamingStatus.streaming,
        startedAt: DateTime.now(),
      ),
    };
  }

  /// 追加内容（带节流）
  void appendContent(String messageId, String chunk) {
    _throttler.run(() {
      final current = state[messageId];
      if (current == null) {
        // 自动开始
        startStreaming(messageId, initialContent: chunk);
        return;
      }

      state = {
        ...state,
        messageId: current.copyWith(
          content: current.content + chunk,
          chunkCount: current.chunkCount + 1,
        ),
      };
    });
  }

  /// 更新完整内容（带节流）
  void updateContent(String messageId, String content) {
    _throttler.run(() {
      final current = state[messageId];
      if (current == null) {
        startStreaming(messageId, initialContent: content);
        return;
      }

      state = {
        ...state,
        messageId: current.copyWith(
          content: content,
          chunkCount: current.chunkCount + 1,
        ),
      };
    });
  }

  /// 完成流式传输
  void complete(String messageId) {
    _throttler.runForced(() {
      final current = state[messageId];
      if (current == null) return;

      state = {
        ...state,
        messageId: current.copyWith(
          status: StreamingStatus.complete,
          completedAt: DateTime.now(),
        ),
      };
    });
  }

  /// 设置错误状态
  void setError(String messageId) {
    _throttler.runForced(() {
      final current = state[messageId];
      if (current == null) return;

      state = {
        ...state,
        messageId: current.copyWith(
          status: StreamingStatus.error,
          completedAt: DateTime.now(),
        ),
      };
    });
  }

  /// 移除消息（流式完成后清理）
  void remove(String messageId) {
    state = Map.from(state)..remove(messageId);
  }

  /// 清空所有
  void clear() {
    state = {};
  }

  /// 获取消息内容
  String? getContent(String messageId) {
    return state[messageId]?.content;
  }

  /// 检查是否正在流式传输
  bool isStreaming(String messageId) {
    return state[messageId]?.status == StreamingStatus.streaming;
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }
}

/// 流式消息 Provider
final streamingMessagesProvider = StateNotifierProvider<
  StreamingMessagesNotifier,
  Map<String, StreamingMessageState>
>((ref) => StreamingMessagesNotifier());

/// 单个消息流式状态 Provider
final streamingMessageProvider =
    Provider.family<StreamingMessageState?, String>((ref, messageId) {
      return ref.watch(streamingMessagesProvider)[messageId];
    });

/// 消息是否正在流式传输 Provider
final isMessageStreamingProvider = Provider.family<bool, String>((
  ref,
  messageId,
) {
  final state = ref.watch(streamingMessageProvider(messageId));
  return state?.status == StreamingStatus.streaming;
});

/// 流式内容 Provider（用于 UI 绑定）
final streamingContentProvider = Provider.family<String, String>((
  ref,
  messageId,
) {
  return ref.watch(streamingMessageProvider(messageId))?.content ?? '';
});

/// 是否有任何消息正在流式传输 Provider
/// 用于判断会话是否正在运行 (与 web threadIsRunning 对齐)
final isAnyStreamingProvider = Provider<bool>((ref) {
  final messages = ref.watch(streamingMessagesProvider);
  return messages.values.any(
    (state) => state.status == StreamingStatus.streaming,
  );
});
