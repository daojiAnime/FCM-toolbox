// 消息归一化入口
// 对标 web/src/chat/normalize.ts

import 'types.dart';
import 'normalize_utils.dart';
import 'normalize_agent.dart';
import 'normalize_user.dart';

/// 解包 role-wrapped record envelope
/// 对标 unwrapRoleWrappedRecordEnvelope
({String role, dynamic content, dynamic meta})? unwrapRoleWrappedRecordEnvelope(
  dynamic content,
) {
  if (!isObject(content)) return null;
  final map = content as Map<String, dynamic>;
  final role = map['role'];
  if (role is! String) return null;
  return (role: role, content: map['content'], meta: map['meta']);
}

/// 归一化解密消息
/// 对标 normalizeDecryptedMessage
NormalizedMessage? normalizeDecryptedMessage({
  required String id,
  String? localId,
  required int createdAt,
  required dynamic content,
  String? status,
  String? originalText,
}) {
  final record = unwrapRoleWrappedRecordEnvelope(content);
  if (record == null) {
    // 无法解包，作为文本处理
    return NormalizedMessage(
      id: id,
      localId: localId,
      createdAt: createdAt,
      role: NormalizedRole.agent,
      isSidechain: false,
      agentContent: [
        NormalizedTextContent(
          text: safeStringify(content),
          uuid: id,
          parentUUID: null,
        ),
      ],
      status: status,
      originalText: originalText,
    );
  }

  if (record.role == 'user') {
    final normalized = normalizeUserRecord(
      id,
      localId,
      createdAt,
      record.content,
      meta: record.meta,
    );
    if (normalized != null) {
      return normalized.copyWith(status: status, originalText: originalText);
    }
    // 回退到文本
    return NormalizedMessage(
      id: id,
      localId: localId,
      createdAt: createdAt,
      role: NormalizedRole.user,
      isSidechain: false,
      userContent: NormalizedUserContent(text: safeStringify(record.content)),
      meta: record.meta,
      status: status,
      originalText: originalText,
    );
  }

  if (record.role == 'agent') {
    if (isSkippableAgentContent(record.content)) {
      return null;
    }
    final normalized = normalizeAgentRecord(
      id,
      localId,
      createdAt,
      record.content,
      meta: record.meta,
    );
    if (normalized == null && isCodexContent(record.content)) {
      return null;
    }
    if (normalized != null) {
      return normalized.copyWith(status: status, originalText: originalText);
    }
    // 回退到文本
    return NormalizedMessage(
      id: id,
      localId: localId,
      createdAt: createdAt,
      role: NormalizedRole.agent,
      isSidechain: false,
      agentContent: [
        NormalizedTextContent(
          text: safeStringify(record.content),
          uuid: id,
          parentUUID: null,
        ),
      ],
      meta: record.meta,
      status: status,
      originalText: originalText,
    );
  }

  // 其他角色回退到 agent 文本
  return NormalizedMessage(
    id: id,
    localId: localId,
    createdAt: createdAt,
    role: NormalizedRole.agent,
    isSidechain: false,
    agentContent: [
      NormalizedTextContent(
        text: safeStringify(record.content),
        uuid: id,
        parentUUID: null,
      ),
    ],
    meta: record.meta,
    status: status,
    originalText: originalText,
  );
}
