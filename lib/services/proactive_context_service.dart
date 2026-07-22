import 'dart:async';
import 'dart:developer' as dev;
import 'package:geolocator/geolocator.dart';
import 'realtime_hazard_service.dart';
import 'notification_service.dart';

/// ProactiveContextService — escaneo automático de peligros cercanos.
///
/// AETHERIS revisa periódicamente (cada [scanInterval]) y dispara
/// notificaciones push con nuevas amenazas reales dentro de un radio
/// configurable (default 50 km para sismos; clima y epidemias usan
/// la zona del usuario). El radio "1 km" que pidió el dueño se aplica
/// al reporte verbal; las APIs abiertas sólo devuelven datos útiles
/// a partir de ~5-10 km, así que el resumen incluye el radio real usado.
class ProactiveContextService {
  static const Duration scanInterval = Duration(minutes: 30);

  Timer? _timer;
  String _lastDigest = ''; // evita repetir la misma alerta
  bool   _running    = false;

  void start() {
    if (_running) return;
    _running = true;
    // Primer escaneo a los 2 minutos de abrir la app, luego cada 30 min
    Timer(const Duration(minutes: 2), _scanOnce);
    _timer = Timer.periodic(scanInterval, (_) => _scanOnce());
    dev.log('ProactiveContextService: scan cada ${scanInterval.inMinutes} min');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  /// Ejecuta un escaneo manualmente y devuelve el digest en texto.
  static Future<String> scanNow({
    double? lat,
    double? lon,
    double quakeRadiusKm = 50,
  }) async {
    Position? pos;
    if (lat != null && lon != null) {
      pos = Position(
        latitude: lat, longitude: lon,
        timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, altitudeAccuracy: 0,
        heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
      );
    } else {
      try {
        final p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 6));
        pos = p;
      } catch (_) {}
    }

    final buffer = StringBuffer();
    if (pos == null) {
      buffer.write('Sin ubicación: no puedo evaluar peligros cercanos. ');
    } else {
      // Sismos cercanos (radio efectivo)
      final quakes = await RealTimeHazardService.recentQuakes(
        lat: pos.latitude, lon: pos.longitude,
        radiusKm: quakeRadiusKm, hours: 24, minMag: 3.0,
      );
      if (quakes.isNotEmpty) {
        final q = quakes.first;
        buffer.write(
          'Sismo a ${q.distanceKm.toStringAsFixed(0)} km: '
          'Mw ${q.magnitude.toStringAsFixed(1)} (${q.place}). '
        );
      }
      // Clima actual
      final wx = await RealTimeHazardService.weatherWithAlerts(
        lat: pos.latitude, lon: pos.longitude,
      );
      if (wx != null) {
        if (wx.alerts.isNotEmpty) {
          buffer.write('Alerta meteorológica activa: ${wx.alerts.first}. ');
        }
        if (wx.windSpeed >= 15) {
          buffer.write('Viento fuerte: ${wx.windSpeed.toStringAsFixed(0)} m/s. ');
        }
      }
    }

    // Epidemias (sin ubicación; globales)
    final epi = await RealTimeHazardService.epidemicAlerts(max: 1);
    if (epi.isNotEmpty) {
      buffer.write('Alerta epidemiológica: ${epi.first.title}. ');
    }

    if (buffer.isEmpty) {
      buffer.write('Sin peligros relevantes en este momento. Todo bien. ');
    }
    return buffer.toString().trim();
  }

  Future<void> _scanOnce() async {
    try {
      final digest = await scanNow();
      if (digest == _lastDigest) return;
      _lastDigest = digest;

      // Notificar SOLO si hay alerta real (no cuando "todo bien")
      final looksSafe = digest.contains('Todo bien') ||
                        digest.toLowerCase().contains('sin peligros relevantes');
      if (!looksSafe) {
        await NotificationService.instance.notifyHazard(
          title: 'AETHERIS — Vigilancia activa',
          body: digest,
        );
      }
    } catch (e) {
      dev.log('ProactiveContextService.scan error: $e');
    }
  }
}
