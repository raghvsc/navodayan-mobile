class CareSession {
  final String id;
  final String title;
  final String? note;
  final String status;
  final List<String> audiences;
  final bool wantsToLearn;
  final bool canLead;
  final String? scheduledAt;
  final String? scheduleNote;
  final List<dynamic> leads;
  final String? createdAt;
  final int consentCount;
  final bool consented;

  CareSession({
    required this.id,
    required this.title,
    this.note,
    this.status = 'OPEN',
    this.audiences = const [],
    this.wantsToLearn = true,
    this.canLead = false,
    this.scheduledAt,
    this.scheduleNote,
    this.leads = const [],
    this.createdAt,
    this.consentCount = 0,
    this.consented = false,
  });

  factory CareSession.fromJson(Map<String, dynamic> json) {
    var rawAudiences = json['audiences'];
    List<String> parsedAudiences = [];
    if (rawAudiences is List) {
      parsedAudiences = rawAudiences.map((e) => e.toString()).toList();
    }

    return CareSession(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      note: json['note']?.toString(),
      status: json['status']?.toString() ?? 'OPEN',
      audiences: parsedAudiences,
      wantsToLearn: json['wantsToLearn'] == true,
      canLead: json['canLead'] == true,
      scheduledAt: json['scheduledAt']?.toString(),
      scheduleNote: json['scheduleNote']?.toString(),
      leads: json['leads'] is List ? json['leads'] : [],
      createdAt: json['createdAt']?.toString(),
      consentCount: json['consentCount'] is num
          ? (json['consentCount'] as num).toInt()
          : int.tryParse(json['consentCount']?.toString() ?? '') ?? 0,
      consented: json['consented'] == true,
    );
  }

  CareSession copyWith({
    int? consentCount,
    bool? consented,
  }) {
    return CareSession(
      id: id,
      title: title,
      note: note,
      status: status,
      audiences: audiences,
      wantsToLearn: wantsToLearn,
      canLead: canLead,
      scheduledAt: scheduledAt,
      scheduleNote: scheduleNote,
      leads: leads,
      createdAt: createdAt,
      consentCount: consentCount ?? this.consentCount,
      consented: consented ?? this.consented,
    );
  }
}

