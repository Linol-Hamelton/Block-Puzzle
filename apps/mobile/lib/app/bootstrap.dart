import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'block_puzzle_app.dart';
import '../core/logging/app_logger.dart';
import '../core/di/di_container.dart';
import '../data/analytics/analytics_tracker.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  _configureGlobalErrorHandlers();
  runApp(const BlockPuzzleApp());
}

void _configureGlobalErrorHandlers() {
  final AnalyticsTracker analyticsTracker = sl<AnalyticsTracker>();
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
