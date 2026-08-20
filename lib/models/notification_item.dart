enum NotificationType {
  mentorshipRequest,
  mentorshipAccepted,
  mentorshipDeclined,
  eventReminder,
  eventRsvp,
  chatRequest,
  chatAccepted,
  chatMessage,
  general,
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    NotificationType parsedType = NotificationType.general;
    final typeStr = json['type']?.toString();
    if (typeStr != null) {
      for (final val in NotificationType.values) {
        if (val.name == typeStr) {
          parsedType = val;
          break;
        }
      }
    }

    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: parsedType,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] == true,
      data: json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      if (data != null) 'data': data,
    };
  }
}
