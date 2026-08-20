import 'school.dart';
import 'batch.dart';

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
  final String fullName;
  final String? currentRole;
  final String? company;
  final String? location;
  final String? country;
  final String? association;
  final bool openToMentor;
  final String? industry;
  final String? experience;
  final String? bio;
  final School? jnv;
  final Batch? batch;
  final List<ProfileSkill> skills;

  Profile({
    required this.id,
    required this.fullName,
    this.currentRole,
    this.company,
    this.location,
    this.country,
    this.association,
    this.openToMentor = false,
    this.industry,
    this.experience,
    this.bio,
    this.jnv,
    this.batch,
    this.skills = const [],
  });

  String get displayName => fullName.isNotEmpty ? fullName : 'Navodayan';

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
      parts.add('Batch: ${batch!.displayName}');
    }
    return parts.join(' • ');
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    School? parsedSchool;
    if (json['jnv'] is Map<String, dynamic>) {
      parsedSchool = School.fromJson(json['jnv'] as Map<String, dynamic>);
    } else if (json['school'] is Map<String, dynamic>) {
      parsedSchool = School.fromJson(json['school'] as Map<String, dynamic>);
    } else if (json['jnvSchool'] != null) {
      parsedSchool = School(jnvId: json['jnvSchool'].toString(), name: 'JNV', distt: '');
    }

    Batch? parsedBatch;
    if (json['batch'] is Map<String, dynamic>) {
      parsedBatch = Batch.fromJson(json['batch'] as Map<String, dynamic>);
    } else if (json['batchYear'] != null) {
      final year = int.tryParse(json['batchYear'].toString()) ?? 0;
      parsedBatch = Batch(id: json['batchId']?.toString() ?? '', startYear: year, endYear: year);
    }

    List<ProfileSkill> parsedSkills = [];
    if (json['skills'] is List) {
      parsedSkills = (json['skills'] as List)
          .map((s) => ProfileSkill.fromJson(s))
          .where((s) => s.name.isNotEmpty)
          .toList();
    }

    return Profile(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      currentRole: json['currentRole']?.toString(),
      company: json['company']?.toString(),
      location: json['location']?.toString(),
      country: json['country']?.toString(),
      association: json['association']?.toString(),
      openToMentor: json['openToMentor'] == true || json['openToMentor']?.toString() == 'true',
      industry: json['industry']?.toString(),
      experience: json['experience']?.toString(),
      bio: json['bio']?.toString(),
      jnv: parsedSchool,
      batch: parsedBatch,
      skills: parsedSkills,
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
      'openToMentor': openToMentor,
      if (industry != null) 'industry': industry,
      if (experience != null) 'experience': experience,
      if (bio != null) 'bio': bio,
      if (jnv != null) 'jnv': jnv!.toJson(),
      if (batch != null) 'batch': batch!.toJson(),
      'skills': skills.map((s) => s.toJson()).toList(),
    };
  }
}
