import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// 终端字体配置
enum TerminalFontFamily {
  cascadiaCode('CascadiaCodeNF', 'Cascadia Code'),
  jetBrainsMono('JetBrainsMonoNF', 'JetBrains Mono'),
  firaCode('FiraCodeNF', 'Fira Code'),
  hack('HackNF', 'Hack'),
  sourceCodePro('SourceCodeProNF', 'Source Code Pro'),
  meslo('MesloNF', 'Meslo'),
  system('monospace', '系统默认');

  const TerminalFontFamily(this.fontFamily, this.displayName);
  final String fontFamily;
  final String displayName;
}

/// 应用设置
class AppSettings {
  const AppSettings({
    required this.deviceId,
    this.fcmToken,
    this.themeMode = ThemeMode.system,
    this.enableNotifications = true,
    this.enableSound = true,
    this.enableVibration = true,
    this.autoMarkRead = false,
    this.keepMessagesForDays = 7,
    this.terminalFont = TerminalFontFamily.cascadiaCode,
    this.terminalFontSize = 14.0,
  });

  /// 设备唯一标识符（用于 Firestore 消息路由）
  final String deviceId;
  final String? fcmToken;
  final ThemeMode themeMode;
  final bool enableNotifications;
  final bool enableSound;
  final bool enableVibration;
  final bool autoMarkRead;
  final int keepMessagesForDays;
  final TerminalFontFamily terminalFont;
  final double terminalFontSize;

  AppSettings copyWith({
    String? deviceId,
    String? fcmToken,
    ThemeMode? themeMode,
    bool? enableNotifications,
    bool? enableSound,
    bool? enableVibration,
    bool? autoMarkRead,
    int? keepMessagesForDays,
    TerminalFontFamily? terminalFont,
    double? terminalFontSize,
  }) {
    return AppSettings(
      deviceId: deviceId ?? this.deviceId,
      fcmToken: fcmToken ?? this.fcmToken,
      themeMode: themeMode ?? this.themeMode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      autoMarkRead: autoMarkRead ?? this.autoMarkRead,
      keepMessagesForDays: keepMessagesForDays ?? this.keepMessagesForDays,
      terminalFont: terminalFont ?? this.terminalFont,
      terminalFontSize: terminalFontSize ?? this.terminalFontSize,
    );
  }
}

/// 设置状态管理
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings(deviceId: const Uuid().v4()));

  SharedPreferences? _prefs;
  static const _uuid = Uuid();

  // 安全存储实例(用于加密敏感数据)
  // Android 使用 KeyStore 加密, iOS 使用 Keychain
  static const _secureStorage = FlutterSecureStorage();

  // 安全存储的 key
  static const _fcmTokenKey = 'secure_fcm_token';

  /// 初始化设置
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    // 生成或加载 deviceId
    var deviceId = _prefs!.getString('deviceId');
    if (deviceId == null) {
      deviceId = _uuid.v4();
      await _prefs!.setString('deviceId', deviceId);
    }

    final themeModeIndex = _prefs!.getInt('themeMode') ?? 0;
    final themeMode = ThemeMode.values[themeModeIndex];

    // 从安全存储加载 FCM Token(支持向后兼容迁移)
    String? fcmToken;
    try {
      // 优先从安全存储读取
      fcmToken = await _secureStorage.read(key: _fcmTokenKey);

      // 向后兼容:检查旧的 SharedPreferences 是否有 token
      if (fcmToken == null) {
        final oldToken = _prefs!.getString('fcmToken');
        if (oldToken != null && oldToken.isNotEmpty) {
          // 迁移到安全存储
          await _secureStorage.write(key: _fcmTokenKey, value: oldToken);
          // 删除旧数据
          await _prefs!.remove('fcmToken');
          fcmToken = oldToken;
        }
      }
    } catch (e) {
      // 安全存储读取失败,回退到旧方式
      fcmToken = _prefs!.getString('fcmToken');
    }

    // 加载终端字体设置
    final terminalFontIndex = _prefs!.getInt('terminalFont') ?? 0;
    final terminalFont =
        TerminalFontFamily.values[terminalFontIndex.clamp(
          0,
          TerminalFontFamily.values.length - 1,
        )];
    final terminalFontSize = _prefs!.getDouble('terminalFontSize') ?? 14.0;

    state = AppSettings(
      deviceId: deviceId,
      fcmToken: fcmToken,
      themeMode: themeMode,
      enableNotifications: _prefs!.getBool('enableNotifications') ?? true,
      enableSound: _prefs!.getBool('enableSound') ?? true,
      enableVibration: _prefs!.getBool('enableVibration') ?? true,
      autoMarkRead: _prefs!.getBool('autoMarkRead') ?? false,
      keepMessagesForDays: _prefs!.getInt('keepMessagesForDays') ?? 7,
      terminalFont: terminalFont,
      terminalFontSize: terminalFontSize,
    );
  }

  /// 保存 FCM Token(使用加密存储)
  Future<void> setFcmToken(String token) async {
    state = state.copyWith(fcmToken: token);

    try {
      // 保存到加密存储
      await _secureStorage.write(key: _fcmTokenKey, value: token);
      // 清理可能存在的旧数据
      await _prefs?.remove('fcmToken');
    } catch (e) {
      // 如果加密存储失败,回退到普通存储(至少保证功能可用)
      await _prefs?.setString('fcmToken', token);
    }
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

  /// 设置终端字体
  Future<void> setTerminalFont(TerminalFontFamily font) async {
    state = state.copyWith(terminalFont: font);
    await _prefs?.setInt('terminalFont', font.index);
  }

  /// 设置终端字号
  Future<void> setTerminalFontSize(double size) async {
    state = state.copyWith(terminalFontSize: size.clamp(10.0, 24.0));
    await _prefs?.setDouble('terminalFontSize', size.clamp(10.0, 24.0));
  }
}

/// 设置 Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});

/// 主题模式 Provider
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

/// 终端字体 Provider
final terminalFontProvider = Provider<TerminalFontFamily>((ref) {
  return ref.watch(settingsProvider).terminalFont;
});

/// 终端字号 Provider
final terminalFontSizeProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).terminalFontSize;
});
