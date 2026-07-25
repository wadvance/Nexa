import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceTestScreen extends StatefulWidget {
  const VoiceTestScreen({super.key});
  @override
  State<VoiceTestScreen> createState() => _VoiceTestScreenState();
}

class _VoiceTestScreenState extends State<VoiceTestScreen> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _log = "Iniciando...\n";

  @override
  void initState() {
    super.initState();
    testBasicFunction();
  }

  Future<void> testBasicFunction() async {
    try {
      // Paso 2: Inicializar TTS
      _addLog("1. Inicializando TTS...");
      await _tts.setLanguage("es-ES");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);

      // Calentar TTS
      await _tts.speak("");
      await Future.delayed(const Duration(milliseconds: 500));

      // Paso 3: Hablar
      _addLog("2. Intentando hablar...");
      var result = await _tts.speak("Buenos días. Prueba de sonido.");
      _addLog("   Resultado TTS: $result");

      if (result == 1) {
        _addLog("ÉXITO: Deberías escuchar la voz");
      } else {
        _addLog("ERROR: TTS retornó $result");
      }

      // Paso 4: Inicializar STT
      _addLog("3. Inicializando STT...");
      final sttOk = await _speech.initialize(
        onError: (e) => _addLog("   STT error: $e"),
        onStatus: (s) => _addLog("   STT status: $s"),
        debugLogging: true,
      );
      _addLog("   STT disponible: $sttOk");

      if (sttOk) {
        final locales = await _speech.locales();
        _addLog("   Locales: ${locales.map((l) => l.localeId).join(', ')}");
      }

      _addLog("\n=== PRUEBA COMPLETADA ===");

    } catch (e) {
      _addLog("EXCEPCIÓN: $e");
    }
  }

  void _addLog(String msg) {
    setState(() => _log += "$msg\n");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba de Voz')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("LOG:", style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              color: Colors.grey[200],
              width: double.infinity,
              child: SingleChildScrollView(
                child: Text(_log, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _log = "Reiniciando...\n";
                testBasicFunction();
              },
              child: const Text("REINTENTAR"),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                _addLog("\n--- Test TTS manual ---");
                var r = await _tts.speak("Uno, dos, tres. Probando.");
                _addLog("Resultado: $r");
              },
              icon: const Icon(Icons.volume_up),
              label: const Text("HABLAR AHORA"),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                _addLog("\n--- Test listen 5s ---");
                if (!_speech.isAvailable) {
                  _addLog("STT no disponible");
                  return;
                }
                await _speech.listen(
                  onResult: (r) {
                    if (r.finalResult) {
                      _addLog("Reconocido: ${r.recognizedWords}");
                    }
                  },
                  listenOptions: stt.SpeechListenOptions(
                    listenFor: const Duration(seconds: 5),
                    localeId: 'es_ES',
                  ),
                );
                await Future.delayed(const Duration(seconds: 5));
                await _speech.stop();
                _addLog("Listen terminado");
              },
              icon: const Icon(Icons.mic),
              label: const Text("ESCUCHAR 5s"),
            ),
          ],
        ),
      ),
    );
  }
}
