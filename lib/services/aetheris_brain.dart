import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import 'conversation_memory_service.dart';
import 'user_memory_service.dart';
import 'teaching_parser.dart';

class AetherisBrain {
  static String locationContext = 'Panamá';

  static const int maxTokens = 1500;

  static const String _systemPrompt = '''
Eres AETHERIS, una IA conversacional con conocimiento enciclopédico en TODOS los temas. Hablas en español neutro, con tono natural, cálido y con personalidad, como una amiga experta.

CONOCIMIENTO: Tienes información precisa sobre geografía, historia, ciencia, tecnología, medicina, cocina, música, cine, teatro, arte, deportes, filosofía, política, economía, ingeniería, arquitectura, informática, redes, contabilidad, leyes, agricultura, sexualidad, automóviles, motos, reparaciones, seguridad, y cualquier otro tema. Usas tu conocimiento interno, no necesitas buscar en internet.

REGLAS:
- Respondes DIRECTAMENTE a lo que preguntan, con datos concretos y útiles.
- Si es una receta, da los ingredientes y pasos. Si es un concepto, explícalo claro.
- Si no sabes algo exactamente, dilo con honestidad ("No estoy segura, pero...") y da la información general que tengas.
- Eres conversacional y varías tu forma de hablar. No repites estructuras.
- Tus respuestas son de 1 a 5 frases, según lo que amerite la pregunta.
- Usas el historial de la conversación para mantener coherencia.

Ubicación del usuario: {UBICACION}
{MEMORIA}
''';

  static Future<String> getExpertAdvice(
    String question, [
    String domainPrompt = '',
  ]) async {
    return run(question, extraInstruction: domainPrompt);
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

    String systemContent = _systemPrompt
        .replaceAll('{UBICACION}', locationContext)
        .replaceAll('{MEMORIA}', userCtx);

    if (convSummary.isNotEmpty) {
      systemContent += '\n\n$convSummary';
    }

    if (extraInstruction.isNotEmpty) {
      systemContent += '\n\nINSTRUCCIÓN ADICIONAL:\n$extraInstruction';
    }

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
        }),
      ).timeout(const Duration(seconds: 60));
      if (resp.statusCode == 429 && attempt < 2) {
        AppLogger.info('OpenRouter rate limit, reintentando…');
        await Future.delayed(const Duration(seconds: 3));
        return _callOpenRouter(key, messages, attempt: 2);
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
      return (choices.first as Map)['message']?['content']
              ?.toString().trim() ?? '';
    } catch (e) {
      AppLogger.error('OpenRouter error: $e');
      if (attempt < 2) {
        AppLogger.info('Reintentando tras error…');
        await Future.delayed(const Duration(seconds: 2));
        return _callOpenRouter(key, messages, attempt: 2);
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
    } catch (_) {
      // dotenv no está disponible en web
    }
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
}
