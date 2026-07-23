import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'geocoding_service.dart';
import 'weather_service.dart';
import '../utils/logger.dart';
import 'aetheris_brain.dart';

Future<void> initLocationWeb(String defaultLocation) async {
  try {
    final geo = web.window.navigator.geolocation;
    final completer = Completer<void>();
    geo.getCurrentPosition(
      ((web.GeolocationPosition pos) {
        try {
          final lat = pos.coords.latitude;
          final lon = pos.coords.longitude;
          GeocodingService.reverseGeocode(lat, lon).then((location) {
            AetherisBrain.locationContext = location;
          }).catchError((_) {});
          WeatherService.fetch(lat, lon).then((_) {}).catchError((_) {});
        } catch (e) {
          AppLogger.warn('initLocationWeb success cb: $e');
        }
        if (!completer.isCompleted) completer.complete();
      }).toJS,
      ((web.GeolocationPositionError err) {
        AetherisBrain.locationContext = defaultLocation;
        if (!completer.isCompleted) completer.complete();
      }).toJS,
      web.PositionOptions(
        enableHighAccuracy: false,
        timeout: 5000,
        maximumAge: 60000,
      ),
    );
    // Timeout de seguridad: no dejamos la promesa colgando si el navegador no llama callbacks.
    await completer.future
        .timeout(const Duration(seconds: 6), onTimeout: () {});
  } catch (e) {
    AppLogger.warn('initLocationWeb: $e');
    AetherisBrain.locationContext = defaultLocation;
  }
}
