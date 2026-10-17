class CommunityStats {
  final int navodayans;
  final int jnvSchools;
  final int countries;

  const CommunityStats({
    required this.navodayans,
    required this.jnvSchools,
    required this.countries,
  });

  factory CommunityStats.fromJson(Map<String, dynamic> json) {
    return CommunityStats(
      navodayans: json['navodayans'] is int
          ? json['navodayans'] as int
          : int.tryParse(json['navodayans']?.toString() ?? '10858') ?? 10858,
      jnvSchools: json['jnvSchools'] is int
          ? json['jnvSchools'] as int
          : int.tryParse(json['jnvSchools']?.toString() ?? '499') ?? 499,
      countries: json['countries'] is int
          ? json['countries'] as int
          : int.tryParse(json['countries']?.toString() ?? '25') ?? 25,
    );
  }

  static const defaultStats = CommunityStats(
    navodayans: 10858,
    jnvSchools: 499,
    countries: 25,
  );
}
