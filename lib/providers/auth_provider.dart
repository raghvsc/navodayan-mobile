import 'dart:convert';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';
import '../services/analytics_service.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  static const String tokenKey = 'navodayan_token';
  static const String userKey = 'navodayan_user';

  final ApiClient _api;
  AuthUser? _user;
  String? _token;
  bool _loading = true;

  AuthProvider({ApiClient? api}) : _api = api ?? ApiClient() {
    _init();
  }

  AuthUser? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null && _token != null && _token!.isNotEmpty;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString(tokenKey);
      final storedUser = prefs.getString(userKey);

      if (storedToken != null && storedToken.isNotEmpty) {
        _token = storedToken;
      }
      if (storedUser != null && storedUser.isNotEmpty) {
        try {
          final decoded = jsonDecode(storedUser);
          if (decoded is Map<String, dynamic>) {
            _user = AuthUser.fromJson(decoded);
            _syncFirebaseUser(_user);
          }
        } catch (e) {
          debugPrint('Error decoding cached user: $e');
        }
      }

      if (_token != null && _token!.isNotEmpty) {
        await fetchCurrentUser();
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _syncFirebaseUser(AuthUser? user) {
    try {
      if (user != null) {
        FirebaseCrashlytics.instance.setUserIdentifier(user.id);
        FirebaseCrashlytics.instance.setCustomKey('user_email', user.email);
        FirebaseCrashlytics.instance.setCustomKey('user_role', user.role ?? 'alumni');
        AnalyticsService.instance.setUserId(user.id);
        AnalyticsService.instance.setUserProperty(name: 'role', value: user.role ?? 'alumni');
      } else {
        FirebaseCrashlytics.instance.setUserIdentifier('');
        AnalyticsService.instance.setUserId(null);
      }
    } catch (e) {
      debugPrint('Firebase user sync error: $e');
    }
  }

  Future<void> fetchCurrentUser() async {
    if (_token == null || _token!.isEmpty) return;
    try {
      final res = await _api.get('/auth/me', token: _token);
      final userData = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : (res['user'] is Map<String, dynamic> ? res['user'] as Map<String, dynamic> : null);

      if (userData != null) {
        _user = AuthUser.fromJson(userData);
        _syncFirebaseUser(_user);
        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(userKey, jsonEncode(_user!.toJson()));
      }
    } catch (e) {
      debugPrint('Error fetching /auth/me: $e');
    }
  }

  Future<void> _persist(String nextToken, AuthUser nextUser) async {
    _token = nextToken;
    _user = nextUser;
    _syncFirebaseUser(nextUser);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, nextToken);
      await prefs.setString(userKey, jsonEncode(nextUser.toJson()));
    } catch (e) {
      debugPrint('Error persisting auth state: $e');
    }
  }

  Future<void> login(String email, String password) async {
    final res = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final data = res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : res;

    final token = data['token']?.toString() ?? '';
    final userData = data['user'] as Map<String, dynamic>? ?? {};
    final user = AuthUser.fromJson(userData);

    await _persist(token, user);
    AnalyticsService.instance.logLogin(loginMethod: 'email');
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final res = await _api.post('/auth/register', payload);

    final data = res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : res;

    final token = data['token']?.toString();
    final userData = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : null;

    if (token != null && token.isNotEmpty && userData != null) {
      final user = AuthUser.fromJson(userData);
      await _persist(token, user);
      AnalyticsService.instance.logSignUp(signUpMethod: 'email');
    }

    return data;
  }

  Future<String> resendVerification(String email) async {
    final res = await _api.post('/auth/resend-verification', {'email': email});
    return res['message']?.toString() ?? 'Verification email sent.';
  }

  Future<String> forgotPassword(String email) async {
    final res = await _api.post('/auth/forgot-password', {'email': email});
    return res['message']?.toString() ?? 'Reset instructions sent to your email.';
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _syncFirebaseUser(null);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      await prefs.remove(userKey);
    } catch (e) {
      debugPrint('Error clearing auth state: $e');
    }
  }
}

