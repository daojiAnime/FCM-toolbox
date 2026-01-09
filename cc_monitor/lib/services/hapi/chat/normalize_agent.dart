// Agent 消息归一化
// 对标 web/src/chat/normalizeAgent.ts

import 'types.dart';
import 'normalize_utils.dart';

/// 归一化工具结果权限
ToolResultPermission? normalizeToolResultPermissions(dynamic value) {
  if (!isObject(value)) return null;
  final map = value as Map<String, dynamic>;

  final date = asInt(map['date']);
  final result = map['result'];
  if (date == null) return null;
  if (result != 'approved' && result != 'denied') return null;

  final mode = asString(map['mode']);
  final allowedTools =
      map['allowedTools'] is List
          ? (map['allowedTools'] as List).whereType<String>().toList()
          : null;

  final decision = map['decision'];
  final normalizedDecision =
      (decision == 'approved' ||
              decision == 'approved_for_session' ||
              decision == 'denied' ||
              decision == 'abort')
          ? decision as String
          : null;

  return ToolResultPermission(
    date: date,
    result: result as String,
    mode: mode,
    allowedTools: allowedTools,
    decision: normalizedDecision,
  );
}

/// 归一化 Agent 事件
AgentEvent? normalizeAgentEvent(dynamic value) {
  if (!isObject(value)) return null;
  final map = value as Map<String, dynamic>;
  final type = map['type'];
  if (type is! String) return null;

  switch (type) {
    case 'switch':
      final mode = asString(map['mode']);
      if (mode == 'local') {
        return SwitchEvent(mode: 'local');
      }
      if (mode == 'remote') {
        return SwitchEvent(mode: 'remote');
      }
      return null;
    case 'message':
      final message = asString(map['message']);
      if (message != null) {
        return MessageEvent(message: message);
      }
      return null;
    case 'title-changed':
      final title = asString(map['title']);
      if (title != null) {
        return TitleChangedEvent(title: title);
      }
      return null;
    case 'limit-reached':
      final endsAt = asInt(map['endsAt']);
      if (endsAt != null) {
        return LimitReachedEvent(endsAt: endsAt);
      }
      return null;
    case 'ready':
      return ReadyEvent();
    case 'api-error':
      return ApiErrorEvent(
        retryAttempt: asInt(map['retryAttempt']) ?? 0,
        maxRetries: asInt(map['maxRetries']) ?? 0,
        error: map['error'],
      );
    default:
      return UnknownEvent(type: type, data: map);
  }
}

/// 归一化 Assistant 输出（data.type == 'assistant'）
/// 对标 normalizeAssistantOutput
NormalizedMessage? normalizeAssistantOutput(
  String messageId,
  String? localId,
  int createdAt,
  Map<String, dynamic> data, {
  dynamic meta,
}) {
  final uuid = asString(data['uuid']) ?? messageId;
  final parentUUID = asString(data['parentUuid']);
  final isSidechain = data['isSidechain'] == true;

  final message =
      isObject(data['message'])
          ? data['message'] as Map<String, dynamic>
          : null;
  if (message == null) return null;

  final modelContent = message['content'];
  final blocks = <NormalizedAgentContent>[];

  if (modelContent is String) {
    blocks.add(
      NormalizedTextContent(
        text: modelContent,
        uuid: uuid,
        parentUUID: parentUUID,
      ),
    );
  } else if (modelContent is List) {
    for (final block in modelContent) {
      if (!isObject(block)) continue;
      final blockMap = block as Map<String, dynamic>;
      final blockType = blockMap['type'];
      if (blockType is! String) continue;

      if (blockType == 'text' && blockMap['text'] is String) {
        blocks.add(
          NormalizedTextContent(
            text: blockMap['text'] as String,
            uuid: uuid,
            parentUUID: parentUUID,
          ),
        );
        continue;
      }

      if (blockType == 'thinking' && blockMap['thinking'] is String) {
        blocks.add(
          NormalizedReasoningContent(
            text: blockMap['thinking'] as String,
            uuid: uuid,
            parentUUID: parentUUID,
          ),
        );
        continue;
      }

      if (blockType == 'tool_use' && blockMap['id'] is String) {
        final name = asString(blockMap['name']) ?? 'Tool';
        final input = blockMap['input'];
        final description =
            isObject(input) && input['description'] is String
                ? input['description'] as String
                : null;
        blocks.add(
          NormalizedToolCallContent(
            id: blockMap['id'] as String,
            name: name,
            input: input,
            description: description,
            uuid: uuid,
            parentUUID: parentUUID,
          ),
        );
      }
    }
  }

  // 解析 usage
  final usage =
      isObject(message['usage'])
          ? message['usage'] as Map<String, dynamic>
          : null;
  final inputTokens = usage != null ? asInt(usage['input_tokens']) : null;
  final outputTokens = usage != null ? asInt(usage['output_tokens']) : null;

  return NormalizedMessage(
    id: messageId,
    localId: localId,
    createdAt: createdAt,
    role: NormalizedRole.agent,
    isSidechain: isSidechain,
    agentContent: blocks,
    meta: meta,
    usage:
        inputTokens != null && outputTokens != null
            ? UsageData(
              inputTokens: inputTokens,
              outputTokens: outputTokens,
              cacheCreationInputTokens: asInt(
                usage?['cache_creation_input_tokens'],
              ),
              cacheReadInputTokens: asInt(usage?['cache_read_input_tokens']),
              serviceTier: asString(usage?['service_tier']),
            )
            : null,
  );
}

/// 归一化 User 输出（data.type == 'user'）
/// 对标 normalizeUserOutput
NormalizedMessage? normalizeUserOutput(
  String messageId,
  String? localId,
  int createdAt,
  Map<String, dynamic> data, {
  dynamic meta,
}) {
  final uuid = asString(data['uuid']) ?? messageId;
  final parentUUID = asString(data['parentUuid']);
  final isSidechain = data['isSidechain'] == true;

  final message =
      isObject(data['message'])
          ? data['message'] as Map<String, dynamic>
          : null;
  if (message == null) return null;

  final messageContent = message['content'];

  // Sidechain root（content 是字符串）
  if (isSidechain && messageContent is String) {
    return NormalizedMessage(
      id: messageId,
      localId: localId,
      createdAt: createdAt,
      role: NormalizedRole.agent,
      isSidechain: true,
      agentContent: [
        NormalizedSidechainContent(uuid: uuid, prompt: messageContent),
      ],
    );
  }

  // 普通用户文本
  if (messageContent is String) {
    return NormalizedMessage(
      id: messageId,
      localId: localId,
      createdAt: createdAt,
      role: NormalizedRole.user,
      isSidechain: false,
      userContent: NormalizedUserContent(text: messageContent),
      meta: meta,
    );
  }

  // 数组内容（tool_result 等）
  final blocks = <NormalizedAgentContent>[];
  if (messageContent is List) {
    for (final block in messageContent) {
      if (!isObject(block)) continue;
      final blockMap = block as Map<String, dynamic>;
      final blockType = blockMap['type'];
      if (blockType is! String) continue;

      if (blockType == 'text' && blockMap['text'] is String) {
        blocks.add(
          NormalizedTextContent(
            text: blockMap['text'] as String,
            uuid: uuid,
            parentUUID: parentUUID,
          ),
        );
        continue;
      }

      if (blockType == 'tool_result' && blockMap['tool_use_id'] is String) {
        final isError = blockMap['is_error'] == true;
        final rawContent = blockMap['content'];
        final embeddedToolUseResult = data['toolUseResult'];
        final permissions = normalizeToolResultPermissions(
          blockMap['permissions'],
        );

        blocks.add(
          NormalizedToolResultContent(
            toolUseId: blockMap['tool_use_id'] as String,
            content: embeddedToolUseResult ?? rawContent,
            isError: isError,
            uuid: uuid,
            parentUUID: parentUUID,
            permissions: permissions,
          ),
        );
      }
    }
  }

  return NormalizedMessage(
    id: messageId,
    localId: localId,
    createdAt: createdAt,
    role: NormalizedRole.agent,
    isSidechain: isSidechain,
    agentContent: blocks,
    meta: meta,
  );
}

/// 检查是否为可跳过的 Agent 内容
bool isSkippableAgentContent(dynamic content) {
  if (!isObject(content)) return false;
  final map = content as Map<String, dynamic>;
  if (map['type'] != 'output') return false;

  final data =
      isObject(map['data']) ? map['data'] as Map<String, dynamic> : null;
  if (data == null) return false;

  return data['isMeta'] == true || data['isCompactSummary'] == true;
}

/// 检查是否为 Codex 内容
bool isCodexContent(dynamic content) {
  return isObject(content) &&
      (content as Map<String, dynamic>)['type'] == 'codex';
}

/// 归一化 Agent 记录
/// 对标 normalizeAgentRecord
NormalizedMessage? normalizeAgentRecord(
  String messageId,
  String? localId,
  int createdAt,
  dynamic content, {
  dynamic meta,
}) {
  if (!isObject(content)) return null;
  final contentMap = content as Map<String, dynamic>;
  final type = contentMap['type'];
  if (type is! String) return null;

  if (type == 'output') {
    final data =
        isObject(contentMap['data'])
            ? contentMap['data'] as Map<String, dynamic>
            : null;
    if (data == null || data['type'] is! String) return null;

    // 跳过 meta/compact-summary
    if (data['isMeta'] == true || data['isCompactSummary'] == true) return null;

    final dataType = data['type'] as String;

    if (dataType == 'assistant') {
      return normalizeAssistantOutput(
        messageId,
        localId,
        createdAt,
        data,
        meta: meta,
      );
    }

    if (dataType == 'user') {
      return normalizeUserOutput(
        messageId,
        localId,
        createdAt,
        data,
        meta: meta,
      );
    }

    if (dataType == 'summary' && data['summary'] is String) {
      return NormalizedMessage(
        id: messageId,
        localId: localId,
        createdAt: createdAt,
        role: NormalizedRole.agent,
        isSidechain: false,
        agentContent: [
          NormalizedSummaryContent(summary: data['summary'] as String),
        ],
        meta: meta,
      );
    }

    if (dataType == 'system' && data['subtype'] == 'api_error') {
      return NormalizedMessage(
        id: messageId,
        localId: localId,
        createdAt: createdAt,
        role: NormalizedRole.event,
        isSidechain: false,
        eventContent: ApiErrorEvent(
          retryAttempt: asInt(data['retryAttempt']) ?? 0,
          maxRetries: asInt(data['maxRetries']) ?? 0,
          error: data['error'],
        ),
        meta: meta,
      );
    }

    return null;
  }

  if (type == 'event') {
    final event = normalizeAgentEvent(contentMap['data']);
    if (event == null) return null;
    return NormalizedMessage(
      id: messageId,
      localId: localId,
      createdAt: createdAt,
      role: NormalizedRole.event,
      isSidechain: false,
      eventContent: event,
      meta: meta,
    );
  }

  if (type == 'codex') {
    final data =
        isObject(contentMap['data'])
            ? contentMap['data'] as Map<String, dynamic>
            : null;
    if (data == null || data['type'] is! String) return null;

    final dataType = data['type'] as String;

    if (dataType == 'message' && data['message'] is String) {
      return NormalizedMessage(
        id: messageId,
        localId: localId,
        createdAt: createdAt,
        role: NormalizedRole.agent,
        isSidechain: false,
        agentContent: [
          NormalizedTextContent(
            text: data['message'] as String,
            uuid: messageId,
            parentUUID: null,
          ),
        ],
        meta: meta,
      );
    }

    if (dataType == 'reasoning' && data['message'] is String) {
      return NormalizedMessage(
        id: messageId,
        localId: localId,
        createdAt: createdAt,
        role: NormalizedRole.agent,
        isSidechain: false,
        agentContent: [
          NormalizedReasoningContent(
            text: data['message'] as String,
            uuid: messageId,
            parentUUID: null,
          ),
        ],
        meta: meta,
      );
    }

    if (dataType == 'tool-call' && data['callId'] is String) {
      final uuid = asString(data['id']) ?? messageId;
      return NormalizedMessage(
        id: messageId,
        localId: localId,
        createdAt: createdAt,
        role: NormalizedRole.agent,
        isSidechain: false,
        agentContent: [
          NormalizedToolCallContent(
            id: data['callId'] as String,
            name: asString(data['name']) ?? 'unknown',
            input: data['input'],
            description: null,
            uuid: uuid,
            parentUUID: null,
          ),
        ],
        meta: meta,
      );
    }

    if (dataType == 'tool-call-result' && data['callId'] is String) {
      final uuid = asString(data['id']) ?? messageId;
      return NormalizedMessage(
        id: messageId,
        localId: localId,
        createdAt: createdAt,
        role: NormalizedRole.agent,
        isSidechain: false,
        agentContent: [
          NormalizedToolResultContent(
            toolUseId: data['callId'] as String,
            content: data['output'],
            isError: false,
            uuid: uuid,
            parentUUID: null,
          ),
        ],
        meta: meta,
      );
    }
  }

  return null;
}
