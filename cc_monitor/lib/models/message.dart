import 'package:freezed_annotation/freezed_annotation.dart';
import 'payload/payload.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// 消息模型
@freezed
class Message with _$Message {
  const Message._();

  const factory Message({
    /// 消息 ID
    required String id,

    /// 会话 ID
    required String sessionId,

    /// 消息负载
    required Payload payload,

    /// 项目名称
    required String projectName,

    /// 项目路径
    String? projectPath,

    /// Hook 事件类型
    String? hookEvent,

    /// 工具名称 (如果是工具相关消息)
    String? toolName,

    /// 是否已读
    @Default(false) bool isRead,

    /// 创建时间
    required DateTime createdAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  /// 获取消息类型
  String get type => payload.type;

  /// 获取消息标题
  String get title => switch (payload) {
    ProgressPayload(:final title) => title,
    CompletePayload(:final title) => title,
    ErrorPayload(:final title) => title,
    WarningPayload(:final title) => title,
    CodePayload(:final title) => title,
    MarkdownPayload(:final title) => title,
    ImagePayload(:final title) => title,
    InteractivePayload(:final title) => title,
  };
}

/// 消息列表扩展
extension MessageListExtension on List<Message> {
  /// 按时间倒序排序
  List<Message> sortedByTime() {
    return [...this]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 未读消息数
  int get unreadCount => where((m) => !m.isRead).length;

  /// 按会话分组
  Map<String, List<Message>> groupBySession() {
    final map = <String, List<Message>>{};
    for (final message in this) {
      map.putIfAbsent(message.sessionId, () => []).add(message);
    }
    return map;
  }
}
