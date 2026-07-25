import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _defaultLocation = 'Panamá';

  static Future<String> reverseGeocode(double lat, double lon) async {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (key == null || key.isEmpty) return _defaultLocation;

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lon&language=es&key=$key',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) return _defaultLocation;

      final data = jsonDecode(response.body);
      if (data['status'] != 'OK') return _defaultLocation;

      final results = data['results'] as List;
      if (results.isEmpty) return _defaultLocation;

      String? locality;
      String? country;
      for (final component in results[0]['address_components'] as List) {
        final types = component['types'] as List;
        if (types.contains('locality')) {
          locality = component['long_name'];
        }
        if (types.contains('country')) {
          country = component['long_name'];
        }
      }

      if (locality != null && country != null) return '$locality, $country';
      if (locality != null) return locality;
      if (country != null) return country;
      return _defaultLocation;
    } catch (_) {
      return _defaultLocation;
    }
  }
}
