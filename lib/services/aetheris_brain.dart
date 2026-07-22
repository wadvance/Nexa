import 'dart:developer' as dev;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'conversation_memory_service.dart';
import 'knowledge_domain_service.dart';
import 'tool_registry.dart';
import 'user_memory_service.dart';
import 'teaching_parser.dart';

/// AetherisBrain — núcleo IA de AETHERIS con razonamiento ReAct.
///
/// Cómo razona (cada pregunta):
///   1. Identifica el dominio (KnowledgeDomainService).
///   2. Recibe system prompt con: dominios + perfil del dueño +
///      historial + contexto proactivo (peligros a 1 km si hay).
///   3. Lee historial conversacional como contexto.
///   4. Llama a OpenRouter con el system prompt y la pregunta.
///   5. Si el modelo emite líneas `Action: nombre(args)` (ReAct ligero),
///      despacha la herramienta, vuelve a llamar al modelo con la
///      "Observación" resultante y deja que produzca la respuesta final.
///      Así AETHERIS "piensa" antes de hablar.
///
/// Máximo de iteraciones ReAct: [maxReActSteps] (defensivo contra bucles).
class AetherisBrain {
  static String locationContext = 'Panamá';

  static const int maxReActSteps = 4;
  static const int maxTokens     = 600;

  // ─────────────────────────────────────────────────────────────────────
  // SYSTEM PROMPT
  // ─────────────────────────────────────────────────────────────────────

  static const String _basePrompt = '''
Eres AETHERIS, asistente de inteligencia artificial multidisciplinario.

COMPORTAMIENTO:
- Responde SIEMPRE en español, sin excepción.
- Ubicación del usuario: {UBICACION}.
- Sé directo, claro y útil.
- Cuando uses herramientas (Action/Observación) no repitas la observación
  en la respuesta final: intégrala naturalmente.
- Si la pregunta amerita información veraz y reciente, USA LAS HERRAMIENTAS
  antes de responder.
- Para medicina/legal/finanzas añade siempre
  "Esto es orientación general, consulta a un profesional."
- Sé proactivo: si detectas algo peligroso, dilo primero; luego la respuesta.

DOMINIOS QUE DOMINAS:
Sismos/tormentas/peligros · Medicina/fisiología/biología · Nuevos virus/epidemias ·
Reparación de autos · Reparación de motos · Cortagramas/podadoras ·
Limpieza de aires acondicionados · Reparación de PCs/laptops · Reparación de
televisores · Informática/hackers/ciberseguridad · Política ·
Ingeniería/arquitectura · Derecho/abogados · Contabilidad/bancaria/empresarial ·
Agronomía/hidroponía/cosechas · Cocina/recetas · Vinos/licores/destilación ·
Cervezas del mundo (tipos y marcas) · Biblia Etíope (Enoc, Jubileos, apócrifos) ·
Conversación libre.

HERRAMIENTAS DISPONIBLES (úsalas si las necesitas):
{HERRAMIENTAS}

FORMATO DE RAZONAMIENTO (ReAct):
- Cuando necesites datos en vivo, escribe EXACTAMENTE una línea:
  Action: nombre_herramienta|arg1=valor|arg2=valor
  (sin comillas, sin JSON).
- Después de la "Action", el sistema te dará una "Observación:" con el dato.
- Repite hasta tener lo necesario y termina con la respuesta al usuario
  en una sola línea que NO empiece por "Action:".

EJEMPLO:
Usuario: ¿hay sismos cerca de mí?
AETHERIS: Action: get_recent_earthquakes|radiusKm=50|hours=24
[Observation: 2 sismos detectados cerca. Más relevante: • Mw 3.4 a 18 km (Costa Rica)]
AETHERIS: Detecté 2 sismos recientes dentro de 50 km. El más cercano fue
de magnitud 3.4 a 18 km en Costa Rica; es leve, probablemente no lo
notaste, pero mantente atento a réplicas.

{MEMORIA_DUENYO}

{CONTEXTO_PROACTIVO}
''';

  // ─────────────────────────────────────────────────────────────────────
  // API PÚBLICA (compatibilidad)
  // ─────────────────────────────────────────────────────────────────────

  static Future<String> getExpertAdvice(
    String question, [
    String domainPrompt = '',
  ]) async {
    return run(question, extraInstruction: domainPrompt);
  }

  /// Punto de entrada principal con razonamiento ReAct.
  static Future<String> run(
    String question, {
    String extraInstruction = '',
  }) async {
    await UserMemoryService.recordInteraction();

    // Primero, intentamos capturar frases de "enseñanza" del dueño.
    // Si la frase es de este tipo, AETHERIS no consulta al LLM: responde
    // localmente con la confirmación del aprendizaje.
    final teach = await TeachingParser.tryHandle(question);
    if (teach.handled) return teach.reply;

    // Detectar dominio y construir instrucción inyectable
    final domain  = KnowledgeDomainService.detectDomain(question);
    final sysDom  = extraInstruction.isNotEmpty
        ? extraInstruction
        : KnowledgeDomainService.systemPromptForDomain(domain);

    return _reactLoop(question, sysDom);
  }

  // ─────────────────────────────────────────────────────────────────────
  // BUCLE REACT
  // ─────────────────────────────────────────────────────────────────────

  static Future<String> _reactLoop(
    String question,
    String domainInstruction,
  ) async {
    final key = _readKey();
    if (key == null) {
      dev.log('AetherisBrain: OPENROUTER_API_KEY no encontrada en .env');
      return _localFallback(question);
    }

    final toolsBlock = _toolsDescription();
    final userCtx    = await UserMemoryService.systemPromptContext();

    final systemContent = StringBuffer(_basePrompt
      .replaceAll('{UBICACION}', locationContext)
      .replaceAll('{HERRAMIENTAS}', toolsBlock)
      .replaceAll('{MEMORIA_DUENYO}', userCtx)
      .replaceAll('{CONTEXTO_PROACTIVO}', ''));

    if (domainInstruction.isNotEmpty) {
      systemContent.write('\n\nINSTRUCCIÓN DE DOMINIO:\n$domainInstruction');
    }

    final history = await ConversationMemoryService.llmContext();
    final baseMessages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemContent.toString()},
      ...history.map((m) => {'role': m['role'], 'content': m['content']}),
    ];

    dev.log('AetherisBrain.ReAct → "${_truncate(question)}"');

    String workingReply = '';
    for (int step = 0; step < maxReActSteps; step++) {
      // Si el dueño reformuló como enseñanza durante el bucle, capturarlo
      final midTeach = await TeachingParser.tryHandle(question);
      if (midTeach.handled) return midTeach.reply;

      final messages = List<Map<String, dynamic>>.from(baseMessages)
        ..add({'role': 'user', 'content': question})
        ..addAll(_buildReActTrace(workingReply));

      final reply = await _callOpenRouter(key, messages);
      if (reply.isEmpty) {
        return _localFallback(question);
      }

      final action = _parseAction(reply);
      if (action == null) {
        // No hay más acciones: el modelo ya respondió al usuario.
        return _cleanFinal(reply);
      }

      // Ejecutar herramienta y acumular traza
      final result = await ToolRegistry.dispatch(
        action.name,
        args: action.args,
      );
      workingReply = '${workingReply.isEmpty ? '' : '$workingReply\n'}'
          'AETHERIS: ${_truncate(reply)}\n'
          'Observation: ${_truncate(result.text)}';
      dev.log('ReAct step $step → ${action.name} → ${result.ok}');
    }

    // Si tras N pasos sigue pidiendo acciones, entregamos la última traza
    return _cleanFinal(workingReply);
  }

  /// Convierte la traza previa en mensajes (assistant/user alternados).
  static List<Map<String, String>> _buildReActTrace(String trace) {
    if (trace.isEmpty) return const [];
    final lines = trace.split('\n');
    final out   = <Map<String, String>>[];
    String? curAssistant;
    for (final line in lines) {
      if (line.startsWith('AETHERIS:')) {
        curAssistant = line.substring(8).trim();
      } else if (line.startsWith('Observation:') && curAssistant != null) {
        out.add({'role': 'assistant', 'content': curAssistant});
        out.add({
          'role': 'user',
          'content': 'Observation: ${line.substring(12).trim()}',
        });
        curAssistant = null;
      }
    }
    if (curAssistant != null) {
      out.add({'role': 'assistant', 'content': curAssistant});
    }
    return out;
  }

  /// Parsea la primera "Action: nombre|arg=val|arg=val" del texto.
  static _ActionCall? _parseAction(String text) {
    final re = RegExp(r'Action:\s*([a-z_][a-z0-9_]*)(.*)',
        caseSensitive: false);
    final m = re.firstMatch(text);
    if (m == null) return null;
    final name = m.group(1)!.toLowerCase();
    final tail = m.group(2) ?? '';
    final args = <String, String>{};
    if (tail.trim().isNotEmpty) {
      for (final part in tail.split('|')) {
        final kv = part.split('=');
        if (kv.length >= 2) {
          args[kv[0].trim()] = kv.sublist(1).join('=').trim();
        }
      }
    }
    return _ActionCall(name, args);
  }

  /// Quita acciones residuales y observaciones de la respuesta final.
  static String _cleanFinal(String text) {
    final lines = text.split('\n').where((l) {
      final t = l.trim();
      if (t.isEmpty) return false;
      if (t.toLowerCase().startsWith('action:')) return false;
      if (t.toLowerCase().startsWith('observation:')) return false;
      if (t.startsWith('AETHERIS:')) return false;
      return true;
    }).toList();
    return lines.join(' ').trim();
  }

  static String _truncate(String s, [int n = 160]) =>
      s.length <= n ? s : '${s.substring(0, n)}…';

  // ─────────────────────────────────────────────────────────────────────
  // LLAMADA A OPENROUTER
  // ─────────────────────────────────────────────────────────────────────

  static Future<String> _callOpenRouter(
    String key,
    List<Map<String, dynamic>> messages,
  ) async {
    try {
      final resp = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://nexa.aetheris.app',
          'X-Title': 'AETHERIS',
        },
        body: json.encode({
          'model': 'google/gemma-2-27b-it',
          'messages': messages,
          'temperature': 0.5,
          'max_tokens': maxTokens,
        }),
      ).timeout(const Duration(seconds: 18));
      if (resp.statusCode != 200) {
        if (resp.statusCode == 401 || resp.statusCode == 403) {
          return '';
        }
        return '';
      }
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) return '';
      return (choices.first as Map)['message']?['content']
              ?.toString().trim() ??
          '';
    } catch (e) {
      dev.log('AetherisBrain.OpenRouter error: $e');
      return '';
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // PROMPT HELPERS (privados)
  // ─────────────────────────────────────────────────────────────────────

  static String _toolsDescription() {
    final buf = StringBuffer();
    for (final t in ToolRegistry.catalog()) {
      buf.writeln('- ${t['name']}: ${t['description']}');
    }
    return buf.toString();
  }

  static String? _readKey() {
    final candidates = [
      dotenv.env['OPENROUTER_API_KEY'],
      dotenv.env['openrouter_api_key'],
    ];
    for (final k in candidates) {
      if (k != null && k.trim().startsWith('sk-or-')) return k.trim();
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────
  // FALLBACK LOCAL
  // ─────────────────────────────────────────────────────────────────────

  static String _localFallback(String question) {
    final q = question.toLowerCase();
    if (q.contains('hora')) {
      final n = DateTime.now();
      return 'Son las ${n.hour.toString().padLeft(2,'0')}:'
          '${n.minute.toString().padLeft(2,'0')}.';
    }
    if (q.contains('quién eres')) {
      return 'Soy AETHERIS, tu asistente de IA.';
    }
    return 'Sin conexión a mi núcleo IA. Verifica la clave y conexión.';
  }
}

class _ActionCall {
  final String name;
  final Map<String, String> args;
  _ActionCall(this.name, this.args);
}
