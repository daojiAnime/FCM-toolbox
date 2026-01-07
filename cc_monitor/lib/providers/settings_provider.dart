import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置
class AppSettings {
  const AppSettings({
    this.fcmToken,
    this.themeMode = ThemeMode.system,
    this.enableNotifications = true,
    this.enableSound = true,
    this.enableVibration = true,
    this.autoMarkRead = false,
    this.keepMessagesForDays = 7,
  });

  final String? fcmToken;
  final ThemeMode themeMode;
  final bool enableNotifications;
  final bool enableSound;
  final bool enableVibration;
  final bool autoMarkRead;
  final int keepMessagesForDays;

  AppSettings copyWith({
    String? fcmToken,
    ThemeMode? themeMode,
    bool? enableNotifications,
    bool? enableSound,
    bool? enableVibration,
    bool? autoMarkRead,
    int? keepMessagesForDays,
  }) {
    return AppSettings(
      fcmToken: fcmToken ?? this.fcmToken,
      themeMode: themeMode ?? this.themeMode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      autoMarkRead: autoMarkRead ?? this.autoMarkRead,
      keepMessagesForDays: keepMessagesForDays ?? this.keepMessagesForDays,
    );
  }
}

/// 设置状态管理
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  SharedPreferences? _prefs;

  /// 初始化设置
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    if (_prefs == null) return;

    final themeModeIndex = _prefs!.getInt('themeMode') ?? 0;
    final themeMode = ThemeMode.values[themeModeIndex];

    state = AppSettings(
      fcmToken: _prefs!.getString('fcmToken'),
      themeMode: themeMode,
      enableNotifications: _prefs!.getBool('enableNotifications') ?? true,
      enableSound: _prefs!.getBool('enableSound') ?? true,
      enableVibration: _prefs!.getBool('enableVibration') ?? true,
      autoMarkRead: _prefs!.getBool('autoMarkRead') ?? false,
      keepMessagesForDays: _prefs!.getInt('keepMessagesForDays') ?? 7,
    );
  }

  /// 保存 FCM Token
  Future<void> setFcmToken(String token) async {
    state = state.copyWith(fcmToken: token);
    await _prefs?.setString('fcmToken', token);
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs?.setInt('themeMode', mode.index);
  }

  /// 设置通知开关
  Future<void> setEnableNotifications(bool enable) async {
    state = state.copyWith(enableNotifications: enable);
    await _prefs?.setBool('enableNotifications', enable);
  }

  /// 设置声音开关
  Future<void> setEnableSound(bool enable) async {
    state = state.copyWith(enableSound: enable);
    await _prefs?.setBool('enableSound', enable);
  }

  /// 设置震动开关
  Future<void> setEnableVibration(bool enable) async {
    state = state.copyWith(enableVibration: enable);
    await _prefs?.setBool('enableVibration', enable);
  }

  /// 设置自动标记已读
  Future<void> setAutoMarkRead(bool enable) async {
    state = state.copyWith(autoMarkRead: enable);
    await _prefs?.setBool('autoMarkRead', enable);
  }

  /// 设置消息保留天数
  Future<void> setKeepMessagesForDays(int days) async {
    state = state.copyWith(keepMessagesForDays: days);
    await _prefs?.setInt('keepMessagesForDays', days);
  }
}

/// 设置 Provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

/// 主题模式 Provider
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});
