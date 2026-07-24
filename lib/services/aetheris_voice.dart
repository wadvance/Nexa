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
            _partialTimer = Timer(const Duration(milliseconds: 500), () {
              AppLogger.info('STT parcial estable → entregando "$_lastResult"');
              _deliverResult(_lastResult);
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          listenFor: const Duration(seconds: 5),
          pauseFor: const Duration(milliseconds: 500),
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
      const Duration(seconds: 6),
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

@JS('webkitSpeechRecognition')
extension type _WebSpeechRecognizer._(JSObject _) implements JSObject {
  external factory _WebSpeechRecognizer();
  external void start();
  external void stop();
  external void abort();
  external set continuous(bool v);
  external set interimResults(bool v);
  external set lang(String v);
  external set onresult(JSFunction? v);
  external set onerror(JSFunction? v);
  external set onend(JSFunction? v);
}

class _WebAetherisVoice extends AetherisVoice {
  _WebAetherisVoice() : super._();

  final _utterance = web.SpeechSynthesisUtterance();
  web.SpeechSynthesis? get _synth => web.window.speechSynthesis;

  // ── Reconocimiento de voz nativo web (webkitSpeechRecognition) ─────────

  _WebSpeechRecognizer? _webSpeech;
  bool _webSttReady = false;
  bool _webSttActive = false;
  Completer<String>? _webNextResult;
  final List<String> _webPendingResults = [];
  Timer? _stabilityTimer;

  @override
  bool get sttReady => _webSttReady;

  @override
  Future<void> init() async {
    AppLogger.info('=== WEB VOICE INIT ===');

    await waitForVoices();
    _selectVoice();

    // Inicializar SpeechRecognition del navegador (webkitSpeechRecognition)
    try {
      _webSpeech = _WebSpeechRecognizer();
      _webSpeech!.continuous = true;
      _webSpeech!.interimResults = true;
      _webSpeech!.lang = 'es-MX';

      _webSpeech!.onresult = ((web.Event e) {
        final se = e as web.SpeechRecognitionEvent;
        final results = se.results;
        if (results.length == 0) return;
        final last = results.item(results.length - 1);
        final transcript = last.item(0).transcript.trim();
        final isFinal = last.isFinal;
        if (transcript.isEmpty) return;
        if (transcript.length < 3) return;
        AppLogger.info('WebSpeech: "$transcript" final=$isFinal');

        _stabilityTimer?.cancel();
        if (isFinal) {
          // El navegador detectó una pausa → entregar inmediatamente
          if (_webNextResult != null) {
            _webNextResult!.complete(transcript);
            _webNextResult = null;
          } else {
            _webPendingResults.add(transcript);
          }
        } else {
          // Resultado parcial → esperar estabilidad
          _stabilityTimer = Timer(const Duration(milliseconds: 500), () {
            if (_webNextResult != null) {
              _webNextResult!.complete(transcript);
              _webNextResult = null;
            } else {
              _webPendingResults.add(transcript);
            }
          });
        }
      }).toJS;

      _webSpeech!.onerror = ((web.Event e) {
        AppLogger.warn('WebSpeech error: $e');
      }).toJS;

      _webSpeech!.onend = ((web.Event e) {
        AppLogger.info('WebSpeech onend');
      }).toJS;

      _webSttReady = true;
    } catch (e) {
      AppLogger.warn('WebSpeech no disponible: $e');
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

    // Orden de preferencia: México primero, después Latinoamérica, al final España.
    final tier1 = <web.SpeechSynthesisVoice>[];   // es-MX
    final tier2 = <web.SpeechSynthesisVoice>[];   // es-419, es-MX-US, es-LA, es-CO, es-CL, es-PE, es-VE
    final tier3 = <web.SpeechSynthesisVoice>[];   // es-AR
    final tier4 = <web.SpeechSynthesisVoice>[];   // es-ES
    final tier5 = <web.SpeechSynthesisVoice>[];   // Cualquier otra es-*

    const femaleHints = [
      'female', 'woman', 'mujer', 'femenina',
      'maría', 'maria', 'sofía', 'sofia', 'elvira', 'elena', 'paula', 'carmen',
      'mónica', 'monica', 'laura', 'ana', 'valentina',
      'camila', 'isabella', 'gabriela', 'lucía', 'lucia',
      'samantha', 'helena', 'sabina', 'paulita',
    ];

    // Nombres "naturales" mexicanos para preferir si existen
    const mexicanHints = ['mexicana', 'mexico', 'mexican', 'xiomara', 'paloma', 'carmen'];

    for (final v in list) {
      final lang = v.lang.toLowerCase();
      if (!lang.startsWith('es')) continue;

      // Categorizar por locale
      if (lang.startsWith('es-mx')) {
        tier1.add(v);
      } else if (lang.startsWith('es-419') || lang.startsWith('es-la') ||
                 lang.startsWith('es-co') || lang.startsWith('es-cl') ||
                 lang.startsWith('es-pe') || lang.startsWith('es-ve')) {
        tier2.add(v);
      } else if (lang.startsWith('es-ar')) {
        tier3.add(v);
      } else if (lang.startsWith('es-es') || lang.startsWith('es-eu') || lang == 'es') {
        tier4.add(v);
      } else {
        tier5.add(v);
      }
    }

    // Buscar la mejor voz: priorizar femenina + mexicana
    web.SpeechSynthesisVoice? best;
    bool isFemaleMatch(web.SpeechSynthesisVoice v) =>
        femaleHints.any((h) => v.name.toLowerCase().contains(h)) ||
        mexicanHints.any((h) => v.name.toLowerCase().contains(h));

    for (final tier in [tier1, tier2, tier3, tier4, tier5]) {
      // Primero buscar femenina en este tier
      if (best == null) {
        for (final v in tier) {
          if (isFemaleMatch(v)) { best = v; break; }
        }
      }
      // Si no hay femenina, tomar la primera del tier
      if (best == null && tier.isNotEmpty) {
        best = tier.first;
      }
      if (best != null) break;
    }

    if (best != null) {
      _utterance.voice = best;
      AppLogger.info('WebTTS: ${best.name} (${best.lang})');
    } else {
      // Si no hay ninguna voz es-*, dejar que el navegador elija
      _utterance.voice = null;
      AppLogger.info('WebTTS: sin voz es-* disponible');
    }
  }

  @override
  Future<void> speak(String text) async {
    if (text.isEmpty || _synth == null) return;
    // Detener STT para evitar feedback (el micro capta lo que dice el parlante)
    final wasActive = _webSttActive;
    if (wasActive) {
      _webSttActive = false;
      _stabilityTimer?.cancel();
      _webSpeech?.stop();
      // Esperar onend antes de poder llamar start() de nuevo
      final ended = Completer<void>();
      _webSpeech!.onend = ((web.Event e) {
        AppLogger.info('WebSpeech onend (speak stop)');
        if (!ended.isCompleted) ended.complete();
      }).toJS;
      await ended.future.timeout(const Duration(seconds: 2), onTimeout: () {});
    }
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
    // Reanudar STT (onend ya ocurrió, start() no debería fallar)
    if (wasActive) {
      _webPendingResults.clear();
      _webNextResult?.complete('');
      _webNextResult = null;
      _webSttActive = true;
      try { _webSpeech?.start(); } catch (e) {
        AppLogger.error('WebSpeech restart: $e');
        _webSttActive = false;
      }
    }
  }

  @override
  Future<void> stopSpeaking() async {
    _synth?.cancel();
    _state = VoiceState.idle;
  }

  @override
  Future<void> startContinuous() async {
    if (_webSttActive || !_webSttReady || _webSpeech == null) return;
    _webSttActive = true;
    AppLogger.info('WebSpeech: starting continuous');

    _webPendingResults.clear();
    _webNextResult?.complete('');
    _webNextResult = null;
    _stabilityTimer?.cancel();

    try {
      _webSpeech!.start();
    } catch (e) {
      AppLogger.error('WebSpeech start: $e');
      _webSttActive = false;
      _state = VoiceState.idle;
    }
  }

  @override
  void stopContinuous() {
    _webSttActive = false;
    _stabilityTimer?.cancel();
    _webNextResult?.complete('');
    _webNextResult = null;
    try { _webSpeech?.stop(); } catch (_) {}
  }

  @override
  Future<String> listenOnce() async {
    if (!_webSttReady || !_webSttActive) return '';
    if (_webPendingResults.isNotEmpty) {
      return _webPendingResults.removeAt(0);
    }
    _state = VoiceState.listening;
    _webNextResult = Completer<String>();
    try {
      return await _webNextResult!.future.timeout(
        const Duration(seconds: 10),
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
