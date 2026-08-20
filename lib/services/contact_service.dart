import 'api_client.dart';

class ContactService {
  final ApiClient _apiClient;

  ContactService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<void> submitContact({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    await _apiClient.post(
      '/contact',
      {
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
      },
    );
  }
}
