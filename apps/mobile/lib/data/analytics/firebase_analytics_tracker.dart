import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_tracker.dart';

/// Production [AnalyticsTracker] that routes to Firebase Analytics.
class FirebaseAnalyticsTracker implements AnalyticsTracker {
  FirebaseAnalyticsTracker();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: params,
    );
  }

  @override
  Future<void> flush({bool force = false}) async {
    // Firebase Analytics handles flushing automatically
  }

  @override
  Future<void> close() async {
    // No-op for Firebase Analytics as it manages its own lifecycle.
  }
}
