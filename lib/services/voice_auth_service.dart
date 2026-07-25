import 'owner_guard_service.dart';

/// VoiceAuthService — capa de autorización de voz en tiempo real.
///
/// Cada texto recibido del STT pasa por aquí antes de procesarse.
/// Si el propietario está registrado y el guardia activo, se compara
/// la entrada contra el hash registrado.
///
/// Resultados posibles:
///   • authorized   → coincide con el propietario o guardia desactivado
///   • unauthorized → voz no reconocida, debe mostrarse el warning
///   • unregistered → no hay propietario registrado, pasar sin bloqueo
class VoiceAuthResult {
  final VoiceAuthStatus status;
  final String ownerName;

  const VoiceAuthResult(this.status, {this.ownerName = ''});
}

enum VoiceAuthStatus { authorized, unauthorized, unregistered }

class VoiceAuthService {
  /// Evalúa si [spokenText] proviene del propietario registrado.
  /// Usa un contador de fallos para no bloquear por ruido de fondo accidental.
  static int _failStreak = 0;
  static const int _maxFailsBeforeWarn = 2; // avisar tras 2 frases no reconocidas

  static VoiceAuthResult evaluate(String spokenText) {
    // Sin propietario registrado → acceso libre
    if (!OwnerGuardService.isRegistered) {
      return const VoiceAuthResult(VoiceAuthStatus.unregistered);
    }

    // Guardia desactivado → acceso libre
    if (!OwnerGuardService.isEnabled) {
      return const VoiceAuthResult(VoiceAuthStatus.authorized);
    }

    // Sesión ya verificada en este ciclo → acceso libre
    if (OwnerGuardService.ownerVerified) {
      _failStreak = 0;
      return VoiceAuthResult(
          VoiceAuthStatus.authorized,
          ownerName: OwnerGuardService.ownerName);
    }

    // Intentar verificar con la frase recibida
    final ok = OwnerGuardService.verifyVoice(spokenText);
    if (ok) {
      _failStreak = 0;
      return VoiceAuthResult(
          VoiceAuthStatus.authorized,
          ownerName: OwnerGuardService.ownerName);
    }

    // Frase no coincide — acumular fallos
    _failStreak++;
    if (_failStreak >= _maxFailsBeforeWarn) {
      return VoiceAuthResult(
          VoiceAuthStatus.unauthorized,
          ownerName: OwnerGuardService.ownerName);
    }

    // Primeros fallos: no bloquear todavía (puede ser ruido o frase corta)
    return const VoiceAuthResult(VoiceAuthStatus.authorized);
  }

  /// Resetea el contador de fallos (llamar al verificar manualmente).
  static void resetStreak() => _failStreak = 0;
}
