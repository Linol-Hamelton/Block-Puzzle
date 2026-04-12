import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import 'analytics_tracker.dart';
import 'analytics_schema_validator.dart';

class DebugAnalyticsTracker implements AnalyticsTracker {
  DebugAnalyticsTracker({
    required this.logger,
    AnalyticsSchemaValidator? schemaValidator,
  }) : _schemaValidator = schemaValidator ?? const AnalyticsSchemaValidator();

  final AppLogger logger;
  final AnalyticsSchemaValidator _schemaValidator;

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {
    if (kReleaseMode) {
      return;
    }

    final Map<String, Object?> payload = Map<String, Object?>.from(params);
    payload.putIfAbsent('schema_version', () => _schemaValidator.schemaVersion);
    payload.putIfAbsent(
      'event_ts_utc',
      () => DateTime.now().toUtc().toIso8601String(),
    );

    final AnalyticsValidationResult validation = _schemaValidator.validate(
      eventName,
      params: payload,
    );

    if (validation.warnings.isNotEmpty) {
      logger.warn(
        'Analytics warnings for "$eventName": ${validation.warnings.join(' | ')}',
      );
    }

    if (!validation.isValid) {
      logger.error(
        '[ANALYTICS][QUARANTINE] $eventName '
        'missing=${validation.missingRequired}',
      );
      return;
    }

    debugPrint('[ANALYTICS] $eventName $payload');
  }

  @override
  Future<void> flush({
    bool force = false,
  }) async {}

  @override
  Future<void> close() async {}
}
