import 'crash_reporter.dart';

/// No-op [CrashReporter] for debug/dev builds.
///
/// Silently discards all crash reports. Keeps the contract satisfied
/// without requiring Firebase SDK availability during development.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}

  @override
  Future<void> setUserId(String userId) async {}

  @override
  Future<void> log(String message) async {}
}
