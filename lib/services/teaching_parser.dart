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

    return (handled: false, reply: '');
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

