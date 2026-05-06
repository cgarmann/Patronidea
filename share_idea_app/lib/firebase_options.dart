import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDESARK7HX-r4bIM7XrDbsJHZDiTIQXNCA',
    appId: '1:1002199718024:android:195d7afe7bff14727ca73d',
    messagingSenderId: '1002199718024',
    projectId: 'share-your-idea-schjoldr',
    storageBucket: 'share-your-idea-schjoldr.firebasestorage.app',
  );

  // TODO(ios): Replace placeholder values with real values from Firebase Console
  // after registering the iOS app (Project Settings → Add app → iOS).
  // Download GoogleService-Info.plist and copy the values here.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '1002199718024',
    projectId: 'share-your-idea-schjoldr',
    storageBucket: 'share-your-idea-schjoldr.firebasestorage.app',
    iosBundleId: 'com.schjoldr.shareIdea',
  );
}
