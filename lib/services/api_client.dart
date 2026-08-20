import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client();

  Future<Map<String, dynamic>> _request(
    String endpoint, {
    String method = 'GET',
    dynamic body,
    String? token,
    Map<String, String>? queryParams,
  }) async {
    String url = '$baseUrl$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      final uri = Uri.parse(url);
      final mergedParams = Map<String, String>.from(uri.queryParameters)..addAll(queryParams);
      url = uri.replace(queryParameters: mergedParams).toString();
    }

    final uri = Uri.parse(url);
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    http.Response response;
    final bodyStr = body != null ? jsonEncode(body) : null;

    try {
      switch (method.toUpperCase()) {
        case 'POST':
          response = await _client.post(uri, headers: headers, body: bodyStr);
          break;
        case 'PUT':
          response = await _client.put(uri, headers: headers, body: bodyStr);
          break;
        case 'PATCH':
          response = await _client.patch(uri, headers: headers, body: bodyStr);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers, body: bodyStr);
          break;
        case 'GET':
        default:
          response = await _client.get(uri, headers: headers);
          break;
      }
    } catch (e) {
      throw Exception('Unable to reach the server. Please check your network connection.');
    }

    Map<String, dynamic> responseData = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          responseData = decoded;
        } else if (decoded is List) {
          responseData = {'data': decoded};
        }
      } catch (_) {
        responseData = {'message': response.body};
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMsg = responseData['message']?.toString() ??
          responseData['error']?.toString() ??
          'Request failed with status ${response.statusCode}';
      throw Exception(errorMsg);
    }

    return responseData;
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
    Map<String, String>? queryParams,
  }) {
    return _request(endpoint, method: 'GET', token: token, queryParams: queryParams);
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    dynamic body, {
    String? token,
    Map<String, String>? queryParams,
  }) {
    return _request(endpoint, method: 'POST', body: body, token: token, queryParams: queryParams);
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    dynamic body, {
    String? token,
    Map<String, String>? queryParams,
  }) {
    return _request(endpoint, method: 'PUT', body: body, token: token, queryParams: queryParams);
  }

  Future<Map<String, dynamic>> patch(
    String endpoint,
    dynamic body, {
    String? token,
    Map<String, String>? queryParams,
  }) {
    return _request(endpoint, method: 'PATCH', body: body, token: token, queryParams: queryParams);
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
    Map<String, String>? queryParams,
  }) {
    return _request(endpoint, method: 'DELETE', token: token, queryParams: queryParams);
  }
}
