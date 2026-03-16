import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBe63wGoIkqIAy6Wo6vJyBlXrYlJOwI0vE',
    appId: '1:262084784828:web:9253451fe79f540ec016b9',
    messagingSenderId: '262084784828',
    projectId: 'shadow-hunt-885c6',
    authDomain: 'shadow-hunt-885c6.firebaseapp.com',
    databaseURL:
        'https://shadow-hunt-885c6-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'shadow-hunt-885c6.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBe63wGoIkqIAy6Wo6vJyBlXrYlJOwI0vE',
    appId: '1:262084784828:android:04eff48216ced0d5c016b9',
    messagingSenderId: '262084784828',
    projectId: 'shadow-hunt-885c6',
    databaseURL:
        'https://shadow-hunt-885c6-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'shadow-hunt-885c6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBe63wGoIkqIAy6Wo6vJyBlXrYlJOwI0vE',
    appId: '1:262084784828:ios:0000000000000000c016b9',
    messagingSenderId: '262084784828',
    projectId: 'shadow-hunt-885c6',
    databaseURL:
        'https://shadow-hunt-885c6-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'shadow-hunt-885c6.firebasestorage.app',
    iosBundleId: 'com.example.shadowHunt',
  );
}
