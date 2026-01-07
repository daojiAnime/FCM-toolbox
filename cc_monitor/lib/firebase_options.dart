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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  // iOS 配置 - 需要时添加实际配置
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '507149970914',
    projectId: 'ccpush-45c62',
    databaseURL: 'https://ccpush-45c62-default-rtdb.firebaseio.com',
    storageBucket: 'ccpush-45c62.firebasestorage.app',
    iosBundleId: 'com.example.ccMonitor',
  );
}
