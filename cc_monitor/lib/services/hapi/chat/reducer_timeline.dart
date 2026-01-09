// Timeline Reducer
// 对标 web/src/chat/reducerTimeline.ts
// 核心：遍历消息构建 ChatBlock，tool-result 关联到 tool-call

import 'types.dart';
import 'tracer.dart';
import 'reducer_tools.dart';

/// Reducer 上下文
class ReducerContext {
  final Map<String, PermissionEntry> permissionsById;
  final Map<String, List<TracedMessage>> groups;
  final Set<String> consumedGroupIds;
  final Map<String, String> titleChangesByToolUseId;
  final Set<String> emittedTitleChangeToolUseIds;

  ReducerContext({
    required this.permissionsById,
    required this.groups,
    required this.consumedGroupIds,
    required this.titleChangesByToolUseId,
    required this.emittedTitleChangeToolUseIds,
  });
}

/// Timeline Reducer 结果
class TimelineReducerResult {
  final List<ChatBlock> blocks;
  final Map<String, ToolCallBlock> toolBlocksById;
  final bool hasReadyEvent;

  TimelineReducerResult({
    required this.blocks,
    required this.toolBlocksById,
    required this.hasReadyEvent,
  });
}

/// 提取 tool result 内容为字符串
String? _extractResultContent(dynamic content) {
  if (content == null) return null;
  if (content is String) return content;
  if (content is List) {
    final texts = <String>[];
    for (final item in content) {
      if (item is Map && item['type'] == 'text' && item['text'] is String) {
        texts.add(item['text'] as String);
      }
    }
    return texts.isNotEmpty ? texts.join('\n') : null;
  }
  return content.toString();
}

/// Reduce timeline
/// 对标 reduceTimeline
TimelineReducerResult reduceTimeline(
  List<TracedMessage> messages,
  ReducerContext context,
) {
  final blocks = <ChatBlock>[];
  final toolBlocksById = <String, ToolCallBlock>{};
  var hasReadyEvent = false;

  for (final msg in messages) {
    // Event 消息
    if (msg.role == NormalizedRole.event) {
      final event = msg.eventContent;
      if (event is ReadyEvent) {
        hasReadyEvent = true;
        continue;
      }
      if (event != null) {
        blocks.add(
          AgentEventBlock(
            id: msg.id,
            createdAt: msg.createdAt,
            event: event,
            meta: msg.meta,
          ),
        );
      }
      continue;
    }

    // User 消息
    if (msg.role == NormalizedRole.user) {
      final userContent = msg.userContent;
      if (userContent != null) {
        blocks.add(
          UserTextBlock(
            id: msg.id,
            localId: msg.localId,
            createdAt: msg.createdAt,
            text: userContent.text,
            status: msg.status,
            originalText: msg.originalText,
            meta: msg.meta,
          ),
        );
      }
      continue;
    }

    // Agent 消息
    if (msg.role == NormalizedRole.agent) {
      final content = msg.agentContent;
      if (content == null) continue;

      for (var idx = 0; idx < content.length; idx++) {
        final c = content[idx];

        // 文本
        if (c is NormalizedTextContent) {
          blocks.add(
            AgentTextBlock(
              id: '${msg.id}:$idx',
              localId: msg.localId,
              createdAt: msg.createdAt,
              text: c.text,
              meta: msg.meta,
            ),
          );
          continue;
        }

        // 推理
        if (c is NormalizedReasoningContent) {
          blocks.add(
            AgentReasoningBlock(
              id: '${msg.id}:$idx',
              localId: msg.localId,
              createdAt: msg.createdAt,
              text: c.text,
              meta: msg.meta,
            ),
          );
          continue;
        }

        // 摘要
        if (c is NormalizedSummaryContent) {
          blocks.add(
            AgentEventBlock(
              id: '${msg.id}:$idx',
              createdAt: msg.createdAt,
              event: MessageEvent(message: c.summary),
              meta: msg.meta,
            ),
          );
          continue;
        }

        // 工具调用
        if (c is NormalizedToolCallContent) {
          // 跳过改标题工具
          if (isChangeTitleToolName(c.name)) {
            final title =
                context.titleChangesByToolUseId[c.id] ??
                extractTitleFromChangeTitleInput(c.input);
            if (title != null &&
                !context.emittedTitleChangeToolUseIds.contains(c.id)) {
              context.emittedTitleChangeToolUseIds.add(c.id);
              blocks.add(
                AgentEventBlock(
                  id: '${msg.id}:$idx',
                  createdAt: msg.createdAt,
                  event: TitleChangedEvent(title: title),
                  meta: msg.meta,
                ),
              );
            }
            continue;
          }

          final permission = context.permissionsById[c.id]?.permission;

          final block = ensureToolBlock(
            blocks,
            toolBlocksById,
            c.id,
            createdAt: msg.createdAt,
            localId: msg.localId,
            meta: msg.meta,
            name: c.name,
            input: c.input,
            description: c.description,
            permission: permission,
          );

          if (block.tool.state == 'pending') {
            block.tool.state = 'running';
            block.tool.startedAt = msg.createdAt;
          }

          // Task 工具：处理 sidechain 子消息
          if (c.name == 'Task' && !context.consumedGroupIds.contains(msg.id)) {
            final sidechain = context.groups[msg.id];
            if (sidechain != null && sidechain.isNotEmpty) {
              context.consumedGroupIds.add(msg.id);
              final child = reduceTimeline(sidechain, context);
              hasReadyEvent = hasReadyEvent || child.hasReadyEvent;
              block.children = child.blocks;
            }
          }
          continue;
        }

        // 工具结果 - 核心：关联到对应的 tool-call
        if (c is NormalizedToolResultContent) {
          // 跳过改标题工具结果
          final title = context.titleChangesByToolUseId[c.toolUseId];
          if (title != null) {
            if (!context.emittedTitleChangeToolUseIds.contains(c.toolUseId)) {
              context.emittedTitleChangeToolUseIds.add(c.toolUseId);
              blocks.add(
                AgentEventBlock(
                  id: '${msg.id}:$idx',
                  createdAt: msg.createdAt,
                  event: TitleChangedEvent(title: title),
                  meta: msg.meta,
                ),
              );
            }
            continue;
          }

          // 获取权限
          final permissionEntry = context.permissionsById[c.toolUseId];
          ToolPermission? permission;

          if (c.permissions != null) {
            final permissionFromResult = ToolPermission(
              id: c.toolUseId,
              status:
                  c.permissions!.result == 'approved' ? 'approved' : 'denied',
              date: c.permissions!.date,
              mode: c.permissions!.mode,
              allowedTools: c.permissions!.allowedTools,
              decision: c.permissions!.decision,
            );

            if (permissionEntry?.permission != null) {
              permission = ToolPermission(
                id: permissionFromResult.id,
                status: permissionFromResult.status,
                reason: permissionEntry!.permission.reason,
                mode:
                    permissionFromResult.mode ??
                    permissionEntry.permission.mode,
                allowedTools:
                    permissionFromResult.allowedTools ??
                    permissionEntry.permission.allowedTools,
                decision:
                    permissionFromResult.decision ??
                    permissionEntry.permission.decision,
                answers: permissionEntry.permission.answers,
                date: permissionFromResult.date,
                createdAt: permissionEntry.permission.createdAt,
                completedAt: permissionEntry.permission.completedAt,
              );
            } else {
              permission = permissionFromResult;
            }
          } else {
            permission = permissionEntry?.permission;
          }

          // 确保 tool block 存在并更新结果
          final block = ensureToolBlock(
            blocks,
            toolBlocksById,
            c.toolUseId,
            createdAt: msg.createdAt,
            localId: msg.localId,
            meta: msg.meta,
            name: permissionEntry?.toolName ?? 'Tool',
            input: permissionEntry?.input,
            description: null,
            permission: permission,
          );

          // ========== 核心：设置 result ==========
          block.tool.result = _extractResultContent(c.content);
          block.tool.completedAt = msg.createdAt;
          block.tool.state = c.isError ? 'error' : 'completed';
          continue;
        }

        // Sidechain 内容
        if (c is NormalizedSidechainContent) {
          blocks.add(
            UserTextBlock(
              id: '${msg.id}:$idx',
              localId: null,
              createdAt: msg.createdAt,
              text: c.prompt,
            ),
          );
        }
      }
    }
  }

  return TimelineReducerResult(
    blocks: blocks,
    toolBlocksById: toolBlocksById,
    hasReadyEvent: hasReadyEvent,
  );
}
