import 'dart:convert';

import 'types.dart';

/// Chat blocks indexed by ID
typedef ChatBlocksById = Map<String, ChatBlock>;

/// Reconcile chat blocks to avoid unnecessary widget rebuilds
///
/// Compares new blocks with previous blocks and reuses objects
/// when they are equal, which helps Flutter's widget diffing.
///
/// Mirrors web/src/chat/reconcile.ts
({List<ChatBlock> blocks, ChatBlocksById byId}) reconcileChatBlocks(
  List<ChatBlock> nextBlocks,
  ChatBlocksById prevById,
) {
  final reconciledBlocks = _reconcileBlockList(nextBlocks, prevById);
  final newById = _indexBlocks(reconciledBlocks);
  return (blocks: reconciledBlocks, byId: newById);
}

/// Reconcile a list of blocks
List<ChatBlock> _reconcileBlockList(
  List<ChatBlock> blocks,
  ChatBlocksById prevById,
) {
  return blocks.map((block) => _reconcileBlock(block, prevById)).toList();
}

/// Reconcile a single block
ChatBlock _reconcileBlock(ChatBlock block, ChatBlocksById prevById) {
  final prevBlock = prevById[block.id];
  if (prevBlock == null) return block;

  // For tool call blocks, also reconcile children
  if (block is ToolCallBlock && prevBlock is ToolCallBlock) {
    final reconciledChildren = _reconcileBlockList(block.children, prevById);

    // Create a new block with reconciled children
    final blockWithChildren = ToolCallBlock(
      id: block.id,
      localId: block.localId,
      createdAt: block.createdAt,
      tool: block.tool,
      children: reconciledChildren,
      meta: block.meta,
    );

    if (_areToolCallBlocksEqual(blockWithChildren, prevBlock)) {
      return prevBlock;
    }
    return blockWithChildren;
  }

  // Compare blocks
  if (_areBlocksEqual(block, prevBlock)) {
    return prevBlock;
  }

  return block;
}

/// Index all blocks (including nested children) by ID
ChatBlocksById _indexBlocks(List<ChatBlock> blocks) {
  final index = <String, ChatBlock>{};

  void addBlock(ChatBlock block) {
    index[block.id] = block;
    if (block is ToolCallBlock) {
      for (final child in block.children) {
        addBlock(child);
      }
    }
  }

  for (final block in blocks) {
    addBlock(block);
  }

  return index;
}

/// Compare two blocks for equality
bool _areBlocksEqual(ChatBlock a, ChatBlock b) {
  if (a.runtimeType != b.runtimeType) return false;

  return switch (a) {
    UserTextBlock() => _areUserTextBlocksEqual(a, b as UserTextBlock),
    AgentTextBlock() => _areAgentTextBlocksEqual(a, b as AgentTextBlock),
    AgentReasoningBlock() => _areAgentReasoningBlocksEqual(
      a,
      b as AgentReasoningBlock,
    ),
    CliOutputBlock() => _areCliOutputBlocksEqual(a, b as CliOutputBlock),
    AgentEventBlock() => _areAgentEventBlocksEqual(a, b as AgentEventBlock),
    ToolCallBlock() => _areToolCallBlocksEqual(a, b as ToolCallBlock),
  };
}

bool _areUserTextBlocksEqual(UserTextBlock a, UserTextBlock b) {
  return a.id == b.id &&
      a.text == b.text &&
      a.status == b.status &&
      a.originalText == b.originalText &&
      a.localId == b.localId &&
      a.createdAt == b.createdAt;
}

bool _areAgentTextBlocksEqual(AgentTextBlock a, AgentTextBlock b) {
  return a.id == b.id &&
      a.text == b.text &&
      a.localId == b.localId &&
      a.createdAt == b.createdAt;
}

bool _areAgentReasoningBlocksEqual(
  AgentReasoningBlock a,
  AgentReasoningBlock b,
) {
  return a.id == b.id &&
      a.text == b.text &&
      a.localId == b.localId &&
      a.createdAt == b.createdAt;
}

bool _areCliOutputBlocksEqual(CliOutputBlock a, CliOutputBlock b) {
  return a.id == b.id &&
      a.text == b.text &&
      a.source == b.source &&
      a.localId == b.localId &&
      a.createdAt == b.createdAt;
}

bool _areAgentEventBlocksEqual(AgentEventBlock a, AgentEventBlock b) {
  return a.id == b.id &&
      a.createdAt == b.createdAt &&
      _getEventKey(a.event) == _getEventKey(b.event);
}

bool _areToolCallBlocksEqual(ToolCallBlock a, ToolCallBlock b) {
  if (a.id != b.id || a.localId != b.localId || a.createdAt != b.createdAt) {
    return false;
  }

  final toolA = a.tool;
  final toolB = b.tool;

  if (toolA.id != toolB.id ||
      toolA.name != toolB.name ||
      toolA.state != toolB.state ||
      toolA.description != toolB.description ||
      toolA.startedAt != toolB.startedAt ||
      toolA.completedAt != toolB.completedAt) {
    return false;
  }

  // Compare input/result as JSON
  if (!_deepEquals(toolA.input, toolB.input)) return false;
  if (!_deepEquals(toolA.result, toolB.result)) return false;

  // Compare permission on tool
  if (!_arePermissionsEqual(toolA.permission, toolB.permission)) return false;

  // Compare children count (deep comparison done in reconciliation)
  if (a.children.length != b.children.length) return false;

  return true;
}

bool _arePermissionsEqual(ToolPermission? a, ToolPermission? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;

  return a.id == b.id &&
      a.status == b.status &&
      a.reason == b.reason &&
      a.mode == b.mode &&
      a.decision == b.decision &&
      a.date == b.date &&
      a.createdAt == b.createdAt &&
      a.completedAt == b.completedAt &&
      _areStringListsEqual(a.allowedTools, b.allowedTools) &&
      _areAnswersEqual(a.answers, b.answers);
}

bool _areStringListsEqual(List<String>? a, List<String>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _areAnswersEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!_deepEquals(a[key], b[key])) return false;
  }
  return true;
}

/// Generate a unique key for an event for comparison
String _getEventKey(AgentEvent event) {
  return switch (event) {
    SwitchEvent(:final mode) => 'switch:$mode',
    MessageEvent(:final message) => 'message:$message',
    TitleChangedEvent(:final title) => 'title:$title',
    LimitReachedEvent(:final endsAt) => 'limit:$endsAt',
    ApiErrorEvent(:final retryAttempt, :final maxRetries) =>
      'api-error:$retryAttempt/$maxRetries',
    ReadyEvent() => 'ready',
    UnknownEvent(:final type, :final data) => () {
      try {
        return 'unknown:$type:${jsonEncode(data)}';
      } catch (_) {
        return 'unknown:$type';
      }
    }(),
  };
}

/// Deep equality check for dynamic values
bool _deepEquals(dynamic a, dynamic b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.runtimeType != b.runtimeType) return false;

  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }

  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }

  return a == b;
}
