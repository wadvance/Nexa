import 'dart:convert';
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/security_log.dart';

/// Servicio de persistencia de eventos de seguridad.
///
/// Usa Firestore (colección `security_logs`) cuando está disponible. Si la
/// conexión falla (p. ej. Firestore no habilitado o sin reglas), cae back a
/// almacenamiento local con shared_preferences para que la app siga funcionando.
class SecurityLogService {
  static const _localKey = 'aetheris_security_logs';
  static final _collection =
      FirebaseFirestore.instance.collection('security_logs');

  /// Guarda un evento de seguridad y devuelve su ID.
  static Future<String> saveLog(SecurityLog log) async {
    try {
      final doc = await _collection.add(log.toMap());
      return doc.id;
    } catch (e) {
      dev.log('SecurityLogService: Firestore no disponible, usando local. $e');
      return _saveLocal(log);
    }
  }

  static Future<String> _saveLocal(SecurityLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_localKey) ?? [];
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final withId = SecurityLog(
      id: id,
      timestamp: log.timestamp,
      location: log.location,
      detectedThreat: log.detectedThreat,
      iaAnalysis: log.iaAnalysis,
    );
    list.add(jsonEncode(withId.toMap()));
    await prefs.setStringList(_localKey, list);
    return id;
  }

  /// Stream en tiempo real de los logs (más recientes primero).
  static Stream<List<SecurityLog>> watchLogs() {
    return _collection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SecurityLog.fromDoc).toList())
        .handleError((e) async* {
      dev.log('SecurityLogService.watchLogs error: $e');
      yield await _loadLocal();
    });
  }

  static Future<List<SecurityLog>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_localKey) ?? [];
    final logs = list
        .map((s) => SecurityLog.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  /// Devuelve los eventos más recientes (para leerlos por voz).
  static Future<List<SecurityLog>> getRecentLogs({int limit = 5}) async {
    try {
      final snap = await _collection
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(SecurityLog.fromDoc).toList();
    } catch (e) {
      dev.log('SecurityLogService.getRecentLogs fallback local. $e');
      return _loadLocal();
    }
  }

  /// Borra todos los eventos registrados.
  static Future<void> clearLogs() async {
    try {
      final snap = await _collection.get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      dev.log('SecurityLogService.clearLogs fallback local. $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localKey);
    }
  }

  /// Registra una amenaza detectada con el análisis de AETHERIS.
  static Future<String> reportThreat({
    required String detectedThreat,
    required String iaAnalysis,
    GeoPoint? location,
  }) {
    return saveLog(
      SecurityLog(
        timestamp: DateTime.now(),
        location: location,
        detectedThreat: detectedThreat,
        iaAnalysis: iaAnalysis,
      ),
    );
  }
}
