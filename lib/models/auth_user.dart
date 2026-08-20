class UserProfile {
  final String? id;
  final String? fullName;
  final bool openToMentor;
  final String? approvalStatus;

  UserProfile({
    this.id,
    this.fullName,
    this.openToMentor = false,
    this.approvalStatus,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString(),
      fullName: json['fullName']?.toString(),
      openToMentor: json['openToMentor'] == true || json['openToMentor']?.toString() == 'true',
      approvalStatus: json['approvalStatus']?.toString() ?? json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (fullName != null) 'fullName': fullName,
      'openToMentor': openToMentor,
      if (approvalStatus != null) 'approvalStatus': approvalStatus,
    };
  }
}

class AuthUser {
  final String id;
  final String email;
  final String? role;
  final UserProfile? profile;

  AuthUser({
    required this.id,
    required this.email,
    this.role,
    this.profile,
  });

  bool get isAdmin => role?.toUpperCase() == 'ADMIN';
  bool get isCoordinator => role?.toUpperCase() == 'COORDINATOR';
  bool get isApproved => profile?.approvalStatus?.toUpperCase() == 'APPROVED';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString(),
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (role != null) 'role': role,
      if (profile != null) 'profile': profile!.toJson(),
    };
  }
}
