import 'dart:async';
import 'dart:developer';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class CarBluetoothService {
  static StreamSubscription<List<ScanResult>>? _subscription;

  static void connectToVehicle() async {
    // Escanear buscando el ID de tu sistema de infoentretenimiento
    _subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == "CAR_AUDIO_SYSTEM") {
          r.device.connect();
          log("Conectado a sistema de vehículo. Aetheris activo.");
        }
      }
    });
  }

  static void disconnect() {
    _subscription?.cancel();
    _subscription = null;
  }
}