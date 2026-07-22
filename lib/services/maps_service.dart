import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

class MapsService {
  static void _log(String msg) {
    dev.log('MapsService: $msg', name: 'MapsService');
  }

  static const String _apiKey = 'AIzaSyAOVODxIhTMsFK59M36NHeSGg9vneD-9tc';
  static const String _geocodingBase = 'https://maps.googleapis.com/maps/api/geocode/json';
  static const String _directionsBase = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String _staticMapBase = 'https://maps.googleapis.com/maps/api/staticmap';

  /// Convierte una dirección en coordenadas (latitud, longitud).
  static Future<Map<String, double>?> geocodeAddress(String address) async {
    final uri = Uri.parse('$_geocodingBase?address=${Uri.encodeComponent(address)}&key=$_apiKey');
    
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return {
            'lat': location['lat'].toDouble(),
            'lng': location['lng'].toDouble(),
          };
        }
      }
      return null;
    } catch (e) {
      _log('Error en geocoding: $e');
      return null;
    }
  }

  /// Obtiene una ruta entre dos puntos.
  static Future<Map<String, dynamic>?> getDirections(
    String origin,
    String destination, {
    String mode = 'driving',
  }) async {
    final uri = Uri.parse(
      '$_directionsBase?origin=${Uri.encodeComponent(origin)}'
      '&destination=${Uri.encodeComponent(destination)}'
      '&mode=$mode'
      '&language=es'
      '&key=$_apiKey',
    );
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return data['routes'][0];
        }
      }
      return null;
    } catch (e) {
      _log('Error en directions: $e');
      return null;
    }
  }

  /// Abre Google Maps con una dirección de destino.
  static void openInMaps(String destination) {
    final encoded = Uri.encodeComponent(destination);
    final url = 'https://www.google.com/maps/search/?api=1&query=$encoded';
    web.window.open(url, '_blank');
  }

  /// Genera URL para mapa estático.
  static String getStaticMapUrl({
    required double lat,
    required double lng,
    int zoom = 14,
    int width = 600,
    int height = 400,
  }) {
    return '$_staticMapBase?center=$lat,$lng&zoom=$zoom&size=${width}x$height&key=$_apiKey';
  }

  /// Obtiene la URL para abrir navegación turn-by-turn.
  static String getNavigationUrl(double lat, double lng) {
    return 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
  }
}
