import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../common/colors.dart';
import '../services/hapi/hapi_api_service.dart';

/// hapi 会话管理页面
class SessionManagementPage extends ConsumerStatefulWidget {
  const SessionManagementPage({super.key});

  @override
  ConsumerState<SessionManagementPage> createState() =>
      _SessionManagementPageState();
}

class _SessionManagementPageState extends ConsumerState<SessionManagementPage> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  String? _error;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(hapiApiServiceProvider);
      if (apiService == null) {
        throw HapiApiException('hapi 服务未配置');
      }

      final sessions = await apiService.getSessions(forceRefresh: true);
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _activeSessions =>
      _sessions.where((s) => s['archived'] != true).toList();

  List<Map<String, dynamic>> get _archivedSessions =>
      _sessions.where((s) => s['archived'] == true).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('会话管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSessionDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('新建会话'),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState(theme);
    }

    if (_sessions.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          // 活跃会话
          if (_activeSessions.isNotEmpty) ...[
            _buildSectionHeader(theme, '活跃会话', _activeSessions.length),
            ..._activeSessions.asMap().entries.map((entry) {
              return _SessionTile(
                session: entry.value,
                onAction: _handleSessionAction,
              ).animate().fadeIn(
                duration: const Duration(milliseconds: 300),
                delay: Duration(milliseconds: entry.key * 50),
              );
            }),
          ],
          // 已归档会话
          if (_archivedSessions.isNotEmpty) ...[
            _buildArchivedHeader(theme),
            if (_showArchived)
              ..._archivedSessions.asMap().entries.map((entry) {
                return _SessionTile(
                  session: entry.value,
                  isArchived: true,
                  onAction: _handleSessionAction,
                ).animate().fadeIn(duration: const Duration(milliseconds: 200));
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('加载失败', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _error ?? '未知错误',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadSessions,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.terminal_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无会话',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮创建新会话',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedHeader(ThemeData theme) {
    return InkWell(
      onTap: () => setState(() => _showArchived = !_showArchived),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Text(
              '已归档',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_archivedSessions.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            Icon(
              _showArchived ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSessionAction(
    String sessionId,
    _SessionAction action,
  ) async {
    final apiService = ref.read(hapiApiServiceProvider);
    if (apiService == null) return;

    try {
      bool success = false;
      String message = '';

      switch (action) {
        case _SessionAction.switchTo:
          success = await apiService.switchSession(sessionId);
          message = success ? '已切换到会话' : '切换失败';
          break;
        case _SessionAction.abort:
          final confirmed = await _showConfirmDialog(
            context,
            title: '中止会话',
            content: '确定要中止此会话吗？当前任务将被终止。',
            confirmText: '中止',
            isDestructive: true,
          );
          if (confirmed == true) {
            success = await apiService.abortSession(sessionId);
            message = success ? '会话已中止' : '中止失败';
          }
          break;
        case _SessionAction.archive:
          success = await apiService.archiveSession(sessionId);
          message = success ? '会话已归档' : '归档失败';
          break;
        case _SessionAction.delete:
          final confirmed = await _showConfirmDialog(
            context,
            title: '删除会话',
            content: '确定要删除此会话吗？此操作无法撤销。',
            confirmText: '删除',
            isDestructive: true,
          );
          if (confirmed == true) {
            success = await apiService.deleteSession(sessionId);
            message = success ? '会话已删除' : '删除失败';
          }
          break;
        case _SessionAction.rename:
          final newName = await _showRenameDialog(context, sessionId);
          if (newName != null && newName.isNotEmpty) {
            success = await apiService.renameSession(sessionId, newName);
            message = success ? '已重命名' : '重命名失败';
          }
          break;
        case _SessionAction.setPermissionMode:
          final mode = await _showPermissionModeDialog(context);
          if (mode != null) {
            success = await apiService.setPermissionMode(sessionId, mode);
            message = success ? '权限模式已更新' : '设置失败';
          }
          break;
        case _SessionAction.setModel:
          final model = await _showModelDialog(context);
          if (model != null) {
            success = await apiService.setModel(sessionId, model);
            message = success ? '模型已更新' : '设置失败';
          }
          break;
      }

      if (message.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
        if (success) {
          _loadSessions();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style:
                    isDestructive
                        ? FilledButton.styleFrom(
                          backgroundColor: MessageColors.error,
                        )
                        : null,
                child: Text(confirmText),
              ),
            ],
          ),
    );
  }

  Future<String?> _showRenameDialog(
    BuildContext context,
    String sessionId,
  ) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('重命名会话'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '新名称',
                hintText: '输入会话名称',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }

  Future<String?> _showPermissionModeDialog(BuildContext context) {
    final modes = [
      ('default', '默认', '使用配置文件设置'),
      ('plan', '计划模式', '执行前需确认计划'),
      ('auto-edit', '自动编辑', '自动执行安全操作'),
      ('full-auto', '完全自动', '自动执行所有操作'),
      ('none', '无权限', '禁用所有自动操作'),
    ];

    return showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('选择权限模式'),
            children:
                modes.map((mode) {
                  return SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, mode.$1),
                    child: ListTile(
                      title: Text(mode.$2),
                      subtitle: Text(mode.$3),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  );
                }).toList(),
          ),
    );
  }

  Future<String?> _showModelDialog(BuildContext context) {
    final models = [
      ('sonnet', 'Claude Sonnet', '平衡性能与成本'),
      ('opus', 'Claude Opus', '最强性能'),
      ('haiku', 'Claude Haiku', '快速响应'),
    ];

    return showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('选择模型'),
            children:
                models.map((model) {
                  return SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, model.$1),
                    child: ListTile(
                      title: Text(model.$2),
                      subtitle: Text(model.$3),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  );
                }).toList(),
          ),
    );
  }

  Future<void> _showCreateSessionDialog(BuildContext dialogContext) async {
    final controller = TextEditingController();
    final directory = await showDialog<String>(
      context: dialogContext,
      builder:
          (ctx) => AlertDialog(
            title: const Text('新建会话'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '项目目录',
                hintText: '例如: /Users/you/projects/my-app',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('创建'),
              ),
            ],
          ),
    );

    if (directory == null || directory.isEmpty || !mounted) return;

    try {
      final apiService = ref.read(hapiApiServiceProvider);
      if (apiService == null) return;

      final result = await apiService.createSession(directory: directory);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result != null ? '会话已创建' : '创建失败'),
          backgroundColor: result != null ? Colors.green : Colors.red,
        ),
      );
      if (result != null) {
        _loadSessions();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

/// 会话操作类型
enum _SessionAction {
  switchTo,
  abort,
  archive,
  delete,
  rename,
  setPermissionMode,
  setModel,
}

/// 会话卡片
class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.onAction,
    this.isArchived = false,
  });

  final Map<String, dynamic> session;
  final void Function(String sessionId, _SessionAction action) onAction;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionId = session['id'] as String? ?? '';
    final name =
        session['name'] as String? ??
        session['directory'] as String? ??
        'Unnamed';
    final directory = session['directory'] as String? ?? '';
    final model = session['model'] as String? ?? 'sonnet';
    final permissionMode = session['permissionMode'] as String? ?? 'default';
    final status = session['status'] as String? ?? '';
    final isActive = status == 'active' || status == 'waiting';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            isArchived
                ? null
                : () => onAction(sessionId, _SessionAction.switchTo),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  // 状态指示器
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isArchived
                              ? theme.colorScheme.outline
                              : isActive
                              ? Colors.green
                              : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 名称
                  Expanded(
                    child: Text(
                      name.split('/').last,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 操作菜单
                  _buildActionMenu(context, sessionId),
                ],
              ),
              const SizedBox(height: 8),
              // 目录
              if (directory.isNotEmpty)
                Text(
                  directory,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              // 标签
              Wrap(
                spacing: 8,
                children: [
                  _buildChip(context, _modelDisplayName(model), Icons.memory),
                  _buildChip(
                    context,
                    _permissionModeDisplayName(permissionMode),
                    Icons.security,
                  ),
                  if (status.isNotEmpty)
                    _buildChip(
                      context,
                      _statusDisplayName(status),
                      Icons.circle,
                      color: _statusColor(status),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context, String sessionId) {
    return PopupMenuButton<_SessionAction>(
      icon: const Icon(Icons.more_vert),
      itemBuilder:
          (context) => [
            if (!isArchived) ...[
              const PopupMenuItem(
                value: _SessionAction.switchTo,
                child: ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('切换到此会话'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _SessionAction.abort,
                child: ListTile(
                  leading: Icon(Icons.stop, color: Colors.orange),
                  title: Text('中止会话'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _SessionAction.archive,
                child: ListTile(
                  leading: Icon(Icons.archive),
                  title: Text('归档'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _SessionAction.setPermissionMode,
                child: ListTile(
                  leading: Icon(Icons.security),
                  title: Text('权限模式'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _SessionAction.setModel,
                child: ListTile(
                  leading: Icon(Icons.memory),
                  title: Text('切换模型'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
            ],
            const PopupMenuItem(
              value: _SessionAction.rename,
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('重命名'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (isArchived)
              const PopupMenuItem(
                value: _SessionAction.delete,
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('删除', style: TextStyle(color: Colors.red)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
      onSelected: (action) => onAction(sessionId, action),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label,
    IconData icon, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? theme.colorScheme.outline),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color ?? theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  String _modelDisplayName(String model) {
    return switch (model) {
      'sonnet' => 'Sonnet',
      'opus' => 'Opus',
      'haiku' => 'Haiku',
      _ => model,
    };
  }

  String _permissionModeDisplayName(String mode) {
    return switch (mode) {
      'default' => '默认',
      'plan' => '计划',
      'auto-edit' => '自动编辑',
      'full-auto' => '完全自动',
      'none' => '无权限',
      _ => mode,
    };
  }

  String _statusDisplayName(String status) {
    return switch (status) {
      'active' => '运行中',
      'waiting' => '等待中',
      'idle' => '空闲',
      'archived' => '已归档',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'active' => Colors.green,
      'waiting' => Colors.orange,
      'idle' => Colors.grey,
      _ => Colors.grey,
    };
  }
}
