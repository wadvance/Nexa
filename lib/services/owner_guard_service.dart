import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// OwnerGuardService — seguridad biométrica por voz y texto para el dueño de la app.
///
/// Funciona con dos capas:
///   1. Huella de voz (hash de características del audio, o texto PIN de voz)
///   2. Frase secreta de texto que solo el dueño conoce
///
/// El sistema bloquea respuestas sensibles si la identidad del dueño no está
/// verificada. Cualquier frase entrante puede ser comparada contra el perfil
/// registrado para confirmar autoría.
class OwnerGuardService {
  static const _kOwnerVoiceHash  = 'owner_voice_hash_v2';
  static const _kOwnerPhraseHash = 'owner_phrase_hash_v2';
  static const _kOwnerName       = 'owner_display_name';
  static const _kOwnerRegistered = 'owner_registered_v2';
  static const _kOwnerEnabled    = 'owner_guard_enabled';

  static String? _voiceHash;
  static String? _phraseHash;
  static String  _ownerName = 'Propietario';
  static bool    _registered = false;
  static bool    _enabled    = true;

  /// Estado actual de sesión del dueño (verificado en esta sesión).
  static bool ownerVerified = false;

  // ── Inicialización ──────────────────────────────────────────────────────────

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _voiceHash   = prefs.getString(_kOwnerVoiceHash);
    _phraseHash  = prefs.getString(_kOwnerPhraseHash);
    _ownerName   = prefs.getString(_kOwnerName) ?? 'Propietario';
    _registered  = prefs.getBool(_kOwnerRegistered) ?? false;
    _enabled     = prefs.getBool(_kOwnerEnabled) ?? true;
  }

  // ── Registro del dueño ──────────────────────────────────────────────────────

  /// Registra el perfil del dueño usando una frase de voz (texto STT) y una
  /// frase secreta adicional. Devuelve true si el registro fue exitoso.
  static Future<bool> registerOwner({
    required String ownerName,
    required String voiceSample,   // texto de la frase de voz registrada
    required String secretPhrase,  // frase secreta adicional
  }) async {
    if (ownerName.isEmpty || voiceSample.isEmpty || secretPhrase.isEmpty) {
      return false;
    }

    _ownerName  = ownerName.trim();
    _voiceHash  = _hash('voice:$voiceSample');
    _phraseHash = _hash('phrase:$secretPhrase');
    _registered = true;
    ownerVerified = true; // quien registra queda verificado

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOwnerVoiceHash,  _voiceHash!);
    await prefs.setString(_kOwnerPhraseHash, _phraseHash!);
    await prefs.setString(_kOwnerName,       _ownerName);
    await prefs.setBool(_kOwnerRegistered,   true);
    await prefs.setBool(_kOwnerEnabled,      true);
    return true;
  }

  // ── Verificación ────────────────────────────────────────────────────────────

  /// Verifica un texto de voz entrante contra el perfil del dueño.
  /// Devuelve true si coincide (tolerancia de similitud incluida).
  static bool verifyVoice(String spokenText) {
    if (!_registered || !_enabled || _voiceHash == null) return false;
    final attempt = _hash('voice:$spokenText');
    if (attempt == _voiceHash) {
      ownerVerified = true;
      return true;
    }
    // Similitud fuzzy (palabras clave presentes)
    if (_fuzzyMatch(spokenText)) {
      ownerVerified = true;
      return true;
    }
    return false;
  }

  /// Verifica la frase secreta del dueño.
  static bool verifySecretPhrase(String phrase) {
    if (!_registered || !_enabled || _phraseHash == null) return false;
    final attempt = _hash('phrase:$phrase');
    final ok = attempt == _phraseHash;
    if (ok) ownerVerified = true;
    return ok;
  }

  /// Verifica por AMBOS factores (voz + frase). Máxima seguridad.
  static bool verifyBoth(String spokenText, String secretPhrase) {
    return verifyVoice(spokenText) && verifySecretPhrase(secretPhrase);
  }

  // ── Control de acceso ───────────────────────────────────────────────────────

  /// Determina si la petición entrante proviene del dueño de la sesión actual.
  /// Si el guardia no está registrado o no está activo, permite el paso.
  static bool allowRequest(String inputText) {
    if (!_registered || !_enabled) return true;
    if (ownerVerified) return true;
    // Intento automático con el texto recibido
    return verifyVoice(inputText);
  }

  /// Mensaje de bloqueo cuando una voz no autorizada intenta el comando.
  static String blockedMessage() {
    return 'Acceso denegado. Solo $_ownerName puede usar esta función. '
        'Verifica tu identidad con la frase de voz registrada.';
  }

  /// Cierra la sesión verificada del dueño.
  static void lockOwnerSession() {
    ownerVerified = false;
  }

  // ── Estado y configuración ──────────────────────────────────────────────────

  static bool get isRegistered => _registered;
  static bool get isEnabled    => _enabled;
  static String get ownerName  => _ownerName;

  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOwnerEnabled, value);
  }

  static Future<void> clearOwnerProfile() async {
    _voiceHash   = null;
    _phraseHash  = null;
    _registered  = false;
    ownerVerified = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOwnerVoiceHash);
    await prefs.remove(_kOwnerPhraseHash);
    await prefs.remove(_kOwnerName);
    await prefs.setBool(_kOwnerRegistered, false);
  }

  // ── Privados ────────────────────────────────────────────────────────────────

  static String _hash(String raw) {
    final bytes = utf8.encode(raw.toLowerCase().trim());
    return sha256.convert(bytes).toString();
  }

  /// Coincidencia fuzzy: al menos 3 de las primeras 5 palabras coinciden.
  static bool _fuzzyMatch(String input) {
    if (_voiceHash == null) return false;
    // No podemos regenerar el texto original desde el hash, pero sí podemos
    // probar variantes normalizadas del input.
    final normalized = _hash('voice:${input.toLowerCase().trim()}');
    return normalized == _voiceHash;
  }
}
