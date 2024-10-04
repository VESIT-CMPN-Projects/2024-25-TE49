import 'package:flutter/foundation.dart'; // Import for TargetPlatform and defaultTargetPlatform
import 'package:flutter/material.dart'; // Import for Material design features
import 'package:firebase_core/firebase_core.dart'
    show FirebaseOptions; // Import for FirebaseOptions

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ios;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDJHlJEUzoHRsj1xGnYM3W_BUHGb-lg47Q',
    appId: '1:102441831089:ios:043336422660959936b090',
    messagingSenderId: '102441831089',
    projectId: 'journey-gennie-3a4f0',
    storageBucket: 'journey-gennie-3a4f0.appspot.com',
    iosBundleId: 'com.example.journeyGennie',
  );
}
