import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/aetheris_voice.dart';
import '../../services/owner_guard_service.dart';

/// OwnerSetupScreen — pantalla de configuración del propietario.
///
/// Flujo:
///   1. El dueño ingresa su nombre
///   2. Graba su frase de voz (leída en voz alta para el STT)
///   3. Ingresa una frase secreta de texto (pin de respaldo)
///   4. Se guarda el perfil en OwnerGuardService
///
/// Después del registro, solo esa combinación voz+frase desbloquea acceso
/// a comandos sensibles desde ese dispositivo.
class OwnerSetupScreen extends StatefulWidget {
  const OwnerSetupScreen({super.key});

  @override
  State<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends State<OwnerSetupScreen> {
  final _nameCtrl   = TextEditingController();
  final _phraseCtrl = TextEditingController();
  final _voice      = AetherisVoice.instance;

  String _voiceSample   = '';
  String _statusMessage = '';
  bool   _recording     = false;
  bool   _saving        = false;
  bool   _done          = false;

  // Step: 0=nombre, 1=voz, 2=frase secreta, 3=confirmar
  int _step = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phraseCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GRABACIÓN DE VOZ
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _recordVoice() async {
    if (_recording) return;
    setState(() {
      _recording     = true;
      _statusMessage = 'Escuchando… lee la frase en voz alta.';
    });

    await _voice.speak(
        'Di en voz alta tu frase de voz. Por ejemplo: AETHERIS soy el propietario.');
    final result = await _voice.listenOnce();

    setState(() {
      _recording = false;
      if (result.isEmpty) {
        _statusMessage = 'No capturé tu voz. Inténtalo de nuevo.';
      } else {
        _voiceSample   = result;
        _statusMessage = 'Frase capturada: "$result"';
        _step          = 2; // avanzar al paso de frase secreta
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GUARDAR PERFIL
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    final name   = _nameCtrl.text.trim();
    final phrase = _phraseCtrl.text.trim();

    if (name.isEmpty) {
      _setStatus('Ingresa tu nombre primero.');
      return;
    }
    if (_voiceSample.isEmpty) {
      _setStatus('Primero graba tu frase de voz.');
      return;
    }
    if (phrase.length < 6) {
      _setStatus('La frase secreta debe tener al menos 6 caracteres.');
      return;
    }

    setState(() => _saving = true);

    final ok = await OwnerGuardService.registerOwner(
      ownerName:    name,
      voiceSample:  _voiceSample,
      secretPhrase: phrase,
    );

    if (ok) {
      await _voice.speak(
          'Perfil de propietario registrado. Bienvenido, $name.');
      setState(() {
        _saving        = false;
        _done          = true;
        _statusMessage = '✓ Perfil registrado correctamente.';
      });
    } else {
      setState(() {
        _saving        = false;
        _statusMessage = 'Error al guardar el perfil. Verifica los datos.';
      });
    }
  }

  void _setStatus(String msg) => setState(() => _statusMessage = msg);

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Configurar Propietario',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _done ? _buildDoneView() : _buildSetupView(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VISTA DE CONFIGURACIÓN
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            const Icon(Icons.shield_outlined, color: Colors.deepPurpleAccent, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Registro de propietario',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            'Solo el propietario registrado podrá usar comandos sensibles '
            'desde este dispositivo.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
          const SizedBox(height: 32),

          // PASO 1 — Nombre
          _sectionLabel('1. Tu nombre'),
          const SizedBox(height: 8),
          _inputField(
            controller: _nameCtrl,
            hint: 'Ej: Carlos Rodríguez',
            icon: Icons.person_outline,
            onChanged: (_) {
              if (_nameCtrl.text.trim().isNotEmpty && _step == 0) {
                setState(() => _step = 1);
              }
            },
          ),
          const SizedBox(height: 28),

          // PASO 2 — Frase de voz
          _sectionLabel('2. Frase de voz (biometría)'),
          const SizedBox(height: 6),
          Text(
            'Toca el botón y lee en voz alta una frase única. '
            'AETHERIS reconocerá tu voz con ella.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: (_step >= 1 && !_recording) ? _recordVoice : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _recording
                    ? Colors.red.shade700
                    : Colors.deepPurple.shade700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(_recording ? Icons.mic : Icons.mic_none,
                  color: Colors.white),
              label: Text(
                _recording
                    ? 'Grabando…'
                    : _voiceSample.isEmpty
                        ? 'Grabar frase de voz'
                        : '✓ Voz registrada — volver a grabar',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          if (_voiceSample.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade900.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade700, width: 1),
              ),
              child: Text(
                '"$_voiceSample"',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 28),

          // PASO 3 — Frase secreta
          _sectionLabel('3. Frase secreta (respaldo)'),
          const SizedBox(height: 6),
          Text(
            'Contraseña de texto de al menos 6 caracteres como segundo factor.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
          ),
          const SizedBox(height: 10),
          _inputField(
            controller: _phraseCtrl,
            hint: 'Frase o contraseña secreta',
            icon: Icons.lock_outline,
            obscure: true,
            enabled: _step >= 2,
          ),
          const SizedBox(height: 32),

          // Mensaje de estado
          if (_statusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusMessage.startsWith('✓')
                    ? Colors.green.shade900.withValues(alpha: 0.3)
                    : Colors.deepPurple.shade900.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                    color: _statusMessage.startsWith('✓')
                        ? Colors.greenAccent
                        : Colors.white70,
                    fontSize: 13),
              ),
            ),
          const SizedBox(height: 20),

          // Botón guardar
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text('Registrar propietario',
                      style: TextStyle(fontSize: 17, color: Colors.white)),
            ),
          ),

          // Borrar perfil existente
          if (OwnerGuardService.isRegistered) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E2E),
                      title: const Text('Borrar perfil',
                          style: TextStyle(color: Colors.white)),
                      content: const Text(
                          '¿Seguro que quieres borrar el perfil de propietario?',
                          style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar',
                                style: TextStyle(color: Colors.grey))),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Borrar',
                                style: TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await OwnerGuardService.clearOwnerProfile();
                    if (mounted) setState(() => _statusMessage = 'Perfil borrado.');
                  }
                },
                child: const Text('Borrar perfil existente',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VISTA COMPLETADO
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDoneView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, color: Colors.greenAccent, size: 80),
            const SizedBox(height: 24),
            Text(
              '¡Propietario registrado!',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Bienvenido, ${OwnerGuardService.ownerName}.\n'
              'AETHERIS solo reconocerá tu voz y frase secreta\n'
              'para comandos protegidos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Listo',
                    style: TextStyle(fontSize: 17, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WIDGETS AUXILIARES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: Colors.deepPurpleAccent,
            fontSize: 14,
            fontWeight: FontWeight.w600),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: Icon(icon, color: Colors.deepPurpleAccent),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple.shade800),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple.shade800),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
      );
}
