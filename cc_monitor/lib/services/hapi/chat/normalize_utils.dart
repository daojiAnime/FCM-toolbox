// 归一化工具函数
// 对标 web/src/chat/normalizeUtils.ts

import 'dart:convert';

/// 检查是否为对象（非 null 的 Map）
bool isObject(dynamic value) {
  return value != null && value is Map<String, dynamic>;
}

/// 安全获取字符串
String? asString(dynamic value) {
  return value is String ? value : null;
}

/// 安全获取数字
num? asNumber(dynamic value) {
  if (value is num && value.isFinite) return value;
  return null;
}

/// 安全获取整数
int? asInt(dynamic value) {
  final num = asNumber(value);
  return num?.toInt();
}

/// 安全序列化
String safeStringify(dynamic value) {
  if (value is String) return value;
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return value.toString();
  }
}
