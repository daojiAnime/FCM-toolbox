// User 消息归一化
// 对标 web/src/chat/normalizeUser.ts

import 'types.dart';
import 'normalize_utils.dart';

/// 归一化 User 记录
/// 对标 normalizeUserRecord
NormalizedMessage? normalizeUserRecord(
  String messageId,
  String? localId,
  int createdAt,
  dynamic content, {
  dynamic meta,
}) {
  if (content is String) {
    return NormalizedMessage(
      id: messageId,
      localId: localId,
      createdAt: createdAt,
      role: NormalizedRole.user,
      isSidechain: false,
      userContent: NormalizedUserContent(text: content),
      meta: meta,
    );
  }

  if (isObject(content)) {
    final map = content as Map<String, dynamic>;
    if (map['type'] == 'text' && map['text'] is String) {
      return NormalizedMessage(
        id: messageId,
        localId: localId,
        createdAt: createdAt,
        role: NormalizedRole.user,
        isSidechain: false,
        userContent: NormalizedUserContent(text: map['text'] as String),
        meta: meta,
      );
    }
  }

  return null;
}
