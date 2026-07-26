import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'voice_loader_stub.dart'
    if (dart.library.js_interop) 'voice_loader_web.dart';
import '_web_voice_impl_stub.dart'
    if (dart.library.js_interop) '_web_voice_impl.dart';
import '../utils/logger.dart';
import 'voice_shared.dart';

export 'voice_shared.dart' show VoiceState;

AetherisVoice _createVoice() {
  if (kIsWeb) return WebAetherisVoice();
  return AetherisVoice();
}

class AetherisVoice {
  static final AetherisVoice instance = _createVoice();

  AetherisVoice() {
    if (!kIsWeb) {
      _tts = FlutterTts();
      _speech = stt.SpeechToText();
    }
  }

  late final FlutterTts _tts;
  late final stt.SpeechToText _speech;

  VoiceState voiceState = VoiceState.idle;
  String _lastResult = '';
  Completer<String>? _activeCompleter;
  Timer? _partialTimer;
  Timer? _silenceTimer;

  VoiceState get state => voiceState;
  set state(VoiceState value) => voiceState = value;
  // ignore: unnecessary_getters_setters
  bool get sttReady => _speech.isAvailable;
  bool get listening => voiceState == VoiceState.listening;
  bool get speaking => voiceState == VoiceState.speaking;

  String normalizeText(String text) => _normalizeText(text);

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    AppLogger.info('=== INIT VOICE ===');

    await _tts.setSpeechRate(0.92);
    await _tts.setVolume(1.0);
    await _tts.setPitch(0.78);
    await _tts.awaitSpeakCompletion(true);
    await _selectSpanishVoice();

    _tts.setCompletionHandler(() {
      voiceState = VoiceState.idle;
      AppLogger.info('TTS: done');
    });
    _tts.setErrorHandler((msg) {
      voiceState = VoiceState.idle;
      AppLogger.error('TTS error: $msg');
    });

    try {
      await _speech.initialize(
        onError: (e) {
          AppLogger.error('STT error: ${e.errorMsg}');
          // No entregamos aquí — esperamos al timeout
        },
        onStatus: (s) {
          AppLogger.info('STT status: $s');
          // Ignoramos 'notListening' y 'done' — no entregamos resultado
          // El resultado se entrega SOLO por timeout o por el loop principal
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
    if (voiceState == VoiceState.speaking) return;
    if (voiceState == VoiceState.listening) {
      try { await _speech.stop(); } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 100));
    }
    voiceState = VoiceState.speaking;
    try {
      await _tts.speak(_normalizeText(text));
    } catch (e) {
      AppLogger.error('TTS: $e');
    } finally {
      voiceState = VoiceState.idle;
    }
  }

  Future<void> stopSpeaking() async {
    try { await _tts.stop(); } catch (_) {}
    voiceState = VoiceState.idle;
  }

  // ── STT ───────────────────────────────────────────────────────────────────

  Future<String> listenOnce() async {
    if (!_speech.isAvailable) {
      AppLogger.warn('STT no disponible, intentando re-inicializar');
      try {
        await _speech.initialize(
          onError: (e) => AppLogger.error('STT error: ${e.errorMsg}'),
          onStatus: (s) => AppLogger.info('STT status: $s'),
          debugLogging: false,
        );
      } catch (e) {
        AppLogger.error('STT re-init failed: $e');
        return '';
      }
      if (!_speech.isAvailable) {
        AppLogger.warn('STT aún no disponible tras re-init');
        return '';
      }
    }
    if (voiceState == VoiceState.speaking) {
      AppLogger.warn('STT: TTS activo, saltado');
      return '';
    }
    if (voiceState != VoiceState.idle) {
      AppLogger.warn('STT: state=$voiceState, forzando idle');
      voiceState = VoiceState.idle;
    }
    return _doListen();
  }

  Future<String> _doListen() async {
    _lastResult = '';
    _silenceTimer?.cancel();
    voiceState = VoiceState.listening;

    final completer = Completer<String>();
    _activeCompleter = completer;
    _partialTimer?.cancel();

    final localeId = await _bestSpanishLocale();
    AppLogger.info('STT locale: $localeId');

    try {
      await _speech.listen(
        onResult: (r) {
          final words = r.recognizedWords.trim();
          if (words.isNotEmpty && words != _lastResult) {
            _lastResult = words;
            AppLogger.info('STT "$words" final=${r.finalResult}');
          }

          // Reiniciar timer de silencio cada vez que hay speech
          _silenceTimer?.cancel();
          _silenceTimer = Timer(const Duration(seconds: 15), () {
            // 15 segundos sin speech nuevo → entregar resultado
            if (!completer.isCompleted && _lastResult.isNotEmpty) {
              AppLogger.info('STT: 15s silencio, entregando "$_lastResult"');
              try { _speech.stop(); } catch (_) {}
              _deliverResult(_lastResult);
            }
          });
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 15),
          localeId: localeId,
          cancelOnError: false,
          partialResults: true,
        ),
      );
    } catch (e) {
      AppLogger.error('STT listen failed, intentando re-init: $e');
      try {
        await _speech.initialize(
          onError: (e2) => AppLogger.error('STT error: ${e2.errorMsg}'),
          onStatus: (s) => AppLogger.info('STT status: $s'),
          debugLogging: false,
        );
        await _speech.listen(
          onResult: (r) {
            final words = r.recognizedWords.trim();
            if (words.isNotEmpty && words != _lastResult) {
              _lastResult = words;
            }
            _silenceTimer?.cancel();
            _silenceTimer = Timer(const Duration(seconds: 15), () {
              if (!completer.isCompleted && _lastResult.isNotEmpty) {
                try { _speech.stop(); } catch (_) {}
                _deliverResult(_lastResult);
              }
            });
          },
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
            listenFor: const Duration(seconds: 60),
            pauseFor: const Duration(seconds: 15),
            localeId: localeId,
            cancelOnError: false,
            partialResults: true,
          ),
        );
      } catch (e2) {
        AppLogger.error('STT re-init+listen also failed: $e2');
        _deliverResult('');
        _activeCompleter = null;
        return '';
      }
    }

    final result = await completer.future.timeout(
      const Duration(seconds: 65),
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

  void _deliverResult(String value) {
    _partialTimer?.cancel();
    _silenceTimer?.cancel();
    if (voiceState == VoiceState.listening) voiceState = VoiceState.idle;
    final c = _activeCompleter;
    if (c != null && !c.isCompleted) c.complete(value);
  }

  Future<String> _bestSpanishLocale() async {
    try {
      final locales = await _speech.locales();
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

  Future<void> startContinuous() async {}  // web only
  void stopContinuous() {}                  // web only

  void stop() {
    _partialTimer?.cancel();
    _silenceTimer?.cancel();
    try { _speech.stop(); } catch (_) {}
    try { _tts.stop(); } catch (_) {}
    voiceState = VoiceState.idle;
  }
}

