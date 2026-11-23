import 'school.dart';
import 'batch.dart';
import 'auth_user.dart';

class ProfileSkill {
  final String? id;
  final String name;

  ProfileSkill({this.id, required this.name});

  factory ProfileSkill.fromJson(dynamic json) {
    if (json is String) {
      return ProfileSkill(name: json);
    }
    if (json is Map<String, dynamic>) {
      final skillObj = json['skill'] is Map<String, dynamic> ? json['skill'] as Map<String, dynamic> : json;
      return ProfileSkill(
        id: skillObj['id']?.toString(),
        name: skillObj['name']?.toString() ?? '',
      );
    }
    return ProfileSkill(name: json?.toString() ?? '');
  }

  Map<String, dynamic> toJson() => {'name': name};
}

class Profile {
  final String id;
  final String? userId;
  final String fullName;
  final String? currentRole;
  final String? company;
  final String? location;
  final String? country;
  final String? association;
  final String? postingStatus;
  final bool openToMentor;
  final String? industry;
  final String? experience;
  final String? bio;
  final String? imageUrl;
  final School? jnv;
  final Batch? batch;
  final List<ProfileSkill> skills;
  final bool jnvVerified;
  final String? approvalStatus;
  final String profileVisibility;
  final String emailVisibility;
  final String phoneVisibility;
  final String workPhoneVisibility;
  final String addressVisibility;
  final String workAddressVisibility;
  final String educationVisibility;

  Profile({
    required this.id,
    this.userId,
    required this.fullName,
    this.currentRole,
    this.company,
    this.location,
    this.country,
    this.association,
    this.postingStatus,
    this.openToMentor = false,
    this.industry,
    this.experience,
    this.bio,
    this.imageUrl,
    this.jnv,
    this.batch,
    this.skills = const [],
    this.jnvVerified = false,
    this.approvalStatus,
    this.profileVisibility = 'PUBLIC',
    this.emailVisibility = 'NONE',
    this.phoneVisibility = 'NONE',
    this.workPhoneVisibility = 'NONE',
    this.addressVisibility = 'NONE',
    this.workAddressVisibility = 'NONE',
    this.educationVisibility = 'NONE',
  });

  String get displayName => fullName.isNotEmpty ? fullName : 'Navodayan';

  String get effectiveUserId => (userId != null && userId!.isNotEmpty) ? userId! : id;

  bool get isJnvVerified => jnvVerified || approvalStatus?.toUpperCase() == 'APPROVED' || approvalStatus?.toUpperCase() == 'ACTIVE';

  String get postingStatusLabel {
    switch (postingStatus?.toUpperCase()) {
      case 'SCHOOL':
        return 'Posted at a JNV';
      case 'HQ':
        return 'NVS HQ / regional';
      case 'RETIRED':
        return 'Retired';
      default:
        return postingStatus ?? '';
    }
  }

  String get subtitle {
    final parts = <String>[];
    if (currentRole != null && currentRole!.isNotEmpty) parts.add(currentRole!);
    if (company != null && company!.isNotEmpty) parts.add('@ $company');
    return parts.join(' ');
  }

  String get schoolAndBatch {
    final parts = <String>[];
    if (jnv != null && jnv!.name.isNotEmpty) {
      parts.add(jnv!.name);
    }
    if (batch != null && batch!.displayName.isNotEmpty) {
      if (association?.toLowerCase() == 'teacher' || association?.toLowerCase() == 'staff') {
        parts.add('Joined ${batch!.startYear}');
      } else {
        parts.add('Batch: ${batch!.displayName}');
      }
    }
    return parts.join(' • ');
  }

  factory Profile.fromUserProfile(UserProfile userProfile) {
    return Profile(
      id: userProfile.id ?? userProfile.userId ?? '',
      userId: userProfile.userId ?? userProfile.id,
      fullName: userProfile.fullName ?? 'Navodayan',
      currentRole: userProfile.currentRole,
      company: userProfile.company,
      location: userProfile.location,
      country: userProfile.country,
      association: userProfile.association,
      postingStatus: userProfile.postingStatus,
      openToMentor: userProfile.openToMentor,
      industry: userProfile.industry,
      imageUrl: userProfile.imageUrl,
      jnvVerified: userProfile.jnvVerified,
      approvalStatus: userProfile.approvalStatus,
      profileVisibility: userProfile.profileVisibility ?? 'PUBLIC',
      emailVisibility: userProfile.emailVisibility ?? 'NONE',
      phoneVisibility: userProfile.phoneVisibility ?? 'NONE',
      jnv: userProfile.jnvId != null
          ? School(jnvId: userProfile.jnvId.toString(), name: 'JNV School', distt: '')
          : null,
      batch: userProfile.batchId != null
          ? Batch(
              id: userProfile.batchId.toString(),
              startYear: userProfile.batchId!,
              endYear: userProfile.batchId!,
            )
          : null,
      skills: const [],
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    School? parsedSchool;
    if (json['jnv'] is Map<String, dynamic>) {
      parsedSchool = School.fromJson(json['jnv'] as Map<String, dynamic>);
    } else if (json['school'] is Map<String, dynamic>) {
      parsedSchool = School.fromJson(json['school'] as Map<String, dynamic>);
    } else if (json['jnvSchool'] != null) {
      parsedSchool = School(jnvId: json['jnvSchool'].toString(), name: 'JNV', distt: '');
    } else if (json['jnvId'] != null) {
      parsedSchool = School(jnvId: json['jnvId'].toString(), name: 'JNV School', distt: '');
    }

    Batch? parsedBatch;
    if (json['batch'] is Map<String, dynamic>) {
      parsedBatch = Batch.fromJson(json['batch'] as Map<String, dynamic>);
    } else if (json['batchYear'] != null) {
      final year = int.tryParse(json['batchYear'].toString()) ?? 0;
      parsedBatch = Batch(id: json['batchId']?.toString() ?? '', startYear: year, endYear: year);
    } else if (json['batchId'] != null) {
      final year = int.tryParse(json['batchId'].toString()) ?? 0;
      parsedBatch = Batch(id: json['batchId'].toString(), startYear: year, endYear: year);
    }

    List<ProfileSkill> parsedSkills = [];
    if (json['skills'] is List) {
      parsedSkills = (json['skills'] as List)
          .map((s) => ProfileSkill.fromJson(s))
          .where((s) => s.name.isNotEmpty)
          .toList();
    }

    final privacy = json['privacy'] is Map<String, dynamic> ? json['privacy'] as Map<String, dynamic> : null;
    final resolvedUserId = json['userId']?.toString() ??
        (json['user'] is Map ? json['user']['id']?.toString() : null) ??
        (json['account'] is Map ? json['account']['id']?.toString() : null);

    return Profile(
      id: json['id']?.toString() ?? '',
      userId: resolvedUserId,
      fullName: json['fullName']?.toString() ?? '',
      currentRole: json['currentRole']?.toString(),
      company: json['company']?.toString(),
      location: json['location']?.toString(),
      country: json['country']?.toString(),
      association: json['association']?.toString(),
      postingStatus: json['postingStatus']?.toString(),
      openToMentor: json['openToMentor'] == true || json['openToMentor']?.toString() == 'true',
      industry: json['industry']?.toString(),
      experience: json['experience']?.toString(),
      bio: json['bio']?.toString() ?? (json['details'] is Map ? (json['details'] as Map)['bio']?.toString() : null),
      imageUrl: json['imageUrl']?.toString() ??
          json['profilePic']?.toString() ??
          json['avatarUrl']?.toString() ??
          json['photo']?.toString() ??
          (json['details'] is Map ? (json['details'] as Map)['imageUrl']?.toString() : null),
      jnv: parsedSchool,
      batch: parsedBatch,
      skills: parsedSkills,
      jnvVerified: json['jnvVerified'] == true || json['jnvVerified']?.toString() == 'true' || json['verified'] == true,
      approvalStatus: json['approvalStatus']?.toString() ?? json['status']?.toString(),
      profileVisibility: json['profileVisibility']?.toString() ?? privacy?['profileVisibility']?.toString() ?? 'PUBLIC',
      emailVisibility: json['emailVisibility']?.toString() ?? privacy?['emailVisibility']?.toString() ?? 'NONE',
      phoneVisibility: json['phoneVisibility']?.toString() ?? privacy?['phoneVisibility']?.toString() ?? 'NONE',
      workPhoneVisibility: json['workPhoneVisibility']?.toString() ?? privacy?['workPhoneVisibility']?.toString() ?? 'NONE',
      addressVisibility: json['addressVisibility']?.toString() ?? privacy?['addressVisibility']?.toString() ?? 'NONE',
      workAddressVisibility: json['workAddressVisibility']?.toString() ?? privacy?['workAddressVisibility']?.toString() ?? 'NONE',
      educationVisibility: json['educationVisibility']?.toString() ?? privacy?['educationVisibility']?.toString() ?? 'NONE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      if (currentRole != null) 'currentRole': currentRole,
      if (company != null) 'company': company,
      if (location != null) 'location': location,
      if (country != null) 'country': country,
      if (association != null) 'association': association,
      if (postingStatus != null) 'postingStatus': postingStatus,
      'openToMentor': openToMentor,
      if (industry != null) 'industry': industry,
      if (experience != null) 'experience': experience,
      if (bio != null) 'bio': bio,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (jnv != null) 'jnv': jnv!.toJson(),
      if (batch != null) 'batch': batch!.toJson(),
      'skills': skills.map((s) => s.toJson()).toList(),
      'jnvVerified': jnvVerified,
      if (approvalStatus != null) 'approvalStatus': approvalStatus,
      'profileVisibility': profileVisibility,
      'emailVisibility': emailVisibility,
      'phoneVisibility': phoneVisibility,
      'workPhoneVisibility': workPhoneVisibility,
      'addressVisibility': addressVisibility,
      'workAddressVisibility': workAddressVisibility,
      'educationVisibility': educationVisibility,
    };
  }
}
