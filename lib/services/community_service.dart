import 'package:flutter/foundation.dart';
import '../models/community_stats.dart';
import '../models/spotlight_member.dart';
import 'api_client.dart';

class CommunityService {
  final ApiClient _client;

  CommunityService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches dynamic community statistics: { navodayans, jnvSchools, countries }
  Future<CommunityStats> getStats() async {
    try {
      final response = await _client.get('/directory/stats');
      if (response['status'] == 'success' && response['data'] != null) {
        return CommunityStats.fromJson(response['data'] as Map<String, dynamic>);
      }
      return CommunityStats.defaultStats;
    } catch (e) {
      debugPrint('Error fetching /directory/stats: $e');
      return CommunityStats.defaultStats;
    }
  }

  /// Fetches spotlight members for the home page carousel
  Future<SpotlightData?> getSpotlight() async {
    try {
      final response = await _client.get('/directory/spotlight');
      if (response['status'] == 'success' && response['data'] != null) {
        return SpotlightData.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching /directory/spotlight: $e');
      return null;
    }
  }
}
