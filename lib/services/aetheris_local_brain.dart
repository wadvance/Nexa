import 'time_service.dart';
import 'knowledge_base.dart';

/// Cerebro local de AETHERIS (sin red).
///
/// Proporciona respuestas y ayuda en temas frecuentes cuando Gemini
/// no está disponible (p. ej. cuota agotada o sin conexión), para que
/// AETHERIS siga conversando y resolviendo problemas comunes.
class AetherisLocalBrain {
  static Future<String> answer(String rawQuestion) async {
    final q = rawQuestion.toLowerCase().trim();
    if (q.isEmpty) return 'Estoy aquí. Dime qué necesitas.';

    // Identidad y saludo.
    if (_any(q, ['quién eres', 'qué eres', 'quien eres', 'como te llamas', 'cómo te llamas'])) {
      return 'Soy AETHERIS, tu asistente de inteligencia artificial. '
          'Estoy aquí para ayudarte en seguridad y en cualquier tema que necesites.';
    }
    if (_any(q, ['hola', 'buenas', 'saludos', 'qué tal', 'que tal', 'buen día', 'buenos días', 'buenas tardes', 'buenas noches'])) {
      final h = DateTime.now().hour;
      final momento = h < 12 ? 'Buenos días' : h < 19 ? 'Buenas tardes' : 'Buenas noches';
      return '$momento. Dime qué necesitas.';
    }
    if (_any(q, ['gracias', 'gracias', 'mil gracias', 'te agradezco'])) {
      return 'De nada. Siempre estoy para ayudarte.';
    }
    if (_any(q, ['adiós', 'adios', 'hasta luego', 'nos vemos', 'chao', 'chau'])) {
      return 'Hasta luego. Cuida tu seguridad.';
    }

    // Hora y fecha.
    if (_any(q, ['qué hora', 'que hora', 'me dices la hora', 'dime la hora',
        'dame la hora', 'hora actual', 'que horas son'])) {
      return 'Son las ${await TimeService.panamaTimeString()}.';
    }
    if (_any(q, ['qué día', 'que día', 'fecha de hoy', 'qué fecha', 'que fecha',
        'día de hoy', 'que día es hoy'])) {
      return 'Hoy es ${await TimeService.panamaDateString()}.';
    }

    // Cálculo matemático simple.
    final math = _tryMath(q);
    if (math != null) return math;

    // Meteorología, clima y sismografía (temas frecuentes).
    if (_any(q, ['meteorología', 'meteorologia', 'clima', 'tiempo atmosférico', 'pronóstico', 'lluvia', 'huracán', 'tormenta'])) {
      return 'La meteorología estudia la atmósfera y predice el tiempo. '
          'El clima es el patrón a largo plazo (decenas de años). '
          'Para un pronóstico real necesito conexión con mi núcleo en la nube; '
          'mientras tanto, revisa fuentes oficiales de tu país.';
    }
    if (_any(q, ['sismografía', 'sismografia', 'sismología', 'sismologia', 'terremoto', 'sismo', 'temblor', 'magnitud', 'escala de richter'])) {
      return 'La sismología estudia los terremotos. La magnitud se mide con la '
          'escala de Richter o de magnitud momento (Mw). Un sismo de Mw 6 ya '
          'puede causar daños; mayor a 7 es mayor. Ante un temblor: aléjate de '
          'ventanas, cuida tu seguridad y sigue protocolos locales de evacuación.';
    }
    if (_any(q, ['astronomía', 'astronomia', 'espacio', 'estrela', 'planeta', 'luna', 'sol', 'galaxia'])) {
      return 'La astronomía estudia los astros. Si quieres datos precisos del '
          'cielo necesito mi núcleo en la nube; puedo darte conceptos generales ahora.';
    }
    if (_any(q, ['biología', 'biologia', 'célula', 'dna', 'genética', 'genetica', 'organismo'])) {
      return 'La biología estudia la vida: células, ADN, ecosistemas. '
          'Dime una pregunta concreta y, con mi núcleo en la nube, la desarrollo.';
    }

    // Salud y medicamentos (temas frecuentes).
    if (_any(q, ['dolor de cabeza', 'cefalea', 'migraña', 'migrana', 'cabeza'])) {
      return 'Para dolor de cabeza leve o moderado suelen usarse analgésicos comunes como '
          'paracetamol (acetaminofén), ibuprofeno o aspirina. Importante: lee el prospecto, '
          'respeta la dosis y consulta a un médico si el dolor es intenso, recurrente '
          'o viene con fiebre, vómitos o visión borrosa. No soy médico, esto es solo '
          'información general, no sustituye la consulta profesional.';
    }
    if (_any(q, ['fiebre', 'temperatura alta'])) {
      return 'Para fiebre moderada se suele usar paracetamol o ibuprofeno según edad y peso. '
          'Mantente hidratado y descansa. Si la fiebre supera 39 grados, dura más de 3 días '
          'o viene con síntomas graves, consulta a un médico. Esto es orientación general, '
          'no es consejo médico.';
    }
    if (_any(q, ['gripe', 'resfriado', 'catarro', 'congestión', 'congestion'])) {
      return 'Para gripe o resfriado común: descanso, líquidos, paracetamol si hay fiebre o '
          'molestia. Los antibióticos no sirven para virus. Si hay dificultad para respirar, '
          'fiebre alta persistente o empeoramiento, consulta a un médico.';
    }
    if (_any(q, ['tos'])) {
      return 'Para tos seca suele ayudar miel (en mayores de 1 año) o jarabes antitusivos. '
          'Para tos con flema es mejor un expectorante. Si la tos dura más de 3 semanas o '
          'viene con sangre, consulta a un médico.';
    }
    if (_any(q, ['alergia', 'rinitis', 'estornudo'])) {
      return 'Para alergias los antihistamínicos como loratadina o cetirizina son de uso común. '
          'Evita el alérgeno si lo conoces. Si hay dificultad respiratoria o hinchazón de cara, '
          'busca atención médica inmediata, puede ser anafilaxia.';
    }
    if (_any(q, ['estómago', 'estomago', 'gastritis', 'acidez', 'indigestión'])) {
      return 'Para acidez o indigestión轻 suelen usarse antiácidos como omeprazol o ranitidina. '
          'Evita comidas pesadas, alcohol y tabaco. Si el dolor es fuerte, persistente o '
          'viene con sangre, ve al médico de inmediato.';
    }
    if (_any(q, ['insomnio', 'no puedo dormir', 'dormir'])) {
      return 'Para dormir mejor: mantén horarios fijos, evita pantallas 1 hora antes de acostarte, '
          'y reduce la cafeína por la tarde. Si persiste más de 2 semanas, consulta a un médico. '
          'No recomiendo melatonina sin supervisión profesional.';
    }
    if (!q.contains('farmacia') && _any(q, ['medicamento', 'medicina', 'pastilla', 'droga', 'fármaco', 'farmaco'])) {
      return 'Para darte información precisa de un medicamento necesito mi núcleo en la nube. '
          'Mientras tanto: lee siempre el prospecto, respeta la dosis, no mezcles con alcohol '
          'y consulta a tu médico o farmacéutico. ¿Cuál medicamento específicamente?';
    }
    if (_any(q, ['medico', 'médico', 'doctor', 'doctor', 'salud', 'enfermo', 'enfermedad'])) {
      return 'Si tienes síntomas graves (dolor intenso, fiebre muy alta, dificultad para respirar, '
          'sangrado, dolor en el pecho) busca atención médica inmediata o llama a emergencias. '
          'Dime qué síntoma tienes y te oriento en información general.';
    }
    if (_any(q, ['seguridad', 'proteger', 'amenaza', 'vigilar', 'vigilancia', 'intruso', 'robo'])) {
      return 'Recomiendo: mantén el cortafuegos Aegis activo, usa contraseñas '
          'únicas y verifica quién tiene acceso a tus cuentas. '
          'Si sientes peligro inmediato, usa "activar emergencia".';
    }
    if (_any(q, ['contraseña', 'password', 'clave'])) {
      return 'Una clave segura debe tener al menos 12 caracteres, mezcla letras, '
          'números y símbolos, y no reutilices la misma en varios sitios.';
    }
    if (_any(q, ['estrés', 'ansiedad', 'triste', 'miedo', 'ayuda emocional', 'deprimid'])) {
      return 'Lamento que lo pases mal. Respira hondo: inhala 4 segundos, sostén 4, '
          'exhala 4. Si necesitas apoyo profesional, busca ayuda cercana; tu bienestar importa.';
    }

    // Buscar en la base de conocimiento general
    return KnowledgeBase.fallback(rawQuestion);
  }

  static bool _any(String q, List<String> keys) =>
      keys.any((k) => q.contains(k));

  /// Verdadero si el texto es solo un saludo (para responder localmente).
  static bool isGreeting(String q) {
    final t = q.toLowerCase().trim();
    if (t.isEmpty) return false;
    if (t.length > 30) return false; // una pregunta real, no solo saludo
    const saludos = [
      'hola', 'buenas', 'saludos', 'qu tal', 'que tal', 'buen día',
      'buenos días', 'buenas tardes', 'buenas noches', 'chao', 'chau',
      'adiós', 'adios', 'hey', 'qué hay', 'que hay', 'cómo estás',
      'como estas', 'buen dia', 'k tal', 'holi', 'holis',
    ];
    return _any(t, saludos);
  }

  /// Evalúa operaciones aritméticas básicas escritas en texto.
  static String? _tryMath(String q) {
    final match = RegExp(r'(\d+(?:[.,]\d+)?)\s*([+\-*/x×])\s*(\d+(?:[.,]\d+)?)')
        .firstMatch(q);
    if (match == null) return null;
    final a = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    final b = double.tryParse(match.group(3)!.replaceAll(',', '.'));
    final op = match.group(2);
    if (a == null || b == null) return null;
    double r;
    switch (op) {
      case '+':
        r = a + b;
        break;
      case '-':
        r = a - b;
        break;
      case '*':
      case 'x':
      case '×':
        r = a * b;
        break;
      case '/':
        if (b == 0) return 'No puedo dividir entre cero.';
        r = a / b;
        break;
      default:
        return null;
    }
    final result = r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(2);
    return 'El resultado es $result.';
  }
}
