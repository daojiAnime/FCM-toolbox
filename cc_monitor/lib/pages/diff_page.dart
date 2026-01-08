import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../common/colors.dart';
import '../services/hapi/hapi_api_service.dart';

/// Git Diff 页面
class DiffPage extends ConsumerStatefulWidget {
  const DiffPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<DiffPage> createState() => _DiffPageState();
}

class _DiffPageState extends ConsumerState<DiffPage> {
  bool _isLoading = false;
  String? _error;
  List<HapiDiff> _diffs = [];
  String? _selectedFilePath;

  @override
  void initState() {
    super.initState();
    _loadDiffs();
  }

  Future<void> _loadDiffs() async {
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
      final diffs = await apiService.getSessionDiff(widget.sessionId);
      setState(() {
        _diffs = diffs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('变更差异'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDiffs,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_diffs.isEmpty) {
      return _buildEmptyState();
    }

    // 使用分栏布局：左侧文件列表，右侧 diff 内容
    return LayoutBuilder(
      builder: (context, constraints) {
        // 宽屏使用分栏布局
        if (constraints.maxWidth > 600) {
          return Row(
            children: [
              // 左侧文件列表
              SizedBox(width: 280, child: _buildFileList()),
              const VerticalDivider(width: 1),
              // 右侧 diff 内容
              Expanded(
                child:
                    _selectedFilePath != null
                        ? _buildDiffContent(
                          _diffs.firstWhere(
                            (d) => d.filePath == _selectedFilePath,
                            orElse: () => _diffs.first,
                          ),
                        )
                        : _buildSelectFileHint(),
              ),
            ],
          );
        }

        // 窄屏使用列表布局
        return _buildFileListWithDiff();
      },
    );
  }

  Widget _buildErrorState() {
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
              onPressed: _loadDiffs,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: MessageColors.complete,
            ),
            const SizedBox(height: 16),
            Text('暂无变更', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '当前会话没有文件变更',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList() {
    // 统计变更
    final added = _diffs.where((d) => d.status == 'added').length;
    final modified = _diffs.where((d) => d.status == 'modified').length;
    final deleted = _diffs.where((d) => d.status == 'deleted').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 统计信息
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildStatChip('+$added', Colors.green),
              const SizedBox(width: 8),
              _buildStatChip('~$modified', Colors.orange),
              const SizedBox(width: 8),
              _buildStatChip('-$deleted', Colors.red),
            ],
          ),
        ),
        const Divider(height: 1),
        // 文件列表
        Expanded(
          child: ListView.builder(
            itemCount: _diffs.length,
            itemBuilder: (context, index) {
              final diff = _diffs[index];
              final isSelected = diff.filePath == _selectedFilePath;
              return _DiffFileListTile(
                diff: diff,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedFilePath = diff.filePath);
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

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSelectFileHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '选择文件查看变更',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffContent(HapiDiff diff) {
    final theme = Theme.of(context);

    if (diff.patch == null || diff.patch!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(diff.status),
              size: 48,
              color: _getStatusColor(diff.status),
            ),
            const SizedBox(height: 16),
            Text(
              _getStatusText(diff.status),
              style: theme.textTheme.titleMedium?.copyWith(
                color: _getStatusColor(diff.status),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              diff.filePath,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    // 解析 diff 内容
    final lines = diff.patch!.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 文件信息头
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                _getStatusIcon(diff.status),
                size: 18,
                color: _getStatusColor(diff.status),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  diff.filePath,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (diff.additions != null || diff.deletions != null) ...[
                const SizedBox(width: 8),
                if (diff.additions != null && diff.additions! > 0)
                  Text(
                    '+${diff.additions}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                if (diff.deletions != null && diff.deletions! > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '-${diff.deletions}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        // Diff 内容
        Expanded(
          child: ListView.builder(
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final line = lines[index];
              return _DiffLine(line: line);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFileListWithDiff() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _diffs.length,
      itemBuilder: (context, index) {
        final diff = _diffs[index];
        return _DiffCard(diff: diff).animate().fadeIn(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 50),
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    return switch (status) {
      'added' => Icons.add_circle_outline,
      'deleted' => Icons.remove_circle_outline,
      'modified' => Icons.edit_outlined,
      'renamed' => Icons.drive_file_rename_outline,
      _ => Icons.help_outline,
    };
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'added' => Colors.green,
      'deleted' => Colors.red,
      'modified' => Colors.orange,
      'renamed' => Colors.blue,
      _ => Colors.grey,
    };
  }

  String _getStatusText(String status) {
    return switch (status) {
      'added' => '新增文件',
      'deleted' => '删除文件',
      'modified' => '修改文件',
      'renamed' => '重命名文件',
      _ => '未知状态',
    };
  }
}

/// 文件列表项
class _DiffFileListTile extends StatelessWidget {
  const _DiffFileListTile({
    required this.diff,
    required this.isSelected,
    required this.onTap,
  });

  final HapiDiff diff;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = diff.filePath.split('/').last;

    return ListTile(
      selected: isSelected,
      leading: Icon(
        _getStatusIcon(diff.status),
        color: _getStatusColor(diff.status),
        size: 20,
      ),
      title: Text(
        fileName,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        diff.filePath,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
          fontFamily: 'monospace',
          fontSize: 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (diff.additions != null && diff.additions! > 0)
            Text(
              '+${diff.additions}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          if (diff.deletions != null && diff.deletions! > 0) ...[
            const SizedBox(width: 4),
            Text(
              '-${diff.deletions}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  IconData _getStatusIcon(String status) {
    return switch (status) {
      'added' => Icons.add,
      'deleted' => Icons.remove,
      'modified' => Icons.edit,
      'renamed' => Icons.arrow_forward,
      _ => Icons.help_outline,
    };
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'added' => Colors.green,
      'deleted' => Colors.red,
      'modified' => Colors.orange,
      'renamed' => Colors.blue,
      _ => Colors.grey,
    };
  }
}

/// Diff 行
class _DiffLine extends StatelessWidget {
  const _DiffLine({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color? textColor;

    if (line.startsWith('+') && !line.startsWith('+++')) {
      bgColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green.shade700;
    } else if (line.startsWith('-') && !line.startsWith('---')) {
      bgColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red.shade700;
    } else if (line.startsWith('@@')) {
      bgColor = Colors.blue.withValues(alpha: 0.1);
      textColor = Colors.blue.shade700;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      color: bgColor,
      child: Text(
        line,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: textColor,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Diff 卡片（窄屏布局）
class _DiffCard extends StatelessWidget {
  const _DiffCard({required this.diff});

  final HapiDiff diff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = diff.filePath.split('/').last;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文件头
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(diff.status),
                  size: 18,
                  color: _getStatusColor(diff.status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        diff.filePath,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (diff.additions != null || diff.deletions != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (diff.additions != null && diff.additions! > 0)
                        Text(
                          '+${diff.additions}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      if (diff.deletions != null && diff.deletions! > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '-${diff.deletions}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          // Diff 内容预览
          if (diff.patch != null && diff.patch!.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView(
                shrinkWrap: true,
                children:
                    diff.patch!
                        .split('\n')
                        .take(20)
                        .map((line) => _DiffLine(line: line))
                        .toList(),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    return switch (status) {
      'added' => Icons.add_circle_outline,
      'deleted' => Icons.remove_circle_outline,
      'modified' => Icons.edit_outlined,
      'renamed' => Icons.drive_file_rename_outline,
      _ => Icons.help_outline,
    };
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'added' => Colors.green,
      'deleted' => Colors.red,
      'modified' => Colors.orange,
      'renamed' => Colors.blue,
      _ => Colors.grey,
    };
  }
}
