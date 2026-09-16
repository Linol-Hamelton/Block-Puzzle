import 'package:firebase_analytics/firebase_analytics.dart';

import '../../core/logging/app_logger.dart';
import 'analytics_tracker.dart';

/// Production [AnalyticsTracker] that routes to Firebase Analytics.
class FirebaseAnalyticsTracker implements AnalyticsTracker {
  FirebaseAnalyticsTracker({required AppLogger logger}) : _logger = logger;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final AppLogger _logger;

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {
    Map<String, Object>? safeParams;
    if (params.isNotEmpty) {
      safeParams = <String, Object>{};
      for (final MapEntry<String, Object?> entry in params.entries) {
        if (entry.value != null) {
          safeParams[entry.key] = entry.value!;
        }
      }
    }

    // Telemetry must not be able to take the game down.
    //
    // It did: logEvent throws on a name Firebase reserves, the throw escaped
    // into Classic's initialization, and the mode opened to a grey error slab.
    // AnalyticsSchemaValidator now refuses reserved names upstream, but this
    // catch is the guarantee - whatever else the SDK decides to reject, the
    // player keeps playing and the failure is on the log rather than on the
    // screen. Deliberately not silent: a swallowed telemetry failure is how a
    // dashboard ends up confidently wrong.
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: safeParams,
      );
    } catch (error, stackTrace) {
      _logger.error(
        '[ANALYTICS][DROPPED] $eventName rejected by Firebase: $error\n'
        '$stackTrace',
      );
    }
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
