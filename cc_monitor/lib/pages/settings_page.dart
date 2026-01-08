import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../services/github_update_service.dart';
import '../services/hapi/hapi_config_service.dart';
import 'debug_page.dart';
import 'hapi_settings_page.dart';

const _kGitHubUrl = 'https://github.com/daojiAnime/FCM-toolbox';

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
          // 推送配置部分
          _buildSection(
            context,
            title: '推送配置',
            children: [
              // Device ID（Firestore 模式）
              ListTile(
                leading: const Icon(Icons.devices),
                title: const Text('Device ID'),
                subtitle: Text(
                  '${settings.deviceId.substring(0, 8)}...',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: settings.deviceId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Device ID 已复制')),
                    );
                  },
                ),
              ),
              // FCM Token
              ListTile(
                leading: const Icon(Icons.key),
                title: const Text('FCM Token'),
                subtitle: Text(
                  settings.fcmToken != null
                      ? '${settings.fcmToken!.substring(0, 20)}...'
                      : '未获取（需要 APNs 配置）',
                  style: theme.textTheme.bodySmall,
                ),
                trailing:
                    settings.fcmToken != null
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
                  _showPairingDialog(context, settings);
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
                onChanged:
                    settings.enableNotifications
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
                onChanged:
                    settings.enableNotifications
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

          // 高级功能
          _buildSection(
            context,
            title: '高级功能',
            children: [_buildHapiConfigTile(context, ref)],
          ),

          // 开发调试
          _buildSection(
            context,
            title: '开发调试',
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('Firestore 调试'),
                subtitle: const Text('测试实时消息接收'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DebugPage()),
                  );
                },
              ),
            ],
          ),

          // 关于
          _buildSection(
            context,
            title: '关于',
            children: [
              _buildVersionTile(context, ref),
              if (Platform.isAndroid) _buildUpdateTile(context, ref),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('GitHub'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  final uri = Uri.parse(_kGitHubUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
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

  Widget _buildHapiConfigTile(BuildContext context, WidgetRef ref) {
    final hapiConfig = ref.watch(hapiConfigProvider);
    final isConfigured = hapiConfig.isConfigured;
    final isEnabled = hapiConfig.enabled && isConfigured;

    return ListTile(
      leading: Icon(Icons.cloud_sync, color: isEnabled ? Colors.green : null),
      title: const Text('hapi 远程控制'),
      subtitle: Text(
        isEnabled
            ? '已连接'
            : isConfigured
            ? '已配置（未启用）'
            : '未配置',
        style: TextStyle(color: isEnabled ? Colors.green : null),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isConfigured)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isEnabled ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HapiSettingsPage()),
        );
      },
    );
  }

  Widget _buildVersionTile(BuildContext context, WidgetRef ref) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '...';
        final buildNumber = snapshot.data?.buildNumber ?? '';
        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('版本'),
          trailing: Text(
            '$version${buildNumber.isNotEmpty ? '+$buildNumber' : ''}',
          ),
        );
      },
    );
  }

  Widget _buildUpdateTile(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(githubUpdateServiceProvider);

    return ListTile(
      leading: const Icon(Icons.system_update),
      title: const Text('检查更新'),
      subtitle: _buildUpdateSubtitle(updateState),
      trailing: _buildUpdateTrailing(updateState),
      onTap: () async {
        if (updateState is UpdateStateDownloading ||
            updateState is UpdateStateInstalling) {
          return;
        }

        final service = ref.read(githubUpdateServiceProvider.notifier);
        final info = await service.checkForUpdate();

        if (info != null && context.mounted) {
          _showUpdateDialog(context, ref, info);
        } else if (updateState is UpdateStateNoUpdate && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已是最新版本')));
        }
      },
    );
  }

  Widget? _buildUpdateSubtitle(UpdateState state) {
    return switch (state) {
      UpdateStateChecking() => const Text('正在检查...'),
      UpdateStateAvailable(info: final info) => Text('新版本 ${info.version} 可用'),
      UpdateStateDownloading(progress: final p) => Text('下载中 $p%'),
      UpdateStateInstalling() => const Text('正在安装...'),
      UpdateStateError(message: final m) => Text(
        m,
        style: const TextStyle(color: Colors.red),
      ),
      _ => null,
    };
  }

  Widget? _buildUpdateTrailing(UpdateState state) {
    return switch (state) {
      UpdateStateChecking() => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      UpdateStateAvailable() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '有更新',
          style: TextStyle(color: Colors.green, fontSize: 12),
        ),
      ),
      UpdateStateDownloading(progress: final p) => SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(value: p / 100, strokeWidth: 3),
      ),
      UpdateStateInstalling() => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      _ => const Icon(Icons.chevron_right),
    };
  }

  void _showUpdateDialog(BuildContext context, WidgetRef ref, UpdateInfo info) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.system_update, color: Colors.green),
                const SizedBox(width: 8),
                Text('发现新版本 ${info.version}'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 版本信息
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.tagName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '大小: ${info.formattedSize}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${info.publishedAt.month}/${info.publishedAt.day}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 更新说明
                  const Text(
                    '更新说明',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Text(
                        info.releaseNotes,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('稍后'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ref
                      .read(githubUpdateServiceProvider.notifier)
                      .downloadAndInstall(info);
                },
                icon: const Icon(Icons.download),
                label: const Text('立即更新'),
              ),
            ],
          ),
    );
  }

  void _showPairingDialog(BuildContext context, AppSettings settings) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('配对设备'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Device ID (Firestore 模式 - 始终可用)
                const Text(
                  'Firestore 模式（推荐）:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          settings.deviceId,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: settings.deviceId),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Device ID 已复制')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // FCM Token (如果可用)
                if (settings.fcmToken != null) ...[
                  const Text(
                    'FCM 模式:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${settings.fcmToken!.substring(0, 30)}...',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: settings.fcmToken!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('FCM Token 已复制')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Text(
                    'FCM 模式:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '未配置（需要 APNs 证书）',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  '使用方法:\n'
                  '1. 复制 Device ID\n'
                  '2. 在 Claude Code Hook 配置中使用:\n'
                  '   --device-id <YOUR_DEVICE_ID>',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }
}
