// Hapi Chat 类型定义
// 对标 web/src/chat/types.ts

/// 工具调用内容
class ToolUseContent {
  final String type = 'tool-call';
  final String id;
  final String name;
  final dynamic input;
  final String? description;
  final String uuid;
  final String? parentUUID;

  const ToolUseContent({
    required this.id,
    required this.name,
    this.input,
    this.description,
    required this.uuid,
    this.parentUUID,
  });
}

/// 工具结果内容
class ToolResultContent {
  final String type = 'tool-result';
  final String toolUseId;
  final dynamic content;
  final bool isError;
  final String uuid;
  final String? parentUUID;
  final ToolResultPermission? permissions;

  const ToolResultContent({
    required this.toolUseId,
    this.content,
    this.isError = false,
    required this.uuid,
    this.parentUUID,
    this.permissions,
  });
}

/// 工具结果权限
class ToolResultPermission {
  final int date;
  final String result; // 'approved' | 'denied'
  final String? mode;
  final List<String>? allowedTools;
  final String? decision;

  const ToolResultPermission({
    required this.date,
    required this.result,
    this.mode,
    this.allowedTools,
    this.decision,
  });
}

/// 文本内容
class TextContent {
  final String type = 'text';
  final String text;
  final String uuid;
  final String? parentUUID;

  const TextContent({required this.text, required this.uuid, this.parentUUID});
}

/// 推理内容
class ReasoningContent {
  final String type = 'reasoning';
  final String text;
  final String uuid;
  final String? parentUUID;

  const ReasoningContent({
    required this.text,
    required this.uuid,
    this.parentUUID,
  });
}

/// 摘要内容
class SummaryContent {
  final String type = 'summary';
  final String summary;

  const SummaryContent({required this.summary});
}

/// Sidechain 内容
class SidechainContent {
  final String type = 'sidechain';
  final String uuid;
  final String prompt;

  const SidechainContent({required this.uuid, required this.prompt});
}

/// 归一化的 Agent 内容（联合类型）
sealed class NormalizedAgentContent {}

class NormalizedTextContent extends NormalizedAgentContent {
  final String text;
  final String uuid;
  final String? parentUUID;

  NormalizedTextContent({
    required this.text,
    required this.uuid,
    this.parentUUID,
  });
}

class NormalizedReasoningContent extends NormalizedAgentContent {
  final String text;
  final String uuid;
  final String? parentUUID;

  NormalizedReasoningContent({
    required this.text,
    required this.uuid,
    this.parentUUID,
  });
}

class NormalizedToolCallContent extends NormalizedAgentContent {
  final String id;
  final String name;
  final dynamic input;
  final String? description;
  final String uuid;
  final String? parentUUID;

  NormalizedToolCallContent({
    required this.id,
    required this.name,
    this.input,
    this.description,
    required this.uuid,
    this.parentUUID,
  });
}

class NormalizedToolResultContent extends NormalizedAgentContent {
  final String toolUseId;
  final dynamic content;
  final bool isError;
  final String uuid;
  final String? parentUUID;
  final ToolResultPermission? permissions;

  NormalizedToolResultContent({
    required this.toolUseId,
    this.content,
    this.isError = false,
    required this.uuid,
    this.parentUUID,
    this.permissions,
  });
}

class NormalizedSummaryContent extends NormalizedAgentContent {
  final String summary;

  NormalizedSummaryContent({required this.summary});
}

class NormalizedSidechainContent extends NormalizedAgentContent {
  final String uuid;
  final String prompt;

  NormalizedSidechainContent({required this.uuid, required this.prompt});
}

/// 用户消息内容
class NormalizedUserContent {
  final String text;

  const NormalizedUserContent({required this.text});
}

/// Agent 事件
sealed class AgentEvent {}

class SwitchEvent extends AgentEvent {
  final String mode; // 'local' | 'remote'
  SwitchEvent({required this.mode});
}

class MessageEvent extends AgentEvent {
  final String message;
  MessageEvent({required this.message});
}

class TitleChangedEvent extends AgentEvent {
  final String title;
  TitleChangedEvent({required this.title});
}

class LimitReachedEvent extends AgentEvent {
  final int endsAt;
  LimitReachedEvent({required this.endsAt});
}

class ReadyEvent extends AgentEvent {}

class ApiErrorEvent extends AgentEvent {
  final int retryAttempt;
  final int maxRetries;
  final dynamic error;

  ApiErrorEvent({
    required this.retryAttempt,
    required this.maxRetries,
    this.error,
  });
}

class UnknownEvent extends AgentEvent {
  final String type;
  final Map<String, dynamic> data;

  UnknownEvent({required this.type, required this.data});
}

/// 归一化消息的角色
enum NormalizedRole { user, agent, event }

/// 归一化消息
class NormalizedMessage {
  final String id;
  final String? localId;
  final int createdAt;
  final NormalizedRole role;
  final bool isSidechain;
  final dynamic meta;
  final UsageData? usage;
  final String? status;
  final String? originalText;

  // role == user 时的内容
  final NormalizedUserContent? userContent;

  // role == agent 时的内容列表
  final List<NormalizedAgentContent>? agentContent;

  // role == event 时的事件
  final AgentEvent? eventContent;

  const NormalizedMessage({
    required this.id,
    this.localId,
    required this.createdAt,
    required this.role,
    this.isSidechain = false,
    this.meta,
    this.usage,
    this.status,
    this.originalText,
    this.userContent,
    this.agentContent,
    this.eventContent,
  });

  NormalizedMessage copyWith({
    String? id,
    String? localId,
    int? createdAt,
    NormalizedRole? role,
    bool? isSidechain,
    dynamic meta,
    UsageData? usage,
    String? status,
    String? originalText,
    NormalizedUserContent? userContent,
    List<NormalizedAgentContent>? agentContent,
    AgentEvent? eventContent,
  }) {
    return NormalizedMessage(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      isSidechain: isSidechain ?? this.isSidechain,
      meta: meta ?? this.meta,
      usage: usage ?? this.usage,
      status: status ?? this.status,
      originalText: originalText ?? this.originalText,
      userContent: userContent ?? this.userContent,
      agentContent: agentContent ?? this.agentContent,
      eventContent: eventContent ?? this.eventContent,
    );
  }
}

/// Token 使用数据
class UsageData {
  final int inputTokens;
  final int outputTokens;
  final int? cacheCreationInputTokens;
  final int? cacheReadInputTokens;
  final String? serviceTier;

  const UsageData({
    required this.inputTokens,
    required this.outputTokens,
    this.cacheCreationInputTokens,
    this.cacheReadInputTokens,
    this.serviceTier,
  });
}

/// 工具权限
class ToolPermission {
  final String id;
  final String status; // 'pending' | 'approved' | 'denied' | 'canceled'
  final String? reason;
  final String? mode;
  final List<String>? allowedTools;
  final String? decision;
  final Map<String, List<String>>? answers;
  final int? date;
  final int? createdAt;
  final int? completedAt;

  const ToolPermission({
    required this.id,
    required this.status,
    this.reason,
    this.mode,
    this.allowedTools,
    this.decision,
    this.answers,
    this.date,
    this.createdAt,
    this.completedAt,
  });
}

/// 聊天工具调用状态
class ChatToolCall {
  final String id;
  String name;
  String state; // 'pending' | 'running' | 'completed' | 'error'
  dynamic input;
  int createdAt;
  int? startedAt;
  int? completedAt;
  String? description;
  dynamic result;
  ToolPermission? permission;

  ChatToolCall({
    required this.id,
    required this.name,
    required this.state,
    this.input,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.description,
    this.result,
    this.permission,
  });
}

/// 聊天块基类
sealed class ChatBlock {
  String get id;
  int get createdAt;
}

/// 用户文本块
class UserTextBlock extends ChatBlock {
  @override
  final String id;
  final String? localId;
  @override
  final int createdAt;
  final String text;
  final String? status;
  final String? originalText;
  final dynamic meta;

  UserTextBlock({
    required this.id,
    this.localId,
    required this.createdAt,
    required this.text,
    this.status,
    this.originalText,
    this.meta,
  });
}

/// Agent 文本块
class AgentTextBlock extends ChatBlock {
  @override
  final String id;
  final String? localId;
  @override
  final int createdAt;
  final String text;
  final dynamic meta;

  AgentTextBlock({
    required this.id,
    this.localId,
    required this.createdAt,
    required this.text,
    this.meta,
  });
}

/// Agent 推理块
class AgentReasoningBlock extends ChatBlock {
  @override
  final String id;
  final String? localId;
  @override
  final int createdAt;
  final String text;
  final dynamic meta;

  AgentReasoningBlock({
    required this.id,
    this.localId,
    required this.createdAt,
    required this.text,
    this.meta,
  });
}

/// CLI 输出块
class CliOutputBlock extends ChatBlock {
  @override
  final String id;
  final String? localId;
  @override
  final int createdAt;
  final String text;
  final String source; // 'user' | 'assistant'
  final dynamic meta;

  CliOutputBlock({
    required this.id,
    this.localId,
    required this.createdAt,
    required this.text,
    required this.source,
    this.meta,
  });
}

/// Agent 事件块
class AgentEventBlock extends ChatBlock {
  @override
  final String id;
  @override
  final int createdAt;
  final AgentEvent event;
  final dynamic meta;

  AgentEventBlock({
    required this.id,
    required this.createdAt,
    required this.event,
    this.meta,
  });
}

/// 工具调用块
class ToolCallBlock extends ChatBlock {
  @override
  final String id;
  final String? localId;
  @override
  int createdAt;
  final ChatToolCall tool;
  List<ChatBlock> children;
  final dynamic meta;

  ToolCallBlock({
    required this.id,
    this.localId,
    required this.createdAt,
    required this.tool,
    List<ChatBlock>? children,
    this.meta,
  }) : children = children ?? [];
}
