import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'conversation_firestore_service.dart';

/// ConversationMemoryService — historial de conversaciones IA-usuario.
///
/// Persistencia dual: local (SharedPreferences) + nube (Firestore).
/// Cada conversación tiene:
///   • role  : 'user' | 'assistant'
///   • text  : contenido del mensaje
///   • topic : dominio detectado (opcional)
///   • ts    : timestamp Unix ms
///
/// La memoria se usa para:
///   1. Mostrar historial en la UI
///   2. Enviar contexto de últimos N turnos al LLM (memoria conversacional)
///   3. Etiquetar y buscar por tema
///   4. Recordar temas ya tratados en sesiones previas (Firestore)
class ConversationMemoryService {
  static const _kKey       = 'aetheris_chat_memory_v2';
  static const int maxItems = 200; // máximo de mensajes almacenados localmente
  static const int contextWindow = 3; // turnos enviados al LLM como contexto

  static List<ChatMessage> _messages = [];
  static bool _loaded = false;
  static String? _currentUserId;

  // ─────────────────────────────────────────────────────────────────────────
  // Inicialización con usuario
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> initUser(String userId) async {
    _currentUserId = userId;
    await ConversationFirestoreService.initSession(userId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Carga y guardado local
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_kKey);
      if (raw != null) {
        final list  = jsonDecode(raw) as List;
        _messages   = list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      _messages = [];
    }
    _loaded = true;
  }

  static Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json  = jsonEncode(_messages.map((m) => m.toJson()).toList());
      await prefs.setString(_kKey, json);
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Agregar mensajes (local + Firestore)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> addUser(String text, {String topic = 'general'}) async {
    await load();
    _messages.add(ChatMessage(role: 'user', text: text, topic: topic));
    _trim();
    await _save();
    if (_currentUserId != null) {
      await ConversationFirestoreService.saveMessage(
        userId: _currentUserId!,
        role: 'user',
        text: text,
        topic: topic,
      );
    }
  }

  static Future<void> addAssistant(String text, {String topic = 'general'}) async {
    await load();
    _messages.add(ChatMessage(role: 'assistant', text: text, topic: topic));
    _trim();
    await _save();
    if (_currentUserId != null) {
      await ConversationFirestoreService.saveMessage(
        userId: _currentUserId!,
        role: 'assistant',
        text: text,
        topic: topic,
      );
    }
  }

  static void _trim() {
    if (_messages.length > maxItems) {
      _messages = _messages.sublist(_messages.length - maxItems);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Consultas
  // ─────────────────────────────────────────────────────────────────────────

  /// Últimos N mensajes del historial (para mostrar en la UI).
  static Future<List<ChatMessage>> recent({int limit = 50}) async {
    await load();
    if (_messages.isEmpty) return [];
    final start = (_messages.length - limit).clamp(0, _messages.length);
    return _messages.sublist(start);
  }

  /// Últimos [contextWindow] mensajes del usuario como contexto,
  /// más un breve resumen de lo que AETHERIS respondió.
  /// No incluimos las respuestas del asistente directamente para
  /// evitar que el modelo las repita (mimesis).
  static Future<List<Map<String, String>>> llmContext() async {
    await load();
    if (_messages.isEmpty) return [];
    final userMsgs = _messages.where((m) => m.role == 'user').toList();
    if (userMsgs.isEmpty) return [];
    final take = userMsgs.length > contextWindow
        ? contextWindow
        : userMsgs.length;
    final window = userMsgs.sublist(userMsgs.length - take);
    return window.map((m) => {'role': m.role, 'content': m.text}).toList();
  }

  /// Resumen corto de los últimos intercambios para dar contexto al modelo.
  /// Incluye un fragmento de lo que AETHERIS dijo para evitar que repita.
  static Future<String> recentSummary() async {
    await load();
    if (_messages.isEmpty) return '';
    final recent = _messages.length > 4
        ? _messages.sublist(_messages.length - 4)
        : _messages;
    final buf = StringBuffer('Historial (últimos mensajes): ');
    for (final m in recent) {
      if (m.role == 'user') {
        buf.write('Tú: "${m.text.substring(0, m.text.length.clamp(0, 40))}". ');
      } else {
        final preview = m.text.substring(0, m.text.length.clamp(0, 60));
        buf.write('Yo: "$preview". ');
      }
    }
    return buf.toString();
  }

  /// Busca mensajes que contengan [keyword] (local + Firestore).
  static Future<List<ChatMessage>> search(String keyword) async {
    await load();
    final kl = keyword.toLowerCase();
    final local = _messages.where((m) => m.text.toLowerCase().contains(kl)).toList();
    
    if (_currentUserId != null) {
      try {
        final firestoreResults = await ConversationFirestoreService.searchAllSessions(
          userId: _currentUserId!,
          keyword: keyword,
        );
        for (final r in firestoreResults) {
          local.add(ChatMessage(
            role: r['role'] as String? ?? 'user',
            text: r['content'] as String? ?? '',
            topic: r['topic'] as String? ?? 'general',
            ts: r['timestamp'] as int? ?? 0,
          ));
        }
      } catch (_) {}
    }
    return local;
  }

  /// Verifica si un tema ya se ha hablado en sesiones previas (Firestore).
  static Future<bool> hasTopicBeenDiscussed(String topic) async {
    if (_currentUserId == null) return false;
    return await ConversationFirestoreService.hasTopicBeenDiscussed(_currentUserId!, topic);
  }

  /// Obtiene resumen de temas de sesiones anteriores para inyectar en prompt.
  static Future<String> pastSessionsSummary() async {
    if (_currentUserId == null) return '';
    return await ConversationFirestoreService.getTopicsSummary(_currentUserId!);
  }

  /// Filtra mensajes por tema.
  static Future<List<ChatMessage>> byTopic(String topic) async {
    await load();
    return _messages.where((m) => m.topic == topic).toList();
  }

  /// Total de mensajes almacenados.
  static Future<int> count() async {
    await load();
    return _messages.length;
  }

  /// Borra todo el historial local.
  static Future<void> clearAll() async {
    _messages = [];
    _loaded   = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }

  /// Resumen estadístico del historial.
  static Future<String> summary() async {
    await load();
    final total   = _messages.length;
    final user    = _messages.where((m) => m.role == 'user').length;
    final bot     = _messages.where((m) => m.role == 'assistant').length;
    if (total == 0) return 'No hay conversaciones registradas.';
    final topics  = <String>{};
    for (final m in _messages) {
      topics.add(m.topic);
    }
    return 'Tienes $total mensajes: $user tuyos y $bot míos. '
        'Temas tratados: ${topics.join(', ')}.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelo de mensaje
// ─────────────────────────────────────────────────────────────────────────────

class ChatMessage {
  final String role;       // 'user' | 'assistant'
  final String text;
  final String topic;
  final int    ts;         // Unix miliseconds

  ChatMessage({
    required this.role,
    required this.text,
    this.topic = 'general',
    int? ts,
  }) : ts = ts ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
    'role':  role,
    'text':  text,
    'topic': topic,
    'ts':    ts,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    role:  j['role']  as String? ?? 'user',
    text:  j['text']  as String? ?? '',
    topic: j['topic'] as String? ?? 'general',
    ts:    j['ts']    as int?    ?? 0,
  );

  /// Texto formateado para la UI.
  String get displayTime {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }

  bool get isUser      => role == 'user';
  bool get isAssistant => role == 'assistant';
}
