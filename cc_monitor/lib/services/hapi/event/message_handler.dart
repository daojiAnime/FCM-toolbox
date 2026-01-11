import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/logger.dart';
import '../../../providers/streaming_provider.dart';
import '../../toast_service.dart';
import '../buffer_manager.dart';
import '../hapi_sse_service.dart';
import 'event_handler.dart';
import 'message_parser.dart';

/// 消息事件处理器
/// 处理 message、streamingContent、streamingComplete、toast、error 等消息相关事件
class MessageEventHandler extends EventHandler {
  MessageEventHandler(this._ref, this._bufferManager, this._parser);

  final Ref _ref;
  final BufferManager _bufferManager;
  // ignore: unused_field
  final HapiMessageParser _parser;

  static final _handledTypes = {
    HapiSseEventType.message,
    HapiSseEventType.streamingContent,
    HapiSseEventType.streamingComplete,
    HapiSseEventType.toast,
    HapiSseEventType.error,
    HapiSseEventType.unknown,
  };

  @override
  bool canHandle(HapiSseEvent event) {
    return _handledTypes.contains(event.type);
  }

  @override
  void doHandle(HapiSseEvent event) {
    Log.d('MsgHandler', 'Handling ${event.type}');

    switch (event.type) {
      case HapiSseEventType.message:
        _handleMessageEvent(event);
      case HapiSseEventType.streamingContent:
        _handleStreamingContent(event);
      case HapiSseEventType.streamingComplete:
        _handleStreamingComplete(event);
      case HapiSseEventType.toast:
        _handleToast(event);
      case HapiSseEventType.error:
        Log.w('MsgHandler', 'SSE error: ${event.data}');
      case HapiSseEventType.unknown:
        Log.w('MsgHandler', 'Unknown event: ${event.type}');
      default:
        Log.w('MsgHandler', 'Unhandled event type: ${event.type}');
    }
  }

  /// 处理 toast 通知
  void _handleToast(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    final message = data['message'] as String? ?? data['text'] as String?;
    if (message != null) {
      final type = data['type'] as String?;
      final toastType = switch (type) {
        'error' => ToastType.error,
        'warning' => ToastType.warning,
        'success' => ToastType.success,
        _ => ToastType.info,
      };
      ToastService().show(message, type: toastType);
    }
  }

  /// 处理消息事件
  /// hapi SSE 事件结构: { type: 'message-received', sessionId: 'xxx', message: {...} }
  void _handleMessageEvent(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    try {
      // hapi message-received 事件: sessionId 和 message 都在顶层
      final sessionId = event.sessionId ?? data['sessionId'] as String?;
      final messageData = data['message'] as Map<String, dynamic>?;

      if (sessionId == null || messageData == null) return;

      // TODO: 使用 parser 解析消息 (待 parser 方法迁移完成)
      // final message = _parser.parseHapiMessage(messageData, sessionId);
      // if (message != null) {
      //   _ref.read(messagesProvider.notifier).addMessage(message);
      // }

      // 临时占位: 直接记录日志
      Log.d('MsgHandler', 'Received message for session $sessionId');

      // TODO: 更新 session contextSize
      // _updateSessionContextSize(sessionId, messageData);
    } catch (e) {
      Log.e('MsgHandler', 'Failed to parse message', e);
    }
  }

  /// 处理流式内容事件
  void _handleStreamingContent(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    try {
      final messageId = data['messageId'] as String? ?? data['id'] as String?;
      final chunk = data['chunk'] as String? ?? data['content'] as String?;
      final sessionId = event.sessionId ?? data['sessionId'] as String?;

      if (messageId == null) return;

      // 初始化缓冲区和元数据 (使用 BufferManager)
      if (!_bufferManager.hasStreamingBuffer(messageId)) {
        _bufferManager.initStreamingBuffer(messageId, {
          'sessionId': sessionId,
          'type': data['type'] as String? ?? 'markdown',
          'title': data['title'] as String?,
          'language': data['language'] as String?,
          'filename': data['filename'] as String?,
          'projectName': data['projectName'] as String? ?? 'hapi',
          'parentUuid':
              data['parentUuid'] as String? ?? data['parentId'] as String?,
          'contentUuid': data['uuid'] as String?,
        });

        // 开始流式传输
        _ref
            .read(streamingMessagesProvider.notifier)
            .startStreaming(messageId, initialContent: chunk ?? '');

        // TODO: 创建初始消息（状态为 streaming）
        // final message = _createStreamingMessage(messageId, chunk ?? '');
        // if (message != null) {
        //   _ref.read(messagesProvider.notifier).addMessage(message);
        // }
      } else if (chunk != null) {
        // 追加内容 (使用 BufferManager)
        _bufferManager.appendStreamingContent(messageId, chunk);

        // 更新流式内容（使用 provider 内置的节流）
        _ref
            .read(streamingMessagesProvider.notifier)
            .updateContent(
              messageId,
              _bufferManager.getStreamingContent(messageId) ?? '',
            );
      }
    } catch (e) {
      Log.e('MsgHandler', 'Failed to handle streaming content', e);
    }
  }

  /// 处理流式完成事件
  void _handleStreamingComplete(HapiSseEvent event) {
    final data = event.data;
    if (data == null) return;

    try {
      final messageId = data['messageId'] as String? ?? data['id'] as String?;
      if (messageId == null) return;

      // 标记完成
      final notifier = _ref.read(streamingMessagesProvider.notifier);
      notifier.complete(messageId);

      // TODO: 更新消息为完成状态 (使用 BufferManager)
      // final finalContent = _bufferManager.getStreamingContent(messageId) ?? '';
      // final metadata = _bufferManager.getStreamingMetadata(messageId);

      // if (metadata != null) {
      //   final message = _createFinalMessage(messageId, finalContent, metadata);
      //   if (message != null) {
      //     _ref.read(messagesProvider.notifier).replaceMessage(message);
      //   }
      // }

      // 清理缓冲区 (使用 BufferManager)
      _bufferManager.removeStreamingBuffer(messageId);

      // 延迟清理流式状态（让 UI 有时间显示最终状态）
      Future.delayed(const Duration(milliseconds: 500), () {
        notifier.remove(messageId);
      });
    } catch (e) {
      Log.e('MsgHandler', 'Failed to handle streaming complete', e);
    }
  }
}
