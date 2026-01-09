// ignore_for_file: avoid_print
@TestOn('vm')
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:cc_monitor/models/message.dart';
import 'package:cc_monitor/models/payload/payload.dart';
import 'package:cc_monitor/models/task.dart';
import 'package:cc_monitor/services/message_tracer.dart';

/// 测试配置
const String hapiBaseUrl = 'http://10.126.126.1:3006';
const String cliToken = 'xtm2oyRo8BVR1rJBEo-q_DLCfvssaA4Rg0-u_aXMXWg';

/// 模拟 HapiEventHandler 的消息解析逻辑
class MockHapiParser {
  static Message? parseHistoryMessage(
    Map<String, dynamic> rawData,
    String sessionId,
  ) {
    try {
      final id = rawData['id'] as String? ?? '';
      final createdAtMs = rawData['createdAt'] as int? ?? 0;
      final createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtMs);

      final content = rawData['content'] as Map<String, dynamic>?;
      if (content == null) return null;

      final innerContent = content['content'];
      if (innerContent is! Map<String, dynamic>) return null;

      // 检查是否为 event 消息
      final contentType = innerContent['type'] as String?;
      if (contentType == 'event') {
        final eventData = innerContent['data'] as Map<String, dynamic>?;
        if (eventData == null) return null;
        final eventType = eventData['type'] as String?;
        if (eventType == 'ready' || eventType == 'switch') {
          return null; // 跳过系统事件
        }
        // message 事件可以保留
        return null;
      }

      // output 消息
      if (contentType != 'output') return null;

      final innerData = innerContent['data'] as Map<String, dynamic>?;
      if (innerData == null) return null;

      final msgType = innerData['type'] as String?;
      final parentUuid = innerData['parentUuid'] as String?;
      final contentUuid = innerData['uuid'] as String?;
      final isSidechain = innerData['isSidechain'] as bool? ?? false;
      final taskPrompt =
          innerData['taskPrompt'] as String? ?? innerData['prompt'] as String?;

      final messageField = innerData['message'];
      if (messageField == null) {
        if (isSidechain && contentUuid != null) {
          return Message(
            id: id,
            sessionId: sessionId,
            payload: const HiddenPayload(reason: 'empty_sidechain'),
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

      final messageObj =
          messageField is Map<String, dynamic> ? messageField : null;
      if (messageObj == null) return null;

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
      } else {
        return _parseAssistantMessage(
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
    } catch (e) {
      print('Parse error: $e');
      return null;
    }
  }

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
            final toolUseId = item['tool_use_id'] as String?;
            toolResults.add({'tool_use_id': toolUseId});
          }
        }
      }
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

  static Message? _parseAssistantMessage(
    String id,
    String sessionId,
    Map<String, dynamic> messageObj,
    DateTime createdAt,
    String? parentId,
    String? contentUuid,
    bool isSidechain,
    String? taskPrompt,
  ) {
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
          parentId: parentId,
          contentUuid: contentUuid,
          isSidechain: isSidechain,
          taskPrompt: taskPrompt,
        );
      }
      if (isSidechain && contentUuid != null) {
        return Message(
          id: id,
          sessionId: sessionId,
          payload: const HiddenPayload(reason: 'empty_sidechain'),
          projectName: 'hapi',
          createdAt: createdAt,
          role: 'assistant',
          parentId: parentId,
          contentUuid: contentUuid,
          isSidechain: isSidechain,
          taskPrompt: taskPrompt,
        );
      }
      return null;
    }

    final textParts = <String>[];
    final toolCalls = <TaskItem>[];
    String? extractedTaskPrompt;

    for (final item in contentList) {
      if (item is! Map<String, dynamic>) continue;
      final itemType = item['type'] as String?;

      if (itemType == 'text') {
        final text = item['text'] as String? ?? '';
        if (text.isNotEmpty) {
          textParts.add(text);
        }
      } else if (itemType == 'tool_use') {
        final toolName = item['name'] as String? ?? 'unknown';
        final toolId = item['id'] as String? ?? '';
        final input = item['input'] as Map<String, dynamic>?;

        // 提取 Task 工具的 prompt
        if (toolName == 'Task' && input != null) {
          extractedTaskPrompt = input['prompt'] as String?;
        }

        toolCalls.add(
          TaskItem(
            id: toolId,
            name: toolName,
            status: TaskItemStatus.completed,
          ),
        );
      }
    }

    final effectivePrompt = extractedTaskPrompt ?? taskPrompt;

    if (toolCalls.isNotEmpty) {
      return Message(
        id: id,
        sessionId: sessionId,
        payload: TaskExecutionPayload(
          title:
              toolCalls.length == 1
                  ? '执行: ${toolCalls.first.name}'
                  : '执行 ${toolCalls.length} 个工具',
          tasks: toolCalls,
          overallStatus: TaskStatus.completed,
          prompt: effectivePrompt,
        ),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'assistant',
        parentId: parentId,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: effectivePrompt,
      );
    }

    if (textParts.isNotEmpty) {
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
        parentId: parentId,
        contentUuid: contentUuid,
        isSidechain: isSidechain,
        taskPrompt: taskPrompt,
      );
    }

    if (isSidechain && contentUuid != null) {
      return Message(
        id: id,
        sessionId: sessionId,
        payload: const HiddenPayload(reason: 'empty_sidechain'),
        projectName: 'hapi',
        createdAt: createdAt,
        role: 'assistant',
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
  test('Hapi API Integration Test', () async {
    print('=== Hapi API Integration Test ===\n');

    // 1. 先用 CLI token 换取 JWT
    print('1. Authenticating with CLI token...');
    final authResponse = await http.post(
      Uri.parse('$hapiBaseUrl/api/auth'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': cliToken}),
    );

    if (authResponse.statusCode != 200) {
      print('❌ Auth failed: ${authResponse.statusCode} ${authResponse.body}');
      return;
    }

    final authData = jsonDecode(authResponse.body) as Map<String, dynamic>;
    final jwtToken = authData['token'] as String?;
    if (jwtToken == null) {
      print('❌ No JWT token in response');
      return;
    }
    print('✅ Got JWT token: ${jwtToken.substring(0, 20)}...\n');

    // 2. 获取 sessions 列表
    print('2. Fetching sessions...');
    final sessionsResponse = await http.get(
      Uri.parse('$hapiBaseUrl/api/sessions'),
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    if (sessionsResponse.statusCode != 200) {
      print('❌ Failed to fetch sessions: ${sessionsResponse.statusCode}');
      return;
    }

    final sessionsData = jsonDecode(sessionsResponse.body);
    final sessions = sessionsData['sessions'] as List? ?? [];
    print('✅ Found ${sessions.length} sessions\n');

    if (sessions.isEmpty) {
      print('No sessions to test');
      return;
    }

    // 3. 获取第一个 session 的完整消息列表（分页）
    final firstSession = sessions.first as Map<String, dynamic>;
    final sessionId = firstSession['id'] as String;
    print(
      '3. Fetching ALL messages for session: ${sessionId.substring(0, 8)}...',
    );

    final allRawMessages = <Map<String, dynamic>>[];
    int? beforeSeq;
    int pageCount = 0;

    while (true) {
      pageCount++;
      final url =
          beforeSeq != null
              ? '$hapiBaseUrl/api/sessions/$sessionId/messages?beforeSeq=$beforeSeq&limit=50'
              : '$hapiBaseUrl/api/sessions/$sessionId/messages?limit=50';

      final messagesResponse = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );

      if (messagesResponse.statusCode != 200) {
        print('❌ Failed to fetch messages: ${messagesResponse.statusCode}');
        return;
      }

      final messagesData = jsonDecode(messagesResponse.body);
      final pageMessages =
          (messagesData['messages'] as List? ?? [])
              .cast<Map<String, dynamic>>();

      if (pageMessages.isEmpty) break;

      allRawMessages.addAll(pageMessages);

      // 获取最小的 seq 作为下一次请求的 beforeSeq
      final seqs =
          pageMessages
              .map((m) => m['seq'] as int?)
              .where((s) => s != null)
              .cast<int>()
              .toList();

      if (seqs.isEmpty) break;

      final minSeq = seqs.reduce((a, b) => a < b ? a : b);
      if (minSeq <= 1) break; // 已经到最早的消息了

      beforeSeq = minSeq;
      print(
        '   Page $pageCount: ${pageMessages.length} messages, next beforeSeq=$beforeSeq',
      );
    }

    final rawMessages = allRawMessages;
    print(
      '✅ Found ${rawMessages.length} total raw messages (${pageCount} pages)\n',
    );

    // 3. 解析消息
    print('3. Parsing messages...');
    final messages = <Message>[];
    int skippedEvent = 0;
    int skippedOther = 0;

    for (final raw in rawMessages) {
      final msg = MockHapiParser.parseHistoryMessage(
        raw as Map<String, dynamic>,
        sessionId,
      );
      if (msg != null) {
        messages.add(msg);
      } else {
        // 检查是否为 event 消息
        final content = (raw['content'] as Map<String, dynamic>?)?['content'];
        if (content is Map<String, dynamic> && content['type'] == 'event') {
          skippedEvent++;
        } else {
          skippedOther++;
        }
      }
    }

    print(
      '✅ Parsed ${messages.length} messages (skipped: event=$skippedEvent, other=$skippedOther)\n',
    );

    // 4. 统计消息类型
    print('4. Message type breakdown:');
    final typeCount = <String, int>{};
    int sidechainCount = 0;
    int hiddenCount = 0;

    for (final msg in messages) {
      typeCount[msg.payload.type] = (typeCount[msg.payload.type] ?? 0) + 1;
      if (msg.isSidechain) sidechainCount++;
      if (msg.payload is HiddenPayload) hiddenCount++;
    }

    for (final entry in typeCount.entries) {
      print('   ${entry.key}: ${entry.value}');
    }
    print('   sidechain: $sidechainCount');
    print('   hidden: $hiddenCount\n');

    // 5. 追踪和分组
    print('5. Running MessageTracer...');
    final tree = MessageTracer.processMessages(messages);

    final rootCount = tree.length;
    final withChildren = tree.where((n) => n.hasChildren).length;

    // 递归统计所有 children
    int countAllChildren(MessageNode node) {
      int count = node.children.length;
      for (final child in node.children) {
        count += countAllChildren(child);
      }
      return count;
    }

    int maxDepth(MessageNode node) {
      if (node.children.isEmpty) return 0;
      return 1 + node.children.map(maxDepth).reduce((a, b) => a > b ? a : b);
    }

    final totalChildren = tree.fold<int>(
      0,
      (sum, n) => sum + countAllChildren(n),
    );
    final depth =
        tree.isEmpty ? 0 : tree.map(maxDepth).reduce((a, b) => a > b ? a : b);

    print('   Root messages: $rootCount');
    print('   Roots with children: $withChildren');
    print('   Total children (all levels): $totalChildren');
    print('   Max tree depth: $depth\n');

    // 6. 显示完整树结构
    print('6. Complete tree structure:');

    void printNode(MessageNode node, String indent, int level) {
      final msg = node.message;
      final shortId = msg.id.length > 8 ? msg.id.substring(0, 8) : msg.id;
      final title =
          msg.title.length > 50
              ? '${msg.title.substring(0, 50)}...'
              : msg.title;
      final sidechain = msg.isSidechain ? ' [SC]' : '';
      print('$indent[$shortId] $title (${msg.payload.type})$sidechain');
      for (final child in node.children) {
        printNode(child, '$indent   ', level + 1);
      }
    }

    for (final node in tree) {
      printNode(node, '   ', 0);
    }

    // 6b. 分析 sidechain 消息类型分布
    print('\n6b. Sidechain message breakdown:');
    final sidechainMsgs = messages.where((m) => m.isSidechain).toList();
    final scTaskExec =
        sidechainMsgs.where((m) => m.payload is TaskExecutionPayload).length;
    final scHidden =
        sidechainMsgs.where((m) => m.payload is HiddenPayload).length;
    final scUser =
        sidechainMsgs.where((m) => m.payload is UserMessagePayload).length;
    final scMarkdown =
        sidechainMsgs.where((m) => m.payload is MarkdownPayload).length;
    final scOther =
        sidechainMsgs.length - scTaskExec - scHidden - scUser - scMarkdown;
    print('   Total sidechain: ${sidechainMsgs.length}');
    print('   - taskExecution: $scTaskExec');
    print('   - hidden (tool_result): $scHidden');
    print('   - userMessage: $scUser');
    print('   - markdown: $scMarkdown');
    print('   - other: $scOther');
    print(
      '   Visible (non-hidden): ${scTaskExec + scUser + scMarkdown + scOther}',
    );
    print('   hapi shows: Task details (${scTaskExec + scUser + scMarkdown})');

    final sidechainTasks =
        messages
            .where((m) => m.isSidechain && m.payload is TaskExecutionPayload)
            .toList();
    print('\n   Sidechain taskExecution details:');
    for (final t in sidechainTasks.take(5)) {
      final shortId = t.id.length > 8 ? t.id.substring(0, 8) : t.id;
      print('   - [$shortId] uuid=${t.contentUuid}, parentId=${t.parentId}');
      // 查找以这个消息的 uuid 为 parentId 的消息
      final children =
          messages.where((m) => m.parentId == t.contentUuid).toList();
      print('     children count: ${children.length}');
    }

    // 7. 诊断
    print('\n7. Diagnostics:');

    // 检查 Task prompts
    final taskPrompts = <String>[];
    for (final msg in messages) {
      if (!msg.isSidechain && msg.payload is TaskExecutionPayload) {
        final prompt = (msg.payload as TaskExecutionPayload).prompt;
        if (prompt != null && prompt.isNotEmpty) {
          taskPrompts.add(
            prompt.length > 50 ? '${prompt.substring(0, 50)}...' : prompt,
          );
        }
      }
    }
    print('   Task prompts found: ${taskPrompts.length}');
    for (final p in taskPrompts.take(3)) {
      print('      - "$p"');
    }

    // 检查 sidechain taskPrompts
    final sidechainTaskPrompts = <String>[];
    for (final msg in messages) {
      if (msg.isSidechain &&
          msg.taskPrompt != null &&
          msg.taskPrompt!.isNotEmpty) {
        sidechainTaskPrompts.add(
          msg.taskPrompt!.length > 50
              ? '${msg.taskPrompt!.substring(0, 50)}...'
              : msg.taskPrompt!,
        );
      }
    }
    print('   Sidechain taskPrompts found: ${sidechainTaskPrompts.length}');
    for (final p in sidechainTaskPrompts.take(3)) {
      print('      - "$p"');
    }

    // 检查 parentUuid 链
    final uuids = <String>{};
    final parentIds = <String>{};
    for (final msg in messages) {
      if (msg.contentUuid != null) uuids.add(msg.contentUuid!);
      if (msg.isSidechain && msg.parentId != null) parentIds.add(msg.parentId!);
    }
    final orphanParents = parentIds.difference(uuids);
    print('   UUID count: ${uuids.length}');
    print('   Sidechain parentId count: ${parentIds.length}');
    print(
      '   Orphan parentIds (parent not in messages): ${orphanParents.length}',
    );

    // 8. UUID 匹配诊断
    print('\n8. UUID format check:');

    // 检查 contentUuid 的实际格式
    print('   Sample contentUuids:');
    for (final msg in messages.take(5)) {
      print('   - uuid="${msg.contentUuid}", id=${msg.id.substring(0, 8)}');
    }

    print('\n   Sample sidechain parentIds:');
    for (final msg in messages
        .where((m) => m.isSidechain && m.parentId != null)
        .take(5)) {
      print('   - parentId="${msg.parentId}", uuid="${msg.contentUuid}"');
      // 检查这个 parentId 是否真的在 uuids 集合中
      final found = uuids.contains(msg.parentId);
      print('     parentId in uuids: $found');
    }

    // 打印 UUID 匹配情况
    print('\n   Non-sidechain messages:');
    final nonSidechain = messages.where((m) => !m.isSidechain).toList();
    print('   Count: ${nonSidechain.length}');
    for (final msg in nonSidechain.take(5)) {
      print(
        '   - id=${msg.id.substring(0, 8)}, uuid=${msg.contentUuid}, type=${msg.payload.type}',
      );
      if (msg.payload is TaskExecutionPayload) {
        final prompt = (msg.payload as TaskExecutionPayload).prompt;
        print('     prompt: ${prompt?.substring(0, 50) ?? "NULL"}...');
      }
    }

    // 检查第一个 sidechain 消息的 parentId 是否指向非 sidechain 消息
    print('\n   First sidechain parent check:');
    final firstSidechain = messages.firstWhere(
      (m) => m.isSidechain,
      orElse: () => messages.first,
    );
    print(
      '   First sidechain: ${firstSidechain.id.substring(0, 8)}, parentId=${firstSidechain.parentId}',
    );
    if (firstSidechain.parentId != null) {
      final parent =
          messages
              .where((m) => m.contentUuid == firstSidechain.parentId)
              .firstOrNull;
      if (parent != null) {
        print(
          '   Parent found: ${parent.id.substring(0, 8)}, isSidechain=${parent.isSidechain}',
        );
      } else {
        print('   Parent NOT found in messages');
      }
    }

    // 9. 检查原始数据中链头 sidechain 消息的所有字段
    print('\n9. Raw sidechain head data:');
    for (final raw in rawMessages) {
      final rawMap = raw as Map<String, dynamic>;
      final id = rawMap['id'] as String?;
      if (id == firstSidechain.id) {
        final content = rawMap['content'] as Map<String, dynamic>?;
        final innerContent = content?['content'] as Map<String, dynamic>?;
        final data = innerContent?['data'] as Map<String, dynamic>?;
        print('   Found raw data for ${id?.substring(0, 8)}:');
        print('   data keys: ${data?.keys.toList()}');
        print('   isSidechain: ${data?['isSidechain']}');
        print('   parentUuid: ${data?['parentUuid']}');
        print('   uuid: ${data?['uuid']}');
        print('   taskPrompt: ${data?['taskPrompt']}');
        print('   prompt: ${data?['prompt']}');
        // 检查是否有 toolResultBlockId 或类似字段
        for (final key in data?.keys ?? []) {
          if (key.contains('tool') ||
              key.contains('parent') ||
              key.contains('prompt') ||
              key.contains('id')) {
            print('   $key: ${data?[key]}');
          }
        }
        break;
      }
    }

    // 10. 检查 Task 消息前后的消息
    print('\n10. Messages around Task:');
    final taskMsgIndex = messages.indexWhere(
      (m) =>
          m.payload is TaskExecutionPayload &&
          (m.payload as TaskExecutionPayload).prompt != null,
    );
    if (taskMsgIndex >= 0) {
      for (
        var i = taskMsgIndex - 1;
        i <= taskMsgIndex + 3 && i < messages.length;
        i++
      ) {
        if (i < 0) continue;
        final m = messages[i];
        print(
          '   [$i] id=${m.id.substring(0, 8)}, uuid=${m.contentUuid}, sidechain=${m.isSidechain}, type=${m.payload.type}',
        );
      }
    }

    print('\n=== Test Complete ===');
  });
}
