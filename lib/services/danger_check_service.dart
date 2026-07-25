import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'aetheris_brain.dart';

/// Detecta posibles peligros/amenazas próximos a la ubicación del usuario.
/// Combina:
/// - Terremotos recientes (USGS, mundial, gratis)
/// - Análisis contextual basado en hora del día y ubicación
class DangerCheckService {
  static void _log(String msg) {
    dev.log('DangerCheckService: $msg', name: 'DangerCheckService');
  }

  /// Busca eventos sísmicos recientes en un radio de [radiusKm] km.
  static Future<List<Map<String, dynamic>>> nearbyQuakes({
    double? lat,
    double? lon,
    double radiusKm = 500,
    int days = 7,
  }) async {
    final now = DateTime.now().toUtc();
    final start = now.subtract(Duration(days: days));
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse(
      'https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson'
      '&starttime=${fmt(start)}&endtime=${fmt(now)}&minmagnitude=4.5',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final data = json.decode(response.body);
      final features = data['features'] as List?;
      if (features == null || features.isEmpty) return [];

      final results = <Map<String, dynamic>>[];
      for (final f in features) {
        final m = f as Map;
        final coords = m['geometry']['coordinates'] as List;
        final elon = (coords[0] as num).toDouble();
        final elat = (coords[1] as num).toDouble();
        final mag = (m['properties']['mag'] as num?)?.toDouble() ?? 0;
        final place = m['properties']['place']?.toString() ?? '';
        final time = m['properties']['time'] as int?;

        double distKm = 0;
        if (lat != null && lon != null) {
          distKm = _haversine(lat, lon, elat, elon);
        }

        if (distKm <= radiusKm) {
          results.add({
            'mag': mag,
            'place': place,
            'distKm': distKm,
            'time': time,
          });
        }
      }
      results.sort((a, b) => (a['distKm'] as double).compareTo(b['distKm'] as double));
      return results;
    } catch (e) {
      _log('quakes error: $e');
      return [];
    }
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // radio Tierra en km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.asin(math.min(1.0, math.sqrt(a)));
    return r * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;

  /// Análisis contextual: peligros próximos en metros.
  /// Combina: sismos, hora del día, ubicación.
  static Future<String> assessNearbyDanger({double? lat, double? lon, int radiusMeters = 500}) async {
    final quakes = await nearbyQuakes(lat: lat, lon: lon, radiusKm: 500);
    final extremelyClose = quakes.where((q) => (q['distKm'] as double) <= 1.5).toList();

    final hora = DateTime.now().hour;
    final esDeNoche = hora >= 21 || hora <= 6;
    final location = AetherisBrain.locationContext;

    final buffer = StringBuffer();
    buffer.write('En $location ahora mismo: ');

    if (extremelyClose.isEmpty && quakes.isEmpty) {
      buffer.write('no detecté sismos fuertes en 500 km. ');
    } else if (extremelyClose.isNotEmpty) {
      final q = extremelyClose.first;
      final mag = (q['mag'] as double).toStringAsFixed(1);
      final dist = (q['distKm'] as double).toStringAsFixed(0);
      buffer.write('un sismo de magnitud $mag a $dist km. ');
    } else {
      buffer.write('hay ${quakes.length} temblores lejanos, sin riesgo directo. ');
    }

    if (esDeNoche) {
      buffer.write('Es de noche: evita zonas oscuras y ten tu teléfono a mano. ');
    }

    buffer.write('No tengo datos de criminalidad en tiempo real. Consulta alertas oficiales locales.');

    return buffer.toString();
  }
}
