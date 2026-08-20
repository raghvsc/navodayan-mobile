import '../models/school.dart';
import '../models/batch.dart';
import 'api_client.dart';

class SchoolsBatchesService {
  final ApiClient _apiClient;

  SchoolsBatchesService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<School>> getSchools() async {
    final response = await _apiClient.get('/schools');
    final dynamic data = response['data'] ?? response;
    if (data is List) {
      return data.map((json) => School.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<Batch>> getBatches() async {
    final response = await _apiClient.get('/batches');
    final dynamic data = response['data'] ?? response;
    if (data is List) {
      return data.map((json) => Batch.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
