import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> waitForVoices() async {
  final synth = web.window.speechSynthesis;
  if (synth.getVoices().length > 0) return;
  final completer = Completer<void>();
  synth.addEventListener(
    'voiceschanged',
    ((JSAny _) {
      if (!completer.isCompleted) completer.complete();
    }).toJS,
  );
  await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {});
}

/// Voz masculina en español (preferentemente masculina LATINA):
/// Prioriza voces llamadas Pablo, Jorge, David, Carlos, Juan, Diego,
/// Miguel, etc. en español (México, España, Latinoamérica).
String? findMaleSpanishVoice() {
  final synth = web.window.speechSynthesis;
  final voices = synth.getVoices();
  if (voices.length == 0) return null;

  // Nombres masculinos comunes para detección
  const maleNames = [
    'pablo', 'jorge', 'david', 'carlos', 'juan', 'diego', 'miguel',
    'alejandro', 'andres', 'andrés', 'manuel', 'jose', 'josé',
    'antonio', 'javier', 'rafael', 'sergio', 'paco', 'francisco',
    'pedro', 'tomas', 'tomás', 'mateo', 'luis', 'oscar', 'óscar',
    'ruben', 'rubén', 'sebastian', 'sebastián', 'martin', 'martín',
    'santiago', 'enrique', 'ricardo', 'alberto', 'roberto',
    'male', 'man', 'masculine', 'raul', 'raúl',
  ];

  String? matched;
  String? fallback;

  for (var i = 0; i < voices.length; i++) {
    final v = voices[i];
    final name = v.name.toLowerCase();
    final lang = v.lang.toLowerCase();

    if (!lang.startsWith('es')) continue;

    // Guardar primer fallback es-*
    fallback ??= v.name;

    // Buscar nombres masculinos
    if (maleNames.any(name.contains)) {
      return v.name;
    }

    // Detectar por nombre que NO tenga marcadores femeninos
    if (!name.contains('maria') &&
        !name.contains('maría') &&
        !name.contains('sofia') &&
        !name.contains('sofía') &&
        !name.contains('elena') &&
        !name.contains('paula') &&
        !name.contains('carmen') &&
        !name.contains('monica') &&
        !name.contains('mónica') &&
        !name.contains('female') &&
        !name.contains('woman') &&
        matched == null) {
      matched = v.name;
    }
  }

  return matched ?? fallback;
}

({String name, String locale})? findFemaleLatinVoice() => null;
({String name, String locale})? findNonSpanishFemaleVoice() => null;
