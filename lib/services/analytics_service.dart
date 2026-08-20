import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAnalytics? get _analytics {
    if (!_isFirebaseAvailable) return null;
    try {
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  NavigatorObserver get observer {
    if (!_isFirebaseAvailable) return NavigatorObserver();
    try {
      return FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);
    } catch (_) {
      return NavigatorObserver();
    }
  }

  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    final a = _analytics;
    if (a == null) return;
    try {
      await a.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('Analytics logScreenView error: $e');
    }
  }

  Future<void> setUserId(String? userId) async {
    final a = _analytics;
    if (a == null) return;
    try {
      await a.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics setUserId error: $e');
    }
  }

  Future<void> setUserProperty({required String name, required String? value}) async {
    final a = _analytics;
    if (a == null) return;
    try {
      await a.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics setUserProperty error: $e');
    }
  }

  Future<void> logLogin({String loginMethod = 'email'}) async {
    final a = _analytics;
    if (a == null) return;
    try {
      await a.logLogin(loginMethod: loginMethod);
    } catch (e) {
      debugPrint('Analytics logLogin error: $e');
    }
  }

  Future<void> logSignUp({String signUpMethod = 'email'}) async {
    final a = _analytics;
    if (a == null) return;
    try {
      await a.logSignUp(signUpMethod: signUpMethod);
    } catch (e) {
      debugPrint('Analytics logSignUp error: $e');
    }
  }

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    final a = _analytics;
    if (a == null) return;
    try {
      await a.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics logEvent error: $e');
    }
  }

  Future<void> logChatRequestSent({required String recipientId, required String recipientName}) async {
    await logEvent('chat_request_sent', parameters: {
      'recipient_id': recipientId,
      'recipient_name': recipientName,
    });
  }

  Future<void> logChatRequestResponded({required String requestId, required String action}) async {
    await logEvent('chat_request_responded', parameters: {
      'request_id': requestId,
      'action': action,
    });
  }

  Future<void> logChatMessageSent({required String conversationId, required String receiverId}) async {
    await logEvent('chat_message_sent', parameters: {
      'conversation_id': conversationId,
      'receiver_id': receiverId,
    });
  }
}
