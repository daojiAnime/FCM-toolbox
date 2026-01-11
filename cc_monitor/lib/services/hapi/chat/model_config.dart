import 'dart:math';

/// Model context window configuration
///
/// Mirrors web/src/chat/modelConfig.ts

/// Reserved headroom tokens for system prompts, tools, etc.
const _contextHeadroomTokens = 10000;

/// Context window sizes for different models
const Map<String, int> _modelContextWindows = {
  'default': 200000,
  'sonnet': 200000,
  'opus': 200000,
};

/// Get the available context budget in tokens for a model
///
/// Returns null if the model is unknown.
/// Reserves [_contextHeadroomTokens] as buffer.
int? getContextBudgetTokens(String? modelMode) {
  final mode = modelMode ?? 'default';
  final windowTokens = _modelContextWindows[mode];
  if (windowTokens == null) return null;
  return max(1, windowTokens - _contextHeadroomTokens);
}

/// Get the total context window size for a model
int? getContextWindowTokens(String? modelMode) {
  final mode = modelMode ?? 'default';
  return _modelContextWindows[mode];
}

/// Check if a context size is approaching the limit
bool isContextNearLimit(int contextSize, String? modelMode) {
  final budget = getContextBudgetTokens(modelMode);
  if (budget == null) return false;
  return contextSize >= budget * 0.9; // 90% threshold
}
