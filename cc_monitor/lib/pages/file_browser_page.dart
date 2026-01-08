import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../services/hapi/hapi_api_service.dart';

/// 文件浏览器页面
class FileBrowserPage extends ConsumerStatefulWidget {
  const FileBrowserPage({super.key, required this.sessionId, this.initialPath});

  final String sessionId;
  final String? initialPath;

  @override
  ConsumerState<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends ConsumerState<FileBrowserPage> {
  String _currentPath = '';
  final List<String> _pathHistory = [];
  bool _isLoading = false;
  String? _error;
  List<HapiFile> _files = [];

  // 文件内容查看
  String? _viewingFilePath;
  String? _fileContent;
  bool _isLoadingContent = false;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath ?? '';
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final apiService = ref.read(hapiApiServiceProvider);
    if (apiService == null) {
      setState(() => _error = 'hapi 服务未配置');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final files = await apiService.getSessionFiles(
        widget.sessionId,
        path: _currentPath.isNotEmpty ? _currentPath : null,
      );

      // 排序：目录在前，文件在后，按名称排序
      files.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.compareTo(b.name);
      });

      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToDirectory(String dirPath) {
    _pathHistory.add(_currentPath);
    setState(() {
      _currentPath = dirPath;
      _viewingFilePath = null;
      _fileContent = null;
    });
    _loadFiles();
  }

  void _navigateBack() {
    if (_viewingFilePath != null) {
      setState(() {
        _viewingFilePath = null;
        _fileContent = null;
      });
      return;
    }

    if (_pathHistory.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _currentPath = _pathHistory.removeLast();
    });
    _loadFiles();
  }

  Future<void> _viewFile(HapiFile file) async {
    final apiService = ref.read(hapiApiServiceProvider);
    if (apiService == null) return;

    setState(() {
      _viewingFilePath = file.path;
      _isLoadingContent = true;
      _fileContent = null;
    });

    try {
      final content = await apiService.getFileContent(
        widget.sessionId,
        file.path,
      );
      setState(() {
        _fileContent = content;
        _isLoadingContent = false;
      });
    } catch (e) {
      setState(() {
        _fileContent = '无法加载文件内容: $e';
        _isLoadingContent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateBack,
        ),
        title: Text(
          _viewingFilePath != null
              ? _getFileName(_viewingFilePath!)
              : _currentPath.isEmpty
              ? '项目文件'
              : _getFileName(_currentPath),
        ),
        actions: [
          if (_viewingFilePath == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadFiles,
              tooltip: '刷新',
            ),
        ],
      ),
      body: _viewingFilePath != null ? _buildFileViewer() : _buildFileBrowser(),
    );
  }

  Widget _buildFileBrowser() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadFiles,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('空目录', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 路径面包屑
        _buildBreadcrumb(),
        const Divider(height: 1),
        // 文件列表
        Expanded(
          child: ListView.builder(
            itemCount: _files.length,
            itemBuilder: (context, index) {
              final file = _files[index];
              return _FileListTile(
                file: file,
                onTap: () {
                  if (file.isDirectory) {
                    _navigateToDirectory(file.path);
                  } else {
                    _viewFile(file);
                  }
                },
              ).animate().fadeIn(
                duration: const Duration(milliseconds: 200),
                delay: Duration(milliseconds: index * 30),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    final parts = _currentPath.split('/').where((p) => p.isNotEmpty).toList();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 根目录
          TextButton.icon(
            onPressed: () {
              if (_currentPath.isNotEmpty) {
                _pathHistory.clear();
                setState(() => _currentPath = '');
                _loadFiles();
              }
            },
            icon: const Icon(Icons.home, size: 18),
            label: const Text('根目录'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          // 路径部分
          ...parts.asMap().entries.map((entry) {
            final index = entry.key;
            final part = entry.value;
            final fullPath = parts.sublist(0, index + 1).join('/');

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Theme.of(context).colorScheme.outline,
                ),
                TextButton(
                  onPressed:
                      index == parts.length - 1
                          ? null
                          : () {
                            _pathHistory.add(_currentPath);
                            setState(() => _currentPath = fullPath);
                            _loadFiles();
                          },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    part,
                    style:
                        index == parts.length - 1
                            ? TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            )
                            : null,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFileViewer() {
    if (_isLoadingContent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_fileContent == null) {
      return const Center(child: Text('无内容'));
    }

    final language = _getLanguage(_viewingFilePath ?? '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(0),
      child: HighlightView(
        _fileContent!,
        language: language,
        theme: atomOneDarkTheme,
        padding: const EdgeInsets.all(16),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  String _getFileName(String path) {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  String _getLanguage(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'dart' => 'dart',
      'js' => 'javascript',
      'ts' => 'typescript',
      'jsx' || 'tsx' => 'javascript',
      'py' => 'python',
      'rb' => 'ruby',
      'go' => 'go',
      'rs' => 'rust',
      'java' => 'java',
      'kt' => 'kotlin',
      'swift' => 'swift',
      'c' || 'h' => 'c',
      'cpp' || 'hpp' || 'cc' => 'cpp',
      'cs' => 'csharp',
      'php' => 'php',
      'html' || 'htm' => 'html',
      'css' => 'css',
      'scss' || 'sass' => 'scss',
      'json' => 'json',
      'yaml' || 'yml' => 'yaml',
      'xml' => 'xml',
      'md' || 'markdown' => 'markdown',
      'sql' => 'sql',
      'sh' || 'bash' => 'bash',
      'dockerfile' => 'dockerfile',
      'makefile' => 'makefile',
      _ => 'plaintext',
    };
  }
}

/// 文件列表项
class _FileListTile extends StatelessWidget {
  const _FileListTile({required this.file, required this.onTap});

  final HapiFile file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        file.isDirectory ? Icons.folder : _getFileIcon(file.name),
        color:
            file.isDirectory
                ? Colors.amber.shade700
                : theme.colorScheme.primary,
      ),
      title: Text(
        file.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: file.isDirectory ? FontWeight.w500 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle:
          file.isDirectory
              ? null
              : Text(
                _formatSize(file.size),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
      trailing:
          file.isDirectory
              ? Icon(Icons.chevron_right, color: theme.colorScheme.outline)
              : null,
      onTap: onTap,
    );
  }

  IconData _getFileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'dart' => Icons.code,
      'js' || 'ts' || 'jsx' || 'tsx' => Icons.javascript,
      'py' => Icons.code,
      'html' || 'htm' => Icons.html,
      'css' || 'scss' || 'sass' => Icons.css,
      'json' => Icons.data_object,
      'yaml' || 'yml' => Icons.settings,
      'md' || 'markdown' => Icons.description,
      'png' || 'jpg' || 'jpeg' || 'gif' || 'svg' || 'webp' => Icons.image,
      'pdf' => Icons.picture_as_pdf,
      'zip' || 'tar' || 'gz' || 'rar' => Icons.archive,
      'lock' => Icons.lock,
      _ => Icons.insert_drive_file,
    };
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
