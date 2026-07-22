import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'voice_loader_stub.dart'
    if (dart.library.js_interop) 'voice_loader_web.dart';
import '../utils/logger.dart';

enum VoiceState { idle, listening, processing, speaking }

/// AetherisVoice — motor de voz optimizado para Chrome/Web.
///
/// Problema conocido de Chrome Web Speech API:
///   • Nunca emite finalResult=true en modo dictation con partialResults=true.
///   • El status 'notListening' llega DESPUÉS de que _speech.listen() retorna,
///     por lo que hay condición de carrera con el Completer.
///
/// Solución implementada:
///   • listenMode: confirmation  → Chrome sí emite finalResult en este modo.
///   • pauseFor: 800ms           → responde rápido tras silencio breve.
///   • Doble gatillo: finalResult O (parcial con ≥3 palabras estable 500ms).
///   • onStatus 'notListening'   → siempre entrega lo que haya, sin esperar.
///   • Timeout agresivo: 10s     → nunca se queda colgado.
class AetherisVoice {
  static final AetherisVoice instance = AetherisVoice._();
  AetherisVoice._();

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  VoiceState _state = VoiceState.idle;
  String _lastResult = '';
  Completer<String>? _activeCompleter;
  Timer? _partialTimer; // entrega resultado parcial si lleva 500ms estable

  // ── Getters ───────────────────────────────────────────────────────────────

  VoiceState get state  => _state;
  bool get sttReady     => _speech.isAvailable;
  bool get listening    => _state == VoiceState.listening;
  bool get speaking     => _state == VoiceState.speaking;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    AppLogger.info('=== INIT VOICE ===');

    await _tts.setSpeechRate(0.92);
    await _tts.setVolume(1.0);
    await _tts.setPitch(0.78);
    await _tts.awaitSpeakCompletion(true);
    await _selectSpanishVoice();

    _tts.setCompletionHandler(() {
      _state = VoiceState.idle;
      AppLogger.info('TTS: done');
    });
    _tts.setErrorHandler((msg) {
      _state = VoiceState.idle;
      AppLogger.error('TTS error: $msg');
    });

    try {
      await _speech.initialize(
        onError: (e) {
          AppLogger.error('STT error: ${e.errorMsg}');
          // error_no_match: el usuario no dijo nada reconocible → entregar ''
          _deliverResult(_lastResult);
        },
        onStatus: (s) {
          AppLogger.info('STT status: $s');
          // 'notListening' o 'done' → entregar lo capturado inmediatamente
          if (s == 'notListening' || s == 'done') {
            _deliverResult(_lastResult);
          }
        },
        debugLogging: false,
      );
    } catch (e) {
      AppLogger.error('STT init: $e');
    }

    AppLogger.info('=== VOICE READY sttReady=$sttReady ===');
  }

  Future<void> _selectSpanishVoice() async {
    await waitForVoices();
    final voiceName = findMaleSpanishVoice();
    try { await _tts.setLanguage('es-MX'); } catch (_) {
      try { await _tts.setLanguage('es-ES'); } catch (_) {}
    }
    if (voiceName != null) {
      try {
        await _tts.setVoice({'name': voiceName, 'locale': 'es-MX'});
        AppLogger.info('Voice: $voiceName');
      } catch (_) {}
    }
  }

  // ── TTS ───────────────────────────────────────────────────────────────────

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    if (_state == VoiceState.speaking) return;
    if (_state == VoiceState.listening) {
      try { await _speech.stop(); } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _state = VoiceState.speaking;
    try {
      await _tts.speak(_normalizeText(text));
    } catch (e) {
      AppLogger.error('TTS: $e');
    } finally {
      _state = VoiceState.idle;
    }
  }

  Future<void> stopSpeaking() async {
    try { await _tts.stop(); } catch (_) {}
    _state = VoiceState.idle;
  }

  // ── STT ───────────────────────────────────────────────────────────────────

  Future<String> listenOnce() async {
    if (!_speech.isAvailable) {
      AppLogger.warn('STT no disponible');
      return '';
    }
    if (_state == VoiceState.speaking) {
      AppLogger.warn('STT: TTS activo, saltado');
      return '';
    }
    if (_state != VoiceState.idle) {
      AppLogger.warn('STT: state=$_state, saltado');
      return '';
    }
    return _doListen();
  }

  Future<String> _doListen() async {
    _lastResult = '';
    _state = VoiceState.listening;

    final completer = Completer<String>();
    _activeCompleter = completer;
    _partialTimer?.cancel();

    // Detectar locale español disponible
    final localeId = await _bestSpanishLocale();
    AppLogger.info('STT locale: $localeId');

    try {
      await _speech.listen(
        onResult: (r) {
          final words = r.recognizedWords.trim();
          if (words.isNotEmpty) {
            _lastResult = words;
            AppLogger.info('STT "$words" final=${r.finalResult}');
          }

          if (r.finalResult) {
            // Chrome confirmation mode: sí emite finalResult
            _deliverResult(_lastResult);
            return;
          }

          // Gatillo parcial: si el texto lleva 500 ms sin cambiar → entregar
          // Esto cubre el caso en que finalResult nunca llega (Chrome dictation)
          _partialTimer?.cancel();
          if (_lastResult.split(' ').length >= 2) {
            _partialTimer = Timer(const Duration(milliseconds: 800), () {
              AppLogger.info('STT parcial estable → entregando "$_lastResult"');
              _deliverResult(_lastResult);
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          // confirmation: Chrome SÍ emite finalResult en este modo
          listenMode: stt.ListenMode.confirmation,
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(milliseconds: 800),
          localeId: localeId,
          cancelOnError: false,
          partialResults: true,
        ),
      );
    } catch (e) {
      AppLogger.error('STT listen: $e');
      _deliverResult('');
      _activeCompleter = null;
      return '';
    }

    // Timeout máximo: 11s — nunca se queda colgado
    final result = await completer.future.timeout(
      const Duration(seconds: 11),
      onTimeout: () {
        AppLogger.info('STT timeout, entregando "$_lastResult"');
        try { _speech.stop(); } catch (_) {}
        _deliverResult(_lastResult);
        return _lastResult;
      },
    );

    _partialTimer?.cancel();
    _activeCompleter = null;
    AppLogger.info('STT → "$result"');
    return result;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Entrega el resultado al Completer activo y resetea estado.
  void _deliverResult(String value) {
    _partialTimer?.cancel();
    if (_state == VoiceState.listening) _state = VoiceState.idle;
    final c = _activeCompleter;
    if (c != null && !c.isCompleted) c.complete(value);
  }

  Future<String> _bestSpanishLocale() async {
    try {
      final locales = await _speech.locales();
      // Preferencia: es_US (mejor reconocimiento en Chrome) > es_MX > es_419 > es_ES > cualquier es_*
      const preferred = ['es_US', 'es_MX', 'es-419', 'es_ES'];
      for (final pref in preferred) {
        if (locales.any((l) => l.localeId == pref)) return pref;
      }
      final any = locales.firstWhere(
        (l) => l.localeId.startsWith('es'),
        orElse: () => locales.first,
      );
      return any.localeId;
    } catch (_) {
      return 'es-ES';
    }
  }

  String _normalizeText(String t) => t
      .replaceAll('AETHERIS', 'Eteris')
      .replaceAll('Aetheris', 'Eteris')
      .replaceAll('aetheris', 'Eteris');

  void stop() {
    _partialTimer?.cancel();
    try { _speech.stop(); } catch (_) {}
    try { _tts.stop(); } catch (_) {}
    _state = VoiceState.idle;
  }
}
