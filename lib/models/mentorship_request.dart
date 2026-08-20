class MentorshipUser {
  final String email;

  MentorshipUser({required this.email});

  factory MentorshipUser.fromJson(Map<String, dynamic> json) {
    return MentorshipUser(
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'email': email};
}

class MentorshipParticipant {
  final String id;
  final String fullName;
  final String? currentRole;
  final String? batchYear;
  final MentorshipUser? user;

  MentorshipParticipant({
    required this.id,
    required this.fullName,
    this.currentRole,
    this.batchYear,
    this.user,
  });

  factory MentorshipParticipant.fromJson(Map<String, dynamic> json) {
    return MentorshipParticipant(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      currentRole: json['currentRole']?.toString(),
      batchYear: json['batchYear']?.toString(),
      user: json['user'] is Map<String, dynamic>
          ? MentorshipUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      if (currentRole != null) 'currentRole': currentRole,
      if (batchYear != null) 'batchYear': batchYear,
      if (user != null) 'user': user!.toJson(),
    };
  }
}

enum MentorshipStatus { pending, accepted, rejected }

class MentorshipRequest {
  final String id;
  final String requesterId;
  final String mentorId;
  final String message;
  final MentorshipStatus status;
  final DateTime? createdAt;
  final MentorshipParticipant? requester;
  final MentorshipParticipant? mentor;

  MentorshipRequest({
    required this.id,
    required this.requesterId,
    required this.mentorId,
    required this.message,
    required this.status,
    this.createdAt,
    this.requester,
    this.mentor,
  });

  static MentorshipStatus parseStatus(String? statusStr) {
    switch (statusStr?.toUpperCase()) {
      case 'ACCEPTED':
        return MentorshipStatus.accepted;
      case 'REJECTED':
        return MentorshipStatus.rejected;
      case 'PENDING':
      default:
        return MentorshipStatus.pending;
    }
  }

  String get statusString {
    switch (status) {
      case MentorshipStatus.accepted:
        return 'ACCEPTED';
      case MentorshipStatus.rejected:
        return 'REJECTED';
      case MentorshipStatus.pending:
        return 'PENDING';
    }
  }

  factory MentorshipRequest.fromJson(Map<String, dynamic> json) {
    return MentorshipRequest(
      id: json['id']?.toString() ?? '',
      requesterId: json['requesterId']?.toString() ?? '',
      mentorId: json['mentorId']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      status: parseStatus(json['status']?.toString()),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      requester: json['requester'] is Map<String, dynamic>
          ? MentorshipParticipant.fromJson(json['requester'] as Map<String, dynamic>)
          : null,
      mentor: json['mentor'] is Map<String, dynamic>
          ? MentorshipParticipant.fromJson(json['mentor'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterId': requesterId,
      'mentorId': mentorId,
      'message': message,
      'status': statusString,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (requester != null) 'requester': requester!.toJson(),
      if (mentor != null) 'mentor': mentor!.toJson(),
    };
  }
}
