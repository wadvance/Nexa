import 'dart:async';

class CarBluetoothService {
  static bool get isConnected => false;
  static String? get deviceName => null;
  static String? get deviceId => null;

  static Future<String> connectToVehicle() async {
    return 'La conexión Bluetooth a vehículos solo está disponible en navegadores web compatibles (Chrome/Edge con HTTPS).';
  }

  static Future<String> disconnect() async {
    return 'No hay dispositivo conectado.';
  }
}