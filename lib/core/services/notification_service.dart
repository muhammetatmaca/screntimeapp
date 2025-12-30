import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Bildirime tıklayınca yapılacak işlem
      },
    );
  }

  static Future<void> showLimitWarning({
    required String appName,
    required int remainingMinutes,
  }) async {
    final String title = '⏳ $appName Sınırına Yaklaştın!';
    final String body = 'Sürenin bitmesine sadece $remainingMinutes dakika kaldı.';

    await _showNotification(id: appName.hashCode, title: title, body: body);
  }

  static Future<void> showLimitReached({
    required String appName,
  }) async {
    final String title = '🚫 $appName Süresi Doldu!';
    final String body = 'Bugün için ayırdığın süreyi tamamladın. Biraz ara vermeye ne dersin?';

    await _showNotification(id: appName.hashCode + 1, title: title, body: body, isCritical: true);
  }

  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    bool isCritical = false,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'limit_notifications',
      'Limit Bildirimleri',
      channelDescription: 'Uygulama kullanım limiti uyarıları',
      importance: isCritical ? Importance.max : Importance.high,
      priority: isCritical ? Priority.high : Priority.defaultPriority,
      showWhen: true,
      color: const Color(0xFF13EC5B),
      ledColor: const Color(0xFF13EC5B),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
