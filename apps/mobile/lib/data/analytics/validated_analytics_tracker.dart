import '../../core/logging/app_logger.dart';
import 'analytics_schema_validator.dart';
import 'analytics_tracker.dart';

/// Decorator that enforces the analytics schema on the **production** path
/// before delegating to a transport [AnalyticsTracker] (e.g.
/// `FirebaseAnalyticsTracker`).
///
/// Background: production previously routed straight through an unvalidated
/// transport while the validated implementation sat orphaned (see
/// `docs/adr/001-analytics-tracker-choice.md`). This decorator resolves that by
/// making schema validation a transport-independent concern:
///
/// * enriches every event with `schema_version` and `event_ts_utc`,
/// * validates against [AnalyticsSchemaValidator],
/// * logs warnings (unknown event / unknown params) but still forwards,
/// * **quarantines** events missing required params (logs + drops, never sent),
/// * forwards valid events to the wrapped transport.
///
/// Wrap any transport with this in the composition root so Firebase (or a future
/// HTTP pipeline) receives only schema-valid events. Mirrors the validation that
/// `DebugAnalyticsTracker` already performs in debug builds, so debug and release
/// now apply the same contract.
class ValidatedAnalyticsTracker implements AnalyticsTracker {
  ValidatedAnalyticsTracker({
    required AnalyticsTracker inner,
    required AppLogger logger,
    AnalyticsSchemaValidator? schemaValidator,
    DateTime Function()? nowUtcProvider,
  })  : _inner = inner,
        _logger = logger,
        _schemaValidator = schemaValidator ?? const AnalyticsSchemaValidator(),
        _nowUtc = nowUtcProvider ?? (() => DateTime.now().toUtc());

  final AnalyticsTracker _inner;
  final AppLogger _logger;
  final AnalyticsSchemaValidator _schemaValidator;
  final DateTime Function() _nowUtc;

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {
    final Map<String, Object?> payload = Map<String, Object?>.from(params);
    payload.putIfAbsent('schema_version', () => _schemaValidator.schemaVersion);
    payload.putIfAbsent(
      'event_ts_utc',
      () => _nowUtc().toIso8601String(),
    );

    final AnalyticsValidationResult validation = _schemaValidator.validate(
      eventName,
      params: payload,
    );

    if (validation.warnings.isNotEmpty) {
      _logger.warn(
        'Analytics warnings for "$eventName": ${validation.warnings.join(' | ')}',
      );
    }

    if (!validation.isValid) {
      _logger.error(
        '[ANALYTICS][QUARANTINE] $eventName '
        'missing=${validation.missingRequired.join(',')}',
      );
      return;
    }

    await _inner.track(eventName, params: payload);
  }

  @override
  Future<void> flush({bool force = false}) => _inner.flush(force: force);

  @override
  Future<void> close() => _inner.close();
}
