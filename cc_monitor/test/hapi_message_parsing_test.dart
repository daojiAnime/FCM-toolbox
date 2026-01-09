import 'package:flutter_test/flutter_test.dart';
import 'package:cc_monitor/models/message.dart';
import 'package:cc_monitor/models/payload/payload.dart';
import 'package:cc_monitor/models/task.dart';
import 'package:cc_monitor/services/message_tracer.dart';

/// 模拟 hapi API 返回的消息数据结构
/// 参考真实 API 返回格式：content.content.data.{parentUuid, uuid, isSidechain, message}
class MockHapiMessageParser {
  /// 解析单条历史消息（从 API 返回的原始数据）
  static Message? parseHistoryMessage(
    Map<String, dynamic> data,
    String sessionId,
  ) {
    final id = data['id'] as String?;
    if (id == null) return null;

    final createdAtMs = data['createdAt'] as int?;
    final createdAt =
        createdAtMs != null
            ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
            : DateTime.now();

    // content 可能是 String 或 Map
    final contentField = data['content'];
    if (contentField == null) return null;

    if (contentField is String) {
      return Message(
        id: id,
        sessionId: sessionId,
        payload: MarkdownPayload(title: 'Claude', content: contentField),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'assistant',
      );
    }

    final contentWrapper = contentField as Map<String, dynamic>?;
    if (contentWrapper == null) return null;

    final innerContentField = contentWrapper['content'];
    if (innerContentField == null) return null;

    if (innerContentField is String) {
      return Message(
        id: id,
        sessionId: sessionId,
        payload: MarkdownPayload(title: 'Claude', content: innerContentField),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'assistant',
      );
    }

    final innerContent = innerContentField as Map<String, dynamic>?;
    if (innerContent == null) return null;

    // ========== 关键：检查消息类型是 "output" 还是 "event" ==========
    final contentType = innerContent['type'] as String?;

    // Event 消息：ready, switch, message 等系统事件
    if (contentType == 'event') {
      final eventData = innerContent['data'] as Map<String, dynamic>?;
      if (eventData == null) return null;

      final eventType = eventData['type'] as String?;
      // 跳过系统事件消息（ready, switch 等不需要显示在聊天中）
      if (eventType == 'ready' || eventType == 'switch') {
        return null;
      }

      // 其他事件类型（如 message）可以创建系统消息
      final eventMessage = eventData['message'] as String?;
      if (eventMessage != null && eventMessage.isNotEmpty) {
        return Message(
          id: id,
          sessionId: sessionId,
          payload: MarkdownPayload(title: '系统消息', content: eventMessage),
          projectName: 'hapi',
          createdAt: createdAt,
          role: 'system',
        );
      }
      return null;
    }

    // Output 消息：正常的聊天消息
    if (contentType != 'output') {
      return null;
    }

    final innerDataField = innerContent['data'];
    if (innerDataField == null) return null;

    if (innerDataField is String) {
      return Message(
        id: id,
        sessionId: sessionId,
        payload: MarkdownPayload(title: 'Claude', content: innerDataField),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'assistant',
      );
    }

    final innerData = innerDataField as Map<String, dynamic>?;
    if (innerData == null) return null;

    final msgType = innerData['type'] as String?;
    final parentUuid = innerData['parentUuid'] as String?;
    final contentUuid = innerData['uuid'] as String?;
    final isSidechain = innerData['isSidechain'] as bool? ?? false;
    final taskPrompt =
        innerData['taskPrompt'] as String? ?? innerData['prompt'] as String?;

    final messageField = innerData['message'];

    // 关键修复：对于没有 message 字段但有 uuid 的 sidechain 消息，创建占位符
    if (messageField == null) {
      if (isSidechain && contentUuid != null) {
        return Message(
          id: id,
          sessionId: sessionId,
          payload: const MarkdownPayload(title: 'Processing...', content: ''),
          projectName: 'hapi',
          createdAt: createdAt,
          role: 'assistant',
          parentId: parentUuid,
          contentUuid: contentUuid,
          isSidechain: isSidechain,
          taskPrompt: taskPrompt,
        );
      }
      return null;
    }

    if (messageField is String) {
      return Message(
        id: id,
        sessionId: sessionId,
        payload:
            msgType == 'user'
                ? UserMessagePayload(content: messageField)
                : MarkdownPayload(title: 'Claude', content: messageField),
        projectName: 'hapi',
        createdAt: createdAt,
        role: msgType ?? 'assistant',
        parentId: parentUuid,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    }

    final messageObj = messageField as Map<String, dynamic>?;
    if (messageObj == null) return null;

    // ========== 根据消息类型分别处理 ==========
    if (msgType == 'user') {
      return _parseUserMessage(
        id,
        sessionId,
        messageObj,
        createdAt,
        parentUuid,
        contentUuid,
        isSidechain,
        taskPrompt,
      );
    }

    // 解析 assistant 消息内容
    final contentList = messageObj['content'];
    if (contentList is! List) {
      if (contentList is String && contentList.isNotEmpty) {
        return Message(
          id: id,
          sessionId: sessionId,
          payload: MarkdownPayload(title: 'Claude', content: contentList),
          projectName: 'hapi',
          createdAt: createdAt,
          role: 'assistant',
          parentId: parentUuid,
          contentUuid: contentUuid,
          isSidechain: isSidechain,
          taskPrompt: taskPrompt,
        );
      }
      // 关键修复：contentList 不是 List 也不是非空 String，但是 sidechain 消息需要保留
      if (isSidechain && contentUuid != null) {
        return Message(
          id: id,
          sessionId: sessionId,
          payload: const MarkdownPayload(title: 'Processing...', content: ''),
          projectName: 'hapi',
          createdAt: createdAt,
          role: 'assistant',
          parentId: parentUuid,
          contentUuid: contentUuid,
          isSidechain: isSidechain,
          taskPrompt: taskPrompt,
        );
      }
      return null;
    }

    // contentList 是 List 但可能为空
    if (contentList.isEmpty) {
      if (isSidechain && contentUuid != null) {
        return Message(
          id: id,
          sessionId: sessionId,
          payload: const MarkdownPayload(title: 'Processing...', content: ''),
          projectName: 'hapi',
          createdAt: createdAt,
          role: 'assistant',
          parentId: parentUuid,
          contentUuid: contentUuid,
          isSidechain: isSidechain,
          taskPrompt: taskPrompt,
        );
      }
      return null;
    }

    // 收集文本内容
    final textParts = <String>[];
    bool hasToolUse = false;

    for (final item in contentList) {
      if (item is! Map<String, dynamic>) continue;
      final itemType = item['type'] as String?;
      if (itemType == 'text') {
        final text = item['text'] as String? ?? '';
        if (text.isNotEmpty) textParts.add(text);
      } else if (itemType == 'tool_use') {
        hasToolUse = true;
      }
    }

    if (hasToolUse) {
      return Message(
        id: id,
        sessionId: sessionId,
        payload: TaskExecutionPayload(
          title: '执行工具',
          tasks: const [],
          overallStatus: TaskStatus.completed,
          prompt: taskPrompt,
        ),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'assistant',
        parentId: parentUuid,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    } else if (textParts.isNotEmpty) {
      return Message(
        id: id,
        sessionId: sessionId,
        payload: MarkdownPayload(
          title: 'Claude',
          content: textParts.join('\n'),
        ),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'assistant',
        parentId: parentUuid,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    }

    // 空内容但有 uuid 的 sidechain，创建占位符
    if (isSidechain && contentUuid != null) {
      return Message(
        id: id,
        sessionId: sessionId,
        payload: const MarkdownPayload(title: 'Processing...', content: ''),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'assistant',
        parentId: parentUuid,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    }

    return null;
  }

  /// 解析用户历史消息（支持 tool_result 类型）
  static Message? _parseUserMessage(
    String id,
    String sessionId,
    Map<String, dynamic> messageObj,
    DateTime createdAt,
    String? parentId,
    String? contentUuid,
    bool isSidechain,
    String? taskPrompt,
  ) {
    final contentParts = <String>[];
    final toolResults = <Map<String, dynamic>>[];

    final contentList = messageObj['content'];
    if (contentList is List) {
      for (final item in contentList) {
        if (item is Map<String, dynamic>) {
          final itemType = item['type'] as String?;

          if (itemType == 'text') {
            final text = item['text'] as String? ?? '';
            if (text.isNotEmpty) {
              contentParts.add(text);
            }
          } else if (itemType == 'tool_result') {
            // tool_result 不显示在聊天界面，使用 HiddenPayload
            final toolUseId = item['tool_use_id'] as String?;
            toolResults.add({'tool_use_id': toolUseId});
          }
        } else if (item is String) {
          contentParts.add(item);
        }
      }
    } else if (contentList is String) {
      contentParts.add(contentList);
    }

    if (contentParts.isNotEmpty) {
      return Message(
        id: id,
        sessionId: sessionId,
        payload: UserMessagePayload(content: contentParts.join('\n')),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'user',
        parentId: parentId,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    }

    // 只有 tool_result（无文本）：创建隐藏消息保持链完整性
    if (toolResults.isNotEmpty) {
      final toolUseId = toolResults.first['tool_use_id'] as String?;
      return Message(
        id: id,
        sessionId: sessionId,
        payload: HiddenPayload(reason: 'tool_result', toolUseId: toolUseId),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'user',
        parentId: parentId,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    }

    // sidechain 消息创建隐藏占位符
    if (isSidechain && contentUuid != null) {
      return Message(
        id: id,
        sessionId: sessionId,
        payload: const HiddenPayload(reason: 'empty_sidechain'),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'user',
        parentId: parentId,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    }

    return null;
  }
}

void main() {
  group('Hapi Message Parsing Tests', () {
    const sessionId = 'test-session';

    test('解析带有完整 sidechain 字段的消息', () {
      final rawData = {
        'id': 'msg-001',
        'createdAt': 1704067200000,
        'content': {
          'role': 'agent',
          'content': {
            'type': 'output',
            'data': {
              'type': 'assistant',
              'parentUuid': 'parent-uuid-001',
              'uuid': 'uuid-001',
              'isSidechain': true,
              'message': {
                'role': 'assistant',
                'content': [
                  {'type': 'text', 'text': 'Hello world'},
                ],
              },
            },
          },
        },
      };

      final message = MockHapiMessageParser.parseHistoryMessage(
        rawData,
        sessionId,
      );

      expect(message, isNotNull);
      expect(message!.id, equals('msg-001'));
      expect(message.parentId, equals('parent-uuid-001'));
      expect(message.contentUuid, equals('uuid-001'));
      expect(message.isSidechain, isTrue);
    });

    test('解析没有 message 字段但有 uuid 的 sidechain 消息应创建占位符', () {
      final rawData = {
        'id': 'msg-002',
        'createdAt': 1704067200000,
        'content': {
          'role': 'agent',
          'content': {
            'type': 'output',
            'data': {
              'type': 'assistant',
              'parentUuid': 'parent-uuid-002',
              'uuid': 'uuid-002',
              'isSidechain': true,
              // 注意：没有 message 字段
            },
          },
        },
      };

      final message = MockHapiMessageParser.parseHistoryMessage(
        rawData,
        sessionId,
      );

      expect(message, isNotNull, reason: '应该创建占位符消息以保留链');
      expect(message!.contentUuid, equals('uuid-002'));
      expect(message.parentId, equals('parent-uuid-002'));
      expect(message.isSidechain, isTrue);
    });

    test('解析有 message 但 content 为空的 sidechain 消息应创建占位符', () {
      final rawData = {
        'id': 'msg-003',
        'createdAt': 1704067200000,
        'content': {
          'role': 'agent',
          'content': {
            'type': 'output',
            'data': {
              'type': 'assistant',
              'parentUuid': 'parent-uuid-003',
              'uuid': 'uuid-003',
              'isSidechain': true,
              'message': {
                'role': 'assistant',
                'content': [], // 空的 content 数组
              },
            },
          },
        },
      };

      final message = MockHapiMessageParser.parseHistoryMessage(
        rawData,
        sessionId,
      );

      expect(message, isNotNull, reason: '应该创建占位符消息以保留链');
      expect(message!.contentUuid, equals('uuid-003'));
      expect(message.isSidechain, isTrue);
    });

    test('解析有 message 但 content 不是 List 的 sidechain 消息应创建占位符', () {
      final rawData = {
        'id': 'msg-004',
        'createdAt': 1704067200000,
        'content': {
          'role': 'agent',
          'content': {
            'type': 'output',
            'data': {
              'type': 'assistant',
              'parentUuid': 'parent-uuid-004',
              'uuid': 'uuid-004',
              'isSidechain': true,
              'message': {
                'role': 'assistant',
                'content': null, // content 为 null
              },
            },
          },
        },
      };

      final message = MockHapiMessageParser.parseHistoryMessage(
        rawData,
        sessionId,
      );

      expect(message, isNotNull, reason: '应该创建占位符消息以保留链');
      expect(message!.contentUuid, equals('uuid-004'));
      expect(message.isSidechain, isTrue);
    });

    test('解析非 sidechain 的 Task 消息', () {
      final rawData = {
        'id': 'task-001',
        'createdAt': 1704067200000,
        'content': {
          'role': 'agent',
          'content': {
            'type': 'output',
            'data': {
              'type': 'assistant',
              'uuid': 'task-uuid-001',
              'isSidechain': false,
              'message': {
                'role': 'assistant',
                'content': [
                  {'type': 'tool_use', 'name': 'Task', 'id': 'tool-1'},
                ],
              },
            },
          },
        },
      };

      final message = MockHapiMessageParser.parseHistoryMessage(
        rawData,
        sessionId,
      );

      expect(message, isNotNull);
      expect(message!.contentUuid, equals('task-uuid-001'));
      expect(message.isSidechain, isFalse);
      expect(message.payload, isA<TaskExecutionPayload>());
    });
  });

  group('End-to-End Message Chain Tests', () {
    const sessionId = 'test-session';

    test('完整的 sidechain 链应该正确归组', () {
      // 模拟真实的 API 返回数据：1 个 Task + 5 个链式 sidechain
      final rawMessages = [
        // Task 消息（非 sidechain，是根）
        {
          'id': 'task-msg',
          'createdAt': 1704067200000,
          'content': {
            'role': 'agent',
            'content': {
              'type': 'output',
              'data': {
                'type': 'assistant',
                'uuid': 'task-uuid',
                'isSidechain': false,
                'message': {
                  'role': 'assistant',
                  'content': [
                    {'type': 'tool_use', 'name': 'Task', 'id': 'tool-1'},
                  ],
                },
              },
            },
          },
        },
        // Sidechain 1: parentUuid 指向 Task
        {
          'id': 'sc-1',
          'createdAt': 1704067201000,
          'content': {
            'role': 'agent',
            'content': {
              'type': 'output',
              'data': {
                'type': 'assistant',
                'parentUuid': 'task-uuid',
                'uuid': 'sc-uuid-1',
                'isSidechain': true,
                'message': {
                  'role': 'assistant',
                  'content': [
                    {'type': 'text', 'text': 'Step 1'},
                  ],
                },
              },
            },
          },
        },
        // Sidechain 2: parentUuid 指向 sc-1
        {
          'id': 'sc-2',
          'createdAt': 1704067202000,
          'content': {
            'role': 'agent',
            'content': {
              'type': 'output',
              'data': {
                'type': 'assistant',
                'parentUuid': 'sc-uuid-1',
                'uuid': 'sc-uuid-2',
                'isSidechain': true,
                'message': {
                  'role': 'assistant',
                  'content': [
                    {'type': 'text', 'text': 'Step 2'},
                  ],
                },
              },
            },
          },
        },
        // Sidechain 3: 没有 message 字段（应创建占位符）
        {
          'id': 'sc-3',
          'createdAt': 1704067203000,
          'content': {
            'role': 'agent',
            'content': {
              'type': 'output',
              'data': {
                'type': 'assistant',
                'parentUuid': 'sc-uuid-2',
                'uuid': 'sc-uuid-3',
                'isSidechain': true,
                // 没有 message 字段
              },
            },
          },
        },
        // Sidechain 4: parentUuid 指向 sc-3
        {
          'id': 'sc-4',
          'createdAt': 1704067204000,
          'content': {
            'role': 'agent',
            'content': {
              'type': 'output',
              'data': {
                'type': 'assistant',
                'parentUuid': 'sc-uuid-3',
                'uuid': 'sc-uuid-4',
                'isSidechain': true,
                'message': {
                  'role': 'assistant',
                  'content': [
                    {'type': 'text', 'text': 'Step 4'},
                  ],
                },
              },
            },
          },
        },
        // Sidechain 5: parentUuid 指向 sc-4
        {
          'id': 'sc-5',
          'createdAt': 1704067205000,
          'content': {
            'role': 'agent',
            'content': {
              'type': 'output',
              'data': {
                'type': 'assistant',
                'parentUuid': 'sc-uuid-4',
                'uuid': 'sc-uuid-5',
                'isSidechain': true,
                'message': {
                  'role': 'assistant',
                  'content': [
                    {'type': 'text', 'text': 'Step 5'},
                  ],
                },
              },
            },
          },
        },
      ];

      // 解析所有消息
      final messages = <Message>[];
      for (final raw in rawMessages) {
        final msg = MockHapiMessageParser.parseHistoryMessage(raw, sessionId);
        if (msg != null) messages.add(msg);
      }

      print(
        'Parsed ${messages.length} messages from ${rawMessages.length} raw',
      );
      for (final msg in messages) {
        print(
          '  ${msg.id}: isSidechain=${msg.isSidechain}, parentId=${msg.parentId}, uuid=${msg.contentUuid}',
        );
      }

      // 应该解析出 6 条消息（包括占位符）
      expect(messages.length, equals(6), reason: '应该解析出 6 条消息（包括 sc-3 的占位符）');

      // 使用 MessageTracer 处理
      final tree = MessageTracer.processMessages(messages);

      print('Tree structure:');
      for (final node in tree) {
        print('  ${node.message.id}: children=${node.children.length}');
        for (final child in node.children) {
          print('    - ${child.message.id}');
        }
      }

      // 应该只有 1 个根节点（Task）
      expect(tree.length, equals(1), reason: '应该只有 1 个根节点');
      expect(tree[0].message.id, equals('task-msg'));

      // Task 应该有 5 个子节点（所有 sidechain）
      expect(
        tree[0].children.length,
        equals(5),
        reason: 'Task 应该有 5 个 sidechain 子节点',
      );
    });

    test('链中间缺失消息时仍应尽可能归组', () {
      // 模拟链中间消息缺失的情况
      final rawMessages = [
        // Task 消息
        {
          'id': 'task-msg',
          'createdAt': 1704067200000,
          'content': {
            'role': 'agent',
            'content': {
              'type': 'output',
              'data': {
                'type': 'assistant',
                'uuid': 'task-uuid',
                'isSidechain': false,
                'message': {
                  'role': 'assistant',
                  'content': [
                    {'type': 'tool_use', 'name': 'Task', 'id': 'tool-1'},
                  ],
                },
              },
            },
          },
        },
        // Sidechain 1: parentUuid 指向 Task
        {
          'id': 'sc-1',
          'createdAt': 1704067201000,
          'content': {
            'role': 'agent',
            'content': {
              'type': 'output',
              'data': {
                'type': 'assistant',
                'parentUuid': 'task-uuid',
                'uuid': 'sc-uuid-1',
                'isSidechain': true,
                'message': {
                  'role': 'assistant',
                  'content': [
                    {'type': 'text', 'text': 'Step 1'},
                  ],
                },
              },
            },
          },
        },
        // 注意：sc-2 缺失！
        // Sidechain 3: parentUuid 指向不存在的 sc-uuid-2
        {
          'id': 'sc-3',
          'createdAt': 1704067203000,
          'content': {
            'role': 'agent',
            'content': {
              'type': 'output',
              'data': {
                'type': 'assistant',
                'parentUuid': 'sc-uuid-2', // 这个 uuid 不存在！
                'uuid': 'sc-uuid-3',
                'isSidechain': true,
                'taskPrompt': 'Do something', // 有 taskPrompt 用于备选匹配
                'message': {
                  'role': 'assistant',
                  'content': [
                    {'type': 'text', 'text': 'Step 3'},
                  ],
                },
              },
            },
          },
        },
      ];

      // 为 Task 添加 prompt 以支持 taskPrompt 匹配
      (rawMessages[0]['content'] as Map)['content']['data']['prompt'] =
          'Do something';

      final messages = <Message>[];
      for (final raw in rawMessages) {
        final msg = MockHapiMessageParser.parseHistoryMessage(raw, sessionId);
        if (msg != null) messages.add(msg);
      }

      // 修改 Task 消息的 payload 以包含 prompt
      final taskMsg = messages[0];
      messages[0] = taskMsg.copyWith(
        payload: TaskExecutionPayload(
          title: '执行工具',
          tasks: const [],
          overallStatus: TaskStatus.completed,
          prompt: 'Do something',
        ),
      );

      print('Messages with missing chain link:');
      for (final msg in messages) {
        print(
          '  ${msg.id}: parentId=${msg.parentId}, uuid=${msg.contentUuid}, taskPrompt=${msg.taskPrompt}',
        );
      }

      final tree = MessageTracer.processMessages(messages);

      print('Tree with missing link:');
      for (final node in tree) {
        print('  ${node.message.id}: children=${node.children.length}');
      }

      // Task 应该至少有 sc-1（通过 uuid 链）
      final taskNode = tree.firstWhere((n) => n.message.id == 'task-msg');
      expect(
        taskNode.children.any((c) => c.message.id == 'sc-1'),
        isTrue,
        reason: 'sc-1 应该通过 uuid 链归入 Task',
      );

      // sc-3 应该通过 taskPrompt 匹配归入 Task
      expect(
        taskNode.children.any((c) => c.message.id == 'sc-3'),
        isTrue,
        reason: 'sc-3 应该通过 taskPrompt 匹配归入 Task',
      );
    });

    test('多个 Task 各自拥有各自的 sidechain', () {
      final rawMessages = [
        // Task 1
        {
          'id': 'task-1',
          'createdAt': 1704067200000,
          'content': {
            'role': 'agent',
            'content': {
              'type': 'output',
              'data': {
                'type': 'assistant',
                'uuid': 'task-1-uuid',
                'isSidechain': false,
                'message': {
                  'role': 'assistant',
                  'content': [
                    {'type': 'tool_use', 'name': 'Task', 'id': 't1'},
                  ],
                },
              },
            },
          },
        },
        // Task 1 的 sidechain
        {
          'id': 'sc-1-1',
          'createdAt': 1704067201000,
          'content': {
            'role': 'agent',
            'content': {
              'type': 'output',
              'data': {
                'type': 'assistant',
                'parentUuid': 'task-1-uuid',
                'uuid': 'sc-1-1-uuid',
                'isSidechain': true,
                'message': {
                  'role': 'assistant',
                  'content': [
                    {'type': 'text', 'text': 'Task 1 work'},
                  ],
                },
              },
            },
          },
        },
        // Task 2
        {
          'id': 'task-2',
          'createdAt': 1704067202000,
          'content': {
            'role': 'agent',
            'content': {
              'type': 'output',
              'data': {
                'type': 'assistant',
                'uuid': 'task-2-uuid',
                'isSidechain': false,
                'message': {
                  'role': 'assistant',
                  'content': [
                    {'type': 'tool_use', 'name': 'Task', 'id': 't2'},
                  ],
                },
              },
            },
          },
        },
        // Task 2 的 sidechain 1
        {
          'id': 'sc-2-1',
          'createdAt': 1704067203000,
          'content': {
            'role': 'agent',
            'content': {
              'type': 'output',
              'data': {
                'type': 'assistant',
                'parentUuid': 'task-2-uuid',
                'uuid': 'sc-2-1-uuid',
                'isSidechain': true,
                'message': {
                  'role': 'assistant',
                  'content': [
                    {'type': 'text', 'text': 'Task 2 work 1'},
                  ],
                },
              },
            },
          },
        },
        // Task 2 的 sidechain 2（链式）
        {
          'id': 'sc-2-2',
          'createdAt': 1704067204000,
          'content': {
            'role': 'agent',
            'content': {
              'type': 'output',
              'data': {
                'type': 'assistant',
                'parentUuid': 'sc-2-1-uuid',
                'uuid': 'sc-2-2-uuid',
                'isSidechain': true,
                'message': {
                  'role': 'assistant',
                  'content': [
                    {'type': 'text', 'text': 'Task 2 work 2'},
                  ],
                },
              },
            },
          },
        },
      ];

      final messages = <Message>[];
      for (final raw in rawMessages) {
        final msg = MockHapiMessageParser.parseHistoryMessage(raw, sessionId);
        if (msg != null) messages.add(msg);
      }

      final tree = MessageTracer.processMessages(messages);

      print('Multiple tasks tree:');
      for (final node in tree) {
        print('  ${node.message.id}: children=${node.children.length}');
        for (final child in node.children) {
          print('    - ${child.message.id}');
        }
      }

      // 应该有 2 个根节点
      expect(tree.length, equals(2));

      // Task 1 有 1 个子节点
      final task1 = tree.firstWhere((n) => n.message.id == 'task-1');
      expect(task1.children.length, equals(1));

      // Task 2 有 2 个子节点
      final task2 = tree.firstWhere((n) => n.message.id == 'task-2');
      expect(task2.children.length, equals(2));
    });
  });

  group('User Message with tool_result Tests', () {
    const sessionId = 'test-session';

    test('解析包含 tool_result 的用户消息', () {
      // 这是真实 API 返回的用户消息结构
      final rawData = {
        'id': '7d2fba0e-456d-41b6-929e-92b29c390b00',
        'createdAt': 1767844597432,
        'content': {
          'role': 'agent',
          'content': {
            'type': 'output',
            'data': {
              'parentUuid': '4e8c1ee0-7b28-4604-9367-4d620535d677',
              'isSidechain': true,
              'uuid': '5ff6ef70-041f-422a-9abe-c0d8c7013a97',
              'type': 'user',
              'message': {
                'role': 'user',
                'content': [
                  {
                    'tool_use_id': 'toolu_015biLuHPWzzkgtct5pKYZ7H',
                    'type': 'tool_result',
                    'content':
                        '# CC Monitor README\nThis is a test content from tool result.',
                  },
                ],
              },
            },
          },
        },
      };

      final message = MockHapiMessageParser.parseHistoryMessage(
        rawData,
        sessionId,
      );

      expect(message, isNotNull, reason: '应该成功解析 tool_result 消息');
      expect(message!.role, equals('user'));
      expect(message.isSidechain, isTrue);
      expect(message.parentId, equals('4e8c1ee0-7b28-4604-9367-4d620535d677'));
      expect(
        message.contentUuid,
        equals('5ff6ef70-041f-422a-9abe-c0d8c7013a97'),
      );

      // tool_result 消息使用 HiddenPayload（不在聊天界面显示）
      expect(message.payload, isA<HiddenPayload>());
      final payload = message.payload as HiddenPayload;
      expect(payload.reason, equals('tool_result'));
      expect(payload.toolUseId, equals('toolu_015biLuHPWzzkgtct5pKYZ7H'));
    });

    test('解析 tool_result 内容为空的用户消息', () {
      final rawData = {
        'id': 'user-empty-result',
        'createdAt': 1767844597432,
        'content': {
          'role': 'agent',
          'content': {
            'type': 'output',
            'data': {
              'parentUuid': 'parent-uuid',
              'isSidechain': true,
              'uuid': 'user-uuid',
              'type': 'user',
              'message': {
                'role': 'user',
                'content': [
                  {
                    'tool_use_id': 'toolu_xxx',
                    'type': 'tool_result',
                    'content': '', // 空内容
                  },
                ],
              },
            },
          },
        },
      };

      final message = MockHapiMessageParser.parseHistoryMessage(
        rawData,
        sessionId,
      );

      expect(message, isNotNull, reason: '即使内容为空也应该创建隐藏消息');
      expect(message!.role, equals('user'));
      // 空内容的 tool_result 也使用 HiddenPayload
      expect(message.payload, isA<HiddenPayload>());
      final payload = message.payload as HiddenPayload;
      expect(payload.reason, equals('tool_result'));
      expect(payload.toolUseId, equals('toolu_xxx'));
    });
  });

  group('Event Message Tests', () {
    const sessionId = 'test-session';

    test('跳过 ready 事件消息', () {
      final rawData = {
        'id': 'event-ready',
        'createdAt': 1767844663643,
        'content': {
          'role': 'agent',
          'content': {
            'id': 'f3ba1c31-3817-4eac-92dd-ad0ab0c90e92',
            'type': 'event',
            'data': {'type': 'ready'},
          },
        },
      };

      final message = MockHapiMessageParser.parseHistoryMessage(
        rawData,
        sessionId,
      );

      expect(message, isNull, reason: 'ready 事件不应该创建消息');
    });

    test('跳过 switch 事件消息', () {
      final rawData = {
        'id': 'event-switch',
        'createdAt': 1767855995487,
        'content': {
          'role': 'agent',
          'content': {
            'id': '1b4118a8-2edd-4a21-b567-d4ccd0ac974e',
            'type': 'event',
            'data': {'type': 'switch', 'mode': 'local'},
          },
        },
      };

      final message = MockHapiMessageParser.parseHistoryMessage(
        rawData,
        sessionId,
      );

      expect(message, isNull, reason: 'switch 事件不应该创建消息');
    });

    test('解析带有错误信息的 message 事件', () {
      final rawData = {
        'id': 'event-message',
        'createdAt': 1767855999790,
        'content': {
          'role': 'agent',
          'content': {
            'id': 'b2e10f91-ef31-4dd4-913c-c630663f51de',
            'type': 'event',
            'data': {
              'type': 'message',
              'message':
                  'Local Claude process failed: Process exited with code: 1',
            },
          },
        },
      };

      final message = MockHapiMessageParser.parseHistoryMessage(
        rawData,
        sessionId,
      );

      expect(message, isNotNull, reason: 'message 事件应该创建系统消息');
      expect(message!.role, equals('system'));
      expect(message.payload, isA<MarkdownPayload>());
      final payload = message.payload as MarkdownPayload;
      expect(payload.content, contains('Local Claude process failed'));
    });
  });
}
