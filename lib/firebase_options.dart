import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzvJdtaM0UJ6y8mq47JFTZozR2dI7klJw',
    appId: '1:540350814965:android:a1c68bde719e96579103bc',
    messagingSenderId: '540350814965',
    projectId: 'smart-task-manage-129c5',
    storageBucket: 'smart-task-manage-129c5.firebasestorage.app',
  );
}
