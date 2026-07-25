import 'package:flutter/material.dart';
import '../../../services/security_log_service.dart';
import '../../../services/aetheris_voice.dart';
import '../../../models/security_log.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late final Stream<List<SecurityLog>> _stream;
  final AetherisVoice _voice = AetherisVoice.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _stream = SecurityLogService.watchLogs().timeout(
      const Duration(seconds: 10),
      onTimeout: (sink) => sink.close(),
    );
    _voice.init();
  }

  Future<void> _registerByVoice() async {
    if (!_voice.sttReady) await _voice.init();
    if (!_voice.sttReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Micrófono no disponible.')),
        );
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await _voice.speak('Di el tipo de evento de seguridad.');
      final type = await _voice.listenOnce();
      if (type.isEmpty) {
        await _voice.speak('No entendí el tipo de evento.');
        return;
      }
      await _voice.speak('Ahora describe los detalles del análisis.');
      final details = await _voice.listenOnce();
      await SecurityLogService.reportThreat(
        detectedThreat: type,
        iaAnalysis: details.isNotEmpty ? details : 'Sin detalles.',
      );
      await _voice.speak('Evento registrado correctamente en Aetheris.');
    } catch (e) {
      await _voice.speak('Ocurrió un error al registrar el evento.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Eventos Aetheris')),
      body: StreamBuilder<List<SecurityLog>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error al cargar eventos: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(
              child: Text('Sin eventos registrados.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final log = logs[i];
              return ListTile(
                leading: const Icon(Icons.warning_amber, color: Colors.redAccent),
                title: Text(log.detectedThreat),
                subtitle: Text(log.iaAnalysis),
                trailing: Text(
                  '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _registerByVoice,
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.mic),
        label: Text(_busy ? 'Escuchando...' : 'Registrar por voz'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
    );
  }
}
