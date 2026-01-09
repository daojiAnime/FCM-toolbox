import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../common/colors.dart';
import '../providers/machines_provider.dart';
import '../services/hapi/hapi_api_service.dart';
import '../services/hapi/hapi_config_service.dart';
import '../services/hapi/hapi_sse_service.dart';

/// 机器列表页面
class MachinesPage extends ConsumerStatefulWidget {
  const MachinesPage({super.key});

  @override
  ConsumerState<MachinesPage> createState() => _MachinesPageState();
}

class _MachinesPageState extends ConsumerState<MachinesPage> {
  @override
  Widget build(BuildContext context) {
    final hapiConfig = ref.watch(hapiConfigProvider);
    final isConnected = ref.watch(hapiIsConnectedProvider);
    final machinesAsync = ref.watch(machinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('机器列表'),
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(machinesProvider),
            tooltip: '刷新',
          ),
        ],
      ),
      body:
          !hapiConfig.enabled || !hapiConfig.isConfigured
              ? _buildNotConfiguredState(context)
              : !isConnected
              ? _buildNotConnectedState(context)
              : machinesAsync.when(
                data:
                    (machines) =>
                        machines.isEmpty
                            ? _buildEmptyState(context)
                            : _buildMachinesList(context, machines),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(context, error),
              ),
      floatingActionButton:
          hapiConfig.enabled && isConnected
              ? FloatingActionButton.extended(
                heroTag: 'machines_new_session',
                onPressed: () => _showSpawnDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('新建会话'),
              )
              : null,
    );
  }

  Widget _buildNotConfiguredState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('hapi 未配置', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '请先在设置中配置 hapi 服务器',
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

  Widget _buildNotConnectedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('未连接到 hapi', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '请检查网络连接和 hapi 服务器状态',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(machinesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.computer_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('暂无已连接的机器', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '在您的机器上运行 hapi 以连接到服务器',
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

  Widget _buildErrorState(BuildContext context, Object error) {
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
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(machinesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachinesList(BuildContext context, List<HapiMachine> machines) {
    // 分组：在线和离线
    final onlineMachines = machines.where((m) => m.isOnline).toList();
    final offlineMachines = machines.where((m) => !m.isOnline).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        // 在线机器
        if (onlineMachines.isNotEmpty) ...[
          _buildSectionHeader(context, '在线', onlineMachines.length),
          const SizedBox(height: 6),
          ...onlineMachines.asMap().entries.map((entry) {
            return _MachineCard(
              machine: entry.value,
              onSpawn: () => _showSpawnDialogForMachine(context, entry.value),
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 300),
              delay: Duration(milliseconds: entry.key * 50),
            );
          }),
        ],

        // 离线机器
        if (offlineMachines.isNotEmpty) ...[
          if (onlineMachines.isNotEmpty) const SizedBox(height: 16),
          _buildSectionHeader(context, '离线', offlineMachines.length),
          const SizedBox(height: 6),
          ...offlineMachines.asMap().entries.map((entry) {
            return _MachineCard(
              machine: entry.value,
              onSpawn: null, // 离线机器不能启动会话
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 300),
              delay: Duration(
                milliseconds: (onlineMachines.length + entry.key) * 50,
              ),
            );
          }),
        ],
      ],
    );
  }

  /// 紧凑的分组标题
  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示新建会话对话框（选择机器）
  void _showSpawnDialog(BuildContext context) {
    final machinesAsync = ref.read(machinesProvider);
    final onlineMachines =
        machinesAsync.whenOrNull(
          data: (machines) => machines.where((m) => m.isOnline).toList(),
        ) ??
        [];

    if (onlineMachines.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有在线的机器')));
      return;
    }

    if (onlineMachines.length == 1) {
      // 只有一台机器，直接显示启动对话框
      _showSpawnDialogForMachine(context, onlineMachines.first);
      return;
    }

    // 多台机器，先选择机器
    showModalBottomSheet(
      context: context,
      builder:
          (context) => _MachineSelectionSheet(
            machines: onlineMachines,
            onSelect: (machine) {
              Navigator.pop(context);
              _showSpawnDialogForMachine(context, machine);
            },
          ),
    );
  }

  /// 在指定机器上启动会话
  void _showSpawnDialogForMachine(BuildContext context, HapiMachine machine) {
    showDialog(
      context: context,
      builder: (context) => _SpawnSessionDialog(machine: machine),
    );
  }
}

/// 机器卡片 - 紧凑风格，显示更多信息
class _MachineCard extends StatelessWidget {
  const _MachineCard({required this.machine, this.onSpawn});

  final HapiMachine machine;
  final VoidCallback? onSpawn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = machine.isOnline;
    final statusColor =
        isOnline ? MessageColors.complete : theme.colorScheme.outline;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onSpawn,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // 平台图标 + 状态指示
              _buildPlatformIcon(theme, isOnline, statusColor),
              const SizedBox(width: 12),

              // 主信息区
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 第一行：名称 + 状态标签
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            machine.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(theme, isOnline, statusColor),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 第二行：平台 + 端口 + CLI 版本
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildInfoChip(
                          theme,
                          Icons.memory_outlined,
                          machine.platformDisplayName,
                        ),
                        if (machine.httpPort != null)
                          _buildInfoChip(
                            theme,
                            Icons.lan_outlined,
                            ':${machine.httpPort}',
                          ),
                        if (machine.cliVersion != null)
                          _buildInfoChip(
                            theme,
                            Icons.code_outlined,
                            machine.cliVersion!,
                          ),
                        if (machine.daemonStatus != null &&
                            machine.daemonStatus != 'running')
                          _buildInfoChip(
                            theme,
                            Icons.settings_outlined,
                            machine.daemonStatus!,
                            isWarning: true,
                          ),
                      ],
                    ),

                    // 离线时显示上次在线时间
                    if (!isOnline && machine.lastSeenAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '上次在线 ${_formatLastSeen(machine.lastSeenAt!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 启动按钮
              if (isOnline && onSpawn != null) ...[
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  onPressed: onSpawn,
                  tooltip: '启动会话',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 平台图标带状态环
  Widget _buildPlatformIcon(ThemeData theme, bool isOnline, Color statusColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Icon(
        _getPlatformIcon(machine.platform),
        color: statusColor,
        size: 20,
      ),
    );
  }

  /// 在线状态标签
  Widget _buildStatusBadge(ThemeData theme, bool isOnline, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? '在线' : '离线',
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// 信息标签
  Widget _buildInfoChip(
    ThemeData theme,
    IconData icon,
    String text, {
    bool isWarning = false,
  }) {
    final color =
        isWarning
            ? theme.colorScheme.error
            : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  IconData _getPlatformIcon(String? platform) {
    return switch (platform?.toLowerCase()) {
      'darwin' || 'macos' => Icons.apple,
      'win32' || 'windows' => Icons.desktop_windows,
      'linux' => Icons.computer,
      _ => Icons.devices,
    };
  }

  String _formatLastSeen(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小时前';
    } else {
      return '${diff.inDays} 天前';
    }
  }
}

/// 机器选择底部弹窗
class _MachineSelectionSheet extends StatelessWidget {
  const _MachineSelectionSheet({
    required this.machines,
    required this.onSelect,
  });

  final List<HapiMachine> machines;
  final void Function(HapiMachine) onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '选择机器',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            itemCount: machines.length,
            itemBuilder: (context, index) {
              final machine = machines[index];
              return ListTile(
                leading: Icon(_getPlatformIcon(machine.platform)),
                title: Text(machine.name),
                subtitle: Text(machine.hostname ?? machine.id),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onSelect(machine),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getPlatformIcon(String? platform) {
    return switch (platform?.toLowerCase()) {
      'darwin' || 'macos' => Icons.apple,
      'win32' || 'windows' => Icons.desktop_windows,
      'linux' => Icons.computer,
      _ => Icons.devices,
    };
  }
}

/// 启动会话对话框
class _SpawnSessionDialog extends ConsumerStatefulWidget {
  const _SpawnSessionDialog({required this.machine});

  final HapiMachine machine;

  @override
  ConsumerState<_SpawnSessionDialog> createState() =>
      _SpawnSessionDialogState();
}

class _SpawnSessionDialogState extends ConsumerState<_SpawnSessionDialog> {
  final _projectPathController = TextEditingController();
  final _worktreeNameController = TextEditingController();
  String _selectedAgent = 'claude';
  bool _yoloMode = false;
  String? _sessionType;
  bool _showAdvanced = false;

  static const _agents = [
    ('claude', 'Claude Code', 'Anthropic Claude（推荐）'),
    ('codex', 'Codex', 'OpenAI Codex'),
    ('gemini', 'Gemini', 'Google Gemini'),
  ];

  /// 会话类型 (与 Web 版 @hapi/protocol 对齐)
  static const _sessionTypes = [
    (null, '默认', '标准交互模式'),
    ('plan', '计划模式', '仅规划不执行'),
    ('acceptEdits', '自动编辑', '自动批准文件修改'),
    ('bypassPermissions', '完全自动', '自动批准所有操作'),
  ];

  @override
  void dispose() {
    _projectPathController.dispose();
    _worktreeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spawnState = ref.watch(spawnSessionProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('在 ${widget.machine.name} 上启动会话'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 项目路径输入
              TextField(
                controller: _projectPathController,
                decoration: const InputDecoration(
                  labelText: '项目路径（可选）',
                  hintText: '/path/to/project',
                  prefixIcon: Icon(Icons.folder_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Agent 选择
              Text(
                '代理',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments:
                    _agents.map((a) {
                      return ButtonSegment(
                        value: a.$1,
                        label: Text(a.$2),
                        tooltip: a.$3,
                      );
                    }).toList(),
                selected: {_selectedAgent},
                onSelectionChanged: (values) {
                  setState(() => _selectedAgent = values.first);
                },
              ),
              const SizedBox(height: 16),

              // 快捷选项
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    selected: _yoloMode,
                    label: const Text('YOLO 模式'),
                    avatar: Icon(
                      Icons.flash_on,
                      size: 18,
                      color:
                          _yoloMode
                              ? theme.colorScheme.onSecondaryContainer
                              : null,
                    ),
                    tooltip: '跳过所有确认',
                    onSelected: (v) => setState(() => _yoloMode = v),
                  ),
                ],
              ),

              // 高级选项展开
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _showAdvanced ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '高级选项',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 高级选项内容
              if (_showAdvanced) ...[
                const SizedBox(height: 8),
                // 会话类型
                DropdownButtonFormField<String?>(
                  initialValue: _sessionType,
                  decoration: const InputDecoration(
                    labelText: '会话类型',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _sessionTypes.map((t) {
                        return DropdownMenuItem(
                          value: t.$1,
                          child: Text('${t.$2} - ${t.$3}'),
                        );
                      }).toList(),
                  onChanged: (v) => setState(() => _sessionType = v),
                ),
                const SizedBox(height: 12),

                // Worktree 名称
                TextField(
                  controller: _worktreeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Worktree 名称（可选）',
                    hintText: 'feature-branch',
                    prefixIcon: Icon(Icons.account_tree),
                    border: OutlineInputBorder(),
                    helperText: '创建 Git worktree 分支',
                  ),
                ),
              ],

              // 错误提示
              if (spawnState.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          spawnState.error!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              spawnState.isSpawning ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: spawnState.isSpawning ? null : _spawnSession,
          child:
              spawnState.isSpawning
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('启动'),
        ),
      ],
    );
  }

  Future<void> _spawnSession() async {
    final notifier = ref.read(spawnSessionProvider.notifier);
    final projectPath = _projectPathController.text.trim();
    final worktreeName = _worktreeNameController.text.trim();

    final success = await notifier.spawnSession(
      machineId: widget.machine.id,
      projectPath: projectPath.isNotEmpty ? projectPath : null,
      agent: _selectedAgent,
      yolo: _yoloMode ? true : null,
      sessionType: _sessionType,
      worktreeName: worktreeName.isNotEmpty ? worktreeName : null,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('会话已启动'), backgroundColor: Colors.green),
      );
    }
  }
}
