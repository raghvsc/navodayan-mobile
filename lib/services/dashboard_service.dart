import 'dart:typed_data';
import 'api_client.dart';

class DashboardService {
  final ApiClient _api;

  DashboardService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<Map<String, dynamic>> getDashboardOverview() async {
    try {
      final res = await _api.get('/dashboard');
      return res['data'] is Map<String, dynamic> ? res['data'] : res;
    } catch (e) {
      throw Exception('Failed to load dashboard overview: $e');
    }
  }

  Future<Map<String, dynamic>> getMyCoordinators() async {
    try {
      final res = await _api.get('/my-coordinators');
      return res['data'] is Map<String, dynamic> ? res['data'] : res;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getMyOfferings() async {
    try {
      final res = await _api.get('/offerings/mine');
      return res['data'] is Map<String, dynamic> ? res['data'] : res;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getCircleInfo() async {
    try {
      final res = await _api.get('/dashboard/circle');
      return res['data'] is Map<String, dynamic> ? res['data'] : res;
    } catch (e) {
      return {};
    }
  }

  Future<void> confirmCircle() async {
    await _api.post('/dashboard/circle/confirm', {});
  }

  Future<void> changeCircle(String circleKey) async {
    await _api.post('/dashboard/circle/change', {'circleKey': circleKey});
  }

  Future<Map<String, dynamic>> getThanksSummary() async {
    try {
      final res = await _api.get('/thanks/summary');
      return res['data'] is Map<String, dynamic> ? res['data'] : res;
    } catch (e) {
      return {};
    }
  }

  Future<void> submitJnvProof({
    String? note,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    if (fileBytes != null && fileName != null) {
      final fields = <String, String>{};
      if (note != null && note.trim().isNotEmpty) {
        fields['note'] = note.trim();
      }
      await _api.uploadMultipart(
        '/dashboard/jnv-proof',
        fileBytes: fileBytes,
        fieldName: 'proof',
        fileName: fileName,
        fields: fields,
      );
    } else if (note != null && note.trim().isNotEmpty) {
      await _api.post('/dashboard/jnv-proof', {'note': note.trim()});
    }
  }

  Future<void> reportMember({
    required String targetUserId,
    required String reason,
    String? details,
    String targetType = 'USER',
  }) async {
    try {
      await _api.post('/safety/reports', {
        'targetType': targetType,
        'targetId': targetUserId,
        'reasonCode': reason,
        'details': details ?? '',
      });
    } catch (_) {
      await _api.post('/reports', {
        'targetUserId': targetUserId,
        'reason': reason,
        'details': details ?? '',
      });
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _api.post('/safety/blocks', {'userId': userId});
    } catch (_) {
      await _api.post('/users/$userId/block', {});
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _api.delete('/safety/blocks/$userId');
    } catch (_) {
      await _api.delete('/users/$userId/block');
    }
  }

  Future<void> deleteAccount({String? reason}) async {
    try {
      await _api.delete('/users/me');
    } catch (_) {
      try {
        await _api.delete('/profiles/me');
      } catch (_) {
        // If server uses custom endpoint or handles via support
      }
    }
  }

  Future<Map<String, dynamic>> exportUserData() async {
    try {
      final res = await _api.get('/users/me/export');
      return res['data'] is Map<String, dynamic> ? res['data'] : res;
    } catch (_) {
      return await getDashboardOverview();
    }
  }

  Future<void> sendAppreciation({
    required String recipientId,
    required String category,
    required String note,
  }) async {
    await _api.post('/thanks', {
      'recipientId': recipientId,
      'category': category,
      'note': note,
    });
  }
}

