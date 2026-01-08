import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

/// 设置页面
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // FCM Token 部分
          _buildSection(
            context,
            title: '推送配置',
            children: [
              ListTile(
                leading: const Icon(Icons.key),
                title: const Text('FCM Token'),
                subtitle: Text(
                  settings.fcmToken != null
                      ? '${settings.fcmToken!.substring(0, 20)}...'
                      : '未获取',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: settings.fcmToken != null
                    ? IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: settings.fcmToken!),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Token 已复制')),
                          );
                        },
                      )
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('配对设备'),
                subtitle: const Text('扫描二维码配对 Claude Code'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: 显示配对二维码
                  _showPairingDialog(context, settings.fcmToken);
                },
              ),
            ],
          ),

          // 通知设置
          _buildSection(
            context,
            title: '通知',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: const Text('启用通知'),
                subtitle: const Text('接收 Claude Code 的推送通知'),
                value: settings.enableNotifications,
                onChanged: (value) {
                  ref
                      .read(settingsProvider.notifier)
                      .setEnableNotifications(value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.volume_up),
                title: const Text('通知声音'),
                value: settings.enableSound,
                onChanged: settings.enableNotifications
                    ? (value) {
                        ref
                            .read(settingsProvider.notifier)
                            .setEnableSound(value);
                      }
                    : null,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: const Text('通知震动'),
                value: settings.enableVibration,
                onChanged: settings.enableNotifications
                    ? (value) {
                        ref
                            .read(settingsProvider.notifier)
                            .setEnableVibration(value);
                      }
                    : null,
              ),
            ],
          ),

          // 显示设置
          _buildSection(
            context,
            title: '显示',
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('主题'),
                trailing: DropdownButton<ThemeMode>(
                  value: settings.themeMode,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('跟随系统'),
                    ),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('浅色')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('深色')),
                  ],
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(settingsProvider.notifier).setThemeMode(mode);
                    }
                  },
                ),
              ),
            ],
          ),

          // 消息设置
          _buildSection(
            context,
            title: '消息',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.mark_email_read),
                title: const Text('自动标记已读'),
                subtitle: const Text('查看消息时自动标记为已读'),
                value: settings.autoMarkRead,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setAutoMarkRead(value);
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_delete),
                title: const Text('消息保留时间'),
                trailing: DropdownButton<int>(
                  value: settings.keepMessagesForDays,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 天')),
                    DropdownMenuItem(value: 3, child: Text('3 天')),
                    DropdownMenuItem(value: 7, child: Text('7 天')),
                    DropdownMenuItem(value: 14, child: Text('14 天')),
                    DropdownMenuItem(value: 30, child: Text('30 天')),
                  ],
                  onChanged: (days) {
                    if (days != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .setKeepMessagesForDays(days);
                    }
                  },
                ),
              ),
            ],
          ),

          // 关于
          _buildSection(
            context,
            title: '关于',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('版本'),
                trailing: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('GitHub'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  // TODO: 打开 GitHub 链接
                },
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  void _showPairingDialog(BuildContext context, String? token) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('配对设备'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (token != null) ...[
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_2,
                    size: 150,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '在 Claude Code 配置中扫描此二维码',
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                '尚未获取 FCM Token\n请确保已启用通知权限',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          if (token != null)
            FilledButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Token 已复制')));
              },
              child: const Text('复制 Token'),
            ),
        ],
      ),
    );
  }
}
