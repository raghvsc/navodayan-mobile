class EventItem {
  final String id;
  final String title;
  final String description;
  final DateTime? eventDate;
  final String location;
  final String? image;
  final int rsvpCount;

  EventItem({
    required this.id,
    required this.title,
    required this.description,
    this.eventDate,
    required this.location,
    this.image,
    this.rsvpCount = 0,
  });

  bool get isUpcoming {
    if (eventDate == null) return false;
    return eventDate!.isAfter(DateTime.now());
  }

  factory EventItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['eventDate'] != null) {
      parsedDate = DateTime.tryParse(json['eventDate'].toString());
    }

    int rsvps = 0;
    if (json['_count'] is Map<String, dynamic>) {
      final countObj = json['_count'] as Map<String, dynamic>;
      rsvps = countObj['eventrsvp'] is int
          ? countObj['eventrsvp'] as int
          : int.tryParse(countObj['eventrsvp']?.toString() ?? '') ?? 0;
    } else if (json['rsvpCount'] != null) {
      rsvps = json['rsvpCount'] is int
          ? json['rsvpCount'] as int
          : int.tryParse(json['rsvpCount'].toString()) ?? 0;
    }

    return EventItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      eventDate: parsedDate,
      location: json['location']?.toString() ?? '',
      image: json['image']?.toString(),
      rsvpCount: rsvps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      if (eventDate != null) 'eventDate': eventDate!.toIso8601String(),
      'location': location,
      if (image != null) 'image': image,
      '_count': {'eventrsvp': rsvpCount},
    };
  }
}
