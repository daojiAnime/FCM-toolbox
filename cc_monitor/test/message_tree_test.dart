import 'package:flutter_test/flutter_test.dart';
import 'package:cc_monitor/models/message.dart';
import 'package:cc_monitor/models/payload/payload.dart';
import 'package:cc_monitor/models/task.dart';

void main() {
  group('Message Tree Tests', () {
    test('应该将子消息正确分组到父消息下 (contentUuid 匹配)', () {
      // 模拟 hapi 消息结构：
      // 1. Task 消息 (父) - contentUuid = "task-uuid-123"
      // 2. 多个子消息 - parentId = "task-uuid-123"

      final taskMessage = Message(
        id: 'msg-1',
        sessionId: 'session-1',
        projectName: 'test',
        createdAt: DateTime.now(),
        role: 'assistant',
        contentUuid: 'task-uuid-123', // Task 的 contentUuid
        payload: TaskExecutionPayload(
          title: 'Task: Explore',
          tasks: const [],
          overallStatus: TaskStatus.running,
        ),
      );

      final childMessages = List.generate(
        25,
        (i) => Message(
          id: 'msg-child-$i',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: DateTime.now().add(Duration(seconds: i + 1)),
          role: 'assistant',
          parentId: 'task-uuid-123', // 指向 Task 的 contentUuid
          payload: ProgressPayload(
            title: '执行: Read',
            description: 'Reading file $i',
          ),
        ),
      );

      final allMessages = [taskMessage, ...childMessages];

      // 转换为树
      final tree = allMessages.toTree();

      // 验证
      print('Test 1: contentUuid 匹配');
      print('Root nodes: ${tree.length}');
      for (final node in tree) {
        print(
          '  Node: ${node.message.id}, contentUuid: ${node.message.contentUuid}, children: ${node.children.length}',
        );
        for (final child in node.children.take(3)) {
          print(
            '    Child: ${child.message.id}, parentId: ${child.message.parentId}',
          );
        }
        if (node.children.length > 3) {
          print('    ... and ${node.children.length - 3} more');
        }
      }

      // 应该只有 1 个根节点 (Task)
      expect(tree.length, equals(1), reason: '应该只有 1 个根节点');

      // Task 应该有 25 个子节点
      expect(tree[0].children.length, equals(25), reason: 'Task 应该有 25 个子节点');
    });

    test('parentId 直接匹配 id 时应该正确分组', () {
      final taskMessage = Message(
        id: 'task-id-123',
        sessionId: 'session-1',
        projectName: 'test',
        createdAt: DateTime.now(),
        role: 'assistant',
        payload: TaskExecutionPayload(
          title: 'Task: Explore',
          tasks: const [],
          overallStatus: TaskStatus.running,
        ),
      );

      final childMessages = List.generate(
        5,
        (i) => Message(
          id: 'child-$i',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: DateTime.now().add(Duration(seconds: i + 1)),
          role: 'assistant',
          parentId: 'task-id-123', // 直接匹配父消息的 id
          payload: ProgressPayload(
            title: '执行: Read',
            description: 'Reading file $i',
          ),
        ),
      );

      final allMessages = [taskMessage, ...childMessages];
      final tree = allMessages.toTree();

      print('\nTest 2: 直接 id 匹配');
      print('Root nodes: ${tree.length}');
      for (final node in tree) {
        print('  Node: ${node.message.id}, children: ${node.children.length}');
      }

      expect(tree.length, equals(1));
      expect(tree[0].children.length, equals(5));
    });

    test('没有 parentId 的消息应该是根节点', () {
      final messages = List.generate(
        3,
        (i) => Message(
          id: 'msg-$i',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: DateTime.now().add(Duration(seconds: i)),
          role: 'assistant',
          payload: MarkdownPayload(title: 'Response', content: 'Content $i'),
        ),
      );

      final tree = messages.toTree();

      print('\nTest 3: 无 parent');
      print('Root nodes: ${tree.length}');

      expect(tree.length, equals(3));
    });

    test('parentId 无法匹配时消息应该成为根节点', () {
      // 这可能是实际问题的场景：parentId 设置了但找不到对应的父消息
      final childMessages = List.generate(
        5,
        (i) => Message(
          id: 'orphan-$i',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: DateTime.now().add(Duration(seconds: i)),
          role: 'assistant',
          parentId: 'non-existent-parent', // 父消息不存在
          payload: ProgressPayload(
            title: '执行: Read',
            description: 'Orphan message $i',
          ),
        ),
      );

      final tree = childMessages.toTree();

      print('\nTest 4: 孤儿消息 (parent 不存在)');
      print('Root nodes: ${tree.length}');

      // 所有消息都应该成为根节点（因为找不到父消息）
      expect(tree.length, equals(5));
    });
  });
}
