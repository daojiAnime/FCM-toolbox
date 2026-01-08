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
      padding: const EdgeInsets.all(16),
      children: [
        // 在线机器
        if (onlineMachines.isNotEmpty) ...[
          _buildSectionHeader(context, '在线', onlineMachines.length),
          const SizedBox(height: 8),
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
          if (onlineMachines.isNotEmpty) const SizedBox(height: 24),
          _buildSectionHeader(context, '离线', offlineMachines.length),
          const SizedBox(height: 8),
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

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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

/// 机器卡片
class _MachineCard extends StatelessWidget {
  const _MachineCard({required this.machine, this.onSpawn});

  final HapiMachine machine;
  final VoidCallback? onSpawn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = machine.isOnline;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onSpawn,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 状态图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      isOnline
                          ? MessageColors.complete.withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getPlatformIcon(machine.platform),
                  color:
                      isOnline
                          ? MessageColors.complete
                          : theme.colorScheme.outline,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // 机器信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            machine.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 在线状态指示器
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                isOnline
                                    ? MessageColors.complete
                                    : theme.colorScheme.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      machine.hostname ?? machine.id,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (machine.lastSeenAt != null && !isOnline) ...[
                      const SizedBox(height: 2),
                      Text(
                        '上次在线: ${_formatLastSeen(machine.lastSeenAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 启动按钮
              if (isOnline && onSpawn != null)
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: onSpawn,
                  tooltip: '启动会话',
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
            ],
          ),
        ),
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
  String _selectedModel = 'sonnet';

  final List<(String, String)> _models = [
    ('sonnet', 'Claude Sonnet (推荐)'),
    ('opus', 'Claude Opus'),
    ('haiku', 'Claude Haiku'),
  ];

  @override
  void dispose() {
    _projectPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spawnState = ref.watch(spawnSessionProvider);

    return AlertDialog(
      title: Text('在 ${widget.machine.name} 上启动会话'),
      content: SingleChildScrollView(
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

            // 模型选择
            Text(
              '模型',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            ...(_models.map((model) {
              return RadioListTile<String>(
                value: model.$1,
                groupValue: _selectedModel,
                title: Text(model.$2),
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedModel = value);
                  }
                },
              );
            })),

            // 错误提示
            if (spawnState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        spawnState.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
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

    final success = await notifier.spawnSession(
      machineId: widget.machine.id,
      projectPath: projectPath.isNotEmpty ? projectPath : null,
      model: _selectedModel,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('会话已启动'), backgroundColor: Colors.green),
      );
    }
  }
}
