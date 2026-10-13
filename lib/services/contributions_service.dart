import 'package:flutter/foundation.dart';
import '../models/contribution.dart';
import 'api_client.dart';

class ContributionsService {
  final ApiClient _client;

  ContributionsService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<ContributionsData> getContributions() async {
    try {
      final response = await _client.get('/contributions');
      return ContributionsData.fromJson(response);
    } catch (e) {
      debugPrint('ContributionsService.getContributions error: $e');
      rethrow;
    }
  }

  Future<List<ContributionCampaign>> getCampaigns() async {
    try {
      final response = await _client.get('/contributions/campaigns');
      final data = response['data'] is Map<String, dynamic> ? response['data'] : response;
      final list = data['campaigns'] as List<dynamic>?;
      return list?.map((e) => ContributionCampaign.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    } catch (e) {
      debugPrint('ContributionsService.getCampaigns error: $e');
      return [];
    }
  }

  Future<bool> logFinancialContribution({
    String? campaignId,
    required num amount,
    String? note,
  }) async {
    try {
      await _client.post(
        '/contributions/financial',
        {
          if (campaignId != null && campaignId.isNotEmpty) 'campaignId': campaignId,
          'amount': amount,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return true;
    } catch (e) {
      debugPrint('ContributionsService.logFinancialContribution error: $e');
      rethrow;
    }
  }

  Future<bool> logPhysicalContribution({
    required String type,
    required num hours,
    String? description,
  }) async {
    try {
      await _client.post(
        '/contributions/physical',
        {
          'type': type,
          'hours': hours,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
      return true;
    } catch (e) {
      debugPrint('ContributionsService.logPhysicalContribution error: $e');
      rethrow;
    }
  }
}
