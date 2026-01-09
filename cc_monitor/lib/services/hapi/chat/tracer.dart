// Sidechain 追踪
// 对标 web/src/chat/tracer.ts

import 'types.dart';
import 'normalize_utils.dart';

/// 带 sidechain ID 的追踪消息
class TracedMessage {
  final NormalizedMessage message;
  final String? sidechainId;

  TracedMessage(this.message, {this.sidechainId});

  // 代理访问
  String get id => message.id;
  String? get localId => message.localId;
  int get createdAt => message.createdAt;
  NormalizedRole get role => message.role;
  bool get isSidechain => message.isSidechain;
  dynamic get meta => message.meta;
  UsageData? get usage => message.usage;
  String? get status => message.status;
  String? get originalText => message.originalText;
  NormalizedUserContent? get userContent => message.userContent;
  List<NormalizedAgentContent>? get agentContent => message.agentContent;
  AgentEvent? get eventContent => message.eventContent;
}

/// 追踪器状态
class _TracerState {
  final promptToTaskId = <String, String>{};
  final uuidToSidechainId = <String, String>{};
  final orphanMessages = <String, List<NormalizedMessage>>{};
}

/// 获取消息的 UUID
String? _getMessageUuid(NormalizedMessage message) {
  if (message.role == NormalizedRole.agent) {
    final content = message.agentContent;
    if (content != null && content.isNotEmpty) {
      final first = content.first;
      if (first is NormalizedTextContent) return first.uuid;
      if (first is NormalizedReasoningContent) return first.uuid;
      if (first is NormalizedToolCallContent) return first.uuid;
      if (first is NormalizedToolResultContent) return first.uuid;
      if (first is NormalizedSidechainContent) return first.uuid;
    }
  }
  return null;
}

/// 获取消息的 parentUUID
String? _getParentUuid(NormalizedMessage message) {
  if (message.role == NormalizedRole.agent) {
    final content = message.agentContent;
    if (content != null && content.isNotEmpty) {
      final first = content.first;
      if (first is NormalizedTextContent) return first.parentUUID;
      if (first is NormalizedReasoningContent) return first.parentUUID;
      if (first is NormalizedToolCallContent) return first.parentUUID;
      if (first is NormalizedToolResultContent) return first.parentUUID;
    }
  }
  return null;
}

/// 处理孤儿消息
List<TracedMessage> _processOrphans(
  _TracerState state,
  String parentUuid,
  String sidechainId,
) {
  final results = <TracedMessage>[];
  final orphans = state.orphanMessages.remove(parentUuid);
  if (orphans == null) return results;

  for (final orphan in orphans) {
    final uuid = _getMessageUuid(orphan);
    if (uuid != null) {
      state.uuidToSidechainId[uuid] = sidechainId;
    }

    results.add(TracedMessage(orphan, sidechainId: sidechainId));

    if (uuid != null) {
      results.addAll(_processOrphans(state, uuid, sidechainId));
    }
  }

  return results;
}

/// 追踪消息，关联 sidechain
/// 对标 traceMessages
List<TracedMessage> traceMessages(List<NormalizedMessage> messages) {
  final state = _TracerState();
  final results = <TracedMessage>[];

  // 第一遍：索引 Task prompts
  for (final message in messages) {
    if (message.role != NormalizedRole.agent) continue;
    final content = message.agentContent;
    if (content == null) continue;

    for (final c in content) {
      if (c is! NormalizedToolCallContent) continue;
      if (c.name != 'Task') continue;
      final input = c.input;
      if (!isObject(input)) continue;
      final prompt = (input as Map<String, dynamic>)['prompt'];
      if (prompt is! String) continue;
      state.promptToTaskId[prompt] = message.id;
    }
  }

  // 第二遍：追踪 sidechain
  for (final message in messages) {
    if (!message.isSidechain) {
      results.add(TracedMessage(message));
      continue;
    }

    final uuid = _getMessageUuid(message);
    final parentUuid = _getParentUuid(message);

    // Sidechain root 匹配（prompt == Task.prompt）
    String? sidechainId;
    if (message.role == NormalizedRole.agent) {
      final content = message.agentContent;
      if (content != null) {
        for (final c in content) {
          if (c is! NormalizedSidechainContent) continue;
          final taskId = state.promptToTaskId[c.prompt];
          if (taskId != null) {
            sidechainId = taskId;
            break;
          }
        }
      }
    }

    if (sidechainId != null && uuid != null) {
      state.uuidToSidechainId[uuid] = sidechainId;
      results.add(TracedMessage(message, sidechainId: sidechainId));
      results.addAll(_processOrphans(state, uuid, sidechainId));
      continue;
    }

    if (parentUuid != null) {
      final parentSidechainId = state.uuidToSidechainId[parentUuid];
      if (parentSidechainId != null) {
        if (uuid != null) {
          state.uuidToSidechainId[uuid] = parentSidechainId;
        }
        results.add(TracedMessage(message, sidechainId: parentSidechainId));
        if (uuid != null) {
          results.addAll(_processOrphans(state, uuid, parentSidechainId));
        }
      } else {
        // 暂存孤儿消息
        state.orphanMessages.putIfAbsent(parentUuid, () => []).add(message);
      }
      continue;
    }

    results.add(TracedMessage(message));
  }

  return results;
}
