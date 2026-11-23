import '../models/care_session.dart';
import 'api_client.dart';

class CareService {
  final ApiClient _api;

  CareService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<CareSession>> getSessions({String? audience}) async {
    try {
      final res = await _api.get('/events/knowledge-sessions');
      final data = res['data'];
      if (data is List) {
        var sessions = data
            .whereType<Map<String, dynamic>>()
            .map((item) => CareSession.fromJson(item))
            .toList();

        if (audience != null && audience.isNotEmpty && audience.toUpperCase() != 'ANY') {
          sessions = sessions.where((s) {
            if (s.audiences.isEmpty) return true;
            return s.audiences.contains(audience.toUpperCase()) || s.audiences.contains('ALL');
          }).toList();
        }
        return sessions;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load CARE sessions: $e');
    }
  }

  Future<bool> toggleConsent(String sessionId, bool currentlyConsented) async {
    if (currentlyConsented) {
      await _api.delete('/events/knowledge-sessions/$sessionId/consent');
      return false;
    } else {
      await _api.post('/events/knowledge-sessions/$sessionId/consent', {});
      return true;
    }
  }

  Future<CareSession> requestSession({
    required String title,
    required String note,
    required List<String> audiences,
    required bool wantsToLearn,
    required bool canLead,
  }) async {
    final body = {
      'title': title.trim(),
      'note': note.trim(),
      'audiences': audiences,
      'wantsToLearn': wantsToLearn,
      'canLead': canLead,
    };
    final res = await _api.post('/events/knowledge-sessions', body);
    final data = res['data'];
    if (data is Map<String, dynamic>) {
      return CareSession.fromJson(data);
    }
    return CareSession(id: '', title: title);
  }
}

