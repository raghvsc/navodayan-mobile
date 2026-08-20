import '../models/profile.dart';
import 'api_client.dart';

class ProfileService {
  final ApiClient _apiClient;

  ProfileService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<Profile> getProfileById(String id, {String? token}) async {
    final response = await _apiClient.get('/profiles/$id', token: token);
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : (response['profile'] is Map<String, dynamic> ? response['profile'] as Map<String, dynamic> : response);

    return Profile.fromJson(data);
  }

  Future<Profile> getMyProfile({required String token}) async {
    final response = await _apiClient.get('/profiles/me', token: token);
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : (response['profile'] is Map<String, dynamic> ? response['profile'] as Map<String, dynamic> : response);

    return Profile.fromJson(data);
  }

  Future<Profile> updateProfile(Map<String, dynamic> payload, {required String token}) async {
    final response = await _apiClient.patch('/profiles/me', payload, token: token);
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : (response['profile'] is Map<String, dynamic> ? response['profile'] as Map<String, dynamic> : response);

    return Profile.fromJson(data);
  }
}
