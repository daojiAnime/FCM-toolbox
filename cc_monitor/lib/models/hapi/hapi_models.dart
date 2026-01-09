/// 文件信息
class HapiFile {
  HapiFile({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.modifiedAt,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? modifiedAt;

  factory HapiFile.fromJson(Map<String, dynamic> json) {
    return HapiFile(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      isDirectory: json['isDirectory'] as bool? ?? json['type'] == 'directory',
      size: json['size'] as int?,
      modifiedAt:
          json['modifiedAt'] != null
              ? DateTime.tryParse(json['modifiedAt'] as String)
              : null,
    );
  }
}

/// Git Diff 信息
class HapiDiff {
  HapiDiff({
    required this.filePath,
    required this.status,
    this.additions,
    this.deletions,
    this.patch,
  });

  final String filePath;
  final String status; // 'added', 'modified', 'deleted', 'renamed'
  final int? additions;
  final int? deletions;
  final String? patch;

  factory HapiDiff.fromJson(Map<String, dynamic> json) {
    return HapiDiff(
      filePath:
          json['filePath'] as String? ??
          json['path'] as String? ??
          json['filename'] as String? ??
          '',
      status: json['status'] as String? ?? 'modified',
      additions: json['additions'] as int?,
      deletions: json['deletions'] as int?,
      patch: json['patch'] as String? ?? json['diff'] as String?,
    );
  }

  /// 获取状态图标
  String get statusIcon => switch (status) {
    'added' => '+',
    'deleted' => '-',
    'modified' => '~',
    'renamed' => '→',
    _ => '?',
  };
}

/// 机器信息
class HapiMachine {
  HapiMachine({
    required this.id,
    required this.name,
    this.hostname,
    this.platform,
    this.isOnline = false,
    this.lastSeenAt,
    this.cliVersion,
    this.homeDir,
    this.daemonStatus,
    this.httpPort,
  });

  final String id;
  final String name;
  final String? hostname;
  final String? platform;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final String? cliVersion;
  final String? homeDir;
  final String? daemonStatus;
  final int? httpPort;

  /// 获取平台显示名称
  String get platformDisplayName => switch (platform?.toLowerCase()) {
    'darwin' => 'macOS',
    'linux' => 'Linux',
    'win32' || 'windows' => 'Windows',
    _ => platform ?? 'Unknown',
  };

  /// 从 JSON 创建 HapiMachine
  factory HapiMachine.fromJson(Map<String, dynamic> json) {
    // ID 字段
    final id = json['machineId'] as String? ?? json['id'] as String? ?? '';

    // 解析 metadata
    final metadata = json['metadata'] as Map<String, dynamic>?;

    // 名称字段：优先 metadata.host > name > hostname
    String name = 'Unknown';
    if (metadata != null && metadata['host'] != null) {
      name = metadata['host'] as String;
    } else if (json['machineName'] != null) {
      name = json['machineName'] as String;
    } else if (json['name'] != null) {
      name = json['name'] as String;
    } else if (json['hostname'] != null) {
      name = json['hostname'] as String;
    }

    // 主机名：从 metadata.host 或直接字段
    final hostname =
        metadata?['host'] as String? ??
        json['hostname'] as String? ??
        json['host'] as String?;

    // 平台：从 metadata.platform 或直接字段
    final platform =
        metadata?['platform'] as String? ??
        json['platform'] as String? ??
        json['os'] as String?;

    // CLI 版本
    final cliVersion = metadata?['happyCliVersion'] as String?;

    // 主目录
    final homeDir = metadata?['homeDir'] as String?;

    // 解析 daemonState
    final daemonState = json['daemonState'] as Map<String, dynamic>?;
    final daemonStatus = daemonState?['status'] as String?;
    final httpPort = daemonState?['httpPort'] as int?;

    // 在线状态：hapi 使用 active 字段
    final isOnline =
        json['active'] as bool? ??
        json['isOnline'] as bool? ??
        json['online'] as bool? ??
        json['connected'] as bool? ??
        false;

    // 最后活跃时间：hapi 使用 activeAt (毫秒时间戳)
    DateTime? lastSeenAt;
    final activeAtValue =
        json['activeAt'] ?? json['lastSeenAt'] ?? json['lastSeen'];
    if (activeAtValue != null) {
      if (activeAtValue is int) {
        lastSeenAt = DateTime.fromMillisecondsSinceEpoch(activeAtValue);
      } else if (activeAtValue is String) {
        lastSeenAt = DateTime.tryParse(activeAtValue);
      }
    }

    return HapiMachine(
      id: id,
      name: name,
      hostname: hostname,
      platform: platform,
      isOnline: isOnline,
      lastSeenAt: lastSeenAt,
      cliVersion: cliVersion,
      homeDir: homeDir,
      daemonStatus: daemonStatus,
      httpPort: httpPort,
    );
  }
}

/// 健康检查响应
class HapiHealthResponse {
  HapiHealthResponse({required this.success, required this.message, this.data});

  final bool success;
  final String message;
  final dynamic data;
}
