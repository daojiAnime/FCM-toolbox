import 'dart:async';
import '../../common/logger.dart';

/// SSE 解析结果
class SseParseResult {
  const SseParseResult({
    required this.hasEvent,
    this.eventType,
    this.data,
    this.eventId,
    this.retryDelay,
  });

  final bool hasEvent;
  final String? eventType;
  final String? data;
  final String? eventId;
  final Duration? retryDelay;

  /// 空结果（未完成事件）
  static const SseParseResult empty = SseParseResult(hasEvent: false);

  /// 创建事件结果
  factory SseParseResult.event({
    required String eventType,
    required String data,
    String? eventId,
  }) {
    return SseParseResult(
      hasEvent: true,
      eventType: eventType,
      data: data,
      eventId: eventId,
    );
  }

  /// 创建 retry 结果
  factory SseParseResult.retry(Duration delay) {
    return SseParseResult(hasEvent: false, retryDelay: delay);
  }
}

/// SSE 解析器 (Interpreter 模式)
/// 解析 Server-Sent Events 协议流
///
/// SSE 格式规范:
/// - event: event_type
/// - data: event_data
/// - id: event_id
/// - retry: milliseconds
/// - 空行表示事件结束
class SseParser {
  SseParser({String defaultEventType = 'message'})
    : _defaultEventType = defaultEventType,
      _currentEventType = defaultEventType;

  final String _defaultEventType;

  // 当前解析状态
  String _currentEventType;
  final _dataBuffer = StringBuffer();
  String? _lastEventId;

  /// 解析单行 SSE 数据
  /// 返回 null 表示事件尚未完成，返回 SseParseResult 表示事件完成或其他指令
  SseParseResult? parseLine(String line) {
    // 空行表示事件结束
    if (line.isEmpty) {
      return _emitEvent();
    }

    // 注释行（以 : 开头），忽略
    if (line.startsWith(':')) {
      return null;
    }

    // 解析字段
    final colonIndex = line.indexOf(':');
    if (colonIndex == -1) {
      // 无冒号的行，作为字段名处理（值为空）
      return _parseField(line, '');
    }

    final field = line.substring(0, colonIndex);
    var value = line.substring(colonIndex + 1);

    // SSE 规范：如果值以空格开头，移除首个空格
    if (value.startsWith(' ')) {
      value = value.substring(1);
    }

    return _parseField(field, value);
  }

  /// 解析字段
  SseParseResult? _parseField(String field, String value) {
    switch (field) {
      case 'event':
        _currentEventType = value;
        return null;

      case 'data':
        // 多个 data 字段会累积，用换行符连接
        if (_dataBuffer.isNotEmpty) {
          _dataBuffer.write('\n');
        }
        _dataBuffer.write(value);
        return null;

      case 'id':
        // 只有非空 id 才更新
        if (value.isNotEmpty) {
          _lastEventId = value;
        }
        return null;

      case 'retry':
        // 重连延迟（毫秒）
        final retryMs = int.tryParse(value);
        if (retryMs != null && retryMs > 0) {
          Log.d('SseParser', 'Server suggested retry delay: ${retryMs}ms');
          return SseParseResult.retry(Duration(milliseconds: retryMs));
        }
        return null;

      default:
        // 忽略未知字段
        Log.d('SseParser', 'Unknown SSE field: $field');
        return null;
    }
  }

  /// 发射事件
  SseParseResult? _emitEvent() {
    // 如果没有数据，不发射事件
    if (_dataBuffer.isEmpty) {
      return null;
    }

    final result = SseParseResult.event(
      eventType: _currentEventType,
      data: _dataBuffer.toString(),
      eventId: _lastEventId,
    );

    // 重置状态
    _currentEventType = _defaultEventType;
    _dataBuffer.clear();

    return result;
  }

  /// 重置解析器状态
  void reset() {
    _currentEventType = _defaultEventType;
    _dataBuffer.clear();
    _lastEventId = null;
  }

  /// 获取当前缓冲区大小（用于调试）
  int get bufferSize => _dataBuffer.length;

  /// 获取最后的事件 ID
  String? get lastEventId => _lastEventId;
}

/// SSE 流解析器
/// 封装流处理逻辑，提供更高级的 API
class SseStreamParser {
  SseStreamParser({
    String defaultEventType = 'message',
    this.onEvent,
    this.onRetryDelay,
    this.onError,
  }) : _parser = SseParser(defaultEventType: defaultEventType);

  final SseParser _parser;
  final void Function(String eventType, String data, String? eventId)? onEvent;
  final void Function(Duration delay)? onRetryDelay;
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// 创建流转换器
  StreamTransformer<String, SseParseResult> createTransformer() {
    return StreamTransformer<String, SseParseResult>.fromHandlers(
      handleData: (line, sink) {
        try {
          final result = _parser.parseLine(line);
          if (result != null) {
            sink.add(result);

            // 触发回调
            if (result.hasEvent && result.data != null) {
              onEvent?.call(
                result.eventType ?? 'message',
                result.data!,
                result.eventId,
              );
            } else if (result.retryDelay != null) {
              onRetryDelay?.call(result.retryDelay!);
            }
          }
        } catch (e, st) {
          onError?.call(e, st);
          sink.addError(e, st);
        }
      },
      handleError: (error, stackTrace, sink) {
        onError?.call(error, stackTrace);
        sink.addError(error, stackTrace);
      },
      handleDone: (sink) {
        // 流结束时，如果有未完成的事件，发射它
        final result = _parser._emitEvent();
        if (result != null && result.hasEvent) {
          sink.add(result);
          if (result.data != null) {
            onEvent?.call(
              result.eventType ?? 'message',
              result.data!,
              result.eventId,
            );
          }
        }
        sink.close();
      },
    );
  }

  /// 解析字符串流
  Stream<SseParseResult> parse(Stream<String> lineStream) {
    return lineStream.transform(createTransformer());
  }

  /// 重置解析器
  void reset() {
    _parser.reset();
  }
}

/// SSE 解析器工厂
class SseParserFactory {
  SseParserFactory._();

  /// 创建标准 SSE 解析器
  static SseParser createStandard() {
    return SseParser(defaultEventType: 'message');
  }

  /// 创建流解析器
  static SseStreamParser createStreamParser({
    String defaultEventType = 'message',
    void Function(String eventType, String data, String? eventId)? onEvent,
    void Function(Duration delay)? onRetryDelay,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return SseStreamParser(
      defaultEventType: defaultEventType,
      onEvent: onEvent,
      onRetryDelay: onRetryDelay,
      onError: onError,
    );
  }
}
