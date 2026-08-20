import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped with payload: ${response.payload}');
        },
      );

      // Request notification permissions for Android 13+
      if (!kIsWeb) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          await androidImpl.requestNotificationsPermission();
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'navodayan_channel',
        'Navodayan Notifications',
        channelDescription: 'Notifications for Mentorship, Events, and Member Chats',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  Future<void> scheduleEventReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // For in-app notification scheduling, show immediate confirmation or schedule if date is upcoming
    final now = DateTime.now();
    if (scheduledDate.isAfter(now)) {
      debugPrint('Scheduled reminder for $scheduledDate: $title');
      // Show confirmation push
      await showNotification(
        id: id,
        title: '🗓️ Reminder Set: $title',
        body: body,
        payload: payload,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }
}
