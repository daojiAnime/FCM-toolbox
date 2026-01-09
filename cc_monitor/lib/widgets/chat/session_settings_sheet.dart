import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/session_provider.dart';
import '../../services/hapi/hapi_api_service.dart';
import '../../services/toast_service.dart';

/// 权限模式选项 (value, label, description)
/// 与 Web 版 @hapi/protocol 对齐: default, plan, acceptEdits, bypassPermissions
const _permissionModes = [
  ('default', '默认', '使用默认权限策略'),
  ('plan', '计划', '仅允许读取和规划'),
  ('acceptEdits', '自动编辑', '自动批准文件编辑'),
  ('bypassPermissions', '完全自动', '自动批准所有操作'),
];

/// 模型选项 (value, label)
const _modelOptions = [
  ('sonnet', 'Sonnet'),
  ('opus', 'Opus'),
  ('haiku', 'Haiku'),
];

/// 会话设置面板 - 紧凑模式
class SessionSettingsSheet extends ConsumerStatefulWidget {
  const SessionSettingsSheet({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SessionSettingsSheet> createState() =>
      _SessionSettingsSheetState();
}

class _SessionSettingsSheetState extends ConsumerState<SessionSettingsSheet> {
  String _selectedMode = 'default';
  String _selectedModel = 'sonnet';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final api = ref.read(hapiApiServiceProvider);
      if (api == null) throw Exception('API 服务不可用');

      final session = await api.getSession(widget.sessionId);
      if (mounted && session != null) {
        setState(() {
          _selectedMode = session['permissionMode'] as String? ?? 'default';
          _selectedModel = session['modelMode'] as String? ?? 'sonnet';
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

  Future<void> _setPermissionMode(String mode) async {
    if (_isSaving || mode == _selectedMode) return;

    final previousMode = _selectedMode;
    setState(() {
      _isSaving = true;
      _selectedMode = mode; // 乐观更新
    });

    try {
      final api = ref.read(hapiApiServiceProvider);
      if (api == null) throw Exception('API 服务不可用');

      final success = await api.setPermissionMode(widget.sessionId, mode);
      if (success) {
        // 同步更新 sessionsProvider
        final sessions = ref.read(sessionsProvider);
        final session = sessions.firstWhereOrNull(
          (s) => s.id == widget.sessionId,
        );
        if (session != null) {
          ref
              .read(sessionsProvider.notifier)
              .upsertSession(session.copyWith(permissionMode: mode));
        }
      } else {
        setState(() => _selectedMode = previousMode); // 回滚
        ToastService().error('更新失败');
      }
    } catch (e) {
      setState(() => _selectedMode = previousMode); // 回滚
      ToastService().error('更新失败: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _setModel(String model) async {
    if (_isSaving || model == _selectedModel) return;

    final previousModel = _selectedModel;
    setState(() {
      _isSaving = true;
      _selectedModel = model; // 乐观更新
    });

    try {
      final api = ref.read(hapiApiServiceProvider);
      if (api == null) throw Exception('API 服务不可用');

      final success = await api.setModel(widget.sessionId, model);
      if (success) {
        // 同步更新 sessionsProvider
        final sessions = ref.read(sessionsProvider);
        final session = sessions.firstWhereOrNull(
          (s) => s.id == widget.sessionId,
        );
        if (session != null) {
          ref
              .read(sessionsProvider.notifier)
              .upsertSession(session.copyWith(modelMode: model));
        }
      } else {
        setState(() => _selectedModel = previousModel); // 回滚
        ToastService().error('更新失败');
      }
    } catch (e) {
      setState(() => _selectedModel = previousModel); // 回滚
      ToastService().error('更新失败: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽手柄
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 标题栏
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Text(
                    '会话设置',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_isSaving) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // 内容
            _isLoading
                ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
                : _error != null
                ? _buildError(theme)
                : _buildContent(theme),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 32, color: theme.colorScheme.error),
          const SizedBox(height: 8),
          Text('加载失败', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadCurrentSettings();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 模型选择 - SegmentedButton
          _buildSectionLabel('模型', theme),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments:
                  _modelOptions
                      .map((m) => ButtonSegment(value: m.$1, label: Text(m.$2)))
                      .toList(),
              selected: {_selectedModel},
              onSelectionChanged:
                  _isSaving ? null : (set) => _setModel(set.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 权限模式 - Wrap + ChoiceChip
          _buildSectionLabel('权限模式', theme),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                _permissionModes.map((mode) {
                  final isSelected = _selectedMode == mode.$1;
                  return Tooltip(
                    message: mode.$3,
                    preferBelow: true,
                    child: ChoiceChip(
                      label: Text(mode.$2),
                      selected: isSelected,
                      onSelected:
                          _isSaving ? null : (_) => _setPermissionMode(mode.$1),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.outline,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
