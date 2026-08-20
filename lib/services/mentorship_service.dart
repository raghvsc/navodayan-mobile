import '../models/mentorship_request.dart';
import '../models/profile.dart';
import 'api_client.dart';

class MentorshipService {
  final ApiClient _apiClient;

  MentorshipService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Profile>> getMentors({String? token}) async {
    final response = await _apiClient.get(
      '/directory/search',
      token: token,
      queryParams: {'openToMentor': 'true'},
    );

    final dynamic data = response['data'];
    if (data is List) {
      return data.map((json) => Profile.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> sendMentorshipRequest({
    required String mentorId,
    required String message,
    required String token,
  }) async {
    await _apiClient.post(
      '/mentorship/request',
      {
        'mentorId': mentorId,
        'message': message,
      },
      token: token,
    );
  }

  Future<List<MentorshipRequest>> getMentorshipRequests({required String token}) async {
    final response = await _apiClient.get(
      '/mentorship/requests',
      token: token,
    );

    final dynamic data = response['data'] ?? response;
    if (data is List) {
      return data.map((json) => MentorshipRequest.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    required String token,
  }) async {
    await _apiClient.put(
      '/mentorship/$requestId/status',
      {'status': status},
      token: token,
    );
  }
}
