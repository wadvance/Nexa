import 'dart:convert';
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Servicio de gestión del perfil de usuario.
///
/// Usa Firestore (colección `users`) cuando está disponible; si falla, usa
/// almacenamiento local con shared_preferences como fallback.
class UserService {
  static const _localKey = 'aetheris_user_profile';
  static final _collection = FirebaseFirestore.instance.collection('users');

  /// Crea o actualiza el perfil del usuario.
  static Future<void> saveProfile(UserProfile profile) async {
    try {
      await _collection.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      dev.log('UserService: Firestore no disponible, usando local. $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localKey, jsonEncode(profile.toMap()));
    }
  }

  /// Lee el perfil en tiempo real.
  static Stream<UserProfile?> watchProfile(String uid) {
    return _collection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromDoc(doc);
    }).handleError((e) async* {
      dev.log('UserService.watchProfile error: $e');
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKey);
      yield raw == null
          ? null
          : UserProfile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    });
  }

  /// Añade un contacto de confianza a la lista.
  static Future<void> addTrustedContact(String uid, String contact) async {
    try {
      await _collection.doc(uid).update({
        'trusted_contacts': FieldValue.arrayUnion([contact]),
      });
    } catch (e) {
      dev.log('UserService.addTrustedContact fallback local. $e');
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKey);
      final map = raw == null
          ? <String, dynamic>{'uid': uid, 'trusted_contacts': <String>[]}
          : jsonDecode(raw) as Map<String, dynamic>;
      final contacts = List<String>.from(map['trusted_contacts'] ?? []);
      contacts.add(contact);
      map['trusted_contacts'] = contacts;
      map['uid'] = uid;
      await prefs.setString(_localKey, jsonEncode(map));
    }
  }

  /// Actualiza el nivel de seguridad (1 = bajo, 5 = máximo).
  static Future<void> setSecurityLevel(String uid, int level) async {
    try {
      await _collection.doc(uid).update({'security_level': level});
    } catch (e) {
      dev.log('UserService.setSecurityLevel fallback local. $e');
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKey);
      final map = raw == null
          ? <String, dynamic>{'uid': uid, 'security_level': level}
          : jsonDecode(raw) as Map<String, dynamic>;
      map['security_level'] = level;
      map['uid'] = uid;
      await prefs.setString(_localKey, jsonEncode(map));
    }
  }
}
