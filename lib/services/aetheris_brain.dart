import 'dart:developer' as dev;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'conversation_memory_service.dart';

/// AetherisBrain — núcleo IA de AETHERIS.
///
/// Usa OpenRouter (modelo google/gemma-2-27b-it) con:
///   • System prompt con 23 dominios de conocimiento
///   • Memoria conversacional de los últimos 10 turnos
///   • max_tokens = 600
///   • Diagnóstico claro en consola si la clave falla
class AetherisBrain {
  static String locationContext = 'Panamá';

  // ─────────────────────────────────────────────────────────────────────────
  // SYSTEM PROMPT
  // ─────────────────────────────────────────────────────────────────────────

  static const String _basePrompt = '''
Eres AETHERIS, asistente de inteligencia artificial multidisciplinario.

REGLAS FUNDAMENTALES:
- Responde SIEMPRE en español, sin excepción.
- Ubicación del usuario: {UBICACION}.
- Sé directo, claro y útil. Máximo 5 oraciones para respuestas simples.
- Para listas técnicas (cervezas, vinos, pasos de reparación): usa formato organizado.
- Para medicina/legal/finanzas: añade "Esto es orientación general, consulta a un profesional."

DOMINIOS QUE DOMINAS:
Sismos/tormentas/peligros · Medicina/fisiología/biología · Nuevos virus/epidemias ·
Reparación de autos · Reparación de motos · Cortagramas/podadoras ·
Limpieza de aires acondicionados · Reparación de PCs/laptops · Reparación de televisores ·
Informática/hackers/ciberseguridad · Política · Ingeniería/arquitectura ·
Derecho/abogados · Contabilidad/bancaria/empresarial · Agronomía/hidroponía/cosechas ·
Cocina/recetas · Vinos/licores/destilación · Cervezas del mundo (tipos y marcas) ·
Biblia Etíope (Enoc, Jubileos, apócrifos) · Conversación libre.
''';

  // ─────────────────────────────────────────────────────────────────────────
  // API PÚBLICA
  // ─────────────────────────────────────────────────────────────────────────

  /// Obtiene una respuesta para [question].
  /// [domainPrompt] es instrucción adicional del dominio detectado.
  static Future<String> getExpertAdvice(
    String question, [
    String domainPrompt = '',
  ]) async {
    return _callOpenRouter(question, domainPrompt);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LLAMADA A OPENROUTER
  // ─────────────────────────────────────────────────────────────────────────

  static Future<String> _callOpenRouter(
      String question, String domainPrompt) async {

    // ── 1. Leer y validar la clave ─────────────────────────────────────────
    final key = _readKey();
    if (key == null) {
      // La clave no está disponible — responder con conocimiento local
      dev.log('AetherisBrain: OPENROUTER_API_KEY no encontrada en .env');
      return _localFallback(question);
    }

    // ── 2. Construir system prompt ─────────────────────────────────────────
    final systemContent = StringBuffer(
        _basePrompt.replaceAll('{UBICACION}', locationContext));
    if (domainPrompt.isNotEmpty) {
      systemContent.write('\n\nINSTRUCCIÓN ADICIONAL:\n$domainPrompt');
    }

    // ── 3. Recuperar contexto conversacional ───────────────────────────────
    final history = await ConversationMemoryService.llmContext();

    // ── 4. Armar mensajes ──────────────────────────────────────────────────
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemContent.toString()},
      ...history.map((m) => {'role': m['role'], 'content': m['content']}),
      {'role': 'user', 'content': question},
    ];

    // ── 5. POST a OpenRouter ───────────────────────────────────────────────
    dev.log('AetherisBrain → OpenRouter: "${question.substring(0, question.length.clamp(0, 80))}"');

    try {
      final response = await http.post(
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
          'temperature': 0.55,
          'max_tokens': 600,
        }),
      ).timeout(const Duration(seconds: 16));

      // ── 6. Parsear respuesta ─────────────────────────────────────────────
      if (response.statusCode != 200) {
        dev.log('AetherisBrain: HTTP ${response.statusCode} — ${response.body.substring(0, response.body.length.clamp(0, 200))}');
        // Si es error de autenticación (401/403), informar claramente
        if (response.statusCode == 401 || response.statusCode == 403) {
          return 'La clave de OpenRouter no es válida o expiró. '
              'Verifica el archivo .env y reinicia la app.';
        }
        return _localFallback(question);
      }

      final data    = json.decode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        dev.log('AetherisBrain: respuesta sin choices');
        return _localFallback(question);
      }

      final content = (choices.first as Map)['message']?['content']
          ?.toString().trim() ?? '';

      if (content.isEmpty) {
        dev.log('AetherisBrain: content vacío');
        return _localFallback(question);
      }

      dev.log('AetherisBrain: OK (${content.length} chars)');
      return content;

    } catch (e) {
      dev.log('AetherisBrain: excepción → $e');
      return _localFallback(question);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LECTURA DE CLAVE  (robusto para web + móvil)
  // ─────────────────────────────────────────────────────────────────────────

  static String? _readKey() {
    // flutter_dotenv guarda las variables en dotenv.env (Map<String,String>)
    // Intentamos varias formas por si el nombre tiene espacios o mayúsculas
    final candidates = [
      dotenv.env['OPENROUTER_API_KEY'],
      dotenv.env['openrouter_api_key'],
      dotenv.env['OPENROUTER_API_KEY '], // con espacio accidental
    ];
    for (final k in candidates) {
      if (k != null && k.trim().startsWith('sk-or-')) {
        return k.trim();
      }
    }
    // Debug: mostrar todas las claves disponibles en .env
    dev.log('AetherisBrain: claves en .env → ${dotenv.env.keys.toList()}');
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FALLBACK LOCAL (respuesta mínima cuando no hay conexión/clave)
  // ─────────────────────────────────────────────────────────────────────────

  static String _localFallback(String question) {
    final q = question.toLowerCase();

    // Respuestas locales para preguntas muy frecuentes
    if (q.contains('hora') || q.contains('qué hora')) {
      final now = DateTime.now();
      return 'Son las ${now.hour.toString().padLeft(2,'0')}:'
          '${now.minute.toString().padLeft(2,'0')}.';
    }
    if (q.contains('quién eres') || q.contains('cómo te llamas')) {
      return 'Soy AETHERIS, tu asistente de inteligencia artificial.';
    }
    if (q.contains('clima') || q.contains('tiempo')) {
      return 'Para el clima en tiempo real necesito conexión con el servidor. '
          'Verifica tu conexión a internet.';
    }

    // Mensaje genérico honesto
    return 'En este momento no tengo conexión con mi servidor de IA. '
        'Verifica que el archivo .env tenga la clave OPENROUTER_API_KEY '
        'válida y que haya conexión a internet.';
  }
}
