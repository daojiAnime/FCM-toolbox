import 'package:flutter_test/flutter_test.dart';
import 'package:cc_monitor/models/message.dart';
import 'package:cc_monitor/models/payload/payload.dart';
import 'package:cc_monitor/models/task.dart';
import 'package:cc_monitor/services/message_tracer.dart';

void main() {
  group('MessageTracer Tests', () {
    test('非 sidechain 消息应该成为独立的根节点', () {
      final messages = [
        Message(
          id: 'msg-1',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: DateTime.now(),
          role: 'assistant',
          isSidechain: false,
          payload: const MarkdownPayload(title: 'Response', content: 'Hello'),
        ),
      ];

      final tree = MessageTracer.processMessages(messages);

      expect(tree.length, equals(1));
      expect(tree[0].message.id, equals('msg-1'));
      expect(tree[0].children.length, equals(0));
    });

    test('sidechain 消息通过 parentId 链追溯到 Task 消息', () {
      final now = DateTime.now();

      // 模拟 hapi 的实际数据结构：
      // 1. Task 消息有 contentUuid，不是 sidechain
      // 2. Sidechain root 的 parentId 指向 Task 的 contentUuid
      // 3. 后续 sidechain 的 parentId 形成链式结构
      final messages = [
        // Task 消息 (非 sidechain)
        Message(
          id: 'task-msg-1',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: now,
          role: 'assistant',
          contentUuid: 'task-uuid-1', // 关键：sidechain 会通过 parentId 指向这个
          isSidechain: false,
          payload: TaskExecutionPayload(
            title: 'Task: Explore',
            tasks: const [],
            overallStatus: TaskStatus.running,
            prompt: 'Explore the codebase',
          ),
        ),
        // Sidechain root 消息 - parentId 指向 Task 的 contentUuid
        Message(
          id: 'sidechain-1',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: now.add(const Duration(seconds: 1)),
          role: 'assistant',
          parentId: 'task-uuid-1', // 指向 Task 的 contentUuid
          contentUuid: 'sc-uuid-1',
          isSidechain: true,
          payload: const MarkdownPayload(title: 'Thinking', content: '...'),
        ),
        // Sidechain 子消息 - parentId 指向前一个 sidechain 的 contentUuid
        Message(
          id: 'sidechain-2',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: now.add(const Duration(seconds: 2)),
          role: 'assistant',
          parentId: 'sc-uuid-1', // 指向前一个 sidechain
          contentUuid: 'sc-uuid-2',
          isSidechain: true,
          payload: ProgressPayload(
            title: '执行: Read',
            description: 'Reading file',
          ),
        ),
      ];

      final tree = MessageTracer.processMessages(messages);

      print('Tree structure:');
      for (final node in tree) {
        print('  ${node.message.id}: children=${node.children.length}');
        for (final child in node.children) {
          print('    - ${child.message.id}: children=${child.children.length}');
        }
      }

      // 应该只有 1 个根节点 (Task)
      expect(tree.length, equals(1));
      expect(tree[0].message.id, equals('task-msg-1'));

      // Task 应该有 2 个直接子节点（所有 sidechain 消息扁平化）
      expect(tree[0].children.length, equals(2));

      // 所有子节点都没有孙节点（扁平化结构）
      for (final child in tree[0].children) {
        expect(child.children.length, equals(0));
      }
    });

    test('25 条链式 sidechain 消息应该全部归入 Task', () {
      final now = DateTime.now();
      final messages = <Message>[];

      // Task 消息
      messages.add(
        Message(
          id: 'task-msg-1',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: now,
          role: 'assistant',
          contentUuid: 'task-uuid-1',
          isSidechain: false,
          payload: TaskExecutionPayload(
            title: 'Task: Explore',
            tasks: const [],
            overallStatus: TaskStatus.running,
            prompt: 'Explore the codebase',
          ),
        ),
      );

      // 生成 25 条链式 sidechain 消息
      // 第一条的 parentId 指向 Task 的 contentUuid
      // 后续每条的 parentId 指向前一条的 contentUuid
      String prevUuid = 'task-uuid-1';
      for (int i = 1; i <= 25; i++) {
        final uuid = 'sc-uuid-$i';
        messages.add(
          Message(
            id: 'sidechain-$i',
            sessionId: 'session-1',
            projectName: 'test',
            createdAt: now.add(Duration(seconds: i)),
            role: 'assistant',
            parentId: prevUuid,
            contentUuid: uuid,
            isSidechain: true,
            payload: ProgressPayload(title: '执行: Tool $i'),
          ),
        );
        prevUuid = uuid;
      }

      final tree = MessageTracer.processMessages(messages);

      print('Total messages: ${messages.length}');
      print('Tree root count: ${tree.length}');
      if (tree.isNotEmpty) {
        print('Task children count: ${tree[0].children.length}');
        if (tree[0].children.isNotEmpty) {
          print(
            'Chain head children count: ${tree[0].children[0].children.length}',
          );
        }
      }

      // 应该只有 1 个根节点 (Task)
      expect(tree.length, equals(1));
      expect(tree[0].message.id, equals('task-msg-1'));

      // Task 应该有 25 个直接子节点（所有 sidechain 消息扁平化）
      // 这样 collapsibleChildren 数量才是 25
      expect(tree[0].children.length, equals(25));

      // 所有子节点都没有孙节点（扁平化结构）
      for (final child in tree[0].children) {
        expect(child.children.length, equals(0));
      }

      // 验证 collapsibleChildren 数量
      // 所有 sidechain 消息都是 ProgressPayload，不是 InteractivePayload
      // 所以 pendingChildren = 0, collapsibleChildren = 25
      final taskNode = tree[0];
      expect(taskNode.pendingChildren.length, equals(0));
      expect(taskNode.collapsibleChildren.length, equals(25));
      print(
        '✅ collapsibleChildren count: ${taskNode.collapsibleChildren.length}',
      );
    });

    test('没有 Task 关联的 sidechain 消息应该成为根节点', () {
      final messages = [
        // 这个 sidechain 消息的 parentId 指向不存在的 uuid
        Message(
          id: 'orphan-sidechain',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: DateTime.now(),
          role: 'assistant',
          parentId: 'non-existent-uuid',
          isSidechain: true,
          payload: ProgressPayload(title: '执行: Read'),
        ),
      ];

      final tree = MessageTracer.processMessages(messages);

      // 无法追溯到根，应该成为独立根节点
      expect(tree.length, equals(1));
      expect(tree[0].message.id, equals('orphan-sidechain'));
      expect(tree[0].children.length, equals(0));
    });

    test('多个 Task 各自拥有自己的 sidechain 消息', () {
      final now = DateTime.now();

      final messages = [
        // Task 1
        Message(
          id: 'task-1',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: now,
          role: 'assistant',
          contentUuid: 'task-uuid-1',
          isSidechain: false,
          payload: TaskExecutionPayload(
            title: 'Task 1',
            tasks: const [],
            overallStatus: TaskStatus.running,
            prompt: 'Task 1 prompt',
          ),
        ),
        // Task 1 的 sidechain
        Message(
          id: 'sc-1-1',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: now.add(const Duration(seconds: 1)),
          role: 'assistant',
          parentId: 'task-uuid-1',
          contentUuid: 'sc-uuid-1-1',
          isSidechain: true,
          payload: ProgressPayload(title: 'Task 1 work'),
        ),
        // Task 2
        Message(
          id: 'task-2',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: now.add(const Duration(seconds: 2)),
          role: 'assistant',
          contentUuid: 'task-uuid-2',
          isSidechain: false,
          payload: TaskExecutionPayload(
            title: 'Task 2',
            tasks: const [],
            overallStatus: TaskStatus.running,
            prompt: 'Task 2 prompt',
          ),
        ),
        // Task 2 的 sidechain
        Message(
          id: 'sc-2-1',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: now.add(const Duration(seconds: 3)),
          role: 'assistant',
          parentId: 'task-uuid-2',
          contentUuid: 'sc-uuid-2-1',
          isSidechain: true,
          payload: ProgressPayload(title: 'Task 2 work'),
        ),
        Message(
          id: 'sc-2-2',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: now.add(const Duration(seconds: 4)),
          role: 'assistant',
          parentId: 'sc-uuid-2-1',
          contentUuid: 'sc-uuid-2-2',
          isSidechain: true,
          payload: ProgressPayload(title: 'Task 2 more work'),
        ),
      ];

      final tree = MessageTracer.processMessages(messages);

      print('Tree structure:');
      for (final node in tree) {
        print('  ${node.message.id}: children=${node.children.length}');
        for (final child in node.children) {
          print('    - ${child.message.id}: children=${child.children.length}');
        }
      }

      // 应该有 2 个根节点 (2 个 Task)
      expect(tree.length, equals(2));

      // Task 1 有 1 个直接子节点（sc-1-1）
      final task1 = tree.firstWhere((n) => n.message.id == 'task-1');
      expect(task1.children.length, equals(1));
      expect(task1.children[0].message.id, equals('sc-1-1'));

      // Task 2 有 2 个直接子节点（所有 sidechain 消息扁平化）
      final task2 = tree.firstWhere((n) => n.message.id == 'task-2');
      expect(task2.children.length, equals(2));

      // 所有子节点都没有孙节点（扁平化结构）
      for (final child in task2.children) {
        expect(child.children.length, equals(0));
      }
    });

    test('空消息列表返回空树', () {
      final tree = MessageTracer.processMessages([]);
      expect(tree.isEmpty, isTrue);
    });
  });
}
