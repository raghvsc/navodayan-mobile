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
      return const ContributionsData();
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
    required String campaignId,
    required num amount,
    String mode = 'UPI',
    String? note,
    String? receivedAt,
  }) async {
    try {
      await _client.post(
        '/contributions/financial',
        {
          'campaignId': campaignId,
          'amount': amount,
          'mode': mode,
          if (note != null && note.isNotEmpty) 'note': note,
          if (receivedAt != null && receivedAt.isNotEmpty) 'receivedAt': receivedAt,
        },
      );
      return true;
    } catch (e) {
      debugPrint('ContributionsService.logFinancialContribution error: $e');
      rethrow;
    }
  }

  Future<bool> deleteFinancialContribution(String id) async {
    try {
      await _client.delete('/contributions/financial/$id');
      return true;
    } catch (e) {
      debugPrint('ContributionsService.deleteFinancialContribution error: $e');
      rethrow;
    }
  }

  Future<bool> logPhysicalContribution({
    required String type,
    required num hours,
    required String title,
    String? campaignId,
    String? note,
    String? contributedAt,
  }) async {
    try {
      await _client.post(
        '/contributions/physical',
        {
          'type': type,
          'hours': hours,
          'title': title,
          if (campaignId != null && campaignId.isNotEmpty) 'campaignId': campaignId,
          if (note != null && note.isNotEmpty) 'note': note,
          if (contributedAt != null && contributedAt.isNotEmpty) 'contributedAt': contributedAt,
        },
      );
      return true;
    } catch (e) {
      debugPrint('ContributionsService.logPhysicalContribution error: $e');
      rethrow;
    }
  }

  Future<bool> deletePhysicalContribution(String id) async {
    try {
      await _client.delete('/contributions/physical/$id');
      return true;
    } catch (e) {
      debugPrint('ContributionsService.deletePhysicalContribution error: $e');
      rethrow;
    }
  }
}
