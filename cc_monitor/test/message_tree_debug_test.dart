import 'package:flutter_test/flutter_test.dart';
import 'package:cc_monitor/models/message.dart';
import 'package:cc_monitor/models/payload/payload.dart';
import 'package:cc_monitor/models/task.dart';

void main() {
  group('Message Tree Debug Tests', () {
    test('模拟实际 hapi 数据场景', () {
      // 模拟实际收到的消息：每个都有 parentId 但指向不存在的父消息
      // 这可能是因为 Task 消息没有被正确创建或 contentUuid 没有设置

      final now = DateTime.now();

      // 场景 1: 所有消息都有 parentId，但指向同一个不存在的 UUID
      final messages1 = [
        Message(
          id: 'msg-1',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: now,
          role: 'assistant',
          parentId: 'some-task-uuid', // 指向不存在的父
          payload: TaskExecutionPayload(
            title: '执行: Read',
            tasks: const [],
            overallStatus: TaskStatus.completed,
          ),
        ),
        Message(
          id: 'msg-2',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: now.add(const Duration(seconds: 1)),
          role: 'assistant',
          parentId: 'some-task-uuid', // 同样指向不存在的父
          payload: TaskExecutionPayload(
            title: '执行: Read',
            tasks: const [],
            overallStatus: TaskStatus.completed,
          ),
        ),
      ];

      final tree1 = messages1.toTree();
      print('场景 1: 所有消息指向不存在的父');
      print('Root nodes: ${tree1.length}');
      for (final node in tree1) {
        print(
          '  Node: ${node.message.id}, parentId: ${node.message.parentId}, children: ${node.children.length}',
        );
      }

      // 场景 2: 消息的 parentId 指向前一个消息的 id（链式结构）
      final messages2 = [
        Message(
          id: 'msg-1',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: now,
          role: 'assistant',
          payload: TaskExecutionPayload(
            title: '执行: Read 1',
            tasks: const [],
            overallStatus: TaskStatus.completed,
          ),
        ),
        Message(
          id: 'msg-2',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: now.add(const Duration(seconds: 1)),
          role: 'assistant',
          parentId: 'msg-1', // 指向前一个消息
          payload: TaskExecutionPayload(
            title: '执行: Read 2',
            tasks: const [],
            overallStatus: TaskStatus.completed,
          ),
        ),
        Message(
          id: 'msg-3',
          sessionId: 'session-1',
          projectName: 'test',
          createdAt: now.add(const Duration(seconds: 2)),
          role: 'assistant',
          parentId: 'msg-2', // 指向前一个消息
          payload: TaskExecutionPayload(
            title: '执行: Read 3',
            tasks: const [],
            overallStatus: TaskStatus.completed,
          ),
        ),
      ];

      final tree2 = messages2.toTree();
      print('\n场景 2: 链式结构 (每个消息指向前一个)');
      print('Root nodes: ${tree2.length}');
      void printTree(List<MessageNode> nodes, int indent) {
        for (final node in nodes) {
          print(
            '${'  ' * indent}Node: ${node.message.id}, children: ${node.children.length}',
          );
          printTree(node.children, indent + 1);
        }
      }

      printTree(tree2, 1);

      // 检查 hasChildren
      final hasValidTree2 = tree2.any((node) => node.hasChildren);
      print('hasValidTree: $hasValidTree2');

      // 期望：场景 2 应该形成深度嵌套的树，每个节点只有一个子节点
      // 这正是截图中看到的情况！
    });
  });
}
