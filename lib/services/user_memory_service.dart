import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// UserMemoryService — memoria a largo plazo del dueño de AETHERIS.
///
/// AETHERIS "aprende" almacenando localmente:
///   • Temas sobre los que más pregunta el dueño (contador).
///   • Temas que el dueño ha corregido o marcado como preferidos.
///   • Ejemplos del tipo "cuando preguntes X, responde Y" — autodidacta.
///   • Hechos sueltos que el dueño le enseña (ej. "mi auto es Toyota Yaris 2018").
///
/// Todo en SharedPreferences (sin coste, sin servidor). El AetherisBrain
/// inyecta este contexto en cada system prompt para que el modelo se
/// comporte de manera personalizada y creciente en el tiempo.
class UserMemoryService {
  static const _kTopicCounts       = 'aetheris_topic_counts_v1';
  static const _kCustomExamples    = 'aetheris_custom_examples_v1';
  static const _kOwnerFacts        = 'aetheris_owner_facts_v1';
  static const _kInteractionCount  = 'aetheris_interaction_count';
  static const _kLastTopics        = 'aetheris_recent_topics_v1';

  // ── Contadores y última actividad ──────────────────────────────────────────

  static Future<void> recordInteraction() async {
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getInt(_kInteractionCount) ?? 0;
    await prefs.setInt(_kInteractionCount, n + 1);
  }

  static Future<int> interactionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kInteractionCount) ?? 0;
  }

  // ── Temas frecuentes ──────────────────────────────────────────────────────

  static Future<void> bumpTopic(String topic) async {
    if (topic.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTopicCounts) ?? '{}';
    final map = jsonDecode(raw) as Map<String, dynamic>;
    map[topic] = ((map[topic] as num?)?.toInt() ?? 0) + 1;
    await prefs.setString(_kTopicCounts, jsonEncode(map));

    final recent = await recentTopics();
    recent.add(topic);
    if (recent.length > 20) recent.removeAt(0);
    await prefs.setStringList(_kLastTopics, recent);
  }

  static Future<List<String>> recentTopics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kLastTopics) ?? <String>[];
  }

  static Future<List<MapEntry<String, int>>> topTopics({int max = 5}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTopicCounts) ?? '{}';
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final entries = map.entries
        .map((e) => MapEntry(e.key, (e.value as num).toInt()))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(max).toList();
  }

  // ── Ejemplos del dueño (autodidacta) ─────────────────────────────────────

  /// Añade un ejemplo: cuando el dueño dice algo similar a [trigger],
  /// AETHERIS debería responder [response].
  static Future<void> addExample({
    required String trigger,
    required String response,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCustomExamples) ?? '[]';
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    list.add({'trigger': trigger.toLowerCase().trim(),
              'response': response.trim()});
    await prefs.setString(_kCustomExamples, jsonEncode(list));
  }

  static Future<List<Map<String, String>>> allExamples() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCustomExamples) ?? '[]';
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map((m) => {
      'trigger':  m['trigger']  as String? ?? '',
      'response': m['response'] as String? ?? '',
    }).toList();
  }

  /// Elimina un ejemplo guardado (por índice).
  static Future<bool> removeExampleAt(int index) async {
    final all = await allExamples();
    if (index < 0 || index >= all.length) return false;
    all.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCustomExamples, jsonEncode(all));
    return true;
  }

  /// Borra un hecho guardado por clave.
  static Future<bool> removeFact(String key) async {
    final facts = await allFacts();
    if (!facts.containsKey(key.toLowerCase())) return false;
    facts.remove(key.toLowerCase());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOwnerFacts, jsonEncode(facts));
    return true;
  }

  /// Busca ejemplos cuyo trigger coincida parcialmente con [query].
  static Future<List<Map<String, String>>> findMatches(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    final all = await allExamples();
    return all.where((e) {
      final t = e['trigger'] ?? '';
      if (t.isEmpty) return false;
      return q.contains(t) || t.contains(q);
    }).toList();
  }

  // ── Hechos del dueño ──────────────────────────────────────────────────────

  /// Guarda un hecho estable sobre el dueño (ej. "dueño: Juan", "auto: Yaris 2018").
  static Future<void> setFact(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kOwnerFacts) ?? '{}';
    final map = jsonDecode(raw) as Map<String, dynamic>;
    map[key.toLowerCase()] = value;
    await prefs.setString(_kOwnerFacts, jsonEncode(map));
  }

  static Future<Map<String, String>> allFacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kOwnerFacts) ?? '{}';
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v.toString()));
  }

  // ── Resumen para inyectar en el system prompt ─────────────────────────────

  static Future<String> systemPromptContext() async {
    final facts = await allFacts();
    final top   = await topTopics(max: 3);
    final recent = await recentTopics();
    final ex    = await allExamples();
    final n     = await interactionCount();

    final buf = StringBuffer();
    buf.writeln('— MEMORIA DEL DUEÑO (interacciones totales: $n) —');

    if (facts.isNotEmpty) {
      buf.writeln('Hechos del dueño:');
      for (final e in facts.entries) {
        buf.writeln('  • ${e.key}: ${e.value}');
      }
    }
    if (top.isNotEmpty) {
      buf.writeln('Temas más frecuentes del dueño: '
          '${top.map((e) => "${e.key} (${e.value})").join(", ")}.');
    }
    if (recent.isNotEmpty) {
      buf.writeln('Últimos temas: ${recent.take(5).join(", ")}.');
    }
    if (ex.isNotEmpty) {
      buf.writeln('Ejemplos enseñados por el dueño:');
      for (final e in ex.take(5)) {
        buf.writeln('  Cuando diga "${e['trigger']}", responde: '
            '"${e['response']}"');
      }
    }
    if (facts.isEmpty && top.isEmpty && ex.isEmpty) {
      buf.writeln('Sin datos aún. Sé proactivo: pregunta al dueño su nombre, '
          'sus intereses y anímalo a enseñarte con ejemplos.');
    }
    return buf.toString();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTopicCounts);
    await prefs.remove(_kCustomExamples);
    await prefs.remove(_kOwnerFacts);
    await prefs.remove(_kInteractionCount);
    await prefs.remove(_kLastTopics);
  }
}
