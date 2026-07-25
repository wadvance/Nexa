import 'user_memory_service.dart';

/// TeachingParser — interpreta frases de "enseñanza" del dueño.
///
/// Patrones reconocidos (frase natural en una sola línea):
///   • "cuando (te diga / me preguntes / …) X, (respóndeme / responde / contesta) Y"
///   • "cuando (escuches / oigas) X, Y"
///   • "si (te digo / me dices) X, Y"
///   • "de aquí en adelante cuando X, Y"
///   • "mi nombre es X", "me llamo X", "yo soy X"
///   • "recuerda que X", "no olvides que X"
///
/// Devuelve {handled: bool, reply: String}. Si handled=true, AETHERIS no
/// consulta al LLM: responde localmente con la confirmación del aprendizaje.
class TeachingParser {
  static Future<({bool handled, String reply})> tryHandle(String raw) async {
    final t = raw.trim();
    if (t.isEmpty) return (handled: false, reply: '');

    final lower = t.toLowerCase();

    // ── 1) Ejemplos "cuando X, Y" ─────────────────────────────────────────
    final ex = _matchExample(t, lower);
    if (ex != null) {
      await UserMemoryService.addExample(
        trigger: ex.trigger,
        response: ex.response,
      );
      return (
        handled: true,
        reply: 'Aprendido. Cuando digas "${ex.trigger}" '
            'te responderé "${ex.response}".'
      );
    }

    // ── 2) Nombre del dueño ──────────────────────────────────────────────
    final nameRe = RegExp(
      r'^(?:me llamo|mi nombre es|yo soy|ll[aá]mame|me dicen)\s+([A-Za-zÁÉÍÓÚáéíóúñÑ ]{2,40})$',
      caseSensitive: false,
    );
    final nameMatch = nameRe.firstMatch(t);
    if (nameMatch != null) {
      final name = nameMatch.group(1)!.trim();
      await UserMemoryService.setFact('nombre', name);
      return (handled: true, reply: 'Entendido, te llamas $name.');
    }

    // ── 3) "Recuerda que X" / "no olvides que X" ─────────────────────────
    final factRe = RegExp(
      r'^(?:recuerda que|no olvides que|anota que|guarda que|toma nota de que)\s+(.+)$',
      caseSensitive: false,
    );
    final factMatch = factRe.firstMatch(t);
    if (factMatch != null) {
      final fact = factMatch.group(1)!.trim();
      final keyBase = fact.length > 24 ? fact.substring(0, 24) : fact;
      final key = 'hecho_${DateTime.now().millisecondsSinceEpoch}';
      await UserMemoryService.setFact(key, '$keyBase — $fact');
      return (handled: true, reply: 'Anotado: "$fact". Lo recordaré.');
    }

    // ── 4) Borrar memoria: "olvida X" / "borra memoria" ──────────────────
    if (lower == 'borra tu memoria' || lower == 'olvida todo' || lower == 'reset memoria') {
      await UserMemoryService.clearAll();
      return (handled: true, reply: 'Listo. He borrado mi memoria local.');
    }

    // ── 5) "¿Qué has aprendido?" / "recuérdame lo que sabes" ─────────────
    final recallPhrases = <String>{
      'qué has aprendido', 'que has aprendido',
      'qué sabes de mí', 'que sabes de mi',
      'qué sabes sobre mí', 'que sabes sobre mi',
      'qué recuerdas', 'que recuerdas',
      'qué recuerdas de mí', 'que recuerdas de mi',
      'recuérdame lo que sabes', 'recuerdame lo que sabes',
      'lista lo aprendido',
      'muéstrame tu memoria', 'muestrame tu memoria',
      'dime lo que sabes',
      'qué has memorizado', 'que has memorizado',
      'resumen de tu memoria', 'resumen de memoria',
    };
    final isRecall = recallPhrases.contains(lower) ||
        recallPhrases.any((p) => lower.startsWith('$p ') || lower == p);
    if (isRecall) {
      final reply = await _buildMemoryDigest();
      return (handled: true, reply: reply);
    }

    // ── 6) "Olvida el ejemplo N" / "olvida el hecho X" ────────────────────
    final forgetEx = RegExp(
      r'^(?:olvida|borra)\s+(?:el\s+)?ejemplo\s+(\d+)$',
      caseSensitive: false,
    );
    final fm = forgetEx.firstMatch(t);
    if (fm != null) {
      final idx = int.tryParse(fm.group(1)!);
      if (idx != null) {
        final all = await UserMemoryService.allExamples();
        if (idx >= 1 && idx <= all.length) {
          await UserMemoryService.removeExampleAt(idx - 1);
          return (
            handled: true,
            reply: 'Borrado el ejemplo $idx '
                '("${all[idx-1]['trigger']}" → "${all[idx-1]['response']}").'
          );
        }
        return (handled: true,
            reply: 'Solo tengo ${all.length} ejemplo(s). Di "olvida el ejemplo N" con N entre 1 y ${all.length}.');
      }
    }

    return (handled: false, reply: '');
  }

  static Future<String> _buildMemoryDigest() async {
    final facts = await UserMemoryService.allFacts();
    final top   = await UserMemoryService.topTopics(max: 3);
    final ex    = await UserMemoryService.allExamples();
    final n     = await UserMemoryService.interactionCount();

    final buf = StringBuffer();
    if (facts.isEmpty && top.isEmpty && ex.isEmpty && n == 0) {
      return 'Aún no he aprendido nada sobre ti. '
          'Dime tu nombre, enséñame alguna preferencia o comparte un hecho.';
    }

    buf.write('Llevo $n conversacion${n == 1 ? '' : 'es'} contigo. ');

    if (facts.isNotEmpty) {
      buf.write('De ti sé que: ');
      final list = facts.entries.take(4).map((e) =>
        e.key == 'nombre' ? 'te llamas ${e.value}' :
        'tu ${e.key} es ${e.value}'
      ).toList();
      buf.write('${list.join('; ')}.');
    }
    if (top.isNotEmpty) {
      final t = top.map((e) => e.key).join(', ');
      buf.writeln('Tus temas favoritos: $t.');
    }
    if (ex.isNotEmpty) {
      buf.writeln('Tienes ${ex.length} ejemplo(s) guardado(s):');
      for (var i = 0; i < ex.length && i < 4; i++) {
        final e = ex[i];
        buf.writeln(' ${i + 1}) Cuando digas "${e['trigger']}", '
            'respondo "${e['response']}".');
      }
      if (ex.length > 4) buf.writeln(' … y ${ex.length - 4} más.');
    }
    return buf.toString().trim();
  }

  /// Intenta extraer (trigger, response) del texto tipo "cuando X, Y".
  static ({String trigger, String response})? _matchExample(
    String raw,
    String lower,
  ) {
    final patterns = <RegExp>[
      // "cuando te diga X, respóndeme Y" / "respóndeme Y"
      RegExp(
        r'cuando\s+(?:te\s+diga|te\s+pregunten|me\s+digan|escuches|oigas|te\s+hablen\s+de)\s+(.+?),\s*(?:resp[oó]ndeme|resp[oó]nde|contesta|dime)\s+(.+)',
        caseSensitive: false,
      ),
      // "cuando X, responde Y"
      RegExp(
        r'cuando\s+(.+?),\s*(?:resp[oó]nde|contesta|dime siempre)\s+(.+)',
        caseSensitive: false,
      ),
      // "si te digo X, Y" / "si me preguntas X, Y"
      RegExp(
        r'si\s+(?:te\s+digo|me\s+preguntas|escuchas)\s+(.+?),\s*(.+)$',
        caseSensitive: false,
      ),
      // "de aquí en adelante cuando X, Y"
      RegExp(
        r'de\s+aqu[ií]\s+en\s+adelante\s+cuando\s+(.+?),\s*(.+)$',
        caseSensitive: false,
      ),
    ];

    for (final re in patterns) {
      final m = re.firstMatch(raw);
      if (m == null) continue;
      String trigger  = m.group(1)!.trim().toLowerCase();
      String response = m.group(2)!.trim();
      // limpia comillas/frenos comunes
      trigger = _clean(trigger);
      response = _cleanResponse(response);
      if (trigger.length < 2 || response.length < 2) continue;
      return (trigger: trigger, response: response);
    }
    return null;
  }

  static String _clean(String s) {
    var v = s.trim();
    if (v.length >= 2 &&
        ((v.startsWith('"') && v.endsWith('"')) ||
         (v.startsWith('"') && v.endsWith('"')))) {
      v = v.substring(1, v.length - 1);
    }
    return v.replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _cleanResponse(String s) =>
      s.replaceFirst(RegExp(r'^(con|que)\s+', caseSensitive: false), '');
}

