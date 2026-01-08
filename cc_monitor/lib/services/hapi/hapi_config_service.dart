import 'package:flutter/foundation.dart';
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

  // 存储键
  static const _keyServerUrl = 'hapi_server_url';
  static const _keyApiToken = 'hapi_api_token';
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

    // Token 从安全存储读取
    String apiToken = '';
    try {
      apiToken = await _secureStorage.read(key: _keyApiToken) ?? '';
    } catch (e) {
      debugPrint('Failed to read hapi token from secure storage: $e');
    }

    state = HapiConfig(
      serverUrl: serverUrl,
      apiToken: apiToken,
      enabled: enabled,
    );

    debugPrint('HapiConfig loaded: ${state.toString()}');
  }

  /// 保存服务器地址
  Future<void> setServerUrl(String url) async {
    // 清理 URL（移除尾部斜杠）
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    state = state.copyWith(serverUrl: cleanUrl);
    await _prefs?.setString(_keyServerUrl, cleanUrl);
  }

  /// 保存 API Token（安全存储）
  Future<void> setApiToken(String token) async {
    state = state.copyWith(apiToken: token);
    try {
      await _secureStorage.write(key: _keyApiToken, value: token);
    } catch (e) {
      debugPrint('Failed to save hapi token to secure storage: $e');
    }
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
    try {
      await _secureStorage.delete(key: _keyApiToken);
    } catch (e) {
      debugPrint('Failed to delete hapi token from secure storage: $e');
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
