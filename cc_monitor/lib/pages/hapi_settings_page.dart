import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hapi/hapi_config_service.dart';
import '../services/hapi/hapi_api_service.dart';

/// hapi 设置页面
class HapiSettingsPage extends ConsumerStatefulWidget {
  const HapiSettingsPage({super.key});

  @override
  ConsumerState<HapiSettingsPage> createState() => _HapiSettingsPageState();
}

class _HapiSettingsPageState extends ConsumerState<HapiSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _apiTokenController = TextEditingController();

  bool _isLoading = false;
  bool _obscureToken = true;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    // 延迟加载配置到输入框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(hapiConfigProvider);
      _serverUrlController.text = config.serverUrl;
      _apiTokenController.text = config.apiToken;
    });
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _apiTokenController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(hapiConfigProvider.notifier)
          .saveConfig(
            serverUrl: _serverUrlController.text.trim(),
            apiToken: _apiTokenController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配置已保存'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testConnection() async {
    if (_serverUrlController.text.isEmpty || _apiTokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先填写服务器地址和 Token'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = null;
      _testSuccess = null;
    });

    try {
      // 临时创建一个 API 服务来测试
      final tempConfig = HapiConfig(
        serverUrl: _serverUrlController.text.trim(),
        apiToken: _apiTokenController.text.trim(),
        enabled: true,
      );
      final tempService = HapiApiService(tempConfig);

      final result = await tempService.testConnection();

      setState(() {
        _testSuccess = result.success;
        _testResult =
            result.success ? '连接成功！服务器响应正常。' : '连接失败：${result.message}';
      });
    } on HapiApiException catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = '连接失败：${e.message}';
      });
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = '连接失败：$e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearConfig() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认清除'),
            content: const Text('确定要清除所有 hapi 配置吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('清除'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await ref.read(hapiConfigProvider.notifier).clearConfig();
      _serverUrlController.clear();
      _apiTokenController.clear();
      setState(() {
        _testResult = null;
        _testSuccess = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('配置已清除')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(hapiConfigProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('hapi 设置'),
        actions: [
          if (config.isConfigured)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearConfig,
              tooltip: '清除配置',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 说明卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '关于 hapi',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'hapi 是一个远程控制 Claude Code 的解决方案。'
                        '配置后可以实现远程发送消息、审批权限、查看文件等高级功能。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 服务器地址
              Text(
                '服务器地址',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _serverUrlController,
                decoration: InputDecoration(
                  hintText: 'https://your-tunnel.trycloudflare.com',
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon:
                      _serverUrlController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _serverUrlController.clear();
                              setState(() {});
                            },
                          )
                          : null,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入服务器地址';
                  }
                  if (!value.startsWith('http://') &&
                      !value.startsWith('https://')) {
                    return '请输入有效的 URL（以 http:// 或 https:// 开头）';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // API Token
              Text(
                'API Token',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '从 hapi server 获取的 CLI_API_TOKEN',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apiTokenController,
                decoration: InputDecoration(
                  hintText: 'your-cli-api-token',
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscureToken
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscureToken = !_obscureToken);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.paste),
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            _apiTokenController.text = data!.text!;
                            setState(() {});
                          }
                        },
                        tooltip: '粘贴',
                      ),
                    ],
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscureToken,
                autocorrect: false,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入 API Token';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 测试结果
              if (_testResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        _testSuccess == true
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _testSuccess == true ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testSuccess == true ? Icons.check_circle : Icons.error,
                        color: _testSuccess == true ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            color:
                                _testSuccess == true
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _testConnection,
                      icon:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.wifi_tethering),
                      label: const Text('测试连接'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _saveConfig,
                      icon: const Icon(Icons.save),
                      label: const Text('保存配置'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 启用开关
              if (config.isConfigured) ...[
                const Divider(),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('启用 hapi'),
                  subtitle: const Text('开启后将使用 hapi 进行消息交互'),
                  value: config.enabled,
                  onChanged: (value) {
                    ref.read(hapiConfigProvider.notifier).setEnabled(value);
                  },
                ),
              ],

              const SizedBox(height: 24),

              // 帮助信息
              ExpansionTile(
                title: const Text('如何获取配置？'),
                leading: const Icon(Icons.help_outline),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHelpStep(
                          '1',
                          '安装 hapi CLI',
                          'npm install -g @twsxtd/hapi',
                        ),
                        _buildHelpStep('2', '启动 hapi server', 'hapi server'),
                        _buildHelpStep(
                          '3',
                          '获取 Token',
                          '首次启动时会显示 CLI_API_TOKEN',
                        ),
                        _buildHelpStep(
                          '4',
                          '配置 Tunnel（可选）',
                          'cloudflared tunnel run --url http://localhost:3006',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '详细文档: https://github.com/tiann/hapi',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpStep(String number, String title, String code) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
