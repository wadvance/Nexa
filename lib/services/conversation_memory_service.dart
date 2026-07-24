import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ConversationMemoryService — historial de conversaciones IA-usuario.
///
/// Persistencia local vía SharedPreferences (sin necesidad de Firestore
/// para el historial de chat). Cada conversación tiene:
///   • role  : 'user' | 'assistant'
///   • text  : contenido del mensaje
///   • topic : dominio detectado (opcional)
///   • ts    : timestamp Unix ms
///
/// La memoria se usa para:
///   1. Mostrar historial en la UI
///   2. Enviar contexto de últimos N turnos al LLM (memoria conversacional)
///   3. Etiquetar y buscar por tema
class ConversationMemoryService {
  static const _kKey       = 'aetheris_chat_memory_v2';
  static const int maxItems = 200; // máximo de mensajes almacenados localmente
  static const int contextWindow = 1; // turnos enviados al LLM como contexto

  static List<ChatMessage> _messages = [];
  static bool _loaded = false;

  // ─────────────────────────────────────────────────────────────────────────
  // Carga y guardado
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
  // Agregar mensajes
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> addUser(String text, {String topic = 'general'}) async {
    await load();
    _messages.add(ChatMessage(role: 'user', text: text, topic: topic));
    _trim();
    await _save();
  }

  static Future<void> addAssistant(String text, {String topic = 'general'}) async {
    await load();
    _messages.add(ChatMessage(role: 'assistant', text: text, topic: topic));
    _trim();
    await _save();
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

  /// Últimos [contextWindow] mensajes del usuario (sin las respuestas del AI)
  /// formateados para enviar al LLM. Si el AI ve sus propias respuestas, las
  /// repite. Por eso filtramos: solo contexto del usuario.
  /// Devuelve lista de maps [{role, content}].
  static Future<List<Map<String, String>>> llmContext() async {
    await load();
    if (_messages.isEmpty) return [];
    // Solo mensajes del usuario (excluir respuestas del AI para evitar mimesis)
    final userMsgs = _messages.where((m) => m.role == 'user').toList();
    if (userMsgs.isEmpty) return [];
    final take = userMsgs.length > contextWindow
        ? contextWindow
        : userMsgs.length;
    final window = userMsgs.sublist(userMsgs.length - take);
    return window.map((m) => {'role': m.role, 'content': m.text}).toList();
  }

  /// Busca mensajes que contengan [keyword].
  static Future<List<ChatMessage>> search(String keyword) async {
    await load();
    final kl = keyword.toLowerCase();
    return _messages.where((m) => m.text.toLowerCase().contains(kl)).toList();
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

  /// Borra todo el historial.
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
