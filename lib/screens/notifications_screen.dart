import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/notification_item.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_actions.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.mentorshipRequest:
      case NotificationType.mentorshipAccepted:
      case NotificationType.mentorshipDeclined:
        return Icons.school_rounded;
      case NotificationType.eventReminder:
      case NotificationType.eventRsvp:
        return Icons.event_available_rounded;
      case NotificationType.chatRequest:
      case NotificationType.chatAccepted:
      case NotificationType.chatMessage:
        return Icons.chat_bubble_rounded;
      case NotificationType.general:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(NotificationType type, ThemePalette colors) {
    switch (type) {
      case NotificationType.mentorshipRequest:
      case NotificationType.mentorshipAccepted:
        return colors.primary;
      case NotificationType.eventReminder:
      case NotificationType.eventRsvp:
        return colors.accent;
      case NotificationType.chatRequest:
      case NotificationType.chatAccepted:
      case NotificationType.chatMessage:
        return colors.secondary;
      case NotificationType.mentorshipDeclined:
        return colors.error;
      case NotificationType.general:
        return colors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.notifications;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  notifProvider.markAllAsRead();
                } else if (value == 'clear_all') {
                  notifProvider.clearAll();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Clear all', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          const CommonAppBarActions(),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 48,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Notifications Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You\'ll be notified about mentorships, events, and chats here.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = notifications[index];
                final icon = _getIconForType(item.type);
                final itemColor = _getColorForType(item.type, colors);
                final timeAgo = DateFormat('MMM d, h:mm a').format(item.createdAt);

                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    notifProvider.deleteNotification(item.id);
                  },
                  child: Material(
                    color: item.isRead ? colors.surface : colors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (!item.isRead) {
                          notifProvider.markAsRead(item.id);
                        }
                        _handleNotificationTap(context, item);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.isRead ? colors.border : colors.primary.withValues(alpha: 0.4),
                            width: item.isRead ? 1 : 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: itemColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: itemColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (!item.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(left: 6),
                                          decoration: BoxDecoration(
                                            color: colors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.body,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    timeAgo,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textSecondary.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationItem item) {
    switch (item.type) {
      case NotificationType.mentorshipRequest:
      case NotificationType.mentorshipAccepted:
      case NotificationType.mentorshipDeclined:
        Navigator.pushNamed(context, '/mentorship');
        break;
      case NotificationType.eventReminder:
      case NotificationType.eventRsvp:
        Navigator.pushNamed(context, '/events');
        break;
      case NotificationType.chatRequest:
      case NotificationType.chatAccepted:
      case NotificationType.chatMessage:
        Navigator.pushNamed(context, '/chats');
        break;
      case NotificationType.general:
        break;
    }
  }
}
