class CoordinatorFeatures {
  final bool members;
  final bool updateMemberEmail;
  final bool events;
  final bool announcements;
  final bool contributions;
  final bool feedback;
  final bool batchCoordinators;
  final bool membershipApprovals;

  const CoordinatorFeatures({
    this.members = true,
    this.updateMemberEmail = false,
    this.events = true,
    this.announcements = false,
    this.contributions = true,
    this.feedback = true,
    this.batchCoordinators = true,
    this.membershipApprovals = true,
  });

  factory CoordinatorFeatures.fromJson(Map<String, dynamic> json) {
    return CoordinatorFeatures(
      members: json['members'] ?? true,
      updateMemberEmail: json['updateMemberEmail'] ?? false,
      events: json['events'] ?? true,
      announcements: json['announcements'] ?? false,
      contributions: json['contributions'] ?? true,
      feedback: json['feedback'] ?? true,
      batchCoordinators: json['batchCoordinators'] ?? true,
      membershipApprovals: json['membershipApprovals'] ?? true,
    );
  }
}

class CoordinatorViewing {
  final String? userId;
  final String? level;
  final String? scopeLabel;
  final int? jnvId;
  final String? jnvName;

  const CoordinatorViewing({
    this.userId,
    this.level,
    this.scopeLabel,
    this.jnvId,
    this.jnvName,
  });

  factory CoordinatorViewing.fromJson(Map<String, dynamic> json) {
    return CoordinatorViewing(
      userId: json['userId']?.toString(),
      level: json['level']?.toString(),
      scopeLabel: json['scopeLabel']?.toString(),
      jnvId: json['jnvId'] is int ? json['jnvId'] : int.tryParse(json['jnvId']?.toString() ?? ''),
      jnvName: json['jnvName']?.toString(),
    );
  }
}

class CoordinatorContext {
  final bool readOnly;
  final bool canManageSchoolPrograms;
  final bool canReviewContributions;
  final bool canManageBatchCoordinators;
  final bool canApproveMembers;
  final CoordinatorFeatures features;
  final CoordinatorViewing viewing;

  const CoordinatorContext({
    this.readOnly = false,
    this.canManageSchoolPrograms = false,
    this.canReviewContributions = false,
    this.canManageBatchCoordinators = false,
    this.canApproveMembers = false,
    this.features = const CoordinatorFeatures(),
    this.viewing = const CoordinatorViewing(),
  });

  factory CoordinatorContext.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    return CoordinatorContext(
      readOnly: data['readOnly'] == true,
      canManageSchoolPrograms: data['canManageSchoolPrograms'] == true,
      canReviewContributions: data['canReviewContributions'] == true,
      canManageBatchCoordinators: data['canManageBatchCoordinators'] == true,
      canApproveMembers: data['canApproveMembers'] == true,
      features: data['features'] != null
          ? CoordinatorFeatures.fromJson(data['features'] as Map<String, dynamic>)
          : const CoordinatorFeatures(),
      viewing: data['viewing'] != null
          ? CoordinatorViewing.fromJson(data['viewing'] as Map<String, dynamic>)
          : const CoordinatorViewing(),
    );
  }
}

class CoordinatorFeedback {
  final String id;
  final String type;
  final String title;
  final String description;
  final String status;
  final int? jnvId;
  final DateTime? createdAt;

  const CoordinatorFeedback({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    this.jnvId,
    this.createdAt,
  });

  factory CoordinatorFeedback.fromJson(Map<String, dynamic> json) {
    return CoordinatorFeedback(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'FEEDBACK',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      jnvId: json['jnvId'] is int ? json['jnvId'] : int.tryParse(json['jnvId']?.toString() ?? ''),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}
