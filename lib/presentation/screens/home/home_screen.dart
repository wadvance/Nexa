import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/aetheris_voice.dart';
import '../../../domain/voice_commands.dart';
import '../../../services/conversation_memory_service.dart';
import '../../../services/location_service.dart';
import '../../../services/voice_auth_service.dart';
import '../../../utils/logger.dart';
import '../owner_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  final AetherisVoice _voice    = AetherisVoice.instance;
  final VoiceCommands _commands = VoiceCommands();

  bool   _busy       = false;
  bool   _started    = false;
  bool   _looping    = false;
  bool   _muted      = false;
  String _lastResponse = '';

  // Historial
  bool              _showHistory    = false;
  List<ChatMessage> _chatHistory    = [];
  bool              _historyLoading = false;

  final ValueNotifier<VoiceState> _voiceState =
      ValueNotifier(VoiceState.idle);

  final ValueNotifier<bool> _unauthorizedWarning = ValueNotifier(false);

  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _initVoice();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _voiceState.dispose();
    _unauthorizedWarning.dispose();
    _voice.stop();
    super.dispose();
  }

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> _initVoice() async {
    try {
      await _voice.init();
      AppLogger.info('Voice ready');
    } catch (e) {
      AppLogger.error('Voice init: $e');
    }
  }

  // ── Actualiza el notifier de estado de voz ───────────────────────────────

  void _syncVoiceState() {
    _voiceState.value = _voice.state;
  }

  // ── Loop principal ───────────────────────────────────────────────────────

  Future<void> _start() async {
    if (_started) return;
    setState(() { _started = true; });
    await Future.delayed(const Duration(milliseconds: 300));
    // Pido la ubicación AHORA (tras el primer gesto del usuario — evita
    // el Uncaught Error de Edge/Firefox con Tracking Prevention).
    // ignore: unawaited_futures
    LocationService.requestNow();
    final h = DateTime.now().hour;
    final saludo = h < 12 ? 'Buenos días' : h < 19 ? 'Buenas tardes' : 'Buenas noches';
    final mensaje = '$saludo. Soy AETHERIS. ¿En qué te puedo ayudar?';
    await _voice.speak(mensaje);
      _syncVoiceState();
    if (kIsWeb) {
      _voiceState.value = VoiceState.idle;
    } else if (mounted) {
      _loop();
    }
  }

  /// Web: inicia la sesión continua de voz tras el primer tap.
  /// Después de eso todo es manos libres (el STT queda escuchando).
  Future<void> _webStart() async {
    if (_busy || _voice.speaking || !_started) return;
    setState(() { _busy = true; });
    _syncVoiceState();
    try {
      await _voice.startContinuous();
      if (!mounted) return;
      if (!_voice.sttReady) {
        setState(() { _busy = false; });
        return;
      }
      // Obtener el primer resultado (el usuario ya está hablando)
      final texto = await _voice.listenOnce();
      if (!mounted) return;
      if (texto.isEmpty) {
        setState(() { _busy = false; });
        return;
      }
      await _processAndRespond(texto);
      // A partir de aquí, manos libres vía _loop()
      if (mounted) _loop();
    } catch (e, st) {
      AppLogger.error('_webStart: $e\n$st');
      if (mounted) setState(() { _busy = false; });
    }
  }

  /// Procesa un texto y responde por voz.
  Future<void> _processAndRespond(String texto) async {
    _syncVoiceState();
    try {
      AppLogger.info('Process: "$texto"');
      var respuesta = await _commands.execute(texto, context, _uid);
      _lastResponse = respuesta;
      AppLogger.info('Reply: "${respuesta.substring(0, respuesta.length.clamp(0, 120))}"');
      _chatHistory.add(ChatMessage(role: 'user', text: texto));
      _chatHistory.add(ChatMessage(role: 'bot', text: respuesta));
      // Garantizar que SIEMPRE hable algo — si la IA devuelve vacío,
      // dar una respuesta empática para que el usuario sepa que estoy aquí.
      if (respuesta.trim().isEmpty || respuesta.trim() == ' ') {
        respuesta = 'No pude procesar tu pregunta. Intenta de nuevo.';
      }
      await _voice.speak(respuesta);
      _syncVoiceState();
    } catch (e, st) {
      AppLogger.error('_processAndRespond: $e\n$st');
      try { await _voice.speak('Lo siento, tuve un problema. ¿Repites?'); } catch (_) {}
    }
    if (mounted) { setState(() => _busy = false); _syncVoiceState(); }
  }

  Future<void> _loop() async {
    if (!mounted || _looping) return;
    _looping = true;

    while (mounted && !_muted) {
      // Esperar a que el TTS termine
      while (_voice.speaking) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) break;
      }
      if (!mounted) break;
      // Pausa para evitar que el micrófono capte el eco de la propia voz
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) break;
      _syncVoiceState();

      if (!_voice.sttReady) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      final listenFuture = _voice.listenOnce();
      _syncVoiceState();

      final texto = await listenFuture;
      _syncVoiceState();
      if (!mounted) break;

      if (texto.isEmpty || texto.length < 3) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }
      // Ignorar palabras sueltas que son probablemente eco
      final trimmed = texto.trim().toLowerCase();
      if (texto.length < 10 && RegExp(r'^(s[íi]|si|no|ok|hey|ah|oh|eh|a|y|e|o|hola|bueno|bien|gracias|sabes|vale|listo|ya|dale|claro)$', caseSensitive: false).hasMatch(trimmed)) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }
      // Ignorar si el texto transcrito es un eco de la última respuesta
      if (_lastResponse.isNotEmpty) {
        final respLower = _lastResponse.toLowerCase();
        // Ignorar si contiene palabras clave de la respuesta anterior
        final respWords = respLower.split(RegExp(r'\s+')).where((w) => w.length > 4).toList();
        final matchCount = respWords.where((w) => trimmed.contains(w)).length;
        if (matchCount >= 2 || respLower.contains(trimmed) && trimmed.length > 3) {
          await Future.delayed(const Duration(milliseconds: 100));
          continue;
        }
      }

      // ── Verificación biométrica de voz ─────────────────────────────────
      final authResult = VoiceAuthService.evaluate(texto);
      if (authResult.status == VoiceAuthStatus.unauthorized) {
        // Voz no reconocida: mostrar warning, responder por voz y no procesar
        _unauthorizedWarning.value = true;
        AppLogger.warn('Voice auth: voz no reconocida — bloqueado');
        await _voice.speak(
          'Acceso denegado. No reconozco tu voz. '
          'Solo ${authResult.ownerName} puede usar AETHERIS.',
        );
        _syncVoiceState();
        // Ocultar warning después de 4 segundos
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) _unauthorizedWarning.value = false;
        });
        continue;
      }
      // Si llegó aquí, la voz está autorizada — ocultar warning si estaba visible
      if (_unauthorizedWarning.value) _unauthorizedWarning.value = false;

      // Palabras de parada
      if (_isStopWord(texto)) {
        await _voice.stopSpeaking();
        _syncVoiceState();
        continue;
      }

      await _processAndRespond(texto);
      if (_showHistory) _cargarHistorial();
    }

    _looping = false;
    _syncVoiceState();
  }

  // ── Historial ─────────────────────────────────────────────────────────────

  Future<void> _cargarHistorial() async {
    if (_historyLoading) return;
    if (mounted) setState(() => _historyLoading = true);
    final msgs = await ConversationMemoryService.recent(limit: 50);
    if (mounted) {
      setState(() {
        _chatHistory    = msgs.reversed.toList();
        _historyLoading = false;
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _uid => kIsWeb ? 'web_anon' : (FirebaseAuth.instance.currentUser?.uid ?? 'demo_user_001');

  bool _isStopWord(String t) {
    final q = t.toLowerCase().trim();
    const stops = ['para', 'parar', 'basta', 'silencio', 'cállate',
        'callate', 'detener', 'detén', 'alto', 'stop', 'frena', 'ya'];
    for (final w in stops) {
      if (q == w || q.startsWith('$w ')) return true;
    }
    return false;
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: Stack(
        children: [
          // Pantalla principal
          _started
              ? (_showHistory ? _buildHistory() : _buildMain())
              : _buildStart(),

          // ── Warning de voz no autorizada ──────────────────────────────
          ValueListenableBuilder<bool>(
            valueListenable: _unauthorizedWarning,
            builder: (_, show, __) {
              if (!show) return const SizedBox.shrink();
              return Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.redAccent, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.amber, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '⚠ VOZ NO AUTORIZADA',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 1),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'No reconozco tu voz. Acceso denegado.',
                                  style: TextStyle(
                                      color: Colors.white.withValues(
                                          alpha: 0.75),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white54, size: 20),
                            onPressed: () =>
                                _unauthorizedWarning.value = false,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Pantalla inicio ───────────────────────────────────────────────────────

  Widget _buildStart() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Orb de seguridad animada
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                        const Color(0xFF448AFF).withValues(alpha: 0.15),
                        const Color(0xFF00E5FF).withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C4DFF).withValues(
                            alpha: 0.3 + _pulse.value * 0.2),
                        blurRadius: 40 + _pulse.value * 20,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(
                            alpha: 0.15 + _pulse.value * 0.1),
                        blurRadius: 60 + _pulse.value * 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Anillo exterior
                      Transform.rotate(
                        angle: _pulse.value * 0.5,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Anillo medio
                      Transform.rotate(
                        angle: -_pulse.value * 0.3,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      // Núcleo central
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [
                              Color(0xFF7C4DFF),
                              Color(0xFF448AFF),
                              Color(0xFF3D5AFE),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C4DFF).withValues(alpha: 0.8),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Título
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF7C4DFF),
                    Color(0xFF00E5FF),
                    Color(0xFF7C4DFF),
                  ],
                ).createShader(bounds),
                child: const Text(
                  'AETHERIS',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 12,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'INTELLIGENT SECURITY SYSTEM',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 4,
                  color: Colors.white.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 60),

              // Botón de inicio
              SizedBox(
                width: 240,
                height: 68,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7C4DFF),
                          Color.lerp(
                            const Color(0xFF7C4DFF),
                            const Color(0xFF00E5FF),
                            _pulse.value,
                          )!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C4DFF).withValues(
                              alpha: 0.4 + _pulse.value * 0.2),
                          blurRadius: 20 + _pulse.value * 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _start,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(34),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'INICIAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pantalla principal ────────────────────────────────────────────────────

  Widget _buildMain() {
    return SafeArea(
      child: Column(children: [
        // ── Barra superior ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AETHERIS',
                  style: TextStyle(
                      color: Colors.deepPurpleAccent.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold, fontSize: 15,
                      letterSpacing: 2)),
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.manage_accounts,
                      color: Colors.white38, size: 22),
                  tooltip: 'Propietario',
                  onPressed: () {
                    if (!mounted) return;
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const OwnerSetupScreen()));
                  },
                ),
              ]),
            ],
          ),
        ),

        const Spacer(),

        // ── Orb central + estado ────────────────────────────────────────
        // ValueListenableBuilder reconstruye SOLO este subtree cuando
        // cambia el estado de voz — sin Timer, sin rebuilds globales.
        ValueListenableBuilder<VoiceState>(
          valueListenable: _voiceState,
          builder: (_, voiceState, __) {
            final speaking  = voiceState == VoiceState.speaking;
            final listening = voiceState == VoiceState.listening;
            final active    = speaking || listening || _busy;

            final orbColor = speaking
                ? const Color(0xFF2196F3)
                : listening
                    ? const Color(0xFFF44336)
                    : active
                        ? const Color(0xFF7C4DFF)
                        : const Color(0xFF3D5AFE);

            return Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(children: [
                // ORB
                GestureDetector(
                  onTap: () {
                    if (_voice.speaking) {
                      _voice.stopSpeaking();
                      _syncVoiceState();
                    } else if (kIsWeb && !_looping) {
                      _webStart();
                    } else if (!_looping) {
                      _loop();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Anillo exterior rotatorio
                          Transform.rotate(
                            angle: _pulse.value * 0.8,
                            child: Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: orbColor.withValues(
                                      alpha: 0.2 + _pulse.value * 0.15),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          // Anillo medio
                          Transform.rotate(
                            angle: -_pulse.value * 0.5,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: orbColor.withValues(
                                      alpha: 0.25 + _pulse.value * 0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          // Glow exterior
                          if (active)
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: orbColor.withValues(
                                        alpha: 0.3 + _pulse.value * 0.25),
                                    blurRadius: 30 + _pulse.value * 20,
                                    spreadRadius: 8 + _pulse.value * 4,
                                  ),
                                ],
                              ),
                            ),
                          // Núcleo principal
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  orbColor,
                                  Color.lerp(orbColor, Colors.black, 0.3)!,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: orbColor.withValues(alpha: 0.6),
                                  blurRadius: 25,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Icon(
                              speaking
                                  ? Icons.volume_up_rounded
                                  : listening
                                      ? Icons.mic_rounded
                                      : Icons.psychology_outlined,
                              size: 52,
                              color: Colors.white.withValues(
                                  alpha: active ? 1.0 : 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Estado
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    speaking
                        ? 'HABLANDO'
                        : listening
                            ? 'ESCUCHANDO'
                            : active
                                ? 'PROCESANDO'
                                : 'LISTO',
                    key: ValueKey(voiceState),
                    style: TextStyle(
                      color: orbColor.withValues(alpha: 0.7),
                      fontSize: 11,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── CONTROLES ──────────────────────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [

                  // STOP
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: speaking
                        ? GestureDetector(
                            key: const ValueKey('stop'),
                            onTap: () async {
                              await _voice.stopSpeaking();
                              _syncVoiceState();
                            },
                            child: Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.5),
                                  blurRadius: 20, spreadRadius: 2)],
                              ),
                              child: const Icon(Icons.stop_rounded,
                                  color: Colors.white, size: 34),
                            ),
                          )
                        : const SizedBox(key: ValueKey('no-stop'),
                            width: 64, height: 64),
                  ),

                  const SizedBox(width: 20),

                  // MUTE / UNMUTE
                  GestureDetector(
                    onTap: () {
                      setState(() => _muted = !_muted);
                      if (_muted) {
                        _voice.stop();
                        _syncVoiceState();
                      } else {
                        _loop();
                      }
                    },
                    child: Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        color: _muted
                            ? Colors.orange.shade800
                            : Colors.grey.shade800,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white70, size: 26,
                      ),
                    ),
                  ),
                ]),

              ]),
            );
          },
        ),

      ]),
    );
  }

  // ── Historial ─────────────────────────────────────────────────────────────

  Widget _buildHistory() {
    return SafeArea(
      child: Column(children: [
        Container(
          color: Colors.deepPurple.shade900.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _showHistory = false),
            ),
            const Expanded(
              child: Text('Conversaciones',
                  style: TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              tooltip: 'Borrar historial',
              onPressed: () async {
                await ConversationMemoryService.clearAll();
                if (mounted) setState(() => _chatHistory = []);
              },
            ),
          ]),
        ),
        Expanded(
          child: _historyLoading
              ? const Center(child: CircularProgressIndicator(
                  color: Colors.deepPurpleAccent))
              : _chatHistory.isEmpty
                  ? const Center(child: Text('Sin conversaciones.',
                      style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _chatHistory.length,
                      itemBuilder: (_, i) => _buildBubble(_chatHistory[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isUser
              ? Colors.deepPurple.shade700.withValues(alpha: 0.8)
              : Colors.blueGrey.shade900.withValues(alpha: 0.8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(msg.isUser ? 14 : 2),
            bottomRight: Radius.circular(msg.isUser ? 2 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: msg.isUser
              ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.text,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(msg.displayTime,
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(msg.topic,
                    style: const TextStyle(
                        color: Colors.deepPurpleAccent, fontSize: 9)),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Widgets auxiliares ────────────────────────────────────────────────────

  // (removed unused _bubble and _chip)
}
