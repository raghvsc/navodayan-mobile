import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:navodayan/services/api_client.dart';

void main() {
  group('ApiClient Tests', () {
    test('successful GET request parses JSON response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/directory/search');
        expect(request.headers['Authorization'], 'Bearer mock-jwt-token');

        return http.Response(
          jsonEncode({
            'data': [
              {'id': '1', 'fullName': 'Test Navodayan', 'openToMentor': true}
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiClient(baseUrl: 'http://test.local/api', client: mockClient);
      final res = await api.get('/directory/search', token: 'mock-jwt-token');

      expect(res['data'], isList);
      expect((res['data'] as List).length, 1);
      expect((res['data'] as List).first['fullName'], 'Test Navodayan');
    });

    test('throws exception with API error message on non-200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Invalid credentials'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiClient(baseUrl: 'http://test.local/api', client: mockClient);

      expect(
        () => api.post('/auth/login', {'email': 'a@b.com', 'password': 'pass'}),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Invalid credentials'))),
      );
    });
  });
}
