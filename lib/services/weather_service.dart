import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static String get _apiKey =>
      dotenv.env['OPENWEATHERMAP_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  static void _log(String msg) {
    // ignore: avoid_print
    dev.log('WeatherService: $msg', name: 'WeatherService');
  }

  static Future<Map<String, dynamic>?> _makeRequest(String url) async {
    try {
      _log('GET $url');
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        _log('HTTP ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _log('error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getWeather(String city) async {
    final encoded = Uri.encodeComponent(city);
    return _makeRequest('$_baseUrl?q=$encoded&appid=$_apiKey&units=metric&lang=es');
  }

  static Future<Map<String, dynamic>?> getWeatherByCoords(double lat, double lon) async {
    return _makeRequest('$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=es');
  }

  /// Alias compatible con location_service_web.dart
  static Future<Map<String, dynamic>?> fetch(double lat, double lon) {
    return getWeatherByCoords(lat, lon);
  }

  /// Obtiene y formatea el clima de una ciudad específica.
  /// Devuelve mensaje amable si falla (incluido CORS en web).
  static Future<String> formatCityWeather(String city) async {
    final data = await getWeather(city);
    if (data == null) {
      return _fallbackMessage(city);
    }
    return formatWeather(data);
  }

  static Future<String> currentOrDefault() async {
    // En web, saltar geolocator (el plugin web tiene problemas con permisos)
    if (!kIsWeb) {
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          await Geolocator.requestPermission();
        }
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
        final data = await getWeatherByCoords(position.latitude, position.longitude);
        if (data != null) return formatWeather(data);
      } catch (e) {
        _log('geolocation failed: $e');
      }
    }

    // Fallback: Panamá por defecto (el usuario está en Panamá)
    final data = await getWeather('Panama');
    if (data == null) {
      return _fallbackMessage('tu ubicación');
    }
    return formatWeather(data);
  }

  /// Mensaje amable si la API falla (CORS, sin internet, etc.)
  static String _fallbackMessage(String where) {
    return 'No pude consultar el clima de $where en este momento. '
        'Verifica tu conexión a internet o inténtalo de nuevo.';
  }

  static String formatWeather(Map<String, dynamic> data) {
    final weather = data['weather'][0];
    final main = data['main'];
    final wind = data['wind'];
    final cityName = data['name']?.toString() ?? 'tu ubicación';
    final desc = weather['description']?.toString().capitalize() ?? 'desconocido';
    final temp = (main['temp'] as num?)?.toStringAsFixed(1) ?? '?';
    final feels = (main['feels_like'] as num?)?.toStringAsFixed(1) ?? '?';
    final tempMin = (main['temp_min'] as num?)?.toStringAsFixed(1) ?? '?';
    final tempMax = (main['temp_max'] as num?)?.toStringAsFixed(1) ?? '?';
    final hum = main['humidity']?.toString() ?? '?';
    final windSpeed = (wind['speed'] as num?)?.toStringAsFixed(1) ?? '?';

    return 'Clima en $cityName: $desc. '
        'Temperatura $temp grados, sensación $feels. '
        'Mín $tempMin, máx $tempMax. '
        'Humedad $hum por ciento. '
        'Viento $windSpeed metros por segundo.';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}