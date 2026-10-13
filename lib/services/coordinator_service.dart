import 'package:flutter/foundation.dart';
import '../models/coordinator.dart';
import 'api_client.dart';

class CoordinatorService {
  final ApiClient _client;

  CoordinatorService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<CoordinatorContext> getContext() async {
    try {
      final response = await _client.get('/coordinator/context');
      return CoordinatorContext.fromJson(response);
    } catch (e) {
      debugPrint('CoordinatorService.getContext error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMembers({int page = 1, String? search}) async {
    try {
      final query = search != null && search.isNotEmpty ? '&search=${Uri.encodeComponent(search)}' : '';
      final response = await _client.get('/coordinator/members?page=$page&limit=20$query');
      final list = (response['members'] as List<dynamic>?) ?? (response['data'] as List<dynamic>?) ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('CoordinatorService.getMembers error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getApprovalsData() async {
    try {
      final response = await _client.get('/coordinator/approvals?status=PENDING&page=1&limit=20');
      final list = (response['users'] as List<dynamic>?) ?? (response['data'] as List<dynamic>?) ?? [];
      return {'items': list.cast<Map<String, dynamic>>(), 'message': null};
    } catch (e) {
      debugPrint('CoordinatorService.getApprovalsData error: $e');
      final msg = e.toString().replaceAll('Exception: ', '');
      return {'items': <Map<String, dynamic>>[], 'message': msg};
    }
  }

  Future<List<Map<String, dynamic>>> getApprovals() async {
    final data = await getApprovalsData();
    return (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<bool> decideApproval(String memberId, {required bool approve}) async {
    try {
      await _client.put(
        '/coordinator/members/$memberId/approval',
        {'status': approve ? 'APPROVED' : 'REJECTED'},
      );
      return true;
    } catch (e) {
      debugPrint('CoordinatorService.decideApproval error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCoordinatorEvents() async {
    try {
      final response = await _client.get('/coordinator/events');
      final list = (response['data'] as List<dynamic>?) ?? (response['events'] as List<dynamic>?) ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('CoordinatorService.getCoordinatorEvents error: $e');
      return [];
    }
  }

  Future<bool> createCoordinatorEvent(Map<String, dynamic> payload) async {
    try {
      await _client.post('/coordinator/events', payload);
      return true;
    } catch (e) {
      debugPrint('CoordinatorService.createCoordinatorEvent error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getContributionReviews() async {
    try {
      final response = await _client.get('/coordinator/contribution-reviews');
      return response['data'] is Map<String, dynamic> ? response['data'] : response;
    } catch (e) {
      debugPrint('CoordinatorService.getContributionReviews error: $e');
      return {'hoursVerified': 0, 'financial': [], 'physical': []};
    }
  }

  Future<Map<String, dynamic>> getCampaigns() async {
    try {
      final response = await _client.get('/coordinator/campaigns');
      return response['data'] is Map<String, dynamic> ? response['data'] : response;
    } catch (e) {
      debugPrint('CoordinatorService.getCampaigns error: $e');
      return {'campaigns': []};
    }
  }

  Future<Map<String, dynamic>> getBatchCoordinatorsData() async {
    try {
      final response = await _client.get('/coordinator/batch-coordinators');
      return response['data'] is Map<String, dynamic> ? response['data'] : response;
    } catch (e) {
      debugPrint('CoordinatorService.getBatchCoordinatorsData error: $e');
      final msg = e.toString().replaceAll('Exception: ', '');
      return {'error': msg, 'coordinators': []};
    }
  }

  Future<bool> inviteBatchCoordinator(String email, {int? batchId}) async {
    try {
      await _client.post(
        '/coordinator/batch-coordinators/invite',
        {
          'email': email,
          if (batchId != null) 'batchId': batchId,
        },
      );
      return true;
    } catch (e) {
      debugPrint('CoordinatorService.inviteBatchCoordinator error: $e');
      rethrow;
    }
  }

  Future<List<CoordinatorFeedback>> getFeedback() async {
    try {
      final response = await _client.get('/coordinator/feedback');
      final list = (response['data'] as List<dynamic>?) ?? [];
      return list.map((e) => CoordinatorFeedback.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('CoordinatorService.getFeedback error: $e');
      return [];
    }
  }

  Future<bool> submitFeedback({
    required String type,
    required String title,
    required String description,
  }) async {
    try {
      await _client.post(
        '/coordinator/feedback',
        {
          'type': type,
          'title': title,
          'description': description,
        },
      );
      return true;
    } catch (e) {
      debugPrint('CoordinatorService.submitFeedback error: $e');
      rethrow;
    }
  }
}
