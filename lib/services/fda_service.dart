import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;

class FdaService {
  static void _log(String msg) {
    dev.log('FdaService: $msg', name: 'FdaService');
  }

  static const String _baseUrl = 'https://api.fda.gov';

  /// Busca medicamentos por nombre en la base de datos de la FDA.
  /// Devuelve hasta 5 resultados con información clave.
  static Future<Map<String, dynamic>?> searchMedication(String name) async {
    final encoded = Uri.encodeComponent(name);
    final uri = Uri.parse('$_baseUrl/drug/event.json?search=openfda.brand_name:$encoded&limit=5');
    
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        if (results == null || results.isEmpty) {
          // Intentar con nombre genérico
          final uri2 = Uri.parse('$_baseUrl/drug/event.json?search=openfda.generic_name:$encoded&limit=5');
          final response2 = await http.get(uri2);
          if (response2.statusCode == 200) {
            return json.decode(response2.body) as Map<String, dynamic>;
          }
          return null;
        }
        return data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      _log('error: $e');
      return null;
    }
  }

  /// Busca y formatea información de un medicamento para Aetheris.
  static Future<String> getMedicationInfo(String name) async {
    final data = await searchMedication(name);
    if (data == null) {
      return 'No encontré información oficial sobre "$name" en la base de la FDA. '
          'Consulta a tu médico o farmacéutico para información detallada.';
    }
    
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) {
      return 'No hay resultados para "$name" en la base de la FDA.';
    }

    final buffer = StringBuffer('Sobre $name (FDA): ');
    
    final first = results.first as Map<String, dynamic>;
    final openfda = first['openfda'] as Map<String, dynamic>?;
    
    if (openfda != null) {
      final brandName = openfda['brand_name'];
      final genericName = openfda['generic_name'];
      final manufacturer = openfda['manufacturer_name'];
      final route = openfda['route'];
      final substance = openfda['substance_name'];
      
      if (brandName != null) {
        final brands = (brandName as List).take(3).join(', ');
        buffer.write('Nombres comerciales: $brands. ');
      }
      if (genericName != null) {
        final generics = (genericName as List).take(3).join(', ');
        buffer.write('Nombre genérico: $generics. ');
      }
      if (substance != null) {
        final subs = (substance as List).take(3).join(', ');
        buffer.write('Sustancia activa: $subs. ');
      }
      if (manufacturer != null) {
        final mf = (manufacturer as List).take(2).join(', ');
        buffer.write('Fabricante: $mf. ');
      }
      if (route != null) {
        final r = (route as List).take(3).join(', ');
        buffer.write('Vía de administración: $r. ');
      }
    }

    buffer.write('Esta es información oficial de EE. UU. Para tu país, consulta fuentes locales. ');
    buffer.write('No sustituye la consulta médica profesional.');
    
    return buffer.toString();
  }
}
