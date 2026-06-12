import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Function(String?)? _onNotificationTap;

  static Future<void> init({Function(String?)? onNotificationTap}) async {
    _onNotificationTap = onNotificationTap;

    if (kIsWeb) {
      return;
    }

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (_onNotificationTap != null) {
          _onNotificationTap!(payload);
        }
      },
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.requestNotificationsPermission();
    }
  }

  static Future<void> showOrUpdateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'main_channel',
          'App Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(id, title, body, details, payload: payload);
  }

  static Future<void> clearAll() async {
    if (kIsWeb) {
      return;
    }
    await _notificationsPlugin.cancelAll();
  }
}
