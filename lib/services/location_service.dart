import 'location_service_stub.dart'
    if (dart.library.js_interop) 'location_service_web.dart';
import 'aetheris_brain.dart';

class LocationService {
  static const String _default = 'Panamá';
  static bool _initialized = false;

  static Future<void> init() async {
    // Solo asignar el default. NO pedir geolocalización al iniciar: en
    // navegadores con Tracking Prevention (Edge/Firefox en algunos modos),
    // eso lanza un Uncaught Error. La ubicación se pide al primer gesto.
    AetherisBrain.locationContext = _default;
    _initialized = true;
  }

  /// Pide la ubicación AHORA — sólo llamar tras un gesto del usuario.
  static Future<void> requestNow() async {
    if (!_initialized) await init();
    try {
      await initLocationWeb(_default).timeout(const Duration(seconds: 6));
    } catch (_) {
      AetherisBrain.locationContext = _default;
    }
  }
}
