class SpotlightMember {
  final String id;
  final String fullName;
  final String association;
  final String? school;
  final String? district;
  final String? state;
  final int? batchStart;
  final int? batchEnd;
  final String? role;
  final String? company;
  final String? location;
  final bool openToMentor;
  final String? imageUrl;

  SpotlightMember({
    required this.id,
    required this.fullName,
    required this.association,
    this.school,
    this.district,
    this.state,
    this.batchStart,
    this.batchEnd,
    this.role,
    this.company,
    this.location,
    this.openToMentor = false,
    this.imageUrl,
  });

  factory SpotlightMember.fromJson(Map<String, dynamic> json) {
    return SpotlightMember(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Navodayan Alumni',
      association: json['association']?.toString() ?? 'Alumni',
      school: json['school']?.toString(),
      district: json['district']?.toString(),
      state: json['state']?.toString(),
      batchStart: json['batchStart'] is int
          ? json['batchStart'] as int
          : int.tryParse(json['batchStart']?.toString() ?? ''),
      batchEnd: json['batchEnd'] is int
          ? json['batchEnd'] as int
          : int.tryParse(json['batchEnd']?.toString() ?? ''),
      role: json['role']?.toString(),
      company: json['company']?.toString(),
      location: json['location']?.toString(),
      openToMentor: json['openToMentor'] == true,
      imageUrl: json['imageUrl']?.toString() ??
          json['profilePic']?.toString() ??
          json['avatarUrl']?.toString() ??
          json['image']?.toString(),
    );
  }

  String get batchDisplay {
    if (batchStart != null && batchEnd != null) {
      return '$batchStart–$batchEnd';
    } else if (batchStart != null) {
      return '$batchStart';
    }
    return '';
  }

  String get schoolBatchDisplay {
    final parts = <String>[];
    if (school != null && school!.isNotEmpty) {
      parts.add(school!);
    }
    final b = batchDisplay;
    if (b.isNotEmpty) {
      parts.add('Batch $b');
    }
    return parts.join(' · ');
  }

  String get roleCompanyDisplay {
    final parts = <String>[];
    if (role != null && role!.trim().isNotEmpty) {
      parts.add(role!.trim());
    }
    if (company != null && company!.trim().isNotEmpty) {
      parts.add(company!.trim());
    }
    return parts.join(' · ');
  }
}

class SpotlightData {
  final String mode; // 'MANUAL' or 'STATE_RANDOM'
  final List<SpotlightMember> members;

  SpotlightData({
    required this.mode,
    required this.members,
  });

  factory SpotlightData.fromJson(Map<String, dynamic> json) {
    final modeStr = json['mode']?.toString() ?? 'STATE_RANDOM';
    final rawList = json['data'];
    final members = <SpotlightMember>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          members.add(SpotlightMember.fromJson(item));
        }
      }
    }
    return SpotlightData(mode: modeStr, members: members);
  }
}
