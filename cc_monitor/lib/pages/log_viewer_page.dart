import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../common/logger.dart';
import '../services/toast_service.dart';

/// 日志查看页面
class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key});

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  List<File> _logFiles = [];
  File? _selectedFile;
  String _logContent = '';
  bool _isLoading = false;
  bool _autoScroll = true;
  final _scrollController = ScrollController();

  // 过滤条件
  String _filterTag = '';
  String _filterText = '';
  String _filterLevel = 'All';

  @override
  void initState() {
    super.initState();
    _loadLogFiles();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await Log.getLogFiles();
      // 按修改时间倒序排列（最新的在前）
      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });
      setState(() {
        _logFiles = files;
        if (files.isNotEmpty) {
          _selectedFile = files.first; // 默认选择最新的
          _loadLogContent();
        }
      });
    } catch (e) {
      ToastService().error('加载日志文件失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLogContent() async {
    if (_selectedFile == null) return;

    setState(() => _isLoading = true);
    try {
      final content = await _selectedFile!.readAsString();
      setState(() => _logContent = content);

      // 自动滚动到底部
      if (_autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      }
    } catch (e) {
      ToastService().error('读取日志失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 过滤日志内容
  List<String> get _filteredLines {
    final lines = _logContent.split('\n');
    return lines.where((line) {
      if (line.trim().isEmpty) return false;

      // 级别过滤
      if (_filterLevel != 'All') {
        if (!line.contains('[$_filterLevel/')) return false;
      }

      // Tag 过滤
      if (_filterTag.isNotEmpty) {
        if (!line.contains(_filterTag)) return false;
      }

      // 文本过滤
      if (_filterText.isNotEmpty) {
        if (!line.toLowerCase().contains(_filterText.toLowerCase()))
          return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('日志查看器'),
        actions: [
          // 调试信息
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDebugInfo,
            tooltip: '调试信息',
          ),
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogFiles,
            tooltip: '刷新',
          ),
          // 分享按钮
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _selectedFile != null ? _shareLog : null,
            tooltip: '分享日志',
          ),
          // 复制按钮
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLog,
            tooltip: '复制日志',
          ),
          // 清空日志
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmClearLogs,
            tooltip: '清空日志',
          ),
        ],
      ),
      body: Column(
        children: [
          // 文件选择栏
          _buildFileSelector(colorScheme),

          // 过滤栏
          _buildFilterBar(colorScheme),

          // 日志内容
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildLogContent(colorScheme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          setState(() => _autoScroll = !_autoScroll);
          if (_autoScroll && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        },
        tooltip: _autoScroll ? '自动滚动已启用' : '自动滚动已禁用',
        child: Icon(_autoScroll ? Icons.arrow_downward : Icons.stop),
      ),
    );
  }

  Widget _buildFileSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const Icon(Icons.description, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<File>(
              isExpanded: true,
              value: _selectedFile,
              hint: const Text('选择日志文件'),
              items:
                  _logFiles.map((file) {
                    final fileName = file.path.split('/').last;
                    final stat = file.statSync();
                    final size = (stat.size / 1024).toStringAsFixed(1);
                    return DropdownMenuItem(
                      value: file,
                      child: Text('$fileName ($size KB)'),
                    );
                  }).toList(),
              onChanged: (file) {
                setState(() => _selectedFile = file);
                _loadLogContent();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: colorScheme.surfaceContainerHigh,
      child: Row(
        children: [
          // 级别过滤
          DropdownButton<String>(
            value: _filterLevel,
            items:
                ['All', 'V', 'D', 'I', 'W', 'E']
                    .map(
                      (level) =>
                          DropdownMenuItem(value: level, child: Text(level)),
                    )
                    .toList(),
            onChanged: (level) {
              setState(() => _filterLevel = level ?? 'All');
            },
          ),
          const SizedBox(width: 8),
          // Tag 过滤
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Filter by tag...',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              onChanged: (value) {
                setState(() => _filterTag = value);
              },
            ),
          ),
          const SizedBox(width: 8),
          // 文本过滤
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Filter by text...',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              onChanged: (value) {
                setState(() => _filterText = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogContent(ColorScheme colorScheme) {
    if (_selectedFile == null) {
      return const Center(child: Text('没有日志文件'));
    }

    final filteredLines = _filteredLines;

    if (filteredLines.isEmpty) {
      return const Center(child: Text('没有匹配的日志'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredLines.length,
      itemBuilder: (context, index) {
        final line = filteredLines[index];
        return _buildLogLine(line, colorScheme);
      },
    );
  }

  Widget _buildLogLine(String line, ColorScheme colorScheme) {
    // 解析日志级别
    Color? levelColor;
    if (line.contains('[V/')) {
      levelColor = Colors.grey;
    } else if (line.contains('[D/')) {
      levelColor = Colors.blue;
    } else if (line.contains('[I/')) {
      levelColor = Colors.green;
    } else if (line.contains('[W/')) {
      levelColor = Colors.orange;
    } else if (line.contains('[E/')) {
      levelColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: SelectableText(
        line,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: levelColor ?? colorScheme.onSurface,
        ),
      ),
    );
  }

  Future<void> _shareLog() async {
    if (_selectedFile == null) return;

    try {
      await Share.shareXFiles([
        XFile(_selectedFile!.path),
      ], subject: 'CC Monitor 日志');
    } catch (e) {
      ToastService().error('分享失败: $e');
    }
  }

  Future<void> _copyLog() async {
    if (_logContent.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _logContent));
    ToastService().success('日志已复制到剪贴板');
  }

  Future<void> _confirmClearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('清空日志'),
            content: const Text('确定要删除所有日志文件吗？此操作不可恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确定'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _clearAllLogs();
    }
  }

  Future<void> _clearAllLogs() async {
    try {
      for (final file in _logFiles) {
        await file.delete();
      }
      setState(() {
        _logFiles = [];
        _selectedFile = null;
        _logContent = '';
      });
      ToastService().success('日志已清空');
    } catch (e) {
      ToastService().error('清空失败: $e');
    }
  }

  /// 显示调试信息
  void _showDebugInfo() {
    final status = Log.getStatus();
    final buffer = StringBuffer();

    buffer.writeln('📊 日志系统状态\n');
    buffer.writeln('已初始化: ${status['initialized']}');
    buffer.writeln('文件日志: ${status['fileLoggingEnabled']}');
    buffer.writeln('最低级别: ${status['minLevel']}');
    buffer.writeln('Web 平台: ${status['isWeb']}');
    buffer.writeln('写入计数: ${status['writeCount']}');
    buffer.writeln('\n📁 日志文件路径:');
    buffer.writeln(status['currentLogFile'] ?? '(未配置)');
    buffer.writeln('\n📂 文件列表:');
    buffer.writeln('找到 ${_logFiles.length} 个日志文件');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('调试信息'),
            content: SingleChildScrollView(
              child: SelectableText(
                buffer.toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: buffer.toString()),
                  );
                  ToastService().success('已复制到剪贴板');
                },
                child: const Text('复制'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }
}
