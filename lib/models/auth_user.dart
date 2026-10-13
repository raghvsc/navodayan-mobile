class UserProfile {
  final String? id;
  final String? userId;
  final String? fullName;
  final int? batchId;
  final String? currentRole;
  final String? company;
  final String? location;
  final bool openToMentor;
  final String? industry;
  final String? imageUrl;
  final String? association;
  final String? postingStatus;
  final String? country;
  final int? jnvId;
  final bool jnvVerified;
  final String? approvalStatus;
  final bool hideFromDirectory;
  final String? profileVisibility;
  final String? emailVisibility;
  final String? phoneVisibility;

  UserProfile({
    this.id,
    this.userId,
    this.fullName,
    this.batchId,
    this.currentRole,
    this.company,
    this.location,
    this.openToMentor = false,
    this.industry,
    this.imageUrl,
    this.association,
    this.postingStatus,
    this.country,
    this.jnvId,
    this.jnvVerified = false,
    this.approvalStatus,
    this.hideFromDirectory = false,
    this.profileVisibility,
    this.emailVisibility,
    this.phoneVisibility,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString(),
      userId: json['userId']?.toString(),
      fullName: json['fullName']?.toString(),
      batchId: json['batchId'] is num
          ? (json['batchId'] as num).toInt()
          : int.tryParse(json['batchId']?.toString() ?? ''),
      currentRole: json['currentRole']?.toString(),
      company: json['company']?.toString(),
      location: json['location']?.toString(),
      openToMentor: json['openToMentor'] == true || json['openToMentor']?.toString() == 'true',
      industry: json['industry']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      association: json['association']?.toString(),
      postingStatus: json['postingStatus']?.toString(),
      country: json['country']?.toString(),
      jnvId: json['jnvId'] is num
          ? (json['jnvId'] as num).toInt()
          : int.tryParse(json['jnvId']?.toString() ?? ''),
      jnvVerified: json['jnvVerified'] == true || json['jnvVerified']?.toString() == 'true',
      approvalStatus: json['approvalStatus']?.toString() ?? json['status']?.toString(),
      hideFromDirectory: json['hideFromDirectory'] == true || json['hideFromDirectory']?.toString() == 'true',
      profileVisibility: json['profileVisibility']?.toString(),
      emailVisibility: json['emailVisibility']?.toString(),
      phoneVisibility: json['phoneVisibility']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      if (fullName != null) 'fullName': fullName,
      if (batchId != null) 'batchId': batchId,
      if (currentRole != null) 'currentRole': currentRole,
      if (company != null) 'company': company,
      if (location != null) 'location': location,
      'openToMentor': openToMentor,
      if (industry != null) 'industry': industry,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (association != null) 'association': association,
      if (postingStatus != null) 'postingStatus': postingStatus,
      if (country != null) 'country': country,
      if (jnvId != null) 'jnvId': jnvId,
      'jnvVerified': jnvVerified,
      if (approvalStatus != null) 'approvalStatus': approvalStatus,
      'hideFromDirectory': hideFromDirectory,
      if (profileVisibility != null) 'profileVisibility': profileVisibility,
      if (emailVisibility != null) 'emailVisibility': emailVisibility,
      if (phoneVisibility != null) 'phoneVisibility': phoneVisibility,
    };
  }
}

class AuthUser {
  final String id;
  final String email;
  final String? role;
  final String? approvalStatus;
  final bool emailVerified;
  final String? createdAt;
  final String? approvedAt;
  final UserProfile? profile;

  AuthUser({
    required this.id,
    required this.email,
    this.role,
    this.approvalStatus,
    this.emailVerified = false,
    this.createdAt,
    this.approvedAt,
    this.profile,
  });

  bool get isAdmin => role?.toUpperCase() == 'ADMIN';
  bool get isCoordinator => role?.toUpperCase() == 'COORDINATOR';
  bool get isApproved =>
      (approvalStatus ?? profile?.approvalStatus)?.toUpperCase() == 'APPROVED';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString(),
      approvalStatus: json['approvalStatus']?.toString() ??
          (json['profile'] is Map ? json['profile']['approvalStatus']?.toString() : null),
      emailVerified: json['emailVerified'] == true || json['emailVerified']?.toString() == 'true',
      createdAt: json['createdAt']?.toString(),
      approvedAt: json['approvedAt']?.toString(),
      profile: json['profile'] is Map<String, dynamic>
          ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (role != null) 'role': role,
      if (approvalStatus != null) 'approvalStatus': approvalStatus,
      'emailVerified': emailVerified,
      if (createdAt != null) 'createdAt': createdAt,
      if (approvedAt != null) 'approvedAt': approvedAt,
      if (profile != null) 'profile': profile!.toJson(),
    };
  }
}
