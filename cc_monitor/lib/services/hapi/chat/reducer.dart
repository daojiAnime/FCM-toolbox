// 主 Reducer
// 对标 web/src/chat/reducer.ts

import 'types.dart';
import 'tracer.dart';
import 'reducer_tools.dart';
import 'reducer_timeline.dart';

/// 计算 context size
int calculateContextSize(UsageData usage) {
  return (usage.cacheCreationInputTokens ?? 0) +
      (usage.cacheReadInputTokens ?? 0) +
      usage.inputTokens;
}

/// 最新使用量
class LatestUsage {
  final int inputTokens;
  final int outputTokens;
  final int cacheCreation;
  final int cacheRead;
  final int contextSize;
  final int timestamp;

  LatestUsage({
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheCreation,
    required this.cacheRead,
    required this.contextSize,
    required this.timestamp,
  });
}

/// Reducer 结果
class ReducerResult {
  final List<ChatBlock> blocks;
  final bool hasReadyEvent;
  final LatestUsage? latestUsage;

  ReducerResult({
    required this.blocks,
    required this.hasReadyEvent,
    this.latestUsage,
  });
}

/// Reduce chat blocks
/// 对标 reduceChatBlocks
ReducerResult reduceChatBlocks(
  List<NormalizedMessage> normalized, {
  Map<String, dynamic>? agentState,
}) {
  final permissionsById = getPermissions(agentState);
  final toolIdsInMessages = collectToolIdsFromMessages(normalized);
  final titleChangesByToolUseId = collectTitleChanges(normalized);

  // Trace sidechain
  final traced = traceMessages(normalized);
  final groups = <String, List<TracedMessage>>{};
  final root = <TracedMessage>[];

  for (final msg in traced) {
    if (msg.sidechainId != null) {
      groups.putIfAbsent(msg.sidechainId!, () => []).add(msg);
    } else {
      root.add(msg);
    }
  }

  final consumedGroupIds = <String>{};
  final emittedTitleChangeToolUseIds = <String>{};
  final context = ReducerContext(
    permissionsById: permissionsById,
    groups: groups,
    consumedGroupIds: consumedGroupIds,
    titleChangesByToolUseId: titleChangesByToolUseId,
    emittedTitleChangeToolUseIds: emittedTitleChangeToolUseIds,
  );

  final rootResult = reduceTimeline(root, context);
  var hasReadyEvent = rootResult.hasReadyEvent;

  // 创建 permission-only 工具卡片
  for (final entry in permissionsById.entries) {
    final id = entry.key;
    if (toolIdsInMessages.contains(id)) continue;
    if (rootResult.toolBlocksById.containsKey(id)) continue;

    final createdAt =
        entry.value.permission.createdAt ??
        DateTime.now().millisecondsSinceEpoch;
    final block = ensureToolBlock(
      rootResult.blocks,
      rootResult.toolBlocksById,
      id,
      createdAt: createdAt,
      localId: null,
      name: entry.value.toolName,
      input: entry.value.input,
      description: null,
      permission: entry.value.permission,
    );

    if (entry.value.permission.status == 'approved') {
      block.tool.state = 'completed';
      block.tool.completedAt = entry.value.permission.completedAt ?? createdAt;
      block.tool.result ??= 'Approved';
    } else if (entry.value.permission.status == 'denied' ||
        entry.value.permission.status == 'canceled') {
      block.tool.state = 'error';
      block.tool.completedAt = entry.value.permission.completedAt ?? createdAt;
      if (block.tool.result == null && entry.value.permission.reason != null) {
        block.tool.result = {'error': entry.value.permission.reason};
      }
    }
  }

  // 计算最新使用量
  LatestUsage? latestUsage;
  for (var i = normalized.length - 1; i >= 0; i--) {
    final msg = normalized[i];
    if (msg.usage != null) {
      latestUsage = LatestUsage(
        inputTokens: msg.usage!.inputTokens,
        outputTokens: msg.usage!.outputTokens,
        cacheCreation: msg.usage!.cacheCreationInputTokens ?? 0,
        cacheRead: msg.usage!.cacheReadInputTokens ?? 0,
        contextSize: calculateContextSize(msg.usage!),
        timestamp: msg.createdAt,
      );
      break;
    }
  }

  return ReducerResult(
    blocks: rootResult.blocks,
    hasReadyEvent: hasReadyEvent,
    latestUsage: latestUsage,
  );
}
