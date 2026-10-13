class OfferingCategory {
  final String key;
  final String label;

  const OfferingCategory({required this.key, required this.label});

  factory OfferingCategory.fromJson(Map<String, dynamic> json) {
    return OfferingCategory(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class OfferingItem {
  final String id;
  final String businessName;
  final String category;
  final String? categoryLabel;
  final String? summary;
  final String? description;
  final String? website;
  final String? contactEmail;
  final String? contactPhone;
  final String? city;
  final String? state;
  final String? country;
  final bool hiring;
  final String? openRoles;
  final String? userId;
  final String? userFullName;
  final DateTime? createdAt;

  const OfferingItem({
    required this.id,
    required this.businessName,
    required this.category,
    this.categoryLabel,
    this.summary,
    this.description,
    this.website,
    this.contactEmail,
    this.contactPhone,
    this.city,
    this.state,
    this.country,
    this.hiring = false,
    this.openRoles,
    this.userId,
    this.userFullName,
    this.createdAt,
  });

  factory OfferingItem.fromJson(Map<String, dynamic> json) {
    return OfferingItem(
      id: json['id']?.toString() ?? '',
      businessName: json['businessName']?.toString() ?? 'Offering',
      category: json['category']?.toString() ?? 'OTHER',
      categoryLabel: json['categoryLabel']?.toString(),
      summary: json['summary']?.toString(),
      description: json['description']?.toString(),
      website: json['website']?.toString(),
      contactEmail: json['contactEmail']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      hiring: json['hiring'] == true,
      openRoles: json['openRoles']?.toString(),
      userId: json['userId']?.toString() ?? json['user']?['id']?.toString(),
      userFullName: json['userFullName']?.toString() ?? json['user']?['fullName']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'category': category,
        if (summary != null) 'summary': summary,
        if (description != null) 'description': description,
        if (website != null) 'website': website,
        if (contactEmail != null) 'contactEmail': contactEmail,
        if (contactPhone != null) 'contactPhone': contactPhone,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (country != null) 'country': country,
        'hiring': hiring,
        if (openRoles != null) 'openRoles': openRoles,
      };
}
