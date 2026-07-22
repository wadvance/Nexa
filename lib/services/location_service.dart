import 'location_service_stub.dart'
    if (dart.library.js_interop) 'location_service_web.dart';
import 'aetheris_brain.dart';

class LocationService {
  static const String _default = 'Panamá';

  static Future<void> init() async {
    AetherisBrain.locationContext = _default;
    try {
      await initLocationWeb(_default).timeout(const Duration(seconds: 6));
    } catch (_) {
      AetherisBrain.locationContext = _default;
    }
  }
}
