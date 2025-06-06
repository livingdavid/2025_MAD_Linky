import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyAvxtd39dR1h60OFGyW3z4m4xjgSRxFFoE',
    appId: '1:1087183332010:web:b37500e230485ba81ae6d3',
    messagingSenderId: '1087183332010',
    projectId: 'linky-2025',
    authDomain: 'linky-2025.firebaseapp.com',
    storageBucket: 'linky-2025.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAWfxxUxuLtLRvRDERGcIP2mmf9DqGvBsY',
    appId: '1:1087183332010:android:df1fbc7b17e2d9f81ae6d3',
    messagingSenderId: '1087183332010',
    projectId: 'linky-2025',
    storageBucket: 'linky-2025.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD2vsxU_vgTxiYLLfSCYikb8BJBZy3VwBg',
    appId: '1:1087183332010:ios:d33a5367fc96431b1ae6d3',
    messagingSenderId: '1087183332010',
    projectId: 'linky-2025',
    storageBucket: 'linky-2025.firebasestorage.app',
    iosClientId:
        '1087183332010-csn3cgh9s3gtn9om70dc2e752mllbbg1.apps.googleusercontent.com',
    iosBundleId: 'com.jiwonkim.linky',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD2vsxU_vgTxiYLLfSCYikb8BJBZy3VwBg',
    appId: '1:1087183332010:ios:bfe6e10ddc800feb1ae6d3',
    messagingSenderId: '1087183332010',
    projectId: 'linky-2025',
    storageBucket: 'linky-2025.firebasestorage.app',
    iosClientId:
        '1087183332010-f42n5b8lbdkdsaag79dcq7hci3buerku.apps.googleusercontent.com',
    iosBundleId: 'com.example.linky',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAvxtd39dR1h60OFGyW3z4m4xjgSRxFFoE',
    appId: '1:1087183332010:web:525a6d289314c3521ae6d3',
    messagingSenderId: '1087183332010',
    projectId: 'linky-2025',
    authDomain: 'linky-2025.firebaseapp.com',
    storageBucket: 'linky-2025.firebasestorage.app',
  );
}
