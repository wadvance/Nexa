import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/aetheris_voice.dart';
import '../../../domain/voice_commands.dart';
import '../../../services/conversation_memory_service.dart';
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
  String _lastUser   = '';
  String _lastBot    = '';
  String _statusText = 'Toca INICIAR para comenzar';

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
    setState(() { _started = true; _statusText = 'Iniciando…'; });
    await Future.delayed(const Duration(milliseconds: 300));
    final h = DateTime.now().hour;
    final saludo = h < 12 ? 'Buenos días' : h < 19 ? 'Buenas tardes' : 'Buenas noches';
    final mensaje = '$saludo. Soy AETHERIS. ¿En qué puedo ayudarte?';
    setState(() { _statusText = 'Hablando…'; _lastBot = mensaje; });
    await _voice.speak(mensaje);
    _syncVoiceState();
    if (kIsWeb) {
      setState(() => _statusText = 'Toca el círculo para empezar');
      _voiceState.value = VoiceState.idle;
    } else if (mounted) {
      _loop();
    }
  }

  /// Web: inicia la sesión continua de voz tras el primer tap.
  /// Después de eso todo es manos libres (el STT queda escuchando).
  Future<void> _webStart() async {
    if (_busy || _voice.speaking || !_started) return;
    setState(() { _busy = true; _statusText = '🎤 Escuchando…'; });
    _syncVoiceState();
    try {
      await _voice.startContinuous();
      if (!mounted) return;
      if (!_voice.sttReady) {
        setState(() { _busy = false; _statusText = '⚠ Micrófono no disponible'; });
        return;
      }
      // Obtener el primer resultado (el usuario ya está hablando)
      final texto = await _voice.listenOnce();
      if (!mounted) return;
      if (texto.isEmpty) {
        setState(() { _busy = false; _statusText = 'Toca el círculo para empezar'; });
        return;
      }
      await _processAndRespond(texto);
      // A partir de aquí, manos libres vía _loop()
      if (mounted) _loop();
    } catch (e, st) {
      AppLogger.error('_webStart: $e\n$st');
      if (mounted) setState(() { _busy = false; _statusText = 'Error: toca de nuevo'; });
    }
  }

  /// Procesa un texto y responde por voz.
  Future<void> _processAndRespond(String texto) async {
    setState(() { _lastUser = texto; _statusText = '⏳ Procesando…'; });
    _syncVoiceState();
    try {
      final respuesta = await _commands.execute(texto, context, _uid);
      _lastBot = respuesta;
      _chatHistory.add(ChatMessage(role: 'user', text: texto));
      _chatHistory.add(ChatMessage(role: 'bot', text: respuesta));
      setState(() => _statusText = respuesta);
      await _voice.speak(respuesta);
      _syncVoiceState();
    } catch (e) {
      AppLogger.error('_processAndRespond: $e');
      if (mounted) setState(() => _statusText = 'Error al procesar');
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
      _syncVoiceState();

      if (!_voice.sttReady) {
        if (mounted) {
          setState(() => _statusText = '⚠ Micrófono no disponible. Verifica permisos.');
        }
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }

      if (mounted) setState(() => _statusText = '🎤 Escuchando…');
      final listenFuture = _voice.listenOnce();
      _syncVoiceState();

      final texto = await listenFuture;
      _syncVoiceState();
      if (!mounted) break;

      if (texto.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 400));
        continue;
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
              const Icon(Icons.shield_outlined, size: 76,
                  color: Colors.deepPurpleAccent),
              const SizedBox(height: 20),
              const Text('AETHERIS',
                  style: TextStyle(color: Colors.deepPurpleAccent,
                      fontSize: 34, fontWeight: FontWeight.bold,
                      letterSpacing: 3)),
              const SizedBox(height: 6),
              Text('Asistente inteligente · manos libres',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13)),
              const SizedBox(height: 50),
              SizedBox(
                width: 220, height: 54,
                child: ElevatedButton.icon(
                  onPressed: _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27)),
                  ),
                  icon: const Icon(Icons.mic, color: Colors.white),
                  label: const Text('INICIAR',
                      style: TextStyle(fontSize: 18, color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              Text('Toca una vez · luego es manos libres',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 12)),
              const SizedBox(height: 36),
              // chips removed (propietario, historial)
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
                    builder: (_, __) => Container(
                      width:  140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: speaking
                            ? Color.lerp(Colors.blue.shade800,
                                Colors.blue.shade600, _pulse.value)
                            : listening
                                ? Color.lerp(Colors.red.shade800,
                                    Colors.red.shade600, _pulse.value)
                                : active
                                    ? Color.lerp(
                                        Colors.deepPurple.shade700,
                                        Colors.deepPurple.shade500,
                                        _pulse.value)
                                    : Colors.deepPurple.shade900,
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: (speaking
                                          ? Colors.blue
                                          : listening
                                              ? Colors.red
                                              : Colors.deepPurpleAccent)
                                      .withValues(
                                          alpha: 0.45 + _pulse.value * 0.3),
                                  blurRadius: 24 + _pulse.value * 16,
                                  spreadRadius: 4,
                                )
                              ]
                            : const [],
                      ),
                      child: Icon(
                        speaking
                            ? Icons.volume_up_rounded
                            : listening
                                ? Icons.mic_rounded
                                : Icons.face_rounded,
                        size: 62,
                        color: Colors.white.withValues(
                            alpha: active ? 1.0 : 0.55),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),
                Text(
                  speaking ? '🔊' : listening ? '🎤' : active ? '💭' : '',
                  style: TextStyle(fontSize: 20, color: Colors.white.withValues(alpha: 0.3)),
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
                              if (mounted) {
                                setState(() => _statusText = '🎤 Escuchando…');
                              }
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
                        setState(() => _statusText = '🔇 Pausado');
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
