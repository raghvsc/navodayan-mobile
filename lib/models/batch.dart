class Batch {
  final String id;
  final int startYear;
  final int endYear;

  Batch({
    required this.id,
    required this.startYear,
    required this.endYear,
  });

  String get displayName => '$startYear-$endYear';

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id']?.toString() ?? '',
      startYear: json['startYear'] is int
          ? json['startYear'] as int
          : int.tryParse(json['startYear']?.toString() ?? '') ?? 0,
      endYear: json['endYear'] is int
          ? json['endYear'] as int
          : int.tryParse(json['endYear']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startYear': startYear,
      'endYear': endYear,
    };
  }
}
