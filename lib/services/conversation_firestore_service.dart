import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

/// ConversationFirestoreService — guarda el historial de conversación en Firestore.
///
/// Colección: `conversations` (documentos por sesión de usuario)
/// Subcolección: `messages` (cada mensaje individual)
///
/// Permite que AETHERIS recuerde conversaciones previas entre sesiones
/// y haga referencia a temas ya tratados.
class ConversationFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'conversations';
  static const String _messagesSubcollection = 'messages';

  /// ID de la sesión actual (se genera al iniciar la app)
  static String? _currentSessionId;
  static bool _enabled = true;

  /// Inicializa una nueva sesión de conversación
  static Future<void> initSession(String userId) async {
    try {
      _currentSessionId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore.collection(_collection).doc(_currentSessionId).set({
        'userId': userId,
        'startedAt': FieldValue.serverTimestamp(),
        'messageCount': 0,
        'topics': <String>[],
      }, SetOptions(merge: true));
      AppLogger.info('Firestore session initialized: $_currentSessionId');
    } catch (e) {
      AppLogger.warning('Firestore session init failed (offline?): $e');
      _enabled = false;
    }
  }

  /// Guarda un mensaje de usuario o asistente en Firestore
  static Future<void> saveMessage({
    required String userId,
    required String role, // 'user' | 'assistant'
    required String text,
    String topic = 'general',
  }) async {
    if (!_enabled || _currentSessionId == null) return;

    try {
      final msgRef = _firestore
          .collection(_collection)
          .doc(_currentSessionId)
          .collection(_messagesSubcollection)
          .doc();

      await msgRef.set({
        'role': role,
        'text': text,
        'topic': topic,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
      });

      // Actualizar contador y temas en el documento de sesión
      await _firestore.collection(_collection).doc(_currentSessionId).update({
        'messageCount': FieldValue.increment(1),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastTopic': topic,
        'topics': FieldValue.arrayUnion([topic]),
      });
    } catch (e) {
      AppLogger.warning('Firestore save message failed: $e');
      _enabled = false;
    }
  }

  /// Obtiene el historial de mensajes de la sesión actual para el LLM
  static Future<List<Map<String, dynamic>>> getSessionHistory({
    required String userId,
    int limit = 20,
  }) async {
    if (!_enabled || _currentSessionId == null) return [];

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .doc(_currentSessionId)
          .collection(_messagesSubcollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final messages = snapshot.docs
          .map((doc) => {
                'role': doc.data()['role'] as String? ?? 'user',
                'content': doc.data()['text'] as String? ?? '',
                'topic': doc.data()['topic'] as String? ?? 'general',
                'timestamp': (doc.data()['timestamp'] as Timestamp?)?.toDate().millisecondsSinceEpoch ?? 0,
              })
          .toList()
          .reversed
          .toList();

      return messages;
    } catch (e) {
      AppLogger.warning('Firestore get history failed: $e');
      return [];
    }
  }

  /// Busca en TODAS las sesiones del usuario mensajes sobre un tema
  static Future<List<Map<String, dynamic>>> searchAllSessions({
    required String userId,
    required String keyword,
    int limit = 10,
  }) async {
    if (!_enabled) return [];

    try {
      final sessionsSnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('startedAt', descending: true)
          .limit(20)
          .get();

      final results = <Map<String, dynamic>>[];

      for (final sessionDoc in sessionsSnapshot.docs) {
        final messagesSnapshot = await sessionDoc.reference
            .collection(_messagesSubcollection)
            .where('text', isGreaterThanOrEqualTo: keyword)
            .where('text', isLessThanOrEqualTo: '$keyword\uf8ff')
            .limit(limit)
            .get();

        for (final msgDoc in messagesSnapshot.docs) {
          results.add({
            'role': msgDoc.data()['role'] as String? ?? 'user',
            'content': msgDoc.data()['text'] as String? ?? '',
            'topic': msgDoc.data()['topic'] as String? ?? 'general',
            'sessionId': sessionDoc.id,
            'timestamp': (msgDoc.data()['timestamp'] as Timestamp?)?.toDate().millisecondsSinceEpoch ?? 0,
          });
        }

        if (results.length >= limit) break;
      }

      results.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      return results.take(limit).toList();
    } catch (e) {
      AppLogger.warning('Firestore search all sessions failed: $e');
      return [];
    }
  }

  /// Obtiene un resumen de temas tratados en sesiones anteriores
  static Future<String> getTopicsSummary(String userId) async {
    if (!_enabled) return '';

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('startedAt', descending: true)
          .limit(10)
          .get();

      final topics = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final sessionTopics = (data['topics'] as List<dynamic>?)?.cast<String>() ?? [];
        topics.addAll(sessionTopics);
      }

      if (topics.isEmpty) return '';
      return 'Temas conversados en sesiones anteriores: ${topics.take(10).join(", ")}.';
    } catch (e) {
      AppLogger.warning('Firestore topics summary failed: $e');
      return '';
    }
  }

  /// Verifica si un tema ya se ha hablado en conversaciones previas
  static Future<bool> hasTopicBeenDiscussed(String userId, String topic) async {
    if (!_enabled) return false;

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('topics', arrayContains: topic.toLowerCase())
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      AppLogger.warning('Firestore hasTopic failed: $e');
      return false;
    }
  }

  static void disable() => _enabled = false;
  static void enable() => _enabled = true;
  static bool get isEnabled => _enabled;
  static String? get currentSessionId => _currentSessionId;
}