import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Devuelve la hora actual de Panamá (UTC-5, sin horario de verano).
/// En web consulta worldtimeapi.org para evitar depender del huso horario del navegador.
class TimeService {
  static const Duration panamaOffset = Duration(hours: -5);

  /// DateTime actual en Panamá.
  /// En web consulta WorldTimeAPI; en nativo usa UTC - 5h.
  static Future<DateTime> panamaNow() async {
    if (kIsWeb) {
      try {
        final resp = await http.get(
          Uri.parse('https://worldtimeapi.org/api/timezone/America/Panama'),
        ).timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final dt = _parseWorldTime(resp.body);
          if (dt != null) return dt;
        }
      } catch (_) {/* fallback abajo */}
    }
    // Fallback (nativo o si la API falla).
    return DateTime.now().toUtc().add(panamaOffset);
  }

  static DateTime? _parseWorldTime(String body) {
    try {
      final i = body.indexOf('"unixtime":');
      if (i < 0) return null;
      final end = body.indexOf(',', i);
      final raw = end > 0 ? body.substring(i + 12, end) : body.substring(i + 12);
      final epoch = int.tryParse(raw.trim());
      if (epoch == null) return null;
      // worldtimeapi devuelve unix time UTC; restamos 5h para Panamá.
      return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true)
          .add(panamaOffset);
    } catch (_) {
      return null;
    }
  }

  /// "HH:MM (AM/PM)" — solo la hora, sin zona horaria.
  static Future<String> panamaTimeString() async {
    final now = await panamaNow();
    final isPm = now.hour >= 12;
    final period = isPm ? 'PM' : 'AM';
    var h12 = now.hour % 12;
    if (h12 == 0) h12 = 12;
    return '${h12.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')} $period';
  }

  /// "martes 22 de julio de 2026"
  static Future<String> panamaDateString() async {
    final now = await panamaNow();
    return '${_wdia(now.weekday)} ${now.day} de ${_mes(now.month)} de ${now.year}';
  }

  static String _wdia(int d) =>
      const ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo']
          [d - 1];

  static String _mes(int m) => const [
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
      ][m - 1];
}
