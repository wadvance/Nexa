import 'dart:async';
import 'dart:developer' as dev;
import 'dart:js_interop';

@JS('navigator.bluetooth')
external _Bluetooth? _getBluetooth();

extension type _BluetoothDevice._(JSObject _) implements JSObject {
  external String get id;
  external String? get name;
  external _BluetoothRemoteGATTServer get gatt;
}

extension type _BluetoothRemoteGATTServer._(JSObject _) implements JSObject {
  external bool get connected;
  external JSPromise connect();
  external void disconnect();
}

extension type _Bluetooth._(JSObject _) implements JSObject {
  external JSPromise requestDevice(JSObject options);
}

class CarBluetoothService {
  static _BluetoothDevice? _device;
  static bool _connecting = false;

  static bool get isConnected => _device != null;

  static String? get deviceName => _device?.name;

  static String? get deviceId => _device?.id;

  static Future<String> connectToVehicle() async {
    if (_connecting) return 'Ya estoy buscando un dispositivo...';
    if (_device != null) return 'Ya estoy conectado a ${_device!.name ?? "un dispositivo"}.';

    final bt = _getBluetooth();
    if (bt == null) {
      return 'Bluetooth no disponible en este navegador. '
          'Usa Chrome o Edge e intenta con HTTPS.';
    }

    try {
      _connecting = true;
      dev.log('CarBluetooth: Solicitando dispositivo BT...');

      final device = await bt.requestDevice({
        'acceptAllDevices': true,
        'optionalServices': [
          '0000180a-0000-1000-8000-00805f9b34fb', // Device Information
          '0000181a-0000-1000-8000-00805f9b34fb', // Environmental Sensing
          '0000ffe0-0000-1000-8000-00805f9b34fb', // ELM327 OBD2
          '0000fff0-0000-1000-8000-00805f9b34fb', // OBD2 alternate
        ],
      }.toJSBox).toDart as _BluetoothDevice;

      _device = device;
      dev.log('CarBluetooth: Dispositivo seleccionado: ${device.name} (${device.id})');

      final server = device.gatt;
      await server.connect().toDart;
      dev.log('CarBluetooth: Conectado a GATT server');

      return 'Conectado a ${device.name ?? "dispositivo Bluetooth"}. '
          'Ahora puedes pedirme datos del vehículo.';
    } catch (e) {
      dev.log('CarBluetooth: Error: $e');
      _device = null;
      return 'No pude conectar: $e. Asegúrate de tener un adaptador OBD2 '
          'Bluetooth emparejado y cerca.';
    } finally {
      _connecting = false;
    }
  }

  static Future<String> disconnect() async {
    if (_device == null) return 'No hay dispositivo conectado.';
    try {
      _device!.gatt.disconnect();
      dev.log('CarBluetooth: Desconectado');
      _device = null;
      return 'Desconectado del vehículo.';
    } catch (e) {
      _device = null;
      return 'Error al desconectar: $e';
    }
  }
}
