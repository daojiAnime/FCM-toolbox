import '../../common/logger.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// hapi 配置模型
class HapiConfig {
  const HapiConfig({
    this.serverUrl = '',
    this.apiToken = '',
    this.enabled = false,
  });

  /// hapi server URL (例如: https://your-tunnel.trycloudflare.com)
  final String serverUrl;

  /// CLI_API_TOKEN 用于认证
  final String apiToken;

  /// 是否启用 hapi 功能
  final bool enabled;

  /// 配置是否有效（有服务器地址和 Token）
  bool get isConfigured => serverUrl.isNotEmpty && apiToken.isNotEmpty;

  HapiConfig copyWith({String? serverUrl, String? apiToken, bool? enabled}) {
    return HapiConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      apiToken: apiToken ?? this.apiToken,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  String toString() {
    return 'HapiConfig(serverUrl: $serverUrl, apiToken: ${apiToken.isNotEmpty ? "***" : ""}, enabled: $enabled)';
  }
}

/// hapi 配置状态管理
class HapiConfigNotifier extends StateNotifier<HapiConfig> {
  HapiConfigNotifier() : super(const HapiConfig());

  SharedPreferences? _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // 标记 SecureStorage 是否可用（macOS 无签名时不可用）
  bool _secureStorageAvailable = true;

  // 存储键
  static const _keyServerUrl = 'hapi_server_url';
  static const _keyApiToken = 'hapi_api_token';
  static const _keyApiTokenFallback = 'hapi_api_token_fallback'; // 回退存储
  static const _keyEnabled = 'hapi_enabled';

  /// 初始化配置
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadConfig();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    if (_prefs == null) return;

    final serverUrl = _prefs!.getString(_keyServerUrl) ?? '';
    final enabled = _prefs!.getBool(_keyEnabled) ?? false;

    // Token 优先从安全存储读取，失败或为空则从 SharedPreferences 回退读取
    String apiToken = '';
    try {
      apiToken = await _secureStorage.read(key: _keyApiToken) ?? '';
      _secureStorageAvailable = true;
    } catch (e) {
      Log.e('HapiCfg', 'SecureStorage not available: $e');
      _secureStorageAvailable = false;
    }

    // 如果 SecureStorage 为空，尝试从 fallback 读取
    if (apiToken.isEmpty) {
      final fallbackToken = _prefs!.getString(_keyApiTokenFallback);
      if (fallbackToken != null && fallbackToken.isNotEmpty) {
        apiToken = fallbackToken;
      }
    }

    state = HapiConfig(
      serverUrl: serverUrl,
      apiToken: apiToken,
      enabled: enabled,
    );
  }

  /// 保存服务器地址
  Future<void> setServerUrl(String url) async {
    // 清理 URL（移除尾部斜杠）
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    state = state.copyWith(serverUrl: cleanUrl);
    await _prefs?.setString(_keyServerUrl, cleanUrl);
  }

  /// 保存 API Token（优先安全存储，失败则回退到 SharedPreferences）
  Future<void> setApiToken(String token) async {
    state = state.copyWith(apiToken: token);

    if (_secureStorageAvailable) {
      try {
        await _secureStorage.write(key: _keyApiToken, value: token);
        // 成功后清理回退存储
        await _prefs?.remove(_keyApiTokenFallback);
        return;
      } catch (e) {
        Log.w(
          'HapiCfg',
          'Failed to save to secure storage, using fallback: $e',
        );
        _secureStorageAvailable = false;
      }
    }

    // 回退：存储到 SharedPreferences（注意：安全性较低，仅用于开发测试）
    await _prefs?.setString(_keyApiTokenFallback, token);
  }

  /// 设置是否启用
  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await _prefs?.setBool(_keyEnabled, enabled);
  }

  /// 保存完整配置
  Future<void> saveConfig({
    required String serverUrl,
    required String apiToken,
    bool? enabled,
  }) async {
    await setServerUrl(serverUrl);
    await setApiToken(apiToken);
    if (enabled != null) {
      await setEnabled(enabled);
    }
  }

  /// 清除配置
  Future<void> clearConfig() async {
    state = const HapiConfig();
    await _prefs?.remove(_keyServerUrl);
    await _prefs?.remove(_keyEnabled);
    await _prefs?.remove(_keyApiTokenFallback);
    try {
      await _secureStorage.delete(key: _keyApiToken);
    } catch (e) {
      Log.w('HapiCfg', 'Failed to delete token: $e');
    }
  }
}

/// hapi 配置 Provider
final hapiConfigProvider =
    StateNotifierProvider<HapiConfigNotifier, HapiConfig>((ref) {
      return HapiConfigNotifier();
    });

/// hapi 是否已配置 Provider
final hapiIsConfiguredProvider = Provider<bool>((ref) {
  return ref.watch(hapiConfigProvider).isConfigured;
});

/// hapi 是否启用 Provider
final hapiIsEnabledProvider = Provider<bool>((ref) {
  final config = ref.watch(hapiConfigProvider);
  return config.enabled && config.isConfigured;
});
