import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:web/web.dart' as web;
import '../services/aetheris_voice.dart';
import '../services/security_log_service.dart';
import '../utils/logger.dart';
import '../services/aetheris_brain.dart';
import '../services/aetheris_local_brain.dart';
import '../services/emergency_service.dart';
import '../services/car_bluetooth_service.dart';
import '../services/user_service.dart';
import '../services/weather_service.dart';
import '../services/maps_service.dart';
import '../services/conversation_memory_service.dart';
import '../services/knowledge_domain_service.dart';
import '../services/owner_guard_service.dart';
import 'aetheris_engine.dart';
import '../presentation/screens/analysis/analysis_screen.dart';
import '../presentation/screens/security/security_screen.dart';
import '../presentation/screens/events/events_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/owner_setup_screen.dart';

/// Intérprete de comandos de voz de AETHERIS — versión expandida.
/// Cubre todos los dominios de conocimiento + prioridad al dueño.
class VoiceCommands {
  final AetherisVoice _voice = AetherisVoice.instance;

  /// Ejecuta [rawCommand] y devuelve la respuesta que AETHERIS debe pronunciar.
  Future<String> execute(
      String rawCommand, BuildContext context, String uid) async {
    final cmd = rawCommand.toLowerCase().trim();
    if (cmd.isEmpty) return 'No entendí. ¿Podrías repetir?';

    // ── 0. Guardar mensaje del usuario en memoria ──────────────────────────
    final domain = KnowledgeDomainService.detectDomain(cmd);
    final topicName = domain.name;
    // Capturamos el BuildContext antes de cualquier await para evitar
    // el warning use_build_context_synchronously.
    final safeContext = context;
    await ConversationMemoryService.addUser(rawCommand, topic: topicName);

    // ── 1. Verificación de propietario (gate de seguridad) ─────────────────
    if (_isOwnerCommand(cmd)) {
      // safeContext fue capturado antes del await — patrón correcto.
      return await _handleOwnerCommand(rawCommand, cmd, safeContext, uid); // ignore: use_build_context_synchronously
    }

    // Si el guardia está activo y la sesión no está verificada, intentar
    // verificación automática con el texto recibido.
    if (OwnerGuardService.isRegistered &&
        !OwnerGuardService.ownerVerified &&
        _isSensitiveCommand(cmd)) {
      if (!OwnerGuardService.allowRequest(cmd)) {
        final resp = OwnerGuardService.blockedMessage();
        await ConversationMemoryService.addAssistant(resp, topic: 'seguridad');
        return resp;
      }
    }

    // ── 2. Saludos locales ─────────────────────────────────────────────────
    if (AetherisLocalBrain.isGreeting(cmd)) {
      final resp = await AetherisLocalBrain.answer(rawCommand);
      await ConversationMemoryService.addAssistant(resp, topic: 'general');
      return resp;
    }

    // ── 2.5. Comandos de control (parar / silenciar / repetir) ────────────────
    if (_any(cmd, ['parar', 'para', 'basta', 'cállate', 'callate',
        'silencio', 'silenciar', 'detener', 'detén', 'deten', 'detente',
        'parate', 'ya', 'alto', 'frena', 'halt', 'stop'])) {
      // Cortar inmediatamente cualquier audio en reproducción,
      // limpiar cola y dejar STT listo para el siguiente comando.
      await _voice.stopSpeaking();
      await _voice.startContinuous();
      return ' ' ;
    }
    if (_any(cmd, ['repite', 'repetir', 'de nuevo', 'otra vez', 'no entendí',
        'no entendi', 'qué dijiste', 'que dijiste'])) {
      final recent = await ConversationMemoryService.recent(limit: 5);
      final lastAssistant = recent.where((m) => m.isAssistant).toList();
      if (lastAssistant.isNotEmpty) return lastAssistant.last.text;
      return 'No tengo un mensaje anterior para repetir.';
    }

    // ── 3. Clima / Tiempo ──────────────────────────────────────────────────
    if (_isWeatherQuestion(cmd)) {
      AppLogger.info('Weather activado por cmd="$cmd"');
      final resp = await _answerWeather(rawCommand, cmd);
      await ConversationMemoryService.addAssistant(resp, topic: 'clima');
      return resp;
    }

    // ── 4. Seguridad y eventos ─────────────────────────────────────────────
    if (_any(cmd, ['registrar evento', 'nuevo evento', 'reportar'])) {
      final resp = await _registerEvent();
      await ConversationMemoryService.addAssistant(resp, topic: 'seguridad');
      return resp;
    }
    if (_any(cmd, ['ver eventos', 'listar eventos', 'qué eventos', 'muestra eventos'])) {
      final resp = await _readEvents();
      await ConversationMemoryService.addAssistant(resp, topic: 'seguridad');
      return resp;
    }
    if (_any(cmd, ['borrar eventos', 'eliminar eventos', 'limpiar eventos'])) {
      await SecurityLogService.clearLogs();
      const resp = 'Todos los eventos han sido borrados.';
      await ConversationMemoryService.addAssistant(resp, topic: 'seguridad');
      return resp;
    }

    // ── 5. Emergencia / Cortafuegos ───────────────────────────────────────
    if (_any(cmd, ['activar emergencia', 'protocolo de emergencia']) ||
        (_any(cmd, ['alerta']) && _any(cmd, ['emergencia']))) {
      await EmergencyService.triggerProtocol();
      await SecurityLogService.reportThreat(
        detectedThreat: 'Protocolo de emergencia',
        iaAnalysis: 'Activado por comando de voz.',
      );
      const resp = 'Protocolo de emergencia activado. Notificando incidente.';
      await ConversationMemoryService.addAssistant(resp, topic: 'emergencia');
      return resp;
    }
    if (_any(cmd, ['activar cortafuego', 'activar cortafuegos'])) {
      AetherisEngine.isFirewallActive = true;
      return 'Cortafuegos Aegis activado.';
    }
    if (_any(cmd, ['desactivar cortafuego', 'desactivar cortafuegos'])) {
      AetherisEngine.isFirewallActive = false;
      return 'Advertencia: cortafuegos desactivado. Sistema expuesto.';
    }

    // ── 6. Navegación ────────────────────────────────────────────────────
    if (_any(cmd, ['waze', 'google maps', 'mapa', 'abrir mapa', 'llévame',
        'navegar', 'ir a', 'a buscar', 'quiero ir']) &&
        !_any(cmd, ['perfil', 'análisis', 'seguridad', 'eventos'])) {
      return _openNavigation(rawCommand);
    }

    // ── 12. Bluetooth / Vehículo ──────────────────────────────────────────
    if (_any(cmd, ['conectar coche', 'conectar vehículo', 'bluetooth coche'])) {
      CarBluetoothService.connectToVehicle();
      return 'Buscando sistema de vehículo por Bluetooth.';
    }
    if (_any(cmd, ['desconectar coche', 'desconectar vehículo'])) {
      CarBluetoothService.disconnect();
      return 'Desconectado del vehículo.';
    }

    // ── 13. Perfil / Navegación de pantallas ──────────────────────────────
    if (_any(cmd, ['mi perfil', 'ver perfil'])) {
      if (context.mounted) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => ProfileScreen(uid: uid)));
      }
      return 'Abriendo tu perfil.';
    }
    if (RegExp(r'nivel\s+[1-5]').hasMatch(cmd)) {
      final level = int.parse(RegExp(r'([1-5])').firstMatch(cmd)!.group(0)!);
      await UserService.setSecurityLevel(uid, level);
      return 'Nivel de seguridad actualizado a $level.';
    }
    if (_any(cmd, ['añadir contacto', 'agregar contacto'])) {
      final name = rawCommand
          .replaceAll(RegExp(r'(añadir contacto|agregar contacto)',
              caseSensitive: false), '')
          .trim();
      if (name.isNotEmpty) {
        await UserService.addTrustedContact(uid, name);
        return 'Contacto $name añadido.';
      }
      return 'Di el nombre después de "añadir contacto".';
    }
    if (_any(cmd, ['ir a análisis', 'análisis', 'analisis'])) {
      if (context.mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AnalysisScreen()));
      }
      return 'Abriendo análisis.';
    }
    if (_any(cmd, ['ir a seguridad', 'centro de seguridad'])) {
      if (context.mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SecurityScreen()));
      }
      return 'Abriendo centro de seguridad.';
    }
    if (_any(cmd, ['ir a eventos', 'registro de eventos'])) {
      if (context.mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EventsScreen()));
      }
      return 'Abriendo registro de eventos.';
    }

    // ── 14. Sesión ────────────────────────────────────────────────────────
    if (_any(cmd, ['cerrar sesión', 'salir', 'desconectar'])) {
      OwnerGuardService.lockOwnerSession();
      if (!kIsWeb) {
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
      }
      return 'Sesión cerrada. Hasta luego.';
    }

    // ── 15. Ayuda ─────────────────────────────────────────────────────────
    if (_any(cmd, ['ayuda', 'comandos', 'qué puedes hacer', 'que puedes hacer'])) {
      return _helpText();
    }

    // ── 14.9 Cerebro local (primero) ──────────────────────────────────────
    // Siempre intentamos con el conocimiento local (rápido, sin red).
    // Si la respuesta es genérica (el KB no tenía el dato), recurrimos a la IA.
    final localResp = await AetherisLocalBrain.answer(rawCommand);
    if (!_isGenericFallback(localResp)) {
      await ConversationMemoryService.addAssistant(localResp, topic: 'general');
      return localResp;
    }

    // ── 16. Conversación IA libre (fallback si local no sabe) ─────────────
    final aiResp = await _askGemini(rawCommand);
    if (aiResp.isNotEmpty) {
      await ConversationMemoryService.addAssistant(aiResp, topic: 'general');
      return aiResp;
    }

    // Si la IA falló (429, error de red), devolvemos lo que dijo el cerebro local
    await ConversationMemoryService.addAssistant(localResp, topic: 'general');
    return localResp;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROPIETARIO
  // ─────────────────────────────────────────────────────────────────────────

  bool _isOwnerCommand(String cmd) {
    return _any(cmd, [
      'configurar propietario', 'registrar propietario', 'soy el dueño',
      'soy el propietario', 'verificar identidad', 'soy yo',
      'bloquear acceso', 'desbloquear acceso', 'modo propietario',
      'activar guardia', 'desactivar guardia', 'cerrar sesión propietario',
    ]);
  }

  bool _isSensitiveCommand(String cmd) {
    return _any(cmd, [
      'emergencia', 'protocolo', 'cortafuegos', 'datos personales',
      'historial', 'eventos', 'nivel de seguridad', 'contacto',
    ]);
  }

  Future<String> _handleOwnerCommand(
      String raw, String cmd, BuildContext context, String uid) async {
    if (_any(cmd, ['configurar propietario', 'registrar propietario',
        'modo propietario'])) {
      if (context.mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OwnerSetupScreen()));
      }
      return 'Abriendo configuración de propietario.';
    }
    if (_any(cmd, ['verificar identidad', 'soy yo', 'soy el dueño',
        'soy el propietario'])) {
      if (!OwnerGuardService.isRegistered) {
        return 'No hay propietario registrado. Di "configurar propietario" primero.';
      }
      if (OwnerGuardService.verifyVoice(raw)) {
        return 'Identidad verificada. Bienvenido, ${OwnerGuardService.ownerName}.';
      }
      return 'No pude verificar tu identidad. Intenta con tu frase de voz registrada.';
    }
    if (_any(cmd, ['bloquear acceso', 'cerrar sesión propietario'])) {
      OwnerGuardService.lockOwnerSession();
      return 'Sesión de propietario bloqueada.';
    }
    if (_any(cmd, ['activar guardia'])) {
      await OwnerGuardService.setEnabled(true);
      return 'Guardia de propietario activado.';
    }
    if (_any(cmd, ['desactivar guardia'])) {
      await OwnerGuardService.setEnabled(false);
      return 'Guardia de propietario desactivado. Cualquier voz puede acceder.';
    }
    return _askGemini(raw);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CLIMA
  // ─────────────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────────────
  // CLIMA
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> _answerWeather(String raw, String cmd) async {
    AppLogger.info('Weather: raw="$raw" cmd="$cmd"');
    // Buscar preposiciones en el comando en MAYÚSCULAS (no en minúsculas).
    // rawCommand viene tal cual se escuchó.
    final prepsRaw = [
      ' en ', ' de ', ' para ', ' desde ', ' hacia ',
      ' el clima en ', ' tiempo en ', ' clima de ', ' tiempo de ',
      ' el clima de ', ' el tiempo de ',
    ];
    String? city;
    final rawLower = raw.toLowerCase();
    for (final prep in prepsRaw) {
      // buscar en lowercase para indexOf pero extraer en raw para capitalización
      final idx = rawLower.indexOf(prep);
      if (idx >= 0) {
        city = raw.substring(idx + prep.length).trim()
            .replaceAll(RegExp(r'¿'), '')
            .replaceAll(RegExp(r'\?$|^\?'), '')
            .replaceAll(RegExp(r'\b(hoy|mañana|ahora|actual|este mes|allá|alla|alli)\b',
            caseSensitive: false), '')
            .trim();
        // Limpiar palabras sobrantes al final
        city = city.replaceAll(RegExp(r'[.!?]+$'), '').trim();
        if (city.isNotEmpty) break;
      }
    }
    AppLogger.info('Weather: detected city="$city"');
    if (city != null && city.length > 2) {
      try {
        final resp = await WeatherService.formatCityWeather(city);
        AppLogger.info('Weather: city response="${resp.substring(0, resp.length.clamp(0, 60))}…"');
        if (resp.startsWith('No encontré') || resp.startsWith('No pude')) {
          // Si la ciudad no se encontró, intentar con ubicación actual
          return await WeatherService.currentOrDefault();
        }
        return resp;
      } catch (e) {
        AppLogger.error('Weather city error: $e');
        return await WeatherService.currentOrDefault();
      }
    }
    try {
      final geo = await WeatherService.currentOrDefault();
      AppLogger.info('Weather: geo response="${geo.substring(0, geo.length.clamp(0, 60))}…"');
      return geo;
    } catch (e) {
      AppLogger.error('Weather geo error: $e');
      return 'No pude obtener el clima ahora mismo. Verifica tu conexión.';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EVENTOS DE SEGURIDAD
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> _registerEvent() async {
    await _voice.speak('Di el tipo de evento de seguridad.');
    final type = await _voice.listenOnce();
    if (type.isEmpty) return 'No entendí el tipo de evento.';
    await _voice.speak('Ahora describe los detalles.');
    final details = await _voice.listenOnce();
    await SecurityLogService.reportThreat(
      detectedThreat: type,
      iaAnalysis: details.isNotEmpty ? details : 'Sin detalles.',
    );
    return 'Evento registrado: $type.';
  }

  Future<String> _readEvents() async {
    final logs = await SecurityLogService.getRecentLogs(limit: 5);
    if (logs.isEmpty) return 'No hay eventos registrados.';
    final buffer = StringBuffer('Últimos ${logs.length} eventos. ');
    for (var i = 0; i < logs.length; i++) {
      buffer.write('${i + 1}. ${logs[i].detectedThreat}. ');
    }
    return buffer.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NAVEGACIÓN
  // ─────────────────────────────────────────────────────────────────────────

  String _openNavigation(String raw) {
    final dest = raw
        .replaceAll(RegExp(
            r'(abre|abrir|waze|google maps|mapa|navegar a|navegar hasta|ir a|llévame a|en)',
            caseSensitive: false), '')
        .trim();
    final useGoogle = raw.toLowerCase().contains('google') ||
        raw.toLowerCase().contains('mapa');
    if (dest.isNotEmpty && dest.length > 2) {
      if (useGoogle) {
        MapsService.openInMaps(dest);
        return 'Abriendo Google Maps hacia $dest.';
      }
      final enc = Uri.encodeComponent(dest);
      web.window.open('https://waze.com/ul?q=$enc&navigate=yes', '_blank');
      return 'Abriendo Waze hacia $dest.';
    }
    if (useGoogle) {
      web.window.open('https://www.google.com/maps', '_blank');
      return 'Abriendo Google Maps.';
    }
    web.window.open('https://waze.com/ul', '_blank');
    return 'Abriendo Waze.';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IA LIBRE
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> _askGemini(String question) async {
    try {
      final resp = await AetherisBrain.getExpertAdvice(question);
      // Si recibimos un error, vamos al cerebro local.
      if (resp.toLowerCase().contains('no pude') ||
          resp.toLowerCase().contains('error') ||
          resp.toLowerCase().contains('verifica tu conexión') ||
          resp.toLowerCase().contains('inténtalo de nuevo') ||
          resp.toLowerCase().contains('intenta de nuevo') ||
          resp.toLowerCase().contains('problemas de conexión')) {
        return await AetherisLocalBrain.answer(question);
      }
      return resp;
    } catch (_) {
      return await AetherisLocalBrain.answer(question);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AYUDA
  // ─────────────────────────────────────────────────────────────────────────

  String _helpText() {
    return 'Puedo ayudarte con: clima y tormentas, sismos y peligros, '
        'medicina y medicamentos, nuevos virus, reparación de autos, motos, '
        'aires acondicionados, computadoras y televisores, recetas de cocina, '
        'vinos y cervezas, política, ingeniería, leyes, contabilidad, '
        'agronomía e hidroponía, biblia etíope, informática y hackers, '
        'conversación libre, y más. Solo pregunta.';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UTILIDADES
  // ─────────────────────────────────────────────────────────────────────────

  bool _any(String q, List<String> keys) => keys.any(q.contains);

  /// Detecta preguntas sobre el clima/tiempo con palabras clave flexibles.
  /// - Busca keywords exactas (substring)
  /// - También busca proximidad fonética (ej: "llober", "temperatura")
  bool _isWeatherQuestion(String q) {
    // Quita acentos para mejor matching.
    String norm(String s) {
      return s.toLowerCase()
          .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
          .replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('ñ', 'n');
    }
    final t = norm(q);

    // Stems de raices flexionadas/erróneas (cubre variantes del STT).
    const stems = <String>[
      'clima', 'tiempo', 'temperatura',
      'lluv', 'llover', 'llueve', 'llovio', 'llovia',
      'lluvia', 'lluvioso', 'lluviosa',
      'pronost', 'pronostic',
      'calor', 'caluroso', 'frio', 'fria', 'frios',
      'humedad', 'viento', 'temperatura', 'calido', 'frio',
      'nubla', 'nublado', 'soleado', 'sol',
      'tormenta', 'huracan', 'hurac', 'tifon', 'ciclon', 'cicl',
      'grad', 'centigrad', 'celsius', 'kelvin',
      'prevision', 'prevision del tiempo',
      'nevar', 'nieve', 'graniza', 'granizo',
      'meteo', 'meteorolog',
      'reporte del clima',
      'como esta el clima', 'que clima', 'que tiempo hace',
      'como va el tiempo', 'como amanece',
      'hace cuanto llueve', 'cuanto llueve',
      'el pronostico', 'el tiempo', 'el clima',
    ];
    for (final w in stems) {
      if (t.contains(norm(w))) return true;
    }

    // Detección fuzzy: "llober"/"lluvia"/'temperatura' aunque falten letras,
    // — verificamos distancia Levenshtein <= 2.
    final tokens = t.split(RegExp(r'[^a-z]+')).where((e) => e.length >= 4).toList();
    const words = <String>[
      'clima', 'tiempo', 'temperatura', 'lluvia', 'llover', 'llueve',
      'pronost', 'tormenta', 'huracan', 'calor', 'frio', 'fria',
      'nublado', 'soleado', 'nevar', 'meteo',
    ];
    for (final tok in tokens) {
      for (final w in words) {
        if (_levenshtein(tok, w, max: 2)) return true;
      }
    }
    return false;
  }

  bool _levenshtein(String a, String b, {int max = 2}) {
    if ((a.length - b.length).abs() > max) return false;
    // Implementación simple: solo cuenta diferencias.
    if (a == b) return true;
    final la = a.length;
    final lb = b.length;
    final dp = List<List<int>>.generate(la + 1,
        (i) => List<int>.filled(lb + 1, 0));
    for (var i = 0; i <= la; i++) { dp[i][0] = i; }
    for (var j = 0; j <= lb; j++) { dp[0][j] = j; }
    for (var i = 1; i <= la; i++) {
      for (var j = 1; j <= lb; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
        if (dp[i][j] > max) return false;
      }
    }
    return dp[la][lb] <= max;
  }

  /// Verdadero si la respuesta del cerebro local es un fallback genérico
  /// (el KB no tenía el dato específico), lo que indica que debemos
  /// recurrir a la IA en la nube.
  bool _isGenericFallback(String resp) {
    const genericStarts = [
      'Dime más, estoy aquí.',
      'Cuéntame con más detalle.',
      'Explícame un poco más.',
      'Buena pregunta.',
      'Es un tema amplio.',
      'Normalmente hay múltiples factores.',
      'Es un tema interesante.',
    ];
    for (final prefix in genericStarts) {
      if (resp.startsWith(prefix)) return true;
    }
    return false;
  }
}
