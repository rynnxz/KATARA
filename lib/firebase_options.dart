import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps (`katara-melayu`).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return android;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      _ => android,
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDiP5SoFyF-9ivwghm7wHgskBWKrHiGsrM',
    appId: '1:236754467620:android:603644d507d0290562d1b1',
    messagingSenderId: '236754467620',
    projectId: 'katara-melayu',
    storageBucket: 'katara-melayu.firebasestorage.app',
  );
}
