import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 日志级别
enum LogLevel {
  /// 详细日志 - 仅开发调试
  verbose(0, 'V'),

  /// 调试日志 - 开发环境
  debug(1, 'D'),

  /// 信息日志 - 正常流程
  info(2, 'I'),

  /// 警告日志 - 潜在问题
  warning(3, 'W'),

  /// 错误日志 - 异常情况
  error(4, 'E');

  const LogLevel(this.priority, this.symbol);
  final int priority;
  final String symbol;
}

/// 轻量级日志服务
///
/// 使用示例：
/// ```dart
/// Log.d('MyService', 'Debug message');
/// Log.i('MyService', 'Info message');
/// Log.w('MyService', 'Warning message');
/// Log.e('MyService', 'Error message', error, stackTrace);
/// ```
class Log {
  Log._();

  // 配置
  static LogLevel _minLevel = kReleaseMode ? LogLevel.info : LogLevel.verbose;
  static bool _fileLoggingEnabled = false;
  static bool _initialized = false;

  // 文件写入
  static IOSink? _fileSink;
  static String? _currentLogFile;
  static const int _maxLogFiles = 7; // 保留 7 天日志
  static int _writeCount = 0; // 写入计数（用于定期刷新）
  static const int _flushInterval = 20; // 每 20 条日志刷新一次

  /// 初始化 Logger
  ///
  /// [enableFileLogging] 是否启用文件日志（默认开启，Web 不支持）
  /// [minLevel] 最低日志级别（Release 模式默认 info，Debug 模式默认 verbose）
  static Future<void> init({
    bool enableFileLogging = true,
    LogLevel? minLevel,
  }) async {
    if (_initialized) return;

    if (minLevel != null) {
      _minLevel = minLevel;
    }

    _fileLoggingEnabled = enableFileLogging && !kIsWeb;

    if (_fileLoggingEnabled) {
      await _initFileLogging();
      await _cleanupOldLogs();
    }

    _initialized = true;
    final logStatus =
        _fileLoggingEnabled
            ? 'on, path=${_currentLogFile ?? "unknown"}'
            : 'off';
    i(
      'Log',
      'Logger initialized (file=$logStatus, minLevel=${_minLevel.name})',
    );

    // 额外在控制台输出一次完整路径
    if (_fileLoggingEnabled && _currentLogFile != null) {
      debugPrint('📝 Log file: $_currentLogFile');
    }
  }

  /// Verbose 级别日志
  static void v(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.verbose, tag, message, error, stackTrace);
  }

  /// Debug 级别日志
  static void d(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.debug, tag, message, error, stackTrace);
  }

  /// Info 级别日志
  static void i(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.info, tag, message, error, stackTrace);
  }

  /// Warning 级别日志
  static void w(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.warning, tag, message, error, stackTrace);
  }

  /// Error 级别日志
  static void e(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.error, tag, message, error, stackTrace);
  }

  /// 核心日志方法
  static void _log(
    LogLevel level,
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // 级别过滤
    if (level.priority < _minLevel.priority) return;

    // Release 模式下跳过 verbose 和 debug
    if (kReleaseMode && level.priority < LogLevel.info.priority) return;

    final timestamp = DateTime.now();
    final formatted = _formatLog(
      timestamp,
      level,
      tag,
      message,
      error,
      stackTrace,
    );

    // 控制台输出
    debugPrint(formatted);

    // 文件写入（异步，不阻塞）
    if (_fileLoggingEnabled && _fileSink != null) {
      try {
        _fileSink!.writeln(formatted);
        _writeCount++;

        // 定期异步刷新到磁盘（每 10 条日志或遇到 Error/Warning）
        if (_writeCount >= _flushInterval ||
            level.priority >= LogLevel.warning.priority) {
          // 使用 unawaited 异步刷新，不阻塞当前日志写入
          unawaited(_fileSink!.flush());
          _writeCount = 0;
        }
      } catch (e) {
        // 静默处理写入错误，避免影响应用运行
        debugPrint('[Log] Write error: $e');
      }
    }
  }

  /// 格式化日志
  static String _formatLog(
    DateTime timestamp,
    LogLevel level,
    String tag,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final buffer = StringBuffer();

    // 时间戳
    final ts =
        '${timestamp.year.toString().padLeft(4, '0')}-'
        '${timestamp.month.toString().padLeft(2, '0')}-'
        '${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';

    buffer.write('$ts [${level.symbol}/$tag] $message');

    if (error != null) {
      buffer.write('\n  Error: $error');
    }

    if (stackTrace != null) {
      buffer.write('\n  StackTrace: $stackTrace');
    }

    return buffer.toString();
  }

  /// 初始化文件日志
  static Future<void> _initFileLogging() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final date = DateTime.now();
      final fileName =
          'cc_monitor_${date.year}'
          '${date.month.toString().padLeft(2, '0')}'
          '${date.day.toString().padLeft(2, '0')}.log';
      _currentLogFile = '${logDir.path}/$fileName';

      final file = File(_currentLogFile!);
      _fileSink = file.openWrite(mode: FileMode.append);
    } catch (e) {
      debugPrint('[Log] Failed to init file logging: $e');
      _fileLoggingEnabled = false;
    }
  }

  /// 清理旧日志文件
  static Future<void> _cleanupOldLogs() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/logs');

      if (!await logDir.exists()) return;

      final files =
          await logDir.list().where((f) => f.path.endsWith('.log')).toList();

      if (files.length <= _maxLogFiles) return;

      // 按修改时间排序
      final fileStats = <FileSystemEntity, DateTime>{};
      for (final file in files) {
        final stat = await (file as File).stat();
        fileStats[file] = stat.modified;
      }

      files.sort((a, b) {
        return fileStats[b]!.compareTo(fileStats[a]!);
      });

      // 删除超出保留数量的文件
      for (var i = _maxLogFiles; i < files.length; i++) {
        await (files[i] as File).delete();
      }
    } catch (e) {
      debugPrint('[Log] Failed to cleanup logs: $e');
    }
  }

  /// 获取日志文件列表
  static Future<List<File>> getLogFiles() async {
    if (kIsWeb) return [];

    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/logs');

      if (!await logDir.exists()) return [];

      final files = <File>[];
      await for (final entity in logDir.list()) {
        if (entity.path.endsWith('.log')) {
          files.add(entity as File);
        }
      }
      return files;
    } catch (e) {
      return [];
    }
  }

  /// 获取当前日志文件路径
  static String? get currentLogFile => _currentLogFile;

  /// 获取日志系统状态（用于调试）
  static Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'fileLoggingEnabled': _fileLoggingEnabled,
      'currentLogFile': _currentLogFile,
      'minLevel': _minLevel.name,
      'isWeb': kIsWeb,
      'writeCount': _writeCount,
    };
  }

  /// 关闭日志服务
  static Future<void> close() async {
    await _fileSink?.flush();
    await _fileSink?.close();
    _fileSink = null;
    _initialized = false;
  }

  /// 设置最低日志级别
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// 启用/禁用文件日志
  static Future<void> setFileLogging(bool enabled) async {
    if (kIsWeb) return;
    if (enabled == _fileLoggingEnabled) return;

    _fileLoggingEnabled = enabled;

    if (enabled) {
      await _initFileLogging();
    } else {
      await _fileSink?.close();
      _fileSink = null;
    }
  }

  /// 刷新文件缓冲
  static Future<void> flush() async {
    await _fileSink?.flush();
  }
}
