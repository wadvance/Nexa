import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static String get _apiKey {
    final de = dotenv.env['OPENWEATHERMAP_API_KEY'];
    if (de != null && de.isNotEmpty) return de;
    const fromDef = String.fromEnvironment('OPENWEATHERMAP_API_KEY');
    if (fromDef.isNotEmpty) return fromDef;
    return '72c074fd029ea709c8556e780ca50415';
  }

  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const String _forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  static void _log(String msg) {
    dev.log('WeatherService: $msg', name: 'WeatherService');
  }

  static Future<Map<String, dynamic>?> _makeRequest(String url) async {
    try {
      _log('GET $url');
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );
      _log('HTTP ${response.statusCode}');
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
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

  static Future<Map<String, dynamic>?> fetch(double lat, double lon) {
    return getWeatherByCoords(lat, lon);
  }

  static Future<String> formatCityWeather(String city) async {
    final data = await getWeather(city);
    if (data == null) {
      return _fallbackMessage(city);
    }
    return formatWeather(data);
  }

  static Future<Map<String, dynamic>?> getForecast(String city) async {
    final encoded = Uri.encodeComponent(city);
    return _makeRequest('$_forecastUrl?q=$encoded&appid=$_apiKey&units=metric&lang=es&cnt=40');
  }

  static Future<Map<String, dynamic>?> getForecastByCoords(double lat, double lon) async {
    return _makeRequest('$_forecastUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=es&cnt=40');
  }

  static Future<String> formatForecast(String city) async {
    final data = await getForecast(city);
    if (data == null) return _fallbackMessage(city);
    return _summarizeForecast(data, city);
  }

  static Future<String> forecastOrDefault() async {
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
        final data = await getForecastByCoords(position.latitude, position.longitude);
        if (data != null) return _summarizeForecast(data, data['city']?['name'] ?? 'tu ubicación');
      } catch (e) {
        _log('forecast geolocation failed: $e');
      }
    }
    final data = await getForecast('Panama');
    if (data == null) return _fallbackMessage('tu ubicación');
    return _summarizeForecast(data, 'Panamá');
  }

  static String _summarizeForecast(Map<String, dynamic> data, String cityName) {
    final list = data['list'] as List? ?? [];
    if (list.isEmpty) return 'No pude obtener el pronóstico.';

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dayAfter = DateTime(now.year, now.month, now.day + 2);

    final tomorrowEntries = list.where((entry) {
      final dtTxt = (entry['dt_txt'] as String? ?? '').replaceAll(' ', 'T');
      final dt = DateTime.tryParse(dtTxt);
      if (dt == null) return false;
      return dt.isAfter(tomorrow.subtract(const Duration(hours: 1))) &&
             dt.isBefore(dayAfter);
    }).toList();

    if (tomorrowEntries.isEmpty) {
      return _formatNextEntries(list, cityName);
    }

    double tempMin = 999, tempMax = -999;
    double totalRain = 0;
    int rainCount = 0;
    int thunderCount = 0;
    final conditions = <String>{};

    for (final entry in tomorrowEntries) {
      final main = entry['main'];
      final temp = (main['temp'] as num?)?.toDouble() ?? 0;
      final tMin = (main['temp_min'] as num?)?.toDouble() ?? temp;
      final tMax = (main['temp_max'] as num?)?.toDouble() ?? temp;
      if (tMin < tempMin) tempMin = tMin;
      if (tMax > tempMax) tempMax = tMax;

      final weather = (entry['weather'] as List?)?.first;
      final id = weather?['id'] as int? ?? 800;
      final desc = weather?['description']?.toString() ?? '';
      if (desc.isNotEmpty) conditions.add(desc);

      if (id >= 200 && id < 300) thunderCount++;
      if (id >= 300 && id < 700) rainCount++;

      final rain3h = entry['rain']?['3h'] as num?;
      if (rain3h != null) totalRain += rain3h.toDouble();
    }

    final parts = <String>[];
    parts.add('Pronóstico para mañana en $cityName:');

    if (tempMin < 999) {
      parts.add('Temperatura entre ${tempMin.toStringAsFixed(0)} y ${tempMax.toStringAsFixed(0)} grados.');
    }

    if (thunderCount > 0) {
      parts.add('Se esperan tormentas eléctricas. Toma precauciones.');
    } else if (totalRain > 10) {
      parts.add('Lluvia fuerte esperada, aproximadamente ${totalRain.toStringAsFixed(0)} milímetros.');
    } else if (totalRain > 2) {
      parts.add('Lluvia moderada esperada, aproximadamente ${totalRain.toStringAsFixed(0)} milímetros.');
    } else if (rainCount > 0) {
      parts.add('Posibilidad de lluvia leve.');
    } else {
      parts.add('Sin lluvia esperada.');
    }

    if (conditions.isNotEmpty) {
      parts.add('Condiciones: ${conditions.first}.');
    }

    return parts.join(' ');
  }

  static String _formatNextEntries(List list, String cityName) {
    final entries = list.length > 4 ? list.sublist(0, 4) : list;
    final summary = entries.map((e) {
      final dtTxt = (e['dt_txt']?.toString() ?? '').substring(5, 16);
      final desc = (e['weather'] as List?)?.first?['description'] ?? '';
      final temp = (e['main']?['temp'] as num?)?.toStringAsFixed(0) ?? '?';
      return '$dtTxt: $desc, $temp grados';
    }).join('. ');
    return 'Pronóstico cercano para $cityName: $summary.';
  }

  static Future<String> currentOrDefault() async {
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

    final data = await getWeather('Panama');
    if (data == null) {
      return _fallbackMessage('tu ubicación');
    }
    return formatWeather(data);
  }

  static String _fallbackMessage(String where) {
    return 'No pude consultar el clima de $where en este momento. '
        'Verifica tu conexión a internet o inténtalo de nuevo.';
  }

  static String? precipitationAlert(Map<String, dynamic> data) {
    final weather = data['weather'][0];
    final id = weather['id'] as int? ?? 800;
    final rain1h = data['rain']?['1h'] as num?;
    final rain3h = data['rain']?['3h'] as num?;

    if (id >= 200 && id < 300) {
      return '¡Cuidado! Hay tormentas eléctricas activas en la zona. '
          'Busca refugio y evita áreas abiertas.';
    }
    if (id >= 300 && id < 400) {
      final vol = rain1h ?? rain3h ?? 0;
      if (vol > 0) return 'Hay llovizna leve, ${vol.toStringAsFixed(1)}mm en la última hora.';
      return 'Hay llovizna en la zona.';
    }
    if (id >= 500 && id < 510) {
      final vol = rain1h ?? rain3h ?? 0;
      if (vol > 10) return '¡Lluvia intensa! ${vol.toStringAsFixed(1)}mm en la última hora. Posibles inundaciones.';
      if (vol > 5) return 'Lluvia moderada, ${vol.toStringAsFixed(1)}mm en la última hora.';
      if (vol > 0) return 'Está lloviendo, ${vol.toStringAsFixed(1)}mm en la última hora.';
      return 'Está lloviendo actualmente.';
    }
    if (id >= 510 && id < 600) {
      return '¡Lluvia muy intensa con posible riesgo de inundaciones! '
          'Toma precauciones.';
    }
    if (id >= 600 && id < 700) {
      return 'Está nevando.';
    }
    return null;
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

    final alert = precipitationAlert(data);
    final alertText = alert != null ? ' $alert' : '';

    return 'Clima en $cityName: $desc. '
        'Temperatura $temp grados, sensación $feels. '
        'Mín $tempMin, máx $tempMax. '
        'Humedad $hum por ciento. '
        'Viento $windSpeed metros por segundo.'
        '$alertText';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
