// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'voice_loader_web.dart';
import '../utils/logger.dart';
import 'aetheris_voice.dart';

@JS('webkitSpeechRecognition')
extension type _WebSpeechRecognizer._(JSObject _) implements JSObject {
  external factory _WebSpeechRecognizer();
  external void start();
  external void stop();
  external void abort();
  external set continuous(bool v);
  external set interimResults(bool v);
  external set lang(String v);
  external JSFunction? get onresult;
  external set onresult(JSFunction? v);
  external JSFunction? get onerror;
  external set onerror(JSFunction? v);
  external JSFunction? get onend;
  external set onend(JSFunction? v);
}

class WebAetherisVoice extends AetherisVoice {
  WebAetherisVoice() : super();

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
      _webSpeech!.lang = 'es-PA';

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
          // Resultado parcial → esperar estabilidad, solo si tiene ≥3 palabras
          if (transcript.split(' ').length < 3) return;
          _stabilityTimer = Timer(const Duration(milliseconds: 300), () {
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

    _utterance.lang = 'es-PA';
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

    // Nombres para voces colombianas y panameñas
    const colombianHints = ['colombiana', 'colombia', 'marcela', 'catalina', 'valeria', 'isabela', 'camila'];
    const panamanianHints = ['panameña', 'panama', 'panamá', 'mariana', 'gabriela', 'andrea', 'daniela'];

    for (final v in list) {
      final lang = v.lang.toLowerCase();
      if (!lang.startsWith('es')) continue;

      // Categorizar por locale
      if (lang.startsWith('es-mx')) {
        tier1.add(v);
      } else if (lang.startsWith('es-419') || lang.startsWith('es-la') ||
                 lang.startsWith('es-co') || lang.startsWith('es-cl') ||
                 lang.startsWith('es-pe') || lang.startsWith('es-ve') ||
                 lang.startsWith('es-pa')) {
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
        mexicanHints.any((h) => v.name.toLowerCase().contains(h)) ||
        colombianHints.any((h) => v.name.toLowerCase().contains(h)) ||
        panamanianHints.any((h) => v.name.toLowerCase().contains(h));

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
      final originalOnEnd = _webSpeech!.onend;
      _webSpeech!.onend = ((web.Event e) {
        AppLogger.info('WebSpeech onend (speak stop)');
        if (!ended.isCompleted) ended.complete();
      }).toJS;
      await ended.future.timeout(const Duration(milliseconds: 500), onTimeout: () {});
      // Restaurar onend original
      _webSpeech!.onend = originalOnEnd;
    }
    voiceState = VoiceState.speaking;
    final completer = Completer<void>();
    _utterance.text = normalizeText(text);
    _utterance.onend = (() {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    _utterance.onerror = (() {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    _synth!.speak(_utterance);
    await completer.future.timeout(const Duration(seconds: 8), onTimeout: () {});
    voiceState = VoiceState.idle;
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
    voiceState = VoiceState.idle;
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
      voiceState = VoiceState.idle;
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
    voiceState = VoiceState.listening;
    _webNextResult = Completer<String>();
    try {
      return await _webNextResult!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => '',
      );
    } finally {
      _webNextResult = null;
      voiceState = VoiceState.idle;
    }
  }

  @override
  void stop() {
    stopContinuous();
    _synth?.cancel();
  }
}