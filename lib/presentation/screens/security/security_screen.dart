import 'package:flutter/material.dart';
import '../../../domain/aetheris_engine.dart';
import '../../../services/aetheris_voice.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _voice = AetherisVoice.instance;

  @override
  void initState() {
    super.initState();
    _voice.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad y Monitoreo')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Aegis Firewall'),
            subtitle: const Text('Bloqueo de conexiones sospechosas'),
            value: AetherisEngine.isFirewallActive,
            onChanged: (val) {
              setState(() => AetherisEngine.isFirewallActive = val);
              _voice.speak(val
                  ? 'Cortafuegos Aegis activado.'
                  : 'Advertencia: cortafuegos desactivado.');
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield, color: Colors.greenAccent),
              title: const Text('Nivel de seguridad'),
              subtitle: Text(AetherisEngine.isFirewallActive
                  ? 'Protección activa'
                  : 'Sistema expuesto'),
            ),
          ),
        ],
      ),
    );
  }
}
