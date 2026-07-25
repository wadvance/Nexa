import 'dart:developer' as dev;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// NotificationService — notificaciones locales para alertas proactivas.
///
/// • En móvil (Android/iOS) usa flutter_local_notifications real.
/// • En web (kIsWeb) hace fallback a console.log, porque las notificaciones
///   en navegador requieren un Service Worker separado fuera de scope de
///   esta tarea. Se avisa al programador para completar el puente si se
///   quiere PWA push real.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'aetheris_alerts';
  static const _channelName = 'AETHERIS Alertas';
  static const _channelDesc =
      'Alertas proactivas de peligros cercanos y avisos del sistema.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      dev.log('NotificationService: web → usando console fallback');
      _initialized = true;
      return;
    }
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios     = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(const InitializationSettings(
        android: android, iOS: ios,
      ));
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _initialized = true;
    } catch (e) {
      dev.log('NotificationService init error: $e');
    }
  }

  Future<void> notifyHazard({
    required String title,
    required String body,
  }) async {
    await init();
    if (kIsWeb) {
      dev.log('NotificationService[web-fallback] $title — $body');
      return;
    }
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff),
        title,
        body,
        details,
      );
    } catch (e) {
      dev.log('NotificationService.show error: $e');
    }
  }
}
