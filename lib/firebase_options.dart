// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDYSZWktCMW2u_pzpYBi_A_ZszwQRyk6ac',
    appId: '1:252776703139:web:60db327548b9f10d564b16',
    messagingSenderId: '252776703139',
    projectId: 'passwd-brundindev',
    authDomain: 'passwd-brundindev.firebaseapp.com',
    storageBucket: 'passwd-brundindev.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCehziaHQgcKHv6jSwPLe74ThZvdswzVtY',
    appId: '1:252776703139:android:7613a171dd9674d6564b16',
    messagingSenderId: '252776703139',
    projectId: 'passwd-brundindev',
    storageBucket: 'passwd-brundindev.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCtAlz5H9pJZm5_4Jw57idt5ymNHpLXS3c',
    appId: '1:252776703139:ios:b3b9b44409c8cab2564b16',
    messagingSenderId: '252776703139',
    projectId: 'passwd-brundindev',
    storageBucket: 'passwd-brundindev.firebasestorage.app',
    iosBundleId: 'com.example.gestorPassword',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCtAlz5H9pJZm5_4Jw57idt5ymNHpLXS3c',
    appId: '1:252776703139:ios:b3b9b44409c8cab2564b16',
    messagingSenderId: '252776703139',
    projectId: 'passwd-brundindev',
    storageBucket: 'passwd-brundindev.firebasestorage.app',
    iosBundleId: 'com.example.gestorPassword',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDYSZWktCMW2u_pzpYBi_A_ZszwQRyk6ac',
    appId: '1:252776703139:web:9e8552724a4b513b564b16',
    messagingSenderId: '252776703139',
    projectId: 'passwd-brundindev',
    authDomain: 'passwd-brundindev.firebaseapp.com',
    storageBucket: 'passwd-brundindev.firebasestorage.app',
  );
}
