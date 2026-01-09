// 工具相关 reducer 辅助函数
// 对标 web/src/chat/reducerTools.ts

import 'types.dart';
import 'normalize_utils.dart';

/// 权限条目
class PermissionEntry {
  final String toolName;
  final dynamic input;
  final ToolPermission permission;

  PermissionEntry({
    required this.toolName,
    required this.input,
    required this.permission,
  });
}

/// 从 AgentState 获取权限映射
Map<String, PermissionEntry> getPermissions(Map<String, dynamic>? agentState) {
  final map = <String, PermissionEntry>{};
  if (agentState == null) return map;

  final completed = agentState['completedRequests'] as Map<String, dynamic>?;
  if (completed != null) {
    for (final entry in completed.entries) {
      final id = entry.key;
      final value = entry.value as Map<String, dynamic>?;
      if (value == null) continue;

      map[id] = PermissionEntry(
        toolName: asString(value['tool']) ?? '',
        input: value['arguments'],
        permission: ToolPermission(
          id: id,
          status: asString(value['status']) ?? 'pending',
          reason: asString(value['reason']),
          mode: asString(value['mode']),
          decision: asString(value['decision']),
          allowedTools:
              value['allowTools'] is List
                  ? (value['allowTools'] as List).whereType<String>().toList()
                  : null,
          answers: _parseAnswers(value['answers']),
          createdAt: asInt(value['createdAt']),
          completedAt: asInt(value['completedAt']),
        ),
      );
    }
  }

  final requests = agentState['requests'] as Map<String, dynamic>?;
  if (requests != null) {
    for (final entry in requests.entries) {
      final id = entry.key;
      if (map.containsKey(id)) continue;

      final value = entry.value as Map<String, dynamic>?;
      if (value == null) continue;

      map[id] = PermissionEntry(
        toolName: asString(value['tool']) ?? '',
        input: value['arguments'],
        permission: ToolPermission(
          id: id,
          status: 'pending',
          createdAt: asInt(value['createdAt']),
        ),
      );
    }
  }

  return map;
}

Map<String, List<String>>? _parseAnswers(dynamic value) {
  if (value is! Map) return null;
  final result = <String, List<String>>{};
  for (final entry in value.entries) {
    if (entry.key is! String) continue;
    if (entry.value is! List) continue;
    result[entry.key as String] =
        (entry.value as List).whereType<String>().toList();
  }
  return result.isEmpty ? null : result;
}

/// 确保工具块存在
/// 对标 ensureToolBlock
ToolCallBlock ensureToolBlock(
  List<ChatBlock> blocks,
  Map<String, ToolCallBlock> toolBlocksById,
  String id, {
  required int createdAt,
  String? localId,
  dynamic meta,
  required String name,
  dynamic input,
  String? description,
  ToolPermission? permission,
}) {
  final existing = toolBlocksById[id];
  if (existing != null) {
    // 更新已存在的 block
    bool isPlaceholderToolName(String name) {
      final normalized = name.trim().toLowerCase();
      return normalized.isEmpty ||
          normalized == 'tool' ||
          normalized == 'unknown';
    }

    // 保留最早的 createdAt
    if (createdAt < existing.createdAt) {
      existing.createdAt = createdAt;
      existing.tool.createdAt = createdAt;
    }

    if (permission != null) {
      existing.tool.permission = permission;
      if (existing.tool.state == 'running' && permission.status == 'pending') {
        existing.tool.state = 'pending';
      }
    }

    if (!isPlaceholderToolName(name) ||
        isPlaceholderToolName(existing.tool.name)) {
      existing.tool.name = name;
    }

    if (input != null) {
      existing.tool.input = input;
    }

    if (description != null) {
      existing.tool.description = description;
    }

    return existing;
  }

  // 创建新 block
  final initialState =
      permission?.status == 'pending'
          ? 'pending'
          : (permission?.status == 'denied' || permission?.status == 'canceled')
          ? 'error'
          : 'running';

  final tool = ChatToolCall(
    id: id,
    name: name,
    state: initialState,
    input: input,
    createdAt: createdAt,
    startedAt: initialState == 'running' ? createdAt : null,
    completedAt: null,
    description: description,
    permission: permission,
  );

  final block = ToolCallBlock(
    id: id,
    localId: localId,
    createdAt: createdAt,
    tool: tool,
    meta: meta,
  );

  toolBlocksById[id] = block;
  blocks.add(block);
  return block;
}

/// 从消息中收集工具 ID
Set<String> collectToolIdsFromMessages(List<NormalizedMessage> messages) {
  final ids = <String>{};
  for (final msg in messages) {
    if (msg.role != NormalizedRole.agent) continue;
    final content = msg.agentContent;
    if (content == null) continue;

    for (final c in content) {
      if (c is NormalizedToolCallContent) {
        ids.add(c.id);
      } else if (c is NormalizedToolResultContent) {
        ids.add(c.toolUseId);
      }
    }
  }
  return ids;
}

/// 判断是否为改标题工具
bool isChangeTitleToolName(String name) {
  return name == 'mcp__hapi__change_title' || name == 'hapi__change_title';
}

/// 从改标题工具输入中提取标题
String? extractTitleFromChangeTitleInput(dynamic input) {
  if (!isObject(input)) return null;
  final title = (input as Map<String, dynamic>)['title'];
  if (title is! String) return null;
  final trimmed = title.trim();
  return trimmed.isNotEmpty ? trimmed : null;
}

/// 收集标题变更
Map<String, String> collectTitleChanges(List<NormalizedMessage> messages) {
  final map = <String, String>{};
  for (final msg in messages) {
    if (msg.role != NormalizedRole.agent) continue;
    final content = msg.agentContent;
    if (content == null) continue;

    for (final c in content) {
      if (c is! NormalizedToolCallContent) continue;
      if (!isChangeTitleToolName(c.name)) continue;
      final title = extractTitleFromChangeTitleInput(c.input);
      if (title != null) {
        map[c.id] = title;
      }
    }
  }
  return map;
}
