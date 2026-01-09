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

    /// 消息角色 (user/assistant/system)
    @Default('assistant') String role,

    /// 回复的消息 ID (用于引用)
    String? replyToId,

    /// 父消息 ID (用于 Task 子任务折叠)
    String? parentId,

    /// 内容 UUID (用于 hapi 消息追踪)
    String? contentUuid,

    /// 是否为 sidechain 消息 (Task 子任务)
    @Default(false) bool isSidechain,

    /// Task prompt (用于 sidechain root 匹配)
    String? taskPrompt,
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
    ThinkingPayload() => 'Reasoning',
    ImagePayload(:final title) => title,
    InteractivePayload(:final title) => title,
    UserMessagePayload(:final content) =>
      content.length > 30 ? '${content.substring(0, 30)}...' : content,
    TaskExecutionPayload(:final title) => title,
    HiddenPayload(:final reason) => '[Hidden: $reason]',
  };

  /// 是否为用户消息
  bool get isUserMessage => role == 'user' || payload is UserMessagePayload;

  /// 是否为 AI 助手消息
  bool get isAssistantMessage =>
      role == 'assistant' && payload is! UserMessagePayload;
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

  /// 转换为树形结构（用于 Task 子任务折叠）
  List<MessageNode> toTree() {
    // 按时间正序排序
    final sorted = [...this]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // 构建 id -> Message 映射
    final messageMap = <String, Message>{};
    // 构建 contentUuid -> id 映射 (用于通过 uuid 查找消息)
    final uuidToIdMap = <String, String>{};

    for (final msg in sorted) {
      messageMap[msg.id] = msg;
      if (msg.contentUuid != null) {
        uuidToIdMap[msg.contentUuid!] = msg.id;
      }
    }

    // 构建 parentId -> children 映射
    final childrenMap = <String, List<Message>>{};
    final rootMessages = <Message>[];

    for (final msg in sorted) {
      bool hasParent = false;

      if (msg.parentId != null) {
        // 尝试通过 ID 直接查找父消息
        if (messageMap.containsKey(msg.parentId)) {
          childrenMap.putIfAbsent(msg.parentId!, () => []).add(msg);
          hasParent = true;
        }
        // 尝试通过 contentUuid 查找父消息 ID
        else if (uuidToIdMap.containsKey(msg.parentId)) {
          final parentMsgId = uuidToIdMap[msg.parentId]!;
          childrenMap.putIfAbsent(parentMsgId, () => []).add(msg);
          hasParent = true;
        }
      }

      if (!hasParent) {
        rootMessages.add(msg);
      }
    }

    // 递归构建树节点
    List<MessageNode> buildNodes(List<Message> messages) {
      return messages.map((msg) {
        final children = childrenMap[msg.id] ?? [];
        return MessageNode(message: msg, children: buildNodes(children));
      }).toList();
    }

    return buildNodes(rootMessages);
  }
}

/// 消息树节点（用于折叠显示）
class MessageNode {
  final Message message;
  final List<MessageNode> children;

  const MessageNode({required this.message, this.children = const []});

  /// 是否有子消息
  bool get hasChildren => children.isNotEmpty;

  /// 子消息数量（递归）
  int get totalChildCount {
    int count = children.length;
    for (final child in children) {
      count += child.totalChildCount;
    }
    return count;
  }

  /// 是否为 Task 类型（需要折叠子任务）
  bool get isTask => message.payload is TaskExecutionPayload;

  /// 获取待权限的子消息（需要展开显示）
  /// 根据 hapi 文档：只有 status === 'pending' 的权限请求需要展开
  List<MessageNode> get pendingChildren {
    return children.where((node) {
      final payload = node.message.payload;
      if (payload is InteractivePayload) {
        // 只有 pending 状态的权限请求需要展开显示
        return payload.status == PermissionStatus.pending;
      }
      return false;
    }).toList();
  }

  /// 获取其他子消息（可折叠）
  /// 包括：非交互类型的消息 + 已处理的权限请求（approved/denied/canceled）
  List<MessageNode> get collapsibleChildren {
    return children.where((node) {
      final payload = node.message.payload;
      if (payload is InteractivePayload) {
        // 已处理的权限请求归入可折叠组
        return payload.status != PermissionStatus.pending;
      }
      // 其他类型都可折叠
      return true;
    }).toList();
  }
}
