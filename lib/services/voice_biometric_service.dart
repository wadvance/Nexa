import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceBiometricService {
  static const _storageKey = 'aetheris_voice_pin_hash';
  static String? _registeredHash;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _registeredHash = prefs.getString(_storageKey);
  }

  static Future<String> registerVoicePin(String rawAudioData) async {
    final bytes = utf8.encode(rawAudioData);
    _registeredHash = sha256.convert(bytes).toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _registeredHash!);
    return _registeredHash!;
  }

  static bool verifyVoicePin(String rawAudioData) {
    if (_registeredHash == null) return false;
    final bytes = utf8.encode(rawAudioData);
    final attemptHash = sha256.convert(bytes).toString();
    return attemptHash == _registeredHash;
  }

  static bool get isRegistered => _registeredHash != null;

  static Future<void> clear() async {
    _registeredHash = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
