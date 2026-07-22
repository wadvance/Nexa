import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// RealTimeHazardService — datos en tiempo real de peligros latentes.
///
/// Fuentes integradas (todas gratuitas y sin API key):
///   • USGS Earthquake API  → sismos recientes
///   • OpenWeatherMap API   → clima, tormentas, alertas (con clave existente)
///   • WHO / ProMED RSS     → alertas epidemiológicas (nuevos virus, brotes)
///   • NOAA/NWS Alerts      → alertas meteorológicas severas (servicio abierto)
///   • GDACS               → alertas globales de desastres
class RealTimeHazardService {
  static String get _owmKey =>
      dotenv.env['OPENWEATHERMAP_API_KEY'] ?? '';

  // ─────────────────────────────────────────────────────────────────────────
  // SISMOS (USGS)
  // ─────────────────────────────────────────────────────────────────────────

  /// Sismos recientes >= [minMag] en las últimas [hours] horas, dentro de
  /// [radiusKm] km de la posición dada. Si lat/lon son null, devuelve globales.
  static Future<List<QuakeEvent>> recentQuakes({
    double? lat,
    double? lon,
    double radiusKm = 500,
    double minMag   = 4.0,
    int hours       = 24,
  }) async {
    final now   = DateTime.now().toUtc();
    final start = now.subtract(Duration(hours: hours));
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}T'
        '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}:00';

    final uri = Uri.parse(
      'https://earthquake.usgs.gov/fdsnws/event/1/query'
      '?format=geojson&starttime=${fmt(start)}&endtime=${fmt(now)}'
      '&minmagnitude=$minMag&orderby=magnitude',
    );

    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body);
      final features = (json['features'] as List?) ?? [];
      final result = <QuakeEvent>[];

      for (final f in features) {
        final coords = f['geometry']['coordinates'] as List;
        final eLon   = (coords[0] as num).toDouble();
        final eLat   = (coords[1] as num).toDouble();
        final mag    = (f['properties']['mag'] as num?)?.toDouble() ?? 0;
        final place  = f['properties']['place']?.toString() ?? '';
        final ms     = f['properties']['time'] as int? ?? 0;
        final dist   = (lat != null && lon != null)
            ? _haversine(lat, lon, eLat, eLon)
            : 9999.0;

        if (dist <= radiusKm) {
          result.add(QuakeEvent(
            magnitude: mag,
            place: place,
            distanceKm: dist,
            timestamp: DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
            lat: eLat,
            lon: eLon,
          ));
        }
      }
      result.sort((a, b) => b.magnitude.compareTo(a.magnitude));
      return result;
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CLIMA Y ALERTAS METEOROLÓGICAS (OpenWeatherMap)
  // ─────────────────────────────────────────────────────────────────────────

  /// Devuelve clima actual + alertas activas en la posición dada.
  static Future<WeatherSnapshot?> weatherWithAlerts({
    required double lat,
    required double lon,
  }) async {
    try {
      // OneCall 3.0 (o 2.5 si 3.0 no está activo)
      final uri = Uri.parse(
        'https://api.openweathermap.org/data/3.0/onecall'
        '?lat=$lat&lon=$lon&appid=$_owmKey&units=metric&lang=es'
        '&exclude=minutely,hourly,daily',
      );
      var resp = await http.get(uri).timeout(const Duration(seconds: 10));

      // Fallback a 2.5
      if (resp.statusCode != 200) {
        final uri25 = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather'
          '?lat=$lat&lon=$lon&appid=$_owmKey&units=metric&lang=es',
        );
        resp = await http.get(uri25).timeout(const Duration(seconds: 10));
        if (resp.statusCode != 200) return null;
        final d = jsonDecode(resp.body) as Map<String, dynamic>;
        return WeatherSnapshot.fromSimple(d);
      }

      final d = jsonDecode(resp.body) as Map<String, dynamic>;
      return WeatherSnapshot.fromOneCall(d);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ALERTAS GLOBALES DE DESASTRES (GDACS — JSON feed abierto)
  // ─────────────────────────────────────────────────────────────────────────

  /// Alertas activas de GDACS (inundaciones, ciclones, tsunamis, etc.)
  static Future<List<DisasterAlert>> gdacsAlerts() async {
    try {
      final uri = Uri.parse(
        'https://www.gdacs.org/xml/rss.xml',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      // Parseo básico de RSS XML sin librería externa
      return _parseGdacsRss(resp.body);
    } catch (_) {
      return [];
    }
  }

  static List<DisasterAlert> _parseGdacsRss(String xml) {
    final result = <DisasterAlert>[];
    final titlePattern = RegExp(r'<title><!\[CDATA\[(.*?)\]\]><\/title>');
    final descPattern  = RegExp(r'<description><!\[CDATA\[(.*?)\]\]><\/description>');
    final titles  = titlePattern.allMatches(xml).map((m) => m.group(1) ?? '').toList();
    final descs   = descPattern.allMatches(xml).map((m) => m.group(1) ?? '').toList();
    for (var i = 1; i < titles.length && i < 8; i++) {
      final t = titles[i].trim();
      if (t.isEmpty) continue;
      result.add(DisasterAlert(
        title: t,
        description: i < descs.length ? descs[i].trim() : '',
        source: 'GDACS',
      ));
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ALERTAS EPIDEMIOLÓGICAS (ProMED / WHO RSS)
  // ─────────────────────────────────────────────────────────────────────────

  /// Últimos reportes de enfermedades de ProMED (feed RSS abierto).
  static Future<List<EpidemicAlert>> epidemicAlerts({int max = 5}) async {
    try {
      final uri = Uri.parse('https://promedmail.org/feed/');
      final resp = await http.get(uri).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      return _parseEpidemicRss(resp.body, max);
    } catch (_) {
      return [];
    }
  }

  static List<EpidemicAlert> _parseEpidemicRss(String xml, int max) {
    final result  = <EpidemicAlert>[];
    final tPat    = RegExp(r'<title>(.*?)<\/title>', dotAll: true);
    final dPat    = RegExp(r'<description>(.*?)<\/description>', dotAll: true);
    final titles  = tPat.allMatches(xml).map((m) => _stripTags(m.group(1) ?? '')).toList();
    final descs   = dPat.allMatches(xml).map((m) => _stripTags(m.group(1) ?? '')).toList();
    for (var i = 1; i < titles.length && result.length < max; i++) {
      final t = titles[i].trim();
      if (t.isEmpty) continue;
      result.add(EpidemicAlert(
        title: t,
        summary: i < descs.length ? descs[i].trim().substring(0, descs[i].trim().length.clamp(0, 200)) : '',
        source: 'ProMED',
      ));
    }
    return result;
  }

  static String _stripTags(String html) =>
      html.replaceAll(RegExp(r'<[^>]+>'), '').replaceAll('&amp;', '&').trim();

  // ─────────────────────────────────────────────────────────────────────────
  // RESUMEN COMPLETO DE PELIGROS CERCANOS
  // ─────────────────────────────────────────────────────────────────────────

  /// Evalúa todos los peligros cercanos y devuelve un texto de voz listo.
  static Future<String> fullHazardReport({
    double? lat,
    double? lon,
    String location = 'tu zona',
  }) async {
    final buffer = StringBuffer();

    // 1) Sismos
    final quakes = await recentQuakes(lat: lat, lon: lon, radiusKm: 500, hours: 48);
    if (quakes.isEmpty) {
      buffer.write('No se registran sismos significativos en 500 km en las últimas 48 horas. ');
    } else {
      final q = quakes.first;
      final dist = q.distanceKm < 9990
          ? '${q.distanceKm.toStringAsFixed(0)} km'
          : 'distancia no determinada';
      buffer.write(
        'Sismo más cercano: magnitud ${q.magnitude.toStringAsFixed(1)} '
        'en ${q.place} a $dist. ',
      );
      if (quakes.length > 1) {
        buffer.write('Total de ${quakes.length} sismos en el área. ');
      }
    }

    // 2) Clima y alertas meteorológicas
    if (lat != null && lon != null) {
      final wx = await weatherWithAlerts(lat: lat, lon: lon);
      if (wx != null) {
        buffer.write('Clima actual en $location: ${wx.description}, '
            '${wx.tempC.toStringAsFixed(0)}°C, '
            'humedad ${wx.humidity}%. ');
        if (wx.alerts.isNotEmpty) {
          buffer.write('¡Alerta meteorológica activa! ${wx.alerts.first}. ');
        }
        if (wx.windSpeed >= 15) {
          buffer.write('Vientos fuertes de ${wx.windSpeed.toStringAsFixed(0)} m/s. ');
        }
      }
    }

    // 3) Desastres GDACS
    final disasters = await gdacsAlerts();
    if (disasters.isNotEmpty) {
      buffer.write('Alerta global GDACS: ${disasters.first.title}. ');
    }

    // 4) Epidemias / nuevos virus
    final epi = await epidemicAlerts(max: 2);
    if (epi.isNotEmpty) {
      buffer.write('Alerta epidemiológica reciente: ${epi.first.title}. ');
    }

    // Mensaje de cierre
    buffer.write('Para detalles actualizados, consulta las autoridades oficiales de tu país.');

    return buffer.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UTILIDADES
  // ─────────────────────────────────────────────────────────────────────────

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r   = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a    = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return r * 2 * math.asin(math.min(1.0, math.sqrt(a)));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelos de datos
// ─────────────────────────────────────────────────────────────────────────────

class QuakeEvent {
  final double   magnitude;
  final String   place;
  final double   distanceKm;
  final DateTime timestamp;
  final double   lat;
  final double   lon;

  const QuakeEvent({
    required this.magnitude,
    required this.place,
    required this.distanceKm,
    required this.timestamp,
    required this.lat,
    required this.lon,
  });
}

class WeatherSnapshot {
  final String       description;
  final double       tempC;
  final int          humidity;
  final double       windSpeed;
  final List<String> alerts;

  const WeatherSnapshot({
    required this.description,
    required this.tempC,
    required this.humidity,
    required this.windSpeed,
    required this.alerts,
  });

  factory WeatherSnapshot.fromSimple(Map<String, dynamic> d) {
    final w = (d['weather'] as List?)?.first as Map? ?? {};
    final m = d['main'] as Map? ?? {};
    final wind = d['wind'] as Map? ?? {};
    return WeatherSnapshot(
      description: w['description']?.toString() ?? 'sin datos',
      tempC: (m['temp'] as num?)?.toDouble() ?? 0,
      humidity: (m['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0,
      alerts: [],
    );
  }

  factory WeatherSnapshot.fromOneCall(Map<String, dynamic> d) {
    final current = d['current'] as Map? ?? {};
    final w       = (current['weather'] as List?)?.first as Map? ?? {};
    final rawAlerts = d['alerts'] as List? ?? [];
    final alertTexts = rawAlerts
        .map((a) => (a as Map)['event']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    return WeatherSnapshot(
      description: w['description']?.toString() ?? 'sin datos',
      tempC: (current['temp'] as num?)?.toDouble() ?? 0,
      humidity: (current['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (current['wind_speed'] as num?)?.toDouble() ?? 0,
      alerts: alertTexts,
    );
  }
}

class DisasterAlert {
  final String title;
  final String description;
  final String source;
  const DisasterAlert({required this.title, required this.description, required this.source});
}

class EpidemicAlert {
  final String title;
  final String summary;
  final String source;
  const EpidemicAlert({required this.title, required this.summary, required this.source});
}
