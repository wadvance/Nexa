import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../services/user_service.dart';
import '../../../services/aetheris_voice.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Stream<UserProfile?> _stream;
  final AetherisVoice _voice = AetherisVoice.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _stream = UserService.watchProfile(widget.uid).timeout(
      const Duration(seconds: 10),
      onTimeout: (sink) => sink.add(null),
    );
    _voice.init();
  }

  Future<void> _setLevelByVoice() async {
    if (!_voice.sttReady) await _voice.init();
    if (!_voice.sttReady) return;
    setState(() => _busy = true);
    try {
      await _voice.speak(
        'Di un nivel de seguridad del uno al cinco. Uno básico, cinco máxima.',
      );
      final text = await _voice.listenOnce();
      final match = RegExp(r'[1-5]').firstMatch(text);
      if (match != null) {
        final level = int.parse(match.group(0)!);
        await UserService.setSecurityLevel(widget.uid, level);
        await _voice.speak('Nivel de seguridad actualizado a $level.');
      } else {
        await _voice.speak('No detecté un nivel válido entre uno y cinco.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addContactByVoice() async {
    if (!_voice.sttReady) await _voice.init();
    if (!_voice.sttReady) return;
    setState(() => _busy = true);
    try {
      await _voice.speak('Di el nombre del contacto de confianza.');
      final text = await _voice.listenOnce();
      if (text.isNotEmpty) {
        await UserService.addTrustedContact(widget.uid, text);
        await _voice.speak('Contacto $text añadido.');
      } else {
        await _voice.speak('No capturé ningún nombre.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil Aetheris')),
      body: StreamBuilder<UserProfile?>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error al cargar el perfil: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data;
          final level = profile?.securityLevel ?? 1;
          final contacts = profile?.trustedContacts ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.fingerprint, color: Colors.deepPurpleAccent),
                  title: const Text('ID de usuario'),
                  subtitle: Text(widget.uid),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nivel de seguridad',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Slider(
                        value: level.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: 'Nivel $level',
                        onChanged: (val) {
                          UserService.setSecurityLevel(widget.uid, val.toInt());
                        },
                      ),
                      Text('Vigilancia: ${_levelLabel(level)}'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.mic),
                        label: const Text('Cambiar nivel por voz'),
                        onPressed: _busy ? null : _setLevelByVoice,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Contactos de confianza',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...contacts.map((c) => ListTile(
                    leading: const Icon(Icons.contact_phone),
                    title: Text(c),
                  )),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.mic),
                label: const Text('Añadir contacto por voz'),
                onPressed: _busy ? null : _addContactByVoice,
              ),
            ],
          );
        },
      ),
    );
  }

  String _levelLabel(int level) {
    switch (level) {
      case 1:
        return 'Básica';
      case 2:
        return 'Elevada';
      case 3:
        return 'Alta';
      case 4:
        return 'Crítica';
      case 5:
        return 'Máxima (paranoia)';
      default:
        return 'Desconocida';
    }
  }
}
