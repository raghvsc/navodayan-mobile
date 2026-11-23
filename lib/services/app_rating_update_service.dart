import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRatingUpdateService {
  static final AppRatingUpdateService _instance = AppRatingUpdateService._internal();
  factory AppRatingUpdateService() => _instance;
  AppRatingUpdateService._internal();

  static const String _kLaunchCountKey = 'app_rating_launch_count';
  static const String _kLastPromptTimeKey = 'app_rating_last_prompt_time';
  static const String _kHasRatedKey = 'app_has_rated_or_declined';

  final InAppReview _inAppReview = InAppReview.instance;

  /// Call once at app startup to check for Play Store in-app updates
  Future<void> checkForInAppUpdate({BuildContext? context, bool manual = false}) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          if (info.immediateUpdateAllowed) {
            await InAppUpdate.performImmediateUpdate();
          } else if (info.flexibleUpdateAllowed) {
            await InAppUpdate.startFlexibleUpdate();
            await InAppUpdate.completeFlexibleUpdate();
          }
        } else if (manual && context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are on the latest version of Navodayan!')),
          );
        }
      } catch (e) {
        debugPrint('InAppUpdate check info: $e');
        if (manual && context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your app is up to date.')),
          );
        }
      }
    } else if (manual && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your app is up to date.')),
      );
    }
  }

  /// Increments launch counter and triggers Google Play in-app review if threshold met
  Future<void> checkAndPromptReview({bool force = false}) async {
    try {
      if (force) {
        if (await _inAppReview.isAvailable()) {
          await _inAppReview.requestReview();
        } else {
          await _inAppReview.openStoreListing();
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final hasRated = prefs.getBool(_kHasRatedKey) ?? false;
      if (hasRated) return;

      int launches = (prefs.getInt(_kLaunchCountKey) ?? 0) + 1;
      await prefs.setInt(_kLaunchCountKey, launches);

      final lastPrompt = prefs.getInt(_kLastPromptTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final daysSinceLastPrompt = (now - lastPrompt) / (1000 * 60 * 60 * 24);

      // Prompt after 4 launches and at least 7 days interval
      if (launches >= 4 && daysSinceLastPrompt >= 7) {
        if (await _inAppReview.isAvailable()) {
          await prefs.setInt(_kLastPromptTimeKey, now);
          await _inAppReview.requestReview();
        }
      }
    } catch (e) {
      debugPrint('AppReview prompt error: $e');
    }
  }

  /// Open Google Play Store listing directly for user rating
  Future<void> openPlayStoreListing() async {
    try {
      await _inAppReview.openStoreListing();
    } catch (e) {
      debugPrint('Could not open store listing: $e');
    }
  }
}
