import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// GitHub 更新信息
class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final String tagName;
  final DateTime publishedAt;
  final int size;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.tagName,
    required this.publishedAt,
    required this.size,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

/// 更新状态
sealed class UpdateState {}

class UpdateStateIdle extends UpdateState {}

class UpdateStateChecking extends UpdateState {}

class UpdateStateAvailable extends UpdateState {
  final UpdateInfo info;
  UpdateStateAvailable(this.info);
}

class UpdateStateNoUpdate extends UpdateState {}

class UpdateStateDownloading extends UpdateState {
  final int progress;
  UpdateStateDownloading(this.progress);
}

class UpdateStateInstalling extends UpdateState {}

class UpdateStateError extends UpdateState {
  final String message;
  UpdateStateError(this.message);
}

/// GitHub 更新服务 Provider
final githubUpdateServiceProvider =
    StateNotifierProvider<GitHubUpdateService, UpdateState>((ref) {
      return GitHubUpdateService();
    });

/// GitHub 更新服务
class GitHubUpdateService extends StateNotifier<UpdateState> {
  GitHubUpdateService() : super(UpdateStateIdle());

  static const String _owner = 'daojiAnime';
  static const String _repo = 'FCM-toolbox';
  static const String _tagPrefix = 'cc-monitor-v';

  final Dio _dio = Dio();

  /// 检查更新
  Future<UpdateInfo?> checkForUpdate() async {
    if (!Platform.isAndroid) {
      debugPrint('OTA 更新仅支持 Android');
      return null;
    }

    state = UpdateStateChecking();

    try {
      final currentVersion = await _getCurrentVersion();
      debugPrint('当前版本: $currentVersion');

      final response = await _dio.get(
        'https://api.github.com/repos/$_owner/$_repo/releases/latest',
        options: Options(headers: {'Accept': 'application/vnd.github.v3+json'}),
      );

      if (response.statusCode != 200) {
        state = UpdateStateError('获取更新信息失败: ${response.statusCode}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final tagName = data['tag_name'] as String;

      // 验证 tag 格式
      if (!tagName.startsWith(_tagPrefix)) {
        debugPrint('非 CC Monitor 版本: $tagName');
        state = UpdateStateNoUpdate();
        return null;
      }

      final latestVersion = tagName.replaceFirst(_tagPrefix, '');
      debugPrint('最新版本: $latestVersion');

      if (!_isNewerVersion(latestVersion, currentVersion)) {
        debugPrint('已是最新版本');
        state = UpdateStateNoUpdate();
        return null;
      }

      // 查找 APK 资产
      final assets = data['assets'] as List;
      final apkAsset = assets.cast<Map<String, dynamic>>().firstWhere(
        (a) => a['name'].toString().endsWith('.apk'),
        orElse: () => <String, dynamic>{},
      );

      if (apkAsset.isEmpty) {
        state = UpdateStateError('未找到 APK 下载链接');
        return null;
      }

      final info = UpdateInfo(
        version: latestVersion,
        downloadUrl: apkAsset['browser_download_url'] as String,
        releaseNotes: data['body'] as String? ?? '暂无更新说明',
        tagName: tagName,
        publishedAt: DateTime.parse(data['published_at'] as String),
        size: apkAsset['size'] as int? ?? 0,
      );

      state = UpdateStateAvailable(info);
      return info;
    } on DioException catch (e) {
      final message =
          e.response?.statusCode == 404 ? '未找到发布版本' : '网络错误: ${e.message}';
      state = UpdateStateError(message);
      return null;
    } catch (e) {
      state = UpdateStateError('检查更新失败: $e');
      return null;
    }
  }

  /// 下载并安装更新
  Future<void> downloadAndInstall(UpdateInfo info) async {
    if (!Platform.isAndroid) {
      state = UpdateStateError('OTA 更新仅支持 Android');
      return;
    }

    state = UpdateStateDownloading(0);

    try {
      OtaUpdate()
          .execute(
            info.downloadUrl,
            destinationFilename: 'cc-monitor-${info.version}.apk',
          )
          .listen(
            (event) {
              debugPrint('OTA 状态: ${event.status} - ${event.value}');

              switch (event.status) {
                case OtaStatus.DOWNLOADING:
                  final progress = int.tryParse(event.value ?? '0') ?? 0;
                  state = UpdateStateDownloading(progress);
                case OtaStatus.INSTALLING:
                  state = UpdateStateInstalling();
                case OtaStatus.INSTALLATION_DONE:
                  debugPrint('安装完成');
                  state = UpdateStateIdle();
                case OtaStatus.ALREADY_RUNNING_ERROR:
                  state = UpdateStateError('已有下载任务在进行中');
                case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                  state = UpdateStateError('缺少安装权限，请在设置中允许安装未知应用');
                case OtaStatus.INTERNAL_ERROR:
                  state = UpdateStateError('内部错误: ${event.value}');
                case OtaStatus.DOWNLOAD_ERROR:
                  state = UpdateStateError('下载失败: ${event.value}');
                case OtaStatus.CHECKSUM_ERROR:
                  state = UpdateStateError('文件校验失败');
                case OtaStatus.INSTALLATION_ERROR:
                  state = UpdateStateError('安装失败: ${event.value}');
                case OtaStatus.CANCELED:
                  debugPrint('更新已取消');
                  state = UpdateStateIdle();
              }
            },
            onError: (e) {
              debugPrint('OTA 错误: $e');
              state = UpdateStateError('更新失败: $e');
            },
            onDone: () {
              debugPrint('OTA 完成');
            },
          );
    } catch (e) {
      state = UpdateStateError('启动更新失败: $e');
    }
  }

  /// 重置状态
  void reset() {
    state = UpdateStateIdle();
  }

  /// 获取当前版本
  Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// 比较版本号
  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      // 确保两个列表长度相同
      while (latestParts.length < 3) {
        latestParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      debugPrint('版本比较失败: $e');
      return false;
    }
  }
}
