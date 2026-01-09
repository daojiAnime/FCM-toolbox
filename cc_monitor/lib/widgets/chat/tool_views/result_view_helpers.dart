/// Result 视图辅助工具
///
/// 提供通用的文本提取、解析等功能
library;

/// 提取文本内容（从结构化数据）
String? extractTextFromResult(dynamic result) {
  if (result == null) return null;
  if (result is String) return result;

  // 尝试提取常见字段
  if (result is Map<String, dynamic>) {
    // 按优先级尝试
    for (final key in ['content', 'text', 'output', 'message', 'data']) {
      final value = result[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
  }

  return null;
}

/// 是否看起来像 JSON
bool looksLikeJson(String text) {
  final trimmed = text.trim();
  return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
      (trimmed.startsWith('[') && trimmed.endsWith(']'));
}

/// 是否看起来像 HTML
bool looksLikeHtml(String text) {
  final trimmed = text.trimLeft();
  return trimmed.startsWith('<!DOCTYPE') ||
      trimmed.startsWith('<html') ||
      trimmed.startsWith('<div') ||
      trimmed.startsWith('<span');
}

/// 提取行列表
List<String> extractLineList(String text) {
  return text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}
