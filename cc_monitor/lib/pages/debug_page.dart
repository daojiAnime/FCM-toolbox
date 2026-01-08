import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

/// 调试页面 - 用于测试 Firestore 连接
class DebugPage extends ConsumerStatefulWidget {
  const DebugPage({super.key});

  @override
  ConsumerState<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends ConsumerState<DebugPage> {
  String _status = '未连接';
  List<Map<String, dynamic>> _messages = [];
  bool _isListening = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final deviceId = settings.deviceId;
    final collectionPath = 'devices/$deviceId/messages';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore 调试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchMessages(collectionPath),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device ID
            Card(
              child: ListTile(
                leading: const Icon(Icons.devices),
                title: const Text('Device ID'),
                subtitle: SelectableText(deviceId),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: deviceId));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('已复制')));
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Collection Path
            Card(
              child: ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Collection Path'),
                subtitle: SelectableText(collectionPath),
              ),
            ),
            const SizedBox(height: 8),

            // Status
            Card(
              child: ListTile(
                leading: Icon(
                  _isListening ? Icons.cloud_done : Icons.cloud_off,
                  color: _isListening ? Colors.green : Colors.grey,
                ),
                title: const Text('状态'),
                subtitle: Text(_status),
                trailing: Switch(
                  value: _isListening,
                  onChanged: (value) {
                    if (value) {
                      _startListening(collectionPath);
                    } else {
                      _stopListening();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _fetchMessages(collectionPath),
                  icon: const Icon(Icons.download),
                  label: const Text('获取消息'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _startListening(collectionPath),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始监听'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Messages
            Expanded(
              child: Card(
                child: _messages.isEmpty
                    ? const Center(child: Text('暂无消息'))
                    : ListView.builder(
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return ListTile(
                            leading: _getTypeIcon(msg['type'] as String? ?? ''),
                            title: Text(msg['title'] as String? ?? 'No title'),
                            subtitle: Text(msg['message'] as String? ?? ''),
                            trailing: Text(
                              _formatTime(msg['createdAt']),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Icon _getTypeIcon(String type) {
    return switch (type) {
      'complete' => const Icon(Icons.check_circle, color: Colors.green),
      'error' => const Icon(Icons.error, color: Colors.red),
      'warning' => const Icon(Icons.warning, color: Colors.orange),
      'progress' => const Icon(Icons.pending, color: Colors.blue),
      _ => const Icon(Icons.message, color: Colors.grey),
    };
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString().substring(11, 19);
    }
    return '';
  }

  Future<void> _fetchMessages(String collectionPath) async {
    setState(() => _status = '正在获取消息...');

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionPath)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      setState(() {
        _messages = snapshot.docs.map((doc) => doc.data()).toList();
        _status = '获取到 ${_messages.length} 条消息';
      });
    } catch (e) {
      setState(() => _status = '获取失败: $e');
    }
  }

  void _startListening(String collectionPath) {
    setState(() {
      _isListening = true;
      _status = '正在监听...';
    });

    FirebaseFirestore.instance
        .collection(collectionPath)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen(
          (snapshot) {
            setState(() {
              _messages = snapshot.docs.map((doc) => doc.data()).toList();
              _status = '实时监听中 (${_messages.length} 条消息)';
            });
          },
          onError: (e) {
            setState(() {
              _status = '监听错误: $e';
              _isListening = false;
            });
          },
        );
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
      _status = '已停止监听';
    });
  }
}
