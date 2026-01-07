import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: 初始化 Firebase
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // 创建 ProviderContainer 以便初始化设置
  final container = ProviderContainer();

  // 初始化设置
  await container.read(settingsProvider.notifier).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CCMonitorApp(),
    ),
  );
}
