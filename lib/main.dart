import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as dev;
import 'firebase_options.dart';
import 'services/voice_biometric_service.dart';
import 'services/location_service.dart';
import 'services/owner_guard_service.dart';
import 'services/conversation_memory_service.dart';
import 'services/notification_service.dart';
import 'services/proactive_context_service.dart';
import 'presentation/screens/auth/auth_gate.dart';
import 'presentation/screens/voice_test_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Mostrar captura de errores en pantalla para debug
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      dev.log('FlutterError: ${details.exception}\n${details.stack}');
    };

    if (!kIsWeb) {
      try {
        await dotenv.load(fileName: ".env").timeout(const Duration(seconds: 5));
      } catch (e) {
        dev.log('dotenv load error: $e');
      }
    } else {
      dev.log('web: skipping dotenv.load, using --dart-define');
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      dev.log('Firebase init error (web tolerado): $e');
    }

    try {
      await VoiceBiometricService.init();
    } catch (e) {
      dev.log('VoiceBiometric init error: $e');
    }

    try {
      await LocationService.init();
    } catch (e) {
      dev.log('Location init error: $e');
    }

    try {
      await OwnerGuardService.init();
    } catch (e) {
      dev.log('OwnerGuard init error: $e');
    }

    try {
      await ConversationMemoryService.load();
    } catch (e) {
      dev.log('ConversationMemory init error: $e');
    }

    try {
      await NotificationService.instance.init();
    } catch (e) {
      dev.log('Notification init error: $e');
    }

    try {
      ProactiveContextService().start();
    } catch (e) {
      dev.log('ProactiveContext start error: $e');
    }

    runApp(const AetherisApp());
  }, (error, stack) {
    dev.log('UNCAUGHT ERROR: $error\n$stack');
    // Mostrar error en la UI
    runApp(ErrorScreen(error: error.toString()));
  });
}

class AetherisApp extends StatelessWidget {
  const AetherisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AETHERIS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        primaryColor: Colors.deepPurpleAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const AuthGate(),
      routes: {
        '/voice-test': (_) => const VoiceTestScreen(),
      },
    );
  }
}

/// Pantalla de error visible cuando la app se cae al arrancar.
class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 64),
                const SizedBox(height: 20),
                const Text('AETHERIS — Error al iniciar',
                    style: TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(error,
                    style: const TextStyle(color: Colors.orangeAccent,
                        fontSize: 13, fontFamily: 'monospace'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                const Text('Revisa la consola (F12) para más detalles.',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
