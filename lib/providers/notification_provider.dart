import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _storageKey = 'navodayan_notifications';

  final NotificationService _notificationService = NotificationService();
  List<NotificationItem> _notifications = [];
  bool _loading = true;

  NotificationProvider() {
    _init();
  }

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get loading => _loading;

  Future<void> _init() async {
    await _notificationService.init();
    await _loadFromStorage();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored != null && stored.isNotEmpty) {
        final List decoded = jsonDecode(stored) as List;
        _notifications = decoded
            .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // Add helpful welcome sample notifications if none exist
        _notifications = [
          NotificationItem(
            id: 'sample_welcome',
            title: 'Welcome to Navodayan Community',
            body: 'Connect with alumni worldwide, join mentorship programs, and attend events.',
            type: NotificationType.general,
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
            isRead: false,
          ),
        ];
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    bool showPush = true,
  }) async {
    final newItem = NotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
      data: data,
    );

    _notifications.insert(0, newItem);
    notifyListeners();
    await _saveToStorage();

    if (showPush) {
      await _notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        payload: jsonEncode(data ?? {}),
      );
    }
  }

  Future<void> scheduleEventReminder({
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    required String location,
  }) async {
    final title = 'Event Reminder: $eventTitle';
    final body = 'Upcoming event on ${eventDate.day}/${eventDate.month} at $location. Don\'t forget to attend!';

    // Add to notification list
    await addNotification(
      title: 'RSVP Confirmed: $eventTitle',
      body: 'You have RSVP\'d to $eventTitle. A reminder notification has been scheduled.',
      type: NotificationType.eventRsvp,
      data: {'eventId': eventId, 'eventTitle': eventTitle},
      showPush: true,
    );

    // Schedule local push
    await _notificationService.scheduleEventReminder(
      id: eventId.hashCode,
      title: title,
      body: body,
      scheduledDate: eventDate,
      payload: jsonEncode({'eventId': eventId}),
    );
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    await _saveToStorage();
  }
}
