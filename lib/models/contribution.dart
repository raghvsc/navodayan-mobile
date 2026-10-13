class ContributionSummary {
  final num verifiedMoney;
  final num pendingMoney;
  final num committedMoney;
  final num verifiedHours;
  final num pendingHours;

  const ContributionSummary({
    this.verifiedMoney = 0,
    this.pendingMoney = 0,
    this.committedMoney = 0,
    this.verifiedHours = 0,
    this.pendingHours = 0,
  });

  factory ContributionSummary.fromJson(Map<String, dynamic> json) {
    return ContributionSummary(
      verifiedMoney: json['verifiedMoney'] ?? 0,
      pendingMoney: json['pendingMoney'] ?? 0,
      committedMoney: json['committedMoney'] ?? 0,
      verifiedHours: json['verifiedHours'] ?? 0,
      pendingHours: json['pendingHours'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'verifiedMoney': verifiedMoney,
        'pendingMoney': pendingMoney,
        'committedMoney': committedMoney,
        'verifiedHours': verifiedHours,
        'pendingHours': pendingHours,
      };
}

class FinancialContribution {
  final String id;
  final num amount;
  final String? status;
  final String? mode;
  final String? campaignId;
  final String? campaignTitle;
  final String? note;
  final String? rejectionReason;
  final DateTime? createdAt;

  const FinancialContribution({
    required this.id,
    required this.amount,
    this.status,
    this.mode,
    this.campaignId,
    this.campaignTitle,
    this.note,
    this.rejectionReason,
    this.createdAt,
  });

  factory FinancialContribution.fromJson(Map<String, dynamic> json) {
    return FinancialContribution(
      id: json['id']?.toString() ?? '',
      amount: json['amount'] ?? 0,
      status: json['status']?.toString(),
      mode: json['mode']?.toString(),
      campaignId: json['campaignId']?.toString(),
      campaignTitle: json['campaign']?['title']?.toString() ?? json['campaignTitle']?.toString(),
      note: json['note']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

class PhysicalContribution {
  final String id;
  final String type;
  final num hours;
  final String? title;
  final String? campaignTitle;
  final String? status;
  final String? description;
  final String? rejectionReason;
  final DateTime? createdAt;

  const PhysicalContribution({
    required this.id,
    required this.type,
    required this.hours,
    this.title,
    this.campaignTitle,
    this.status,
    this.description,
    this.rejectionReason,
    this.createdAt,
  });

  factory PhysicalContribution.fromJson(Map<String, dynamic> json) {
    return PhysicalContribution(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'VOLUNTEER',
      hours: json['hours'] ?? 0,
      title: json['title']?.toString(),
      campaignTitle: json['campaign']?['title']?.toString() ?? json['campaignTitle']?.toString(),
      status: json['status']?.toString(),
      description: json['description']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

class ContributionCampaign {
  final String id;
  final String title;
  final String? purpose;
  final String? description;
  final String? status;
  final num? targetAmount;
  final num? raisedAmount;

  const ContributionCampaign({
    required this.id,
    required this.title,
    this.purpose,
    this.description,
    this.status,
    this.targetAmount,
    this.raisedAmount,
  });

  factory ContributionCampaign.fromJson(Map<String, dynamic> json) {
    return ContributionCampaign(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      purpose: json['purpose']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      targetAmount: json['targetAmount'],
      raisedAmount: json['raisedAmount'],
    );
  }
}

class ContributionsData {
  final int? jnvId;
  final String? jnvName;
  final ContributionSummary summary;
  final List<FinancialContribution> financial;
  final List<PhysicalContribution> physical;

  const ContributionsData({
    this.jnvId,
    this.jnvName,
    this.summary = const ContributionSummary(),
    this.financial = const [],
    this.physical = const [],
  });

  factory ContributionsData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    return ContributionsData(
      jnvId: data['jnvId'] is int ? data['jnvId'] : int.tryParse(data['jnvId']?.toString() ?? ''),
      jnvName: data['jnvName']?.toString(),
      summary: data['totals'] != null
          ? ContributionSummary.fromJson(data['totals'] as Map<String, dynamic>)
          : data['summary'] != null
              ? ContributionSummary.fromJson(data['summary'] as Map<String, dynamic>)
              : const ContributionSummary(),
      financial: (data['financial'] as List<dynamic>?)
              ?.map((e) => FinancialContribution.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      physical: (data['physical'] as List<dynamic>?)
              ?.map((e) => PhysicalContribution.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
