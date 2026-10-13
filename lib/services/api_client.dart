import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client();

  /// Returns the client type ('web', 'ios', or 'android') expected by the API.
  static String get clientHeaderValue {
    if (ApiConfig.clientKey.contains('_web_')) {
      return 'web';
    }
    if (ApiConfig.clientKey.contains('_ios_')) {
      return 'ios';
    }
    if (ApiConfig.clientKey.contains('_android_')) {
      return 'android';
    }
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'android';
    }
  }

  Future<Map<String, dynamic>> _request(
    String endpoint, {
    String method = 'GET',
    dynamic body,
    String? token,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    String url = '$baseUrl$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      final uri = Uri.parse(url);
      final mergedParams = Map<String, String>.from(uri.queryParameters)..addAll(queryParams);
      url = uri.replace(queryParameters: mergedParams).toString();
    }

    final uri = Uri.parse(url);
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'X-Navodayan-Client': clientHeaderValue,
    };

    if (ApiConfig.clientKey.isNotEmpty) {
      requestHeaders['X-Navodayan-Client-Key'] = ApiConfig.clientKey;
    }

    if (headers != null && headers.isNotEmpty) {
      requestHeaders.addAll(headers);
    }

    if (token != null && token.isNotEmpty) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    http.Response response;
    final bodyStr = body != null ? jsonEncode(body) : null;

    try {
      switch (method.toUpperCase()) {
        case 'POST':
          response = await _client.post(uri, headers: requestHeaders, body: bodyStr);
          break;
        case 'PUT':
          response = await _client.put(uri, headers: requestHeaders, body: bodyStr);
          break;
        case 'PATCH':
          response = await _client.patch(uri, headers: requestHeaders, body: bodyStr);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: requestHeaders, body: bodyStr);
          break;
        case 'GET':
        default:
          response = await _client.get(uri, headers: requestHeaders);
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
    Map<String, String>? headers,
  }) {
    return _request(endpoint, method: 'GET', token: token, queryParams: queryParams, headers: headers);
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    dynamic body, {
    String? token,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) {
    return _request(endpoint, method: 'POST', body: body, token: token, queryParams: queryParams, headers: headers);
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    dynamic body, {
    String? token,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) {
    return _request(endpoint, method: 'PUT', body: body, token: token, queryParams: queryParams, headers: headers);
  }

  Future<Map<String, dynamic>> patch(
    String endpoint,
    dynamic body, {
    String? token,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) {
    return _request(endpoint, method: 'PATCH', body: body, token: token, queryParams: queryParams, headers: headers);
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) {
    return _request(endpoint, method: 'DELETE', token: token, queryParams: queryParams, headers: headers);
  }
}
