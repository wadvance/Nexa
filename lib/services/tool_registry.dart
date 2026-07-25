import 'dart:developer' as dev;
import 'package:geolocator/geolocator.dart';
import 'time_service.dart';
import 'realtime_hazard_service.dart';

/// ToolRegistry — herramientas reales de AETHERIS, expuestas como funciones
/// que el bucle ReAct del cerebro puede invocar antes de responder.
///
/// Cada herramienta devuelve un texto breve (1-3 líneas) listo para que el
/// modelo lo use como "Observación" en la cadena Pensar → Acción → Observación.
class ToolRegistry {
  /// Catálogo que el prompt mostrará al LLM.
  /// Solo nombres + descripción; el despacho real se hace en [_dispatch].
  static List<Map<String, String>> catalog() => const [
    {
      'name': 'get_current_time',
      'description': 'Devuelve la hora actual de Panamá (HH:MM AM/PM).',
    },
    {
      'name': 'get_current_date',
      'description': 'Devuelve la fecha actual de Panamá (lunes 22 de julio…).',
    },
    {
      'name': 'get_location',
      'description': 'Devuelve la ubicación actual del dueño '
                     '(lat, lon, ciudad si está disponible).',
    },
    {
      'name': 'get_recent_earthquakes',
      'description': 'Devuelve sismos recientes en un radio de 50 km y últimas '
                     '24 h, incluyendo magnitud, lugar y distancia.',
    },
    {
      'name': 'get_weather_now',
      'description': 'Devuelve el clima actual en la posición del dueño: '
                     'descripción, temperatura, humedad y viento.',
    },
    {
      'name': 'get_active_hazards_alerts',
      'description': 'Devuelve alertas meteorológicas activas y eventos GDACS '
                     'recientes cerca de la ubicación del dueño.',
    },
    {
      'name': 'get_recent_epidemics',
      'description': 'Devuelve las alertas epidemiológicas más recientes '
                     '(ProMED): nuevos virus, brotes.',
    },
  ];

  /// Despacha una llamada de herramienta por nombre.
  /// Devuelve (ok, observationText).
  static Future<({bool ok, String text})> dispatch(
    String name, {
    Map<String, String> args = const {},
  }) async {
    try {
      switch (name) {
        case 'get_current_time':
          final t = await TimeService.panamaTimeString();
          return (ok: true, text: 'Hora actual: $t');

        case 'get_current_date':
          final d = await TimeService.panamaDateString();
          return (ok: true, text: 'Fecha actual: $d');

        case 'get_location':
          final pos = await _safePosition();
          if (pos == null) {
            return (ok: false, text: 'Ubicación no disponible (sin permiso o GPS apagado).');
          }
          return (
            ok: true,
            text: 'Ubicación: lat ${pos.latitude.toStringAsFixed(4)}, '
                  'lon ${pos.longitude.toStringAsFixed(4)} '
                  '(radio de peligros ≈ 1 km).'
          );

        case 'get_recent_earthquakes':
          final pos = await _safePosition();
          if (pos == null) {
            return (ok: false, text: 'No pude obtener ubicación para filtrar sismos cercanos.');
          }
          final radiusKm = double.tryParse(args['radiusKm'] ?? '50') ?? 50;
          final hours    = int.tryParse(args['hours'] ?? '24') ?? 24;
          final minMag   = double.tryParse(args['minMag'] ?? '2.5') ?? 2.5;
          final quakes = await RealTimeHazardService.recentQuakes(
            lat: pos.latitude,
            lon: pos.longitude,
            radiusKm: radiusKm,
            hours: hours,
            minMag: minMag,
          );
          if (quakes.isEmpty) {
            return (ok: true, text:
              'Sin sismos significativos (>$minMag) en '
              '$radiusKm km de la ubicación en las últimas $hours h.');
          }
          final top = quakes.take(3).map((q) =>
            '• Mw ${q.magnitude.toStringAsFixed(1)} a '
            '${q.distanceKm.toStringAsFixed(0)} km (${q.place})').join('  ');
          return (ok: true, text:
            '${quakes.length} sismos detectados cerca. Más relevante: $top');

        case 'get_weather_now':
          final pos = await _safePosition();
          if (pos == null) {
            return (ok: false, text: 'Sin ubicación: no puedo consultar clima.');
          }
          final wx = await RealTimeHazardService.weatherWithAlerts(
            lat: pos.latitude,
            lon: pos.longitude,
          );
          if (wx == null) {
            return (ok: false, text: 'Servicio de clima no respondió.');
          }
          return (ok: true, text:
            'Clima: ${wx.description}, ${wx.tempC.toStringAsFixed(0)}°C, '
            'humedad ${wx.humidity}%, viento ${wx.windSpeed.toStringAsFixed(0)} m/s.');

        case 'get_active_hazards_alerts':
          final alerts = await RealTimeHazardService.gdacsAlerts();
          if (alerts.isEmpty) {
            return (ok: true, text: 'Sin alertas globales GDACS activas relevantes.');
          }
          final top = alerts.take(3)
            .map((a) => '• ${a.title}').join('  ');
          return (ok: true, text:
            '${alerts.length} alertas GDACS. Más recientes: $top');

        case 'get_recent_epidemics':
          final epi = await RealTimeHazardService.epidemicAlerts(max: 3);
          if (epi.isEmpty) {
            return (ok: true, text: 'Sin alertas epidemiológicas recientes (ProMED).');
          }
          final top = epi.map((e) => '• ${e.title}').join('  ');
          return (ok: true, text: 'Alertas epidemiológicas recientes: $top');

        default:
          return (ok: false, text: 'Herramienta "$name" no reconocida.');
      }
    } catch (e) {
      dev.log('ToolRegistry dispatch error ($name): $e');
      return (ok: false, text: 'Error ejecutando $name: $e');
    }
  }

  /// Pide la posición actual; tolerante a fallos.
  static Future<Position?> _safePosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }
}
