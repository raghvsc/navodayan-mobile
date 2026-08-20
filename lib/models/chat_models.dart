DateTime _parseTimestamp(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  try {
    final dynamic dynamicVal = value;
    if (dynamicVal.toDate != null) {
      return dynamicVal.toDate() as DateTime;
    }
  } catch (_) {}
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

enum ChatRequestStatus {
  pending,
  accepted,
  declined,
}

class ChatRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderRole;
  final String? senderCompany;
  final String receiverId;
  final String receiverName;
  final String? message;
  final ChatRequestStatus status;
  final DateTime createdAt;

  ChatRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderRole,
    this.senderCompany,
    required this.receiverId,
    required this.receiverName,
    this.message,
    this.status = ChatRequestStatus.pending,
    required this.createdAt,
  });

  ChatRequest copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? senderCompany,
    String? receiverId,
    String? receiverName,
    String? message,
    ChatRequestStatus? status,
    DateTime? createdAt,
  }) {
    return ChatRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      senderCompany: senderCompany ?? this.senderCompany,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChatRequest.fromJson(Map<String, dynamic> json) {
    ChatRequestStatus parsedStatus = ChatRequestStatus.pending;
    final statusStr = json['status']?.toString().toLowerCase();
    if (statusStr == 'accepted') parsedStatus = ChatRequestStatus.accepted;
    if (statusStr == 'declined') parsedStatus = ChatRequestStatus.declined;

    return ChatRequest(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? 'Navodayan Member',
      senderRole: json['senderRole']?.toString(),
      senderCompany: json['senderCompany']?.toString(),
      receiverId: json['receiverId']?.toString() ?? '',
      receiverName: json['receiverName']?.toString() ?? 'Navodayan Member',
      message: json['message']?.toString(),
      status: parsedStatus,
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      if (senderRole != null) 'senderRole': senderRole,
      if (senderCompany != null) 'senderCompany': senderCompany,
      'receiverId': receiverId,
      'receiverName': receiverName,
      if (message != null) 'message': message,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'participants': [senderId, receiverId],
    };
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      timestamp: _parseTimestamp(json['timestamp']),
      isRead: json['isRead'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}

class ChatConversation {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantRole;
  final String? participantCompany;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantRole,
    this.participantCompany,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  ChatConversation copyWith({
    String? id,
    String? participantId,
    String? participantName,
    String? participantRole,
    String? participantCompany,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantRole: participantRole ?? this.participantRole,
      participantCompany: participantCompany ?? this.participantCompany,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json, [String? currentUserId]) {
    // If the conversation contains participant mappings
    String partId = json['participantId']?.toString() ?? '';
    String partName = json['participantName']?.toString() ?? 'Navodayan Member';
    String? partRole = json['participantRole']?.toString();
    String? partCompany = json['participantCompany']?.toString();
    int unread = json['unreadCount'] as int? ?? 0;

    if (currentUserId != null && json['participantIds'] is List) {
      final ids = List<String>.from((json['participantIds'] as List).map((e) => e.toString()));
      final otherId = ids.firstWhere((id) => id != currentUserId, orElse: () => partId);
      partId = otherId;

      if (json['participants'] is Map && (json['participants'] as Map).containsKey(otherId)) {
        final otherData = (json['participants'] as Map)[otherId] as Map<String, dynamic>?;
        if (otherData != null) {
          partName = otherData['name']?.toString() ?? partName;
          partRole = otherData['role']?.toString() ?? partRole;
          partCompany = otherData['company']?.toString() ?? partCompany;
        }
      }

      if (json['unreadCounts'] is Map && (json['unreadCounts'] as Map).containsKey(currentUserId)) {
        unread = int.tryParse((json['unreadCounts'] as Map)[currentUserId].toString()) ?? 0;
      }
    }

    return ChatConversation(
      id: json['id']?.toString() ?? '',
      participantId: partId,
      participantName: partName,
      participantRole: partRole,
      participantCompany: partCompany,
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageTime: _parseTimestamp(json['lastMessageTime']),
      unreadCount: unread,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantId': participantId,
      'participantName': participantName,
      if (participantRole != null) 'participantRole': participantRole,
      if (participantCompany != null) 'participantCompany': participantCompany,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
    };
  }
}
