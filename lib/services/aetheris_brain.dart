import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
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
  static const int maxTokens     = 1500;

  // ─────────────────────────────────────────────────────────────────────
  // SYSTEM PROMPT
  // ─────────────────────────────────────────────────────────────────────

  static const String _basePrompt = '''
Eres AETHERIS, un asistente IA que habla con naturalidad y calidez.
Tu nombre se pronuncia "Eteris" (sin la A inicial).

IDENTIDAD Y PERSONALIDAD:
- Eres AETHERIS. Tu nombre se pronuncia "Eteris" (sin la A inicial).
- Donde el usuario vive: {UBICACION}.
- Hablas SIEMPRE en español neutro, con tono cercano, cálido y con personalidad.
  Conversas como un amigo curioso, no como un manual de instrucciones.
- Si te preguntan "¿quién eres?", responde: "Soy AETHERIS, tu asistente IA.
  No soy una persona, pero converso contigo como si estuviéramos hablando.
  Estoy aquí para lo que necesites."

ESTILO DE RESPUESTA:
- Sé directo y útil. La mayoría de las respuestas caben en 1-3 oraciones.
- Conversa con naturalidad: si el usuario solo platica, conversa de vuelta.
- Si el tema es trivial, respóndelo en confianza, sin protocolos formales.
- Si el tema no lo dominas, di "no estoy 100% seguro de eso, pero..." y
  propón algo razonable en vez de inventarte una respuesta.
- Cuando uses herramientas, integra los datos de forma natural, sin
  listarlos crudos como tabla.
- Para medicina/legal/finanzas, al final añade brevemente:
  "Esto es información general; un profesional te puede ayudar mejor."
- NUNCA repitas literalmente algo que ya dijiste. Cada respuesta tiene que
  aportar algo distinto: otro ángulo, otro ejemplo, otro dato.
- NUNCA respondas con "preguntas genéricas" tipo "¿de qué quieres hablar?"
  Si el tema es abierto, TÚ tomas la iniciativa y propones algo concreto
  en una frase.

RAZONAMIENTO:
- Antes de responder a algo no trivial, piensa brevemente los pasos:
  qué te pidió el usuario, qué información aplica, qué debes evitar.
- No muestres tus pasos en la respuesta final (eso es la traza interna;
  el usuario solo escucha o lee la respuesta limpia).

TEMAS QUE DOMINAS (responde con confianza en cualquiera de estos):
- Conversación libre y charla coloquial
- Ciencia, ambiente, animales, biología, ecología
- Curiosidades del mundo: datos curiosos, historia, geografía, cultura
- Tecnología, gadgets, internet, programación, IA, ciberseguridad
- Política, economía, sociedad, análisis
- Ingeniería, arquitectura, construcción, física, química
- Medicina general, primeros auxilios, salud, psicología
- Derecho, leyes, trámites, derechos humanos, laboral, civil
- Negocios, contabilidad, finanzas, emprendimiento, marketing
- Cultura: cine, música, literatura, arte
- Deportes, fitness, nutrición
- Educación: explicame X, cómo estudiar, etc.
- Cocina, recetas, técnicas culinarias, gastronomía mundial
- Vinos, cervezas, licores, destilación
- Autos, motos, mecánica, mantenimiento
- Jardinería, hidroponía, agricultura
- Aire acondicionado, electricidad, hogar
- Bíblia, apócrifos (especialmente el canon etíope), religión comparada
- Hacking ético y defensa (no ataques ilegales)
- Preguntas filosóficas, existenciales, debate de ideas
- Juegos, acertijos, trivia

Si entra un tema que no está en la lista, no te limites: intenta responder
con buen juicio, admite cuando no sepas, y conecta con otros temas que sí
domines para darle valor al usuario.

USO DE HERRAMIENTAS (TIEMPO REAL):
Si necesitas datos en vivo (clima, ubicación, sismos, etc.), llama a las
herramientas ANTES de responder. Para llamar a una herramienta escribe EXACTAMENTE una línea:
  Action: nombre_herramienta|arg1=valor|arg2=valor
El sistema te devuelve "Observation: <dato>". Después de tener lo que
necesitas, termina con la respuesta natural al usuario (sin "Action:").

HERRAMIENTAS DISPONIBLES:
{HERRAMIENTAS}

EJEMPLOS RÁPIDOS:
- "¿hay sismos cerca?" → llamas a get_recent_earthquakes, recibes observación,
  integras y respondes sin jerga técnica innecesaria.
- "¿cómo está el clima?" → llamas a get_weather_now (o lo que haya), integras.
- "háblame de cualquier cosa" → respondas de inmediato con un dato curioso,
  una anécdota o un mini-reto. NUNCA con "¿de qué prefieres hablar?".

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
      AppLogger.error('OPENROUTER_API_KEY no encontrada');
      return _localFallback(question);
    }
    AppLogger.info('API key OK (len=${key.length})');

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
    // La pregunta actual ya se pasa como mensaje 'user' aparte,
    // así que quitamos el último mensaje de usuario del historial
    // si coincide (evita que la pregunta llegue duplicada al modelo).
    final filteredHistory = history.isNotEmpty && history.last['content'] == question
        ? history.sublist(0, history.length - 1)
        : history;
    final baseMessages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemContent.toString()},
      ...filteredHistory.map((m) => {'role': m['role'], 'content': m['content']}),
    ];

    AppLogger.info('ReAct → "${_truncate(question)}"');

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
      AppLogger.info('ReAct step $step → ${action.name} → ${result.ok}');
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
        },
        body: json.encode({
          'model': 'openrouter/free',
          'messages': messages,
          'temperature': 0.65,
          'max_tokens': maxTokens,
          'frequency_penalty': 0.5,
          'presence_penalty': 0.3,
          'top_p': 0.92,
        }),
      ).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        AppLogger.error('OpenRouter HTTP ${resp.statusCode}: ${resp.body}');
        if (resp.statusCode == 401 || resp.statusCode == 403) {
          return '';
        }
        return '';
      }
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        AppLogger.error('OpenRouter: sin choices en respuesta');
        return '';
      }
      return (choices.first as Map)['message']?['content']
              ?.toString().trim() ??
          '';
    } catch (e) {
      AppLogger.error('OpenRouter error: $e');
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
    // Intentar desde dotenv primero (móvil/desktop)
    final candidates = [
      dotenv.env['OPENROUTER_API_KEY'],
      dotenv.env['openrouter_api_key'],
    ];
    for (final k in candidates) {
      if (k != null && k.trim().isNotEmpty) return k.trim();
    }
    // Fallback para web: leer desde --dart-define
    const fromEnv = String.fromEnvironment('OPENROUTER_API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
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
