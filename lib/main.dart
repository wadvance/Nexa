import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    dev.log('FlutterError: ${details.exception}\n${details.stack}');
    FlutterError.presentError(details);
  };

  runApp(const AetherisApp());
}

Future<void> initServices() async {
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env").timeout(const Duration(seconds: 5));
    } catch (e) {
      dev.log('dotenv load error: $e');
    }
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    dev.log('Firebase init error: $e');
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
}

class AetherisApp extends StatefulWidget {
  const AetherisApp({super.key});

  @override
  State<AetherisApp> createState() => _AetherisAppState();
}

class _AetherisAppState extends State<AetherisApp> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = initServices();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AETHERIS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        primaryColor: Colors.deepPurpleAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }
          if (snapshot.hasError) {
            return _ErrorScreen(error: snapshot.error.toString());
          }
          return const AuthGate();
        },
      ),
      routes: {
        '/voice-test': (_) => const VoiceTestScreen(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.deepPurpleAccent),
            SizedBox(height: 20),
            Text('AETHERIS',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 24,
                    letterSpacing: 6)),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(error,
                  style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 13,
                      fontFamily: 'monospace'),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              const Text('Revisa la consola (F12) para más detalles.',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
