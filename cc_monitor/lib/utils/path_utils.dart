// Path utilities for display and manipulation
// Mirrors web/src/utils/path.ts

/// Resolve a path relative to the session root for display
///
/// If the path starts with the session root, returns the relative path.
/// Otherwise, returns the original path.
String resolveDisplayPath(String path, String? sessionRoot) {
  if (sessionRoot == null || sessionRoot.isEmpty) return path;

  final lowerPath = path.toLowerCase();
  final lowerRoot = sessionRoot.toLowerCase();

  if (!lowerPath.startsWith(lowerRoot)) return path;

  final remainder = path.substring(sessionRoot.length);
  if (remainder.isNotEmpty &&
      !remainder.startsWith('/') &&
      !remainder.startsWith('\\')) {
    return path;
  }

  var out = remainder;
  if (out.startsWith('/') || out.startsWith('\\')) {
    out = out.substring(1);
  }

  return out.isEmpty ? '<root>' : out;
}

/// Extract the basename (last path component) from a path
String basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/').where((p) => p.isNotEmpty).toList();
  return parts.isNotEmpty ? parts.last : path;
}

/// Extract the directory name from a path
String dirname(String path) {
  final normalized = path.replaceAll('\\', '/');
  final lastSlash = normalized.lastIndexOf('/');
  if (lastSlash == -1) return '.';
  if (lastSlash == 0) return '/';
  return normalized.substring(0, lastSlash);
}

/// Join path segments
String joinPath(List<String> segments) {
  return segments.where((s) => s.isNotEmpty).join('/');
}
