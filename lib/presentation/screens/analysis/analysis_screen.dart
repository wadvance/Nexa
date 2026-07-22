import 'package:flutter/material.dart';
import '../../../domain/aetheris_engine.dart';
import '../../../services/aetheris_brain.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rendimiento General AETHERIS')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Uso de CPU', style: TextStyle(fontSize: 18)),
            LinearProgressIndicator(
              value: AetherisEngine.cpuUsage,
              minHeight: 10,
            ),
            const SizedBox(height: 20),
            const Text('Uso de RAM', style: TextStyle(fontSize: 18)),
            LinearProgressIndicator(
              value: AetherisEngine.ramUsage,
              minHeight: 10,
              color: Colors.amber,
            ),
            const SizedBox(height: 30),
            Card(
              color: Colors.deepPurple.shade50,
              child: ListTile(
                title: const Text('Estado del Motor'),
                trailing: Text(
                  AetherisEngine.engineStatus,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.psychology),
              label: const Text('Consultar a AETHERIS (Seguridad)'),
              onPressed: () async {
                final advice = await AetherisBrain.getExpertAdvice(
                  'Analiza el entorno de seguridad actual.',
                  'seguridad',
                );
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('AETHERIS'),
                      content: SingleChildScrollView(child: Text(advice)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
