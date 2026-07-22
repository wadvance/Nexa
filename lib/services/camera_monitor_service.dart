/// CameraMonitorService — RTSP camera stub.
/// flutter_vlc_player was removed from pubspec.yaml; this service is
/// kept as a placeholder for a future camera integration.
class CameraMonitorService {
  // TODO: integrate an RTSP/camera package when required.

  void connectToCamera(String rtspUrl) {
    // Stub — no active player implementation.
  }

  // Integración con IA: Aetheris puede recibir un "frame" (foto) del video
  // y analizarlo para detectar personas no autorizadas.
  void analyzeFrame() {
    // Aquí tomamos una captura de pantalla del stream y la enviamos a Gemini 1.5 Pro
    // (Multimodalidad: Video/Imagen + Texto)
  }
}
