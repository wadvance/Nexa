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
    _utterance.rate = 0.92;
    _utterance.pitch = 0.78;
    AppLogger.info('=== WEB VOICE sttReady=$_webSttReady ===');
  }

  void _selectVoice() {
    final synth = _synth;
    if (synth == null) return;
    final voices = synth.getVoices();
    final list = voices.toDart;

    final maleName = findMaleSpanishVoice();
    if (maleName != null) {
      for (final v in list) {
        if (v.name == maleName) {
          _utterance.voice = v;
          AppLogger.info('WebTTS voice: ${v.name}');
          return;
        }
      }
    }

    for (final v in list) {
      if (v.lang.toLowerCase().startsWith('es')) {
        _utterance.voice = v;
        AppLogger.info('WebTTS fallback: ${v.name}');
        return;
      }
    }
  }

  @override
  Future<void> speak(String text) async {
    if (text.isEmpty || _synth == null) return;
    _state = VoiceState.speaking;
    final completer = Completer<void>();
    _utterance.text = text;
    _utterance.onend = (() => completer.complete()).toJS;
    _synth!.speak(_utterance);
    await completer.future;
    _state = VoiceState.idle;
  }

  @override
  Future<void> stopSpeaking() async {
    _synth?.cancel();
    _state = VoiceState.idle;
  }

  @override
  Future<String> listenOnce() async {
    if (!_webSttReady) return '';
    try {
      return await _webStt.listen(
        onResult: (r) => _lastResult = r.recognizedWords,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(milliseconds: 800),
          partialResults: true,
        ),
      );
    } catch (e) {
      AppLogger.error('WebSTT listen: $e');
      return '';
    }
  }

  @override
  void stop() {
    _synth?.cancel();
    try { _webStt.stop(); } catch (_) {}
  }
}
