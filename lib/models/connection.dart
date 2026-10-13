class ConnectionMember {
  final String id;
  final String? fullName;
  final String? currentRole;
  final String? company;
  final String? location;
  final String? jnvName;
  final String? avatarUrl;

  const ConnectionMember({
    required this.id,
    this.fullName,
    this.currentRole,
    this.company,
    this.location,
    this.jnvName,
    this.avatarUrl,
  });

  factory ConnectionMember.fromJson(Map<String, dynamic> json) {
    return ConnectionMember(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['profile']?['fullName']?.toString(),
      currentRole: json['currentRole']?.toString() ?? json['profile']?['currentRole']?.toString(),
      company: json['company']?.toString() ?? json['profile']?['company']?.toString(),
      location: json['location']?.toString() ?? json['profile']?['location']?.toString(),
      jnvName: json['jnv']?['name']?.toString() ?? json['school']?['name']?.toString(),
      avatarUrl: json['avatarUrl']?.toString() ?? json['profile']?['avatarUrl']?.toString(),
    );
  }
}

class ConnectionItem {
  final String id;
  final String status;
  final String? note;
  final DateTime? createdAt;
  final ConnectionMember? otherMember;

  const ConnectionItem({
    required this.id,
    required this.status,
    this.note,
    this.createdAt,
    this.otherMember,
  });

  factory ConnectionItem.fromJson(Map<String, dynamic> json) {
    final memberData = json['member'] ?? json['requester'] ?? json['recipient'] ?? json['user'];
    return ConnectionItem(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      note: json['note']?.toString() ?? json['message']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      otherMember: memberData is Map<String, dynamic> ? ConnectionMember.fromJson(memberData) : null,
    );
  }
}

class ConnectionsData {
  final List<ConnectionItem> incoming;
  final List<ConnectionItem> outgoing;
  final List<ConnectionItem> accepted;

  const ConnectionsData({
    this.incoming = const [],
    this.outgoing = const [],
    this.accepted = const [],
  });

  factory ConnectionsData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    return ConnectionsData(
      incoming: (data['incoming'] as List<dynamic>?)
              ?.map((e) => ConnectionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      outgoing: (data['outgoing'] as List<dynamic>?)
              ?.map((e) => ConnectionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      accepted: (data['accepted'] as List<dynamic>?)
              ?.map((e) => ConnectionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
