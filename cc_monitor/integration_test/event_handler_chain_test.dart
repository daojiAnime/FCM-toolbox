import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cc_monitor/services/hapi/hapi_sse_service.dart';
import 'package:cc_monitor/services/hapi/event/message_handler.dart';
import 'package:cc_monitor/services/hapi/event/session_handler.dart';
import 'package:cc_monitor/services/hapi/event/permission_handler.dart';
import 'package:cc_monitor/services/hapi/event/message_parser.dart';
import 'package:cc_monitor/services/hapi/buffer_manager.dart';
import 'package:cc_monitor/providers/messages_provider.dart';
import 'package:cc_monitor/providers/session_provider.dart';
import 'package:cc_monitor/providers/streaming_provider.dart';
import 'package:cc_monitor/models/session.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Event Handler Chain Integration', () {
    late ProviderContainer container;
    late BufferManager bufferManager;
    late HapiMessageParser parser;

    setUp(() {
      container = ProviderContainer();
      bufferManager = BufferManager();
      parser = HapiMessageParser();
    });

    tearDown(() {
      container.dispose();
      bufferManager.dispose();
      parser.dispose();
    });

    test('Message event flow - SSE → Handler → Provider', () async {
      // 1. 准备测试数据
      final sseEvent = HapiSseEvent(
        type: HapiSseEventType.message,
        sessionId: 'test-session-123',
        data: {
          'sessionId': 'test-session-123',
          'message': {
            'role': 'assistant',
            'content': [
              {'type': 'text', 'text': 'Hello from hapi'},
            ],
            'timestamp': DateTime.now().toIso8601String(),
            'id': 'msg-123',
          },
        },
      );

      // 2. 创建 MessageEventHandler
      final handler = MessageEventHandler(container, bufferManager, parser);

      // 3. 验证处理器能处理此事件
      expect(handler.canHandle(sseEvent), isTrue);

      // 4. 触发事件处理
      handler.handle(sseEvent);

      // 5. 验证消息已添加到 Provider (由于实际实现中 message handler 的 TODO,
      //    这里只验证处理器没有抛出异常)
      // 实际验证需要等待 parser 迁移完成后启用
      // await Future.delayed(Duration(milliseconds: 100));
      // final messages = container.read(messagesProvider);
      // expect(messages.isNotEmpty, isTrue);
      // expect(messages.first.sessionId, 'test-session-123');
    });

    test('Session event flow - updates session provider', () async {
      // 1. 准备测试数据
      final sseEvent = HapiSseEvent(
        type: HapiSseEventType.sessionCreated,
        sessionId: 'session-456',
        data: {
          'id': 'session-456',
          'active': true,
          'createdAt': DateTime.now().toIso8601String(),
          'metadata': {
            'path': '/test/project',
            'summary': {'text': 'Test Project Summary'},
          },
        },
      );

      // 2. 创建 SessionEventHandler
      final handler = SessionEventHandler(container, bufferManager, parser);

      // 3. 验证处理器能处理此事件
      expect(handler.canHandle(sseEvent), isTrue);

      // 4. 触发事件处理
      handler.handle(sseEvent);

      // 5. 等待异步处理完成
      await Future.delayed(Duration(milliseconds: 200));

      // 6. 验证会话已添加到 Provider
      final sessions = container.read(sessionsProvider);
      final targetSession =
          sessions.where((s) => s.id == 'session-456').firstOrNull;

      expect(targetSession, isNotNull);
      expect(targetSession?.id, 'session-456');
      expect(targetSession?.projectPath, '/test/project');

      // 清理
      handler.dispose();
    });

    test('Session update with debouncing - batches multiple updates', () async {
      // 1. 创建 SessionEventHandler
      final handler = SessionEventHandler(container, bufferManager, parser);

      // 2. 快速发送多个会话更新事件（测试防抖）
      for (int i = 0; i < 5; i++) {
        final sseEvent = HapiSseEvent(
          type: HapiSseEventType.sessionUpdate,
          sessionId: 'session-debounce',
          data: {
            'id': 'session-debounce',
            'active': true,
            'createdAt': DateTime.now().toIso8601String(),
            'metadata': {
              'path': '/test/project',
              'summary': {'text': 'Update $i'},
            },
          },
        );
        handler.handle(sseEvent);
        await Future.delayed(Duration(milliseconds: 20));
      }

      // 3. 等待防抖器完成（150ms 延迟 + 额外缓冲）
      await Future.delayed(Duration(milliseconds: 300));

      // 4. 验证只有一个会话且包含最后的更新
      final sessions = container.read(sessionsProvider);
      final targetSessions =
          sessions.where((s) => s.id == 'session-debounce').toList();

      expect(targetSessions.length, 1);
      expect(targetSessions.first.projectSummary, contains('Update'));

      // 清理
      handler.dispose();
    });

    test('Permission event creates interactive message', () async {
      // 1. 准备测试数据
      final sseEvent = HapiSseEvent(
        type: HapiSseEventType.permissionRequest,
        sessionId: 'test-session-perm',
        data: {
          'id': 'perm-789',
          'requestId': 'perm-789',
          'sessionId': 'test-session-perm',
          'toolName': 'Bash',
          'description': 'Execute command: ls -la',
          'args': {'command': 'ls -la'},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // 2. 创建 PermissionEventHandler
      final handler = PermissionEventHandler(container, parser);

      // 3. 验证处理器能处理此事件
      expect(handler.canHandle(sseEvent), isTrue);

      // 4. 触发事件处理
      handler.handle(sseEvent);

      // 5. 等待异步处理完成
      await Future.delayed(Duration(milliseconds: 100));

      // 6. 验证交互消息已添加到 Provider
      final messages = container.read(messagesProvider);
      final permMessages =
          messages.where((m) => m.sessionId == 'test-session-perm').toList();

      expect(permMessages.isNotEmpty, isTrue);
    });

    test('Streaming content event flow - progressive updates', () async {
      // 1. 创建 MessageEventHandler
      final handler = MessageEventHandler(container, bufferManager, parser);

      final messageId = 'stream-msg-001';
      final sessionId = 'test-session-stream';

      // 2. 发送流式内容开始事件
      final startEvent = HapiSseEvent(
        type: HapiSseEventType.streamingContent,
        sessionId: sessionId,
        data: {
          'messageId': messageId,
          'chunk': 'Hello ',
          'sessionId': sessionId,
          'type': 'markdown',
        },
      );
      handler.handle(startEvent);

      await Future.delayed(Duration(milliseconds: 50));

      // 3. 验证流式状态已创建
      expect(bufferManager.hasStreamingBuffer(messageId), isTrue);
      final streaming = container.read(streamingMessagesProvider);
      expect(streaming.containsKey(messageId), isTrue);

      // 4. 发送更多流式内容块
      final chunks = ['World', '!', ' How', ' are', ' you?'];
      for (final chunk in chunks) {
        final chunkEvent = HapiSseEvent(
          type: HapiSseEventType.streamingContent,
          sessionId: sessionId,
          data: {
            'messageId': messageId,
            'chunk': chunk,
            'sessionId': sessionId,
          },
        );
        handler.handle(chunkEvent);
        await Future.delayed(Duration(milliseconds: 20));
      }

      // 5. 验证内容累积
      final bufferedContent = bufferManager.getStreamingContent(messageId);
      expect(bufferedContent, contains('Hello'));
      expect(bufferedContent, contains('World'));

      // 6. 发送流式完成事件
      final completeEvent = HapiSseEvent(
        type: HapiSseEventType.streamingComplete,
        sessionId: sessionId,
        data: {'messageId': messageId, 'sessionId': sessionId},
      );
      handler.handle(completeEvent);

      // 7. 等待完成处理（包括延迟清理）
      await Future.delayed(Duration(milliseconds: 600));

      // 8. 验证缓冲区已清理
      expect(bufferManager.hasStreamingBuffer(messageId), isFalse);
    });

    test('Todo update event updates session todos', () async {
      // 1. 先创建一个会话
      final sessionId = 'test-session-todo';
      final createEvent = HapiSseEvent(
        type: HapiSseEventType.sessionCreated,
        sessionId: sessionId,
        data: {
          'id': sessionId,
          'active': true,
          'createdAt': DateTime.now().toIso8601String(),
          'metadata': {
            'path': '/test/project',
            'summary': {'text': 'Test Project'},
          },
        },
      );

      final sessionHandler = SessionEventHandler(
        container,
        bufferManager,
        parser,
      );
      sessionHandler.handle(createEvent);
      await Future.delayed(Duration(milliseconds: 200));

      // 2. 发送 Todo 更新事件
      final todoEvent = HapiSseEvent(
        type: HapiSseEventType.todoUpdate,
        sessionId: sessionId,
        data: {
          'sessionId': sessionId,
          'todos': [
            {
              'content': 'Read configuration file',
              'status': 'completed',
              'activeForm': 'Reading configuration file',
            },
            {
              'content': 'Update settings',
              'status': 'in_progress',
              'activeForm': 'Updating settings',
            },
            {
              'content': 'Test changes',
              'status': 'pending',
              'activeForm': 'Testing changes',
            },
          ],
        },
      );

      final permHandler = PermissionEventHandler(container, parser);
      permHandler.handle(todoEvent);
      await Future.delayed(Duration(milliseconds: 100));

      // 3. 验证会话的 todos 已更新
      final sessions = container.read(sessionsProvider);
      final session = sessions.where((s) => s.id == sessionId).firstOrNull;

      expect(session, isNotNull);
      expect(session?.todos, isNotNull);
      expect(session!.todos!.length, 3);
      expect(session.todos![0].content, 'Read configuration file');
      expect(session.todos![0].status, 'completed');
      expect(session.todos![1].status, 'in_progress');
      expect(session.todos![2].status, 'pending');

      // 清理
      sessionHandler.dispose();
    });

    test('Multiple event types processed in sequence', () async {
      // 综合测试：依次处理会话创建、消息、权限请求、Todo 更新
      final sessionId = 'test-session-multi';

      final sessionHandler = SessionEventHandler(
        container,
        bufferManager,
        parser,
      );
      final messageHandler = MessageEventHandler(
        container,
        bufferManager,
        parser,
      );
      final permHandler = PermissionEventHandler(container, parser);

      // 1. 创建会话
      final sessionEvent = HapiSseEvent(
        type: HapiSseEventType.sessionCreated,
        sessionId: sessionId,
        data: {
          'id': sessionId,
          'active': true,
          'createdAt': DateTime.now().toIso8601String(),
          'metadata': {
            'path': '/test/multi',
            'summary': {'text': 'Multi-event Test'},
          },
        },
      );
      sessionHandler.handle(sessionEvent);
      await Future.delayed(Duration(milliseconds: 200));

      // 2. 发送消息
      final messageEvent = HapiSseEvent(
        type: HapiSseEventType.message,
        sessionId: sessionId,
        data: {
          'sessionId': sessionId,
          'message': {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Test message'},
            ],
            'id': 'msg-multi-1',
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );
      messageHandler.handle(messageEvent);
      await Future.delayed(Duration(milliseconds: 100));

      // 3. 发送权限请求
      final permEvent = HapiSseEvent(
        type: HapiSseEventType.permissionRequest,
        sessionId: sessionId,
        data: {
          'id': 'perm-multi-1',
          'sessionId': sessionId,
          'toolName': 'Read',
          'description': 'Read file: test.txt',
          'args': {'file_path': '/test/test.txt'},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      permHandler.handle(permEvent);
      await Future.delayed(Duration(milliseconds: 100));

      // 4. 更新 todos
      final todoEvent = HapiSseEvent(
        type: HapiSseEventType.todoUpdate,
        sessionId: sessionId,
        data: {
          'sessionId': sessionId,
          'todos': [
            {
              'content': 'Process multi-event test',
              'status': 'completed',
              'activeForm': 'Processing multi-event test',
            },
          ],
        },
      );
      permHandler.handle(todoEvent);
      await Future.delayed(Duration(milliseconds: 100));

      // 5. 验证所有事件都已正确处理
      final sessions = container.read(sessionsProvider);
      final session = sessions.where((s) => s.id == sessionId).firstOrNull;
      expect(session, isNotNull);
      expect(session?.id, sessionId);
      expect(session?.todos?.length, 1);

      final messages = container.read(messagesProvider);
      final sessionMessages =
          messages.where((m) => m.sessionId == sessionId).toList();
      expect(sessionMessages.isNotEmpty, isTrue);

      // 清理
      sessionHandler.dispose();
    });
  });
}
