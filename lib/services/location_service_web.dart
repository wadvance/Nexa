import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'geocoding_service.dart';
import 'weather_service.dart';
import 'aetheris_brain.dart';

Future<void> initLocationWeb(String defaultLocation) async {
  final geo = web.window.navigator.geolocation;
  final completer = Completer<void>();
  geo.getCurrentPosition(
    ((web.GeolocationPosition pos) {
      final lat = pos.coords.latitude;
      final lon = pos.coords.longitude;
      GeocodingService.reverseGeocode(lat, lon).then((location) {
        AetherisBrain.locationContext = location;
      });
      WeatherService.fetch(lat, lon).then((_) {});
      completer.complete();
    }).toJS,
    ((web.GeolocationPositionError err) {
      AetherisBrain.locationContext = defaultLocation;
      completer.complete();
    }).toJS,
    web.PositionOptions(
      enableHighAccuracy: false,
      timeout: 5000,
      maximumAge: 60000,
    ),
  );
  await completer.future;
}
