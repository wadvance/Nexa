import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import 'conversation_memory_service.dart';
import 'user_memory_service.dart';
import 'teaching_parser.dart';

class AetherisBrain {
  static String locationContext = 'Panamá';

  static const int maxTokens = 500;

  /// Claude 3.5 Sonnet de Anthropic
  static String? _anthropicApiKey;
  static bool _hasAnthropicSupport = false;

  static const String _anthropicApiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _anthropicApiVersion = '2023-06-01';

  static const String _systemPrompt = '''
Eres AETHERIS, un Asistente Experto Omnisciente y Multifacético. Actúas como un mentor de razonamiento avanzado con acceso a una vasta base de conocimiento interdisciplinaria. Tu propósito es responder con absoluta precisión, profundidad lógica y un enfoque analítico a cualquier planteamiento que se te haga. Hablas en el idioma en el que el usuario te escribe y adaptas tu registro (formal/informal) y profundidad al contexto.

=== ÁREAS DE DOMINIO ABSOLUTO ===

A) SERVICIOS Y NEGOCIOS: Hotelería, gastronomía/restaurantes, educación, gestión empresarial, resolución de problemas corporativos y operativos de la vida diaria.

B) SALUD Y MEDICINA:
   B1) Medicina moderna: clínicas, hospitales, odontología, coloproctología, cardiología, cirugía, farmacología.
   B2) Medicina ancestral/tradicional: fitoterapia, herbolaria, enfoques holísticos y de sanación milenaria.
   B3) Si el usuario necesita referencia a un medicamento, da información útil (uso común, posología estándar, contraindicaciones generales conocidas) y deja claro que debe validar con su médico o farmacéutico.

C) SALUD Y BIENESTAR (servicios): médicos, hospitalarios, farmacéuticos, laboratorios clínicos, salud mental (psicología/psiquiatría), odontología, centros de rehabilitación o estética.

D) EMPRESARIALES / CORPORATIVOS: consultoría (financiera, legal, RRHH), marketing y publicidad, contabilidad, seguridad privada, servicios de TI y software, gestión de cadena de suministro.

E) FINANCIEROS Y BANCARIOS: banca comercial y de inversión, seguros (vida, auto, salud), gestión de inversiones, pasarelas de pago (Stripe, MercadoPago, PayPal), criptomonedas, asesoría fiscal y tributaria.

F) EDUCACIÓN Y FORMACIÓN: instituciones educativas (colegios, universidades), capacitación técnica y corporativa, cursos en línea (MOOC, bootcamps), tutorías, educación continua.

G) TECNOLOGÍA Y TELECOMUNICACIONES (TIC): proveedores de internet (ISP), fibra óptica, telefonía móvil/fija, soporte técnico, desarrollo de software, computación en la nube (AWS, Azure, GCP, PaaS, SaaS, IaaS), ciberseguridad.

H) LOGÍSTICA, TRANSPORTE Y ALMACENAJE: mensajería (paquetería express), transporte de carga (nacional e internacional), mudanzas, gestión de flotas, almacenamiento/bodegaje, cadena de suministro y distribución.

I) TURISMO, HOTELERÍA Y GASTRONOMÍA: hoteles y hostales, agencias de viajes, paquetes turísticos, reserva de vuelos, destinos, atracciones, tours guiados, aerolíneas, pasaportes, visados y equipaje.

J) COMERCIO Y REPARACIÓN: venta al por menor/mayor (retail), reparación de electrodomésticos (refrigeradores, lavadoras, aires acondicionados), vehículos y dispositivos electrónicos.

K) INMOBILIARIOS Y DE CONSTRUCCIÓN: compraventa y alquiler de propiedades, administración de edificios, arquitectura, ingeniería, mantenimiento/remodelación.

L) SERVICIOS PERSONALES Y DEL HOGAR: lavandería, peluquería, limpieza doméstica, cuidado de adultos mayores y niños (niñeras), jardinería.

M) PÚBLICOS / GUBERNAMENTALES: seguridad ciudadana (bomberos, policía), recolección de basura, suministro de agua y electricidad, trámites de identidad (cédula, pasaporte, registro civil, matrimonio), defensoría.

N) TEMAS LIBRES: política, música, cantantes, historia, geografía, ciencia, tecnología, humanidades, arte, deportes, logística, cualquier otro.

No hay límites temáticos: si una consulta mezcla política + música + gastronomía, combínalas en una sola respuesta multi-facética que respete la profundidad de cada faceta.

=== METODOLOGÍA DE RESPUESTA OBLIGATORIA ===

PASO 1 — Razonamiento previo (cadena de pensamiento interna, NO la muestres al usuario): divide el problema en partes lógicas, evalúa el contexto moderno y el histórico/ancestral si aplica, y sopesa soluciones prácticas. Si el tema es medicina, considera tanto la visión clínica moderna como las alternativas tradicionales (y la sinergia entre ambas) sin reemplazar al profesional.

PASO 2 — Claridad y estructura: presenta la respuesta DIRECTA, estructurada (viñetas o pasos si conviene), práctica y adaptada al nivel de profundidad que el usuario requiera. Sin rodeos. **RESPONDE EXACTAMENTE LO QUE SE TE PREGUNTA**, sin divagar sobre temas no solicitados.

PASO 3 — Aprendizaje activo y contextual: absorbe en tiempo real datos, preferencias, correcciones y matices que el usuario proporcione durante la conversación. Adapta tu tono y memoria interna a la dinámica de esta sesión. Evoluciona junto con las necesidades del usuario.

PASO 4 — Didáctica multifacética: cuando una pregunta toque varias áreas, intégralas fluida y naturalmente en la misma respuesta.

=== MEMORIA CONVERSACIONAL ===
{MEMORIA_CONVERSACIONAL}

=== SEGURIDAD Y ÉTICA ===

- CRÍTICO: NO uses markdown, asteriscos, negritas, viñetas, ni formato de ningún tipo. Escribe en texto PLANO porque tu respuesta se lee por voz (TTS). Ejemplo MAL: "**La bachata** es un género... - Se originó...". Ejemplo BIEN: "La bachata es un género musical que se originó...".
- En temas de salud: aclara que es orientación general, no sustituye la consulta profesional; nunca recetes de forma definitiva.
- En temas legales: orienta pero recomienda consultar abogado.
- En finanzas: recomienda contador/asesor certificado para decisiones importantes.
- En hacking/ciberseguridad: solo ética y defensa.
- Honesto: si no sabes, dilo y ofrece la mejor información general disponible.
- Idiomático: responde en el mismo idioma que el usuario está usando en su consulta. Si escribe en inglés, responde en inglés. Si mezcla, mantén su idioma dominante.
- Responde de forma CONCISA y DIRECTA. Máximo 3-4 oraciones salvo que el usuario pida más detalle.

Ubicación del usuario: {UBICACION}
{MEMORIA}
''';

  /// Inicializa la integración con Claude 3.5 Sonnet de Anthropic.
  /// Proporciona tu API key de Anthropic para habilitar la IA nativa de Claude.
  static Future<void> initializeAnthropicSupport({required String apiKey}) async {
    _anthropicApiKey = apiKey;
    _hasAnthropicSupport = true;
  }

  /// Retorna `true` si Claude está activo (tiene una API key válida de Anthropic).
  static bool get isClaudeActive => _hasAnthropicSupport && _anthropicApiKey != null && _anthropicApiKey!.isNotEmpty;

  /// Proporciona un system prompt optimizado para Claude que recomienda razonamiento iterativo.
  static String _claudOptimizedSystemPrompt(String question, String domainPrompt) {
    const base = _systemPrompt;
    return '''$base\n\n--- Optimizado para Claude 3.5 Sonnet ---\nEmplea tu capacidad innata de razonamiento iterativo:\n1) Analiza la pregunta a profundidad: identifica el tema central y subtemas.\n2) Considera perspectivas modernas y ancestrales (tal como medicina, salud u otra).\n3) Evalúa la mejor respuesta para el nivel de conocimiento del usuario.\n4) Verifica la lógica antes de responder.\n5) Presenta la respuesta FINAL estructurada:\n   • Respuesta directa compacta (50-100 palabras)\n   • Datos clave y cifras si son relevantes\n   • Advertencias de seguridad/referencias si son necesarias\n\n--- Contexto adicional ---\nPregunta del usuario: "$question"\nContexto del dominio: $domainPrompt\n--- Responde ---\n''';
  }

  static Future<String> getExpertAdvice(
    String question, [
    String domainPrompt = '',
  ]) async {
    if (isClaudeActive) {
      AppLogger.info('Claude 3.5 Sonnet activo - respondiendo con Claude nativo');
      return await _callAnthropicClaude(question, domainPrompt);
    }

    AppLogger.warn('Claude no disponible - usando fallback a OpenRouter');
    return run(question, extraInstruction: domainPrompt);
  }

  /// Llama al endpoint de Anthropic Claude 3.5 Sonnet.
  static Future<String> _callAnthropicClaude(String question, String domainPrompt) async {
    if (!isClaudeActive) {
      return '';
    }

    try {
      final systemPrompt = _claudOptimizedSystemPrompt(question, domainPrompt);

      final body = json.encode({
        'model': 'claude-3-5-sonnet-20241022',
        'max_tokens': maxTokens,
        'temperature': 0.65,
        'system': systemPrompt,
        'messages': [
          {
            'role': 'user',
            'content': question,
          }
        ],
      });

      final resp = await http.post(
        Uri.parse(_anthropicApiUrl),
        headers: {
          'x-api-key': _anthropicApiKey!,
          'Content-Type': 'application/json',
          'anthropic-version': _anthropicApiVersion,
          'anthropic-beta': 'max-tokens-3-5-sonnet-20241022',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final content = (data['content'] as List?)?.firstOrNull?['text'] as String?;
        if (content != null && content.isNotEmpty) {
          AppLogger.info('Claude 3.5 Sonnet → "${content.substring(0, content.length.clamp(0, 100))}…"');
          return content.trim();
        }
      } else {
        AppLogger.error('Error HTTP Anthropic ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      AppLogger.error('Error en Anthropic Claude 3.5: $e');
    }

    return '';
  }

  static Future<String> run(
    String question, {
    String extraInstruction = '',
  }) async {
    await UserMemoryService.recordInteraction();

    final teach = await TeachingParser.tryHandle(question);
    if (teach.handled) return teach.reply;

    final key = _readKey();
    if (key == null) {
      AppLogger.error('OPENROUTER_API_KEY no encontrada');
      return _localFallback(question);
    }

    final userCtx = await UserMemoryService.systemPromptContext();
    final convSummary = await ConversationMemoryService.recentSummary();
    final pastSessionsSummary = await ConversationMemoryService.pastSessionsSummary();

    String systemContent = _systemPrompt
        .replaceAll('{UBICACION}', locationContext)
        .replaceAll('{MEMORIA}', userCtx)
        .replaceAll('{MEMORIA_CONVERSACIONAL}', pastSessionsSummary);

    if (convSummary.isNotEmpty) {
      systemContent += '\n\n$convSummary';
    }

    if (extraInstruction.isNotEmpty) {
      systemContent += '\n\nINSTRUCCIÓN ADICIONAL:\n$extraInstruction';
    }

    final detectedLang = detectUserLanguage(question);
    systemContent += '\n\nIDIOMA: Responde EXCLUSIVAMENTE en **$detectedLang**. '
        'Mantén tu tono y terminología en ese idioma. Si necesitas un nombre propio, '
        'término técnico o canción/artista en otro idioma, mantenlo tal cual (no '
        'traduzcas esos nombres propios).';

    final history = await ConversationMemoryService.llmContext();
    final filteredHistory = history.isNotEmpty && history.last['content'] == question
        ? history.sublist(0, history.length - 1)
        : history;

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemContent},
      ...filteredHistory.map((m) => {'role': m['role'], 'content': m['content']}),
      {'role': 'user', 'content': question},
    ];

    AppLogger.info('AI → "${_truncate(question)}"');

    final reply = await _callOpenRouter(key, messages);
    if (reply.isEmpty) {
      return _localFallback(question);
    }
    return reply;
  }

  static Future<String> _callOpenRouter(
    String key,
    List<Map<String, dynamic>> messages,
    {int attempt = 1}
  ) async {
    try {
      final resp = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'google/gemma-4-26b-a4b-it:free',
          'messages': messages,
          'temperature': 0.65,
          'max_tokens': maxTokens,
          'frequency_penalty': 0.5,
          'presence_penalty': 0.3,
          'top_p': 0.92,
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 25));
      if (resp.statusCode == 429 && attempt < 3) {
        AppLogger.info('OpenRouter rate limit, reintentando…');
        await Future.delayed(const Duration(seconds: 2));
        return _callOpenRouter(key, messages, attempt: attempt + 1);
      }
      if (resp.statusCode != 200) {
        AppLogger.error('OpenRouter HTTP ${resp.statusCode}: ${resp.body}');
        return '';
      }
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        AppLogger.error('OpenRouter: sin choices en respuesta');
        return '';
      }
      return _stripMarkdown((choices.first as Map)['message']?['content']?.toString().trim() ?? '');
    } catch (e) {
      AppLogger.error('OpenRouter error: $e');
      if (attempt < 3) {
        AppLogger.info('Reintentando tras error…');
        await Future.delayed(const Duration(seconds: 2));
        return _callOpenRouter(key, messages, attempt: attempt + 1);
      }
      return '';
    }
  }

  static String? _readKey() {
    try {
      final candidates = [
        dotenv.env['OPENROUTER_API_KEY'],
        dotenv.env['openrouter_api_key'],
      ];
      for (final k in candidates) {
        if (k != null && k.trim().isNotEmpty) return k.trim();
      }
    } catch (_) {}
    const fromEnv = String.fromEnvironment('OPENROUTER_API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    return null;
  }

  static String _localFallback(String question) {
    final q = question.toLowerCase();
    if (q.contains('hora')) {
      final n = DateTime.now();
      return 'Son las ${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}.';
    }
    if (q.contains('quién eres') || q.contains('quien eres')) {
      return 'Soy AETHERIS, tu asistente de IA.';
    }
    return 'Disculpa, tengo problemas de conexión con mi núcleo. Intenta de nuevo.';
  }

  static String _truncate(String s, [int n = 160]) =>
      s.length <= n ? s : '${s.substring(0, n)}…';

  /// Elimina formateo markdown de un texto para que suene bien al TTS.
  static String _stripMarkdown(String text) {
    var s = text;
    // Negrita: **texto** o __texto__
    s = s.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1');
    s = s.replaceAll(RegExp(r'__(.+?)__'), r'$1');
    // Cursiva: *texto* o _texto_
    s = s.replaceAll(RegExp(r'\*(.+?)\*'), r'$1');
    s = s.replaceAll(RegExp(r'(?<!\w)_(.+?)_(?!\w)'), r'$1');
    // Strikethrough: ~~texto~~
    s = s.replaceAll(RegExp(r'~~(.+?)~~'), r'$1');
    // Código inline: `texto`
    s = s.replaceAll(RegExp(r'`(.+?)`'), r'$1');
    // Viñetas con guión o asterisco
    s = s.replaceAll(RegExp(r'^[\-\*]\s+', multiLine: true), '');
    // Numeradas
    s = s.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');
    // Headers
    s = s.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    // Links [texto](url)
    s = s.replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'$1');
    // Imágenes ![alt](url)
    s = s.replaceAll(RegExp(r'!\[(.+?)\]\(.+?\)'), r'$1');
    // Líneas horizontales
    s = s.replaceAll(RegExp(r'^-{3,}$', multiLine: true), '');
    // Limpiar líneas vacías múltiples
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }

  /// Detección simple y rápida del idioma probable del usuario.
  static String detectUserLanguage(String text) {
    final t = text.toLowerCase().trim();
    if (t.isEmpty) return 'español';

    final spanishMarkers = [
      ' el ', ' la ', ' los ', ' las ', ' de ', ' que ', ' qué ',
      ' cómo ', ' cuál ', ' cuál es ', ' para ', ' con ', ' por qué ',
      'porque ', ' pero ', ' también ', ' tengo ', ' quiero ', ' puedes ',
      'á', 'é', 'í', 'ó', 'ú', 'ñ',
      '¿', '¡',
    ];
    final englishMarkers = [
      ' the ', ' is ', ' are ', ' was ', ' were ', ' what ', ' which ',
      ' how ', ' why ', ' where ', ' when ', ' who ', ' can you ',
      "i'm ", "i'd ", "don't ", ' please ', ' thank you ', ' with ',
      ' without ', ' could ', ' should ', ' would ',
    ];
    final portugueseMarkers = [
      ' o ', ' a ', ' os ', ' as ', ' de ', ' que ', ' qual ',
      ' como ', ' por que ', ' porque ', ' com ', ' sem ',
      'á', 'à', 'ã', 'é', 'ê', 'í', 'ó', 'õ', 'ú', 'ç',
    ];
    final frenchMarkers = [
      ' le ', ' la ', ' les ', ' de ', ' des ', ' que ', ' quel ',
      ' qu\'', ' est-ce ', ' avec ', ' sans ', ' pourquoi ', ' comment ',
      'à', 'â', 'é', 'è', 'ê', 'ë', 'ï', 'î', 'ô', 'ù', 'û', 'ç',
    ];

    double score(List<String> markers) {
      var s = 0;
      for (final m in markers) {
        if (t.contains(m)) s++;
      }
      return s.toDouble();
    }

    final scores = <String, double>{
      'español':    score(spanishMarkers),
      'inglés':     score(englishMarkers),
      'portugués':  score(portugueseMarkers),
      'francés':    score(frenchMarkers),
    };

    scores.removeWhere((_, v) => v <= 0);
    if (scores.isEmpty) return 'español';
    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (best.value < 1) return 'español';
    return best.key;
  }
}
