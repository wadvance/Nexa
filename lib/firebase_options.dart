// Archivo generado manualmente con los datos del proyecto Firebase "nexa-ff627".
//
// ⚠️ Las claves se leen desde el archivo .env — nunca las pongas directamente
//    en el código fuente ni las subas a un repo público.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  // Clave leída en runtime desde .env (no const — dotenv es runtime).
  static String get _apiKey =>
      dotenv.env['FIREBASE_API_KEY'] ?? '';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions no ha sido configurado para macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions no ha sido configurado para Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions no ha sido configurado para Linux.',
        );
      default:
        throw UnsupportedError(
          'Plataforma no soportada por DefaultFirebaseOptions.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _apiKey,
    authDomain: 'nexa-ff627.firebaseapp.com',
    projectId: 'nexa-ff627',
    storageBucket: 'nexa-ff627.firebasestorage.app',
    messagingSenderId: '702882467766',
    appId: '1:702882467766:web:c39b0ac2fa3e2485a87b17',
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: _apiKey,
    projectId: 'nexa-ff627',
    storageBucket: 'nexa-ff627.firebasestorage.app',
    messagingSenderId: '702882467766',
    appId: '1:702882467766:android:c39b0ac2fa3e2485a87b17',
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: _apiKey,
    projectId: 'nexa-ff627',
    storageBucket: 'nexa-ff627.firebasestorage.app',
    messagingSenderId: '702882467766',
    appId: '1:702882467766:ios:c39b0ac2fa3e2485a87b17',
  );
}
