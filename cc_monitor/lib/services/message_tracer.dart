import '../common/logger.dart';

import '../models/message.dart';
import '../models/payload/payload.dart';

/// 消息追踪服务 - 实现 hapi 的 sidechain 追踪机制
/// 参考: hapi/web/src/chat/tracer.ts 和 reducerTimeline.ts
///
/// 核心逻辑：
/// 1. 每个 sidechain 消息追溯到它的链头（第一个 sidechain 消息）
/// 2. 链头关联到前面最近的 Task 消息
/// 3. 同一条链的所有消息扁平化归属到链头
class MessageTracer {
  /// 完整的消息处理流程
  static List<MessageNode> processMessages(List<Message> messages) {
    if (messages.isEmpty) return [];

    // 1. 构建 contentUuid -> Message 映射
    final uuidToMessage = <String, Message>{};
    for (final msg in messages) {
      if (msg.contentUuid != null && msg.contentUuid!.isNotEmpty) {
        uuidToMessage[msg.contentUuid!] = msg;
      }
    }

    // 2. 记录非 sidechain 的 Task 消息索引（用于链头匹配）
    final taskIndexes = <int>[];
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      if (!msg.isSidechain && msg.payload is TaskExecutionPayload) {
        taskIndexes.add(i);
      }
    }
    Log.i(
      'MsgTrace',
      ' Total Tasks: ${taskIndexes.length}, uuids: ${uuidToMessage.length}',
    );

    // 3. 找出所有链头及其索引
    // 链头 = sidechain 且 (parentId=null 或 parentId 指向非 sidechain 消息)
    final chainHeadMsgIds = <String>{};
    final msgIndexMap = <String, int>{};
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      msgIndexMap[msg.id] = i;
      if (msg.isSidechain) {
        if (msg.parentId == null || msg.parentId!.isEmpty) {
          chainHeadMsgIds.add(msg.id);
        } else {
          final parent = uuidToMessage[msg.parentId];
          if (parent == null || !parent.isSidechain) {
            chainHeadMsgIds.add(msg.id);
          }
        }
      }
    }
    Log.i('MsgTrace', ' Chain heads found: ${chainHeadMsgIds.length}');

    // 4. 为每个消息找到父消息 ID
    final childToParent = <String, String>{};
    int directToChainHead = 0;
    int chainHeadToTask = 0;
    int orphanCount = 0;

    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      if (!msg.isSidechain) continue;

      if (chainHeadMsgIds.contains(msg.id)) {
        // 这是链头，关联到前面最近的 Task
        int? nearestTaskIndex;
        for (final taskIdx in taskIndexes.reversed) {
          if (taskIdx < i) {
            nearestTaskIndex = taskIdx;
            break;
          }
        }
        if (nearestTaskIndex != null) {
          childToParent[msg.id] = messages[nearestTaskIndex].id;
          chainHeadToTask++;
          final shortId = msg.id.length > 8 ? msg.id.substring(0, 8) : msg.id;
          final shortTask =
              messages[nearestTaskIndex].id.length > 8
                  ? messages[nearestTaskIndex].id.substring(0, 8)
                  : messages[nearestTaskIndex].id;
          Log.i('MsgTrace', ' 🔗 Chain head $shortId -> Task $shortTask');
        } else {
          // 找不到 Task，尝试关联到前面最近的非 sidechain assistant 消息
          int? nearestAssistantIndex;
          for (var j = i - 1; j >= 0; j--) {
            final prevMsg = messages[j];
            if (!prevMsg.isSidechain && prevMsg.role == 'assistant') {
              nearestAssistantIndex = j;
              break;
            }
          }
          if (nearestAssistantIndex != null) {
            childToParent[msg.id] = messages[nearestAssistantIndex].id;
            chainHeadToTask++;
            final shortId = msg.id.length > 8 ? msg.id.substring(0, 8) : msg.id;
            final shortParent =
                messages[nearestAssistantIndex].id.length > 8
                    ? messages[nearestAssistantIndex].id.substring(0, 8)
                    : messages[nearestAssistantIndex].id;
            Log.i(
              'MsgTrace',
              ' 🔗 Chain head $shortId -> Assistant $shortParent (fallback)',
            );
          } else {
            // 仍然找不到，链头将作为独立根节点显示
            orphanCount++;
            final shortId = msg.id.length > 8 ? msg.id.substring(0, 8) : msg.id;
            Log.i(
              'MsgTrace',
              ' ⚠️ Orphan chain head: $shortId (will be root node)',
            );
          }
        }
      } else {
        // 非链头的 sidechain 消息，扁平化归属到 Task（而不是链头）
        // 这样 Task 的 collapsibleChildren 会包含所有 sidechain 消息
        final chainHeadId = _findChainHeadMsgId(
          msg,
          uuidToMessage,
          chainHeadMsgIds,
          {},
        );
        if (chainHeadId != null) {
          // 找到链头对应的 Task
          final taskId = childToParent[chainHeadId];
          if (taskId != null) {
            childToParent[msg.id] = taskId;
            directToChainHead++;
          } else {
            // 链头没有关联 Task，则关联到链头
            childToParent[msg.id] = chainHeadId;
            directToChainHead++;
          }
        } else {
          orphanCount++;
          final shortId = msg.id.length > 8 ? msg.id.substring(0, 8) : msg.id;
          Log.i(
            'MsgTrace',
            ' ⚠️ Orphan sidechain: $shortId, parentId=${msg.parentId}',
          );
        }
      }
    }
    Log.i(
      'MsgTrace',
      ' Traced: toChainHead=$directToChainHead, chainHeadToTask=$chainHeadToTask, orphan=$orphanCount',
    );

    // 5. 构建 parentMsgId -> children 映射
    // hidden 消息的 children 提升到 hidden 的父节点
    final parentToChildren = <String, List<Message>>{};

    // 找到 hidden 消息的有效父节点（跳过 hidden 链）
    String? findVisibleParent(String? msgId) {
      if (msgId == null) return null;
      final msg = messages.firstWhere(
        (m) => m.id == msgId,
        orElse: () => messages.first,
      );
      if (msg.payload is HiddenPayload) {
        // 这个消息是 hidden，继续向上找
        return findVisibleParent(childToParent[msgId]);
      }
      return msgId;
    }

    for (final msg in messages) {
      // 跳过 hidden 消息本身，不显示
      if (msg.payload is HiddenPayload) continue;

      var parentId = childToParent[msg.id];
      // 如果直接父节点是 hidden，找到更上层的可见父节点
      if (parentId != null) {
        final parentMsg = messages.firstWhere(
          (m) => m.id == parentId,
          orElse: () => messages.first,
        );
        if (parentMsg.payload is HiddenPayload) {
          parentId = findVisibleParent(parentId);
        }
      }

      if (parentId != null) {
        parentToChildren.putIfAbsent(parentId, () => []).add(msg);
      }
    }

    // 6. 递归构建树
    MessageNode buildNode(Message msg) {
      final children = parentToChildren[msg.id] ?? [];
      return MessageNode(
        message: msg,
        children: children.map(buildNode).toList(),
      );
    }

    // 7. 根消息 = 没有 parent 的消息，且不是 hidden
    final rootMessages =
        messages
            .where((msg) => !childToParent.containsKey(msg.id))
            .where((msg) => msg.payload is! HiddenPayload)
            .toList();

    return rootMessages.map(buildNode).toList();
  }

  /// 追溯 sidechain 消息到链头
  /// 返回链头消息的 ID
  static String? _findChainHeadMsgId(
    Message msg,
    Map<String, Message> uuidToMessage,
    Set<String> chainHeadMsgIds,
    Set<String> visited,
  ) {
    if (visited.contains(msg.id)) return null;
    visited.add(msg.id);

    // 如果这个消息是链头，返回它的 ID
    if (chainHeadMsgIds.contains(msg.id)) {
      return msg.id;
    }

    // 通过 parentId 找到父消息
    if (msg.parentId == null || msg.parentId!.isEmpty) {
      return null;
    }

    final parent = uuidToMessage[msg.parentId];
    if (parent == null) {
      return null;
    }

    // 如果父消息是链头，返回父消息的 ID
    if (chainHeadMsgIds.contains(parent.id)) {
      return parent.id;
    }

    // 继续追溯
    return _findChainHeadMsgId(parent, uuidToMessage, chainHeadMsgIds, visited);
  }
}
