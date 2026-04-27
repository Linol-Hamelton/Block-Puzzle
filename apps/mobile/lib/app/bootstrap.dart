import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/di/di_container.dart';
import '../core/logging/app_logger.dart';
import '../data/analytics/analytics_tracker.dart';
import '../infra/monitoring/crash_reporter.dart';
import 'block_puzzle_app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Ignore if not configured yet via flutterfire
  }
  
  await Hive.initFlutter();
  await SystemChrome.setPreferredOrientations(
    const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ],
  );
  await configureDependencies();
  _configureGlobalErrorHandlers();
  runApp(const BlockPuzzleApp());
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
