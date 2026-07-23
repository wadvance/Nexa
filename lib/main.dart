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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(const AetherisApp());
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
