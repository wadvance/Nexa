import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:web/web.dart' as web;
import 'voice_loader_stub.dart'
    if (dart.library.js_interop) 'voice_loader_web.dart';
import '../utils/logger.dart';

enum VoiceState { idle, listening, processing, speaking }

AetherisVoice _createVoice() {
  if (kIsWeb) return _WebAetherisVoice();
  return AetherisVoice._();
}

class AetherisVoice {
  static final AetherisVoice instance = _createVoice();

  AetherisVoice._() {
    if (!kIsWeb) {
      _tts = FlutterTts();
      _speech = stt.SpeechToText();
    }
  }

  late final FlutterTts _tts;
  late final stt.SpeechToText _speech;

  VoiceState _state = VoiceState.idle;
  String _lastResult = '';
  Completer<String>? _activeCompleter;
  Timer? _partialTimer;

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
          _deliverResult(_lastResult);
        },
        onStatus: (s) {
          AppLogger.info('STT status: $s');
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
            _deliverResult(_lastResult);
            return;
          }

          _partialTimer?.cancel();
          if (_lastResult.split(' ').length >= 2) {
            _partialTimer = Timer(const Duration(milliseconds: 800), () {
              AppLogger.info('STT parcial estable → entregando "$_lastResult"');
              _deliverResult(_lastResult);
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
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

  void _deliverResult(String value) {
    _partialTimer?.cancel();
    if (_state == VoiceState.listening) _state = VoiceState.idle;
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
    try { _speech.stop(); } catch (_) {}
    try { _tts.stop(); } catch (_) {}
    _state = VoiceState.idle;
  }
}

class _WebAetherisVoice extends AetherisVoice {
  _WebAetherisVoice() : super._();

  final stt.SpeechToText _webStt = stt.SpeechToText();
  final _utterance = web.SpeechSynthesisUtterance();
  web.SpeechSynthesis? get _synth => web.window.speechSynthesis;
  bool _webSttReady = false;
  bool _webSttActive = false;                   // sesión continua iniciada
  Completer<String>? _webNextResult;             // quien espera el próximo resultado
  final List<String> _webPendingResults = [];    // resultados encolados mientras nadie espera
  Timer? _webSttTimeout;                        // timeout de inactividad

  @override
  bool get sttReady => _webSttReady;

  @override
  Future<void> init() async {
    AppLogger.info('=== WEB VOICE INIT ===');

    await waitForVoices();
    _selectVoice();

    try {
      _webSttReady = await _webStt.initialize(
        onError: (e) => AppLogger.error('WebSTT error: ${e.errorMsg}'),
        onStatus: (s) => AppLogger.info('WebSTT status: $s'),
        debugLogging: false,
      );
    } catch (e) {
      AppLogger.error('WebSTT init: $e');
    }

    _utterance.lang = 'es-MX';
    _utterance.rate = 1.08;
    _utterance.pitch = 1.0;
    AppLogger.info('=== WEB VOICE sttReady=$_webSttReady ===');
  }

  void _selectVoice() {
    final synth = _synth;
    if (synth == null) return;
    final voices = synth.getVoices();
    final list = voices.toDart;
    if (list.isEmpty) return;

    web.SpeechSynthesisVoice? latinFemale;
    web.SpeechSynthesisVoice? latinAny;

    const latinLocales = ['es-mx', 'es-us', 'es-419', 'es-la', 'es-co',
                          'es-ar', 'es-cl', 'es-pe', 'es-ve'];
    const femaleHints = ['female', 'woman', 'mujer', 'femenina',
                         'maría', 'sofía', 'elena', 'paula', 'carmen',
                         'mónica', 'laura', 'ana', 'valentina',
                         'camila', 'isabella', 'gabriela', 'lucía',
                         'samantha', 'helena', 'sabina'];

    for (final v in list) {
      final name = v.name.toLowerCase();
      final lang = v.lang.toLowerCase();
      if (!lang.startsWith('es')) continue;

      final isLatin = latinLocales.any((l) => lang.startsWith(l));
      final isFemale = femaleHints.any((h) => name.contains(h));

      if (isLatin && isFemale) latinFemale ??= v;
      if (isLatin) latinAny ??= v;
    }

    // Prioridad: latina femenina > cualquier latina > que el navegador elija
    final selected = latinFemale ?? latinAny;
    if (selected != null) {
      _utterance.voice = selected;
      AppLogger.info('WebTTS: ${selected.name} (${selected.lang})');
    } else {
      // Sin voice explícito: el navegador elige la mejor voz para es-MX
      _utterance.voice = null;
      AppLogger.info('WebTTS: sin voz latina, el navegador elige');
    }
  }

  @override
  Future<void> speak(String text) async {
    if (text.isEmpty || _synth == null) return;
    _state = VoiceState.speaking;
    final completer = Completer<void>();
    _utterance.text = _normalizeText(text);
    _utterance.onend = (() {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    _utterance.onerror = (() {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    _synth!.speak(_utterance);
    await completer.future.timeout(const Duration(seconds: 15), onTimeout: () {});
    _state = VoiceState.idle;
  }

  @override
  Future<void> stopSpeaking() async {
    _synth?.cancel();
    _state = VoiceState.idle;
  }

  /// Inicia la escucha continua (una sola llamada a `listen()` por sesión).
  @override
  Future<void> startContinuous() async {
    if (_webSttActive || !_webSttReady) return;
    _webSttActive = true;
    AppLogger.info('WebSTT: starting continuous session');

    // Reiniciar cola
    _webPendingResults.clear();
    _webNextResult?.complete('');
    _webNextResult = null;

    Timer? partialTimer;

    void deliver(String text) {
      partialTimer?.cancel();
      partialTimer = null;
      if (_webNextResult != null) {
        _webNextResult!.complete(text);
        _webNextResult = null;
      } else {
        _webPendingResults.add(text);
      }
    }

    try {
      await _webStt.listen(
        onResult: (r) {
          final words = r.recognizedWords.trim();
          AppLogger.info('WebSTT partial: "$words" final=${r.finalResult}');

          if (r.finalResult && words.isNotEmpty) {
            deliver(words);
            return;
          }

          if (words.isNotEmpty) {
            partialTimer?.cancel();
            partialTimer = Timer(const Duration(milliseconds: 800), () {
              AppLogger.info('WebSTT stable partial: $words');
              deliver(words);
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(milliseconds: 500),
          partialResults: true,
        ),
      );
    } catch (e) {
      AppLogger.error('WebSTT startContinuous: $e');
      _webSttActive = false;
      _state = VoiceState.idle;
    }
  }

  /// Detiene la sesión continua.
  @override
  void stopContinuous() {
    _webSttActive = false;
    _webSttTimeout?.cancel();
    _webSttTimeout = null;
    try { if (_webStt.isListening) _webStt.stop(); } catch (_) {}
    _webNextResult?.complete('');
    _webNextResult = null;
  }

  @override
  Future<String> listenOnce() async {
    if (!_webSttReady || !_webSttActive) return '';
    // Si hay resultados encolados, devolver el siguiente
    if (_webPendingResults.isNotEmpty) {
      return _webPendingResults.removeAt(0);
    }
    // Esperar el próximo resultado
    _state = VoiceState.listening;
    _webNextResult = Completer<String>();
    try {
      return await _webNextResult!.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => '',
      );
    } finally {
      _webNextResult = null;
      _state = VoiceState.idle;
    }
  }

  @override
  void stop() {
    stopContinuous();
    _synth?.cancel();
  }
}
