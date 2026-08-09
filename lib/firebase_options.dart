// ملف تلقائي - إعدادات الاتصال بمشروع Firebase الخاص بك
// تم استخراج البيانات من google-services.json

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'هذا المشروع مُعد لأندرويد فقط حاليًا',
      );
    }
    switch (Platform.operatingSystem) {
      case 'android':
        return android;
      default:
        throw UnsupportedError(
          'هذا المشروع مُعد لأندرويد فقط حاليًا',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDIQBh2_YZ9F0eujI6N8L2sU7VVB2XH1f8',
    appId: '1:717553697596:android:bfdc99555a904131b55439',
    messagingSenderId: '717553697596',
    projectId: 'ahmed-fikry',
    storageBucket: 'ahmed-fikry.firebasestorage.app',
  );
}
