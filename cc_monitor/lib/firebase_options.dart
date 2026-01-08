// File generated based on google-services.json
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCOxxzxhvhsVqqpAqO0GWvGPO2b_5RhPmo',
    appId: '1:507149970914:android:2badc09fe6eea960df5dbb',
    messagingSenderId: '507149970914',
    projectId: 'ccpush-45c62',
    databaseURL: 'https://ccpush-45c62-default-rtdb.firebaseio.com',
    storageBucket: 'ccpush-45c62.firebasestorage.app',
  );

  // iOS 配置 - 从 GoogleService-Info.plist 提取
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBvqfGfR5BCwuyJU1qSx9s4J0B22X5QUjM',
    appId: '1:507149970914:ios:a21cf6df2e7ab6c8df5dbb',
    messagingSenderId: '507149970914',
    projectId: 'ccpush-45c62',
    databaseURL: 'https://ccpush-45c62-default-rtdb.firebaseio.com',
    storageBucket: 'ccpush-45c62.firebasestorage.app',
    iosBundleId: 'com.example.ccMonitor',
  );

  // macOS 配置 - 与 iOS 共享相同的 Firebase 配置
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBvqfGfR5BCwuyJU1qSx9s4J0B22X5QUjM',
    appId: '1:507149970914:ios:a21cf6df2e7ab6c8df5dbb',
    messagingSenderId: '507149970914',
    projectId: 'ccpush-45c62',
    databaseURL: 'https://ccpush-45c62-default-rtdb.firebaseio.com',
    storageBucket: 'ccpush-45c62.firebasestorage.app',
    iosBundleId: 'com.example.ccMonitor',
  );

  // Windows 配置 - 与 Android 共享相同的 Firebase 项目
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCOxxzxhvhsVqqpAqO0GWvGPO2b_5RhPmo',
    appId: '1:507149970914:android:2badc09fe6eea960df5dbb',
    messagingSenderId: '507149970914',
    projectId: 'ccpush-45c62',
    databaseURL: 'https://ccpush-45c62-default-rtdb.firebaseio.com',
    storageBucket: 'ccpush-45c62.firebasestorage.app',
  );

  // Linux 配置 - 与 Android 共享相同的 Firebase 项目
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyCOxxzxhvhsVqqpAqO0GWvGPO2b_5RhPmo',
    appId: '1:507149970914:android:2badc09fe6eea960df5dbb',
    messagingSenderId: '507149970914',
    projectId: 'ccpush-45c62',
    databaseURL: 'https://ccpush-45c62-default-rtdb.firebaseio.com',
    storageBucket: 'ccpush-45c62.firebasestorage.app',
  );
}
