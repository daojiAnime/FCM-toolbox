// Result text extraction utilities
//
// Recursively extracts text content from tool result objects.
// Supports common field names and nested structures.
// Mirrors web/src/components/ToolCard/resultHelpers.ts

/// Common field names that contain text content
const _textFields = [
  'content',
  'text',
  'output',
  'message',
  'result',
  'data',
  'body',
  'stdout',
  'stderr',
];

/// Extract text content from a result object
///
/// Recursively searches for text content in common field names.
/// Returns the first non-empty text found, or null if none.
String? extractResultText(dynamic result, {int maxDepth = 5}) {
  if (maxDepth <= 0) return null;

  if (result == null) return null;

  // Direct string
  if (result is String) {
    return result.isNotEmpty ? result : null;
  }

  // List - try first element
  if (result is List) {
    for (final item in result) {
      final text = extractResultText(item, maxDepth: maxDepth - 1);
      if (text != null) return text;
    }
    return null;
  }

  // Map - search known fields
  if (result is Map<String, dynamic>) {
    // Check known text fields first
    for (final field in _textFields) {
      final value = result[field];
      if (value != null) {
        final text = extractResultText(value, maxDepth: maxDepth - 1);
        if (text != null) return text;
      }
    }

    // Fall back to any string value
    for (final value in result.values) {
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    // Recurse into nested objects
    for (final value in result.values) {
      if (value is Map || value is List) {
        final text = extractResultText(value, maxDepth: maxDepth - 1);
        if (text != null) return text;
      }
    }
  }

  return null;
}

/// Extract all text content from a result object
///
/// Returns a list of all text values found in the result.
List<String> extractAllResultText(dynamic result, {int maxDepth = 5}) {
  final texts = <String>[];
  _collectTexts(result, texts, maxDepth);
  return texts;
}

void _collectTexts(dynamic value, List<String> texts, int maxDepth) {
  if (maxDepth <= 0 || value == null) return;

  if (value is String && value.isNotEmpty) {
    texts.add(value);
    return;
  }

  if (value is List) {
    for (final item in value) {
      _collectTexts(item, texts, maxDepth - 1);
    }
    return;
  }

  if (value is Map<String, dynamic>) {
    // Prioritize known text fields
    for (final field in _textFields) {
      final fieldValue = value[field];
      if (fieldValue != null) {
        _collectTexts(fieldValue, texts, maxDepth - 1);
      }
    }

    // Then other values
    for (final entry in value.entries) {
      if (!_textFields.contains(entry.key)) {
        _collectTexts(entry.value, texts, maxDepth - 1);
      }
    }
  }
}

/// Parse tool use error from result text
///
/// Extracts error message from `<tool_use_error>` tags.
/// Returns null if no error tag found.
String? parseToolUseError(String text) {
  final errorMatch = RegExp(
    r'<tool_use_error>([\s\S]*?)</tool_use_error>',
    caseSensitive: false,
  ).firstMatch(text);

  if (errorMatch != null) {
    return errorMatch.group(1)?.trim();
  }

  return null;
}

/// Check if result contains an error
bool resultHasError(dynamic result) {
  final text = extractResultText(result);
  if (text == null) return false;
  return parseToolUseError(text) != null;
}

/// Extract error message from result if present
String? extractErrorMessage(dynamic result) {
  final text = extractResultText(result);
  if (text == null) return null;
  return parseToolUseError(text);
}

/// Truncate text to a maximum length
///
/// Adds ellipsis if truncated.
String truncateText(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength - 3)}...';
}

/// Get a preview of the result text
///
/// Returns a short preview suitable for compact display.
String? getResultPreview(dynamic result, {int maxLength = 100}) {
  final text = extractResultText(result);
  if (text == null) return null;

  // Check for error first
  final error = parseToolUseError(text);
  if (error != null) {
    return truncateText('Error: $error', maxLength);
  }

  // Clean up whitespace
  final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return truncateText(cleaned, maxLength);
}
