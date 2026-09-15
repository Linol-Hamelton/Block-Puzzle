import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../firebase_options.dart';
import '../core/di/di_container.dart';
import '../core/logging/app_logger.dart';
import '../data/analytics/analytics_tracker.dart';
import '../infra/monitoring/crash_reporter.dart';
import 'block_puzzle_app.dart';

/// Whether `Firebase.initializeApp()` actually succeeded.
///
/// Everything downstream of Firebase - Crashlytics, Analytics, Remote Config,
/// Auth - is useless when this is false, and the failure used to be swallowed
/// whole, so a build with no `google-services.json` looked healthy while
/// reporting nothing. Callers can read this to tell "no events" apart from
/// "no connection".
bool get firebaseReady => _firebaseReady;
bool _firebaseReady = false;

/// Startup logger used before the DI container exists.
///
/// Deliberately independent of Firebase: the one error we most need to see is
/// Firebase failing to start, and reporting that through Crashlytics or
/// Analytics would route it into the thing that just failed.
final AppLogger _startupLogger = AppLogger();

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase();

  await Hive.initFlutter();
  await SystemChrome.setPreferredOrientations(
    const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ],
  );
  await configureDependencies();
  _configureGlobalErrorHandlers();

  if (!_firebaseReady) {
    // Now that DI exists the analytics queue can carry it too, but the log
    // above is what survives when nothing else does.
    unawaited(
      sl<AnalyticsTracker>().track(
        'ops_error',
        params: <String, Object?>{
          'source': 'firebase_init',
          'error_type': 'FirebaseInitializationFailed',
          'message': 'Firebase is not initialized; remote services are inert',
        },
      ),
    );
  }

  runApp(const BlockPuzzleApp());
}

Future<void> _initializeFirebase() async {
  try {
    // Explicit options rather than the implicit lookup: on Android the implicit
    // form reads google-services.json through the Gradle plugin, which works,
    // but it fails silently on any platform where that file is absent. The
    // generated options are checked in and therefore always present.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firebaseReady = true;
  } catch (error, stackTrace) {
    _firebaseReady = false;
    _startupLogger.error(
      'Firebase.initializeApp failed: $error. Crashlytics, Analytics, Remote '
      'Config and Auth will be inert. Missing google-services.json or '
      'firebase_options.dart is the usual cause.',
    );
    // In debug this must be impossible to miss; shipping a build that silently
    // lost its whole data plane is the failure mode being guarded against.
    assert(() {
      debugPrint('$stackTrace');
      throw StateError('Firebase failed to initialize in a debug build: $error');
    }());
  }
}

/// Top-level handler for anything that escapes [bootstrap].
///
/// Installed by `main()` via `runZonedGuarded`, so it also catches failures
/// that happen before the DI container and the Flutter error handlers exist.
void reportBootstrapError(Object error, StackTrace stackTrace) {
  _startupLogger.error('Unhandled startup error: $error');
  debugPrint('$stackTrace');

  if (!sl.isRegistered<CrashReporter>()) {
    return;
  }
  unawaited(
    sl<CrashReporter>().recordError(error, stackTrace, reason: 'bootstrap'),
  );
}

void _configureGlobalErrorHandlers() {
  final AnalyticsTracker analyticsTracker = sl<AnalyticsTracker>();
  final CrashReporter crashReporter = sl<CrashReporter>();
  final AppLogger logger = sl<AppLogger>();

  final previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (previousFlutterErrorHandler != null) {
      previousFlutterErrorHandler(details);
    } else {
      FlutterError.presentError(details);
    }

    logger.error('FlutterError: ${details.exceptionAsString()}');
    unawaited(
      crashReporter.recordError(
        details.exception,
        details.stack,
        reason: 'flutter_error',
      ),
    );
    unawaited(
      analyticsTracker.track(
        'ops_error',
        params: <String, Object?>{
          'source': 'flutter_error',
          'error_type': details.exception.runtimeType.toString(),
          'message': details.exceptionAsString(),
        },
      ),
    );
  };

  final previousPlatformDispatcherErrorHandler =
      PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (
    Object error,
    StackTrace stackTrace,
  ) {
    logger.error('Unhandled error: $error');
    unawaited(
      crashReporter.recordError(error, stackTrace, reason: 'platform_dispatcher'),
    );
    unawaited(
      analyticsTracker.track(
        'ops_error',
        params: <String, Object?>{
          'source': 'platform_dispatcher',
          'error_type': error.runtimeType.toString(),
          'message': '$error',
        },
      ),
    );
    return previousPlatformDispatcherErrorHandler?.call(error, stackTrace) ??
        false;
  };
}
