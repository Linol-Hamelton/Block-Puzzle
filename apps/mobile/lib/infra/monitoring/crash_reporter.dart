/// Abstraction for crash/error reporting.
///
/// Production builds use [FirebaseCrashReporter]; debug builds use
/// [NoopCrashReporter]. Wired via DI in `di_container.dart`.
abstract class CrashReporter {
  /// Report a non-fatal error with optional stack trace and context.
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });

  /// Record a key-value breadcrumb for debugging context.
  Future<void> setCustomKey(String key, Object value);

  /// Associate the current session with a user identifier.
  Future<void> setUserId(String userId);

  /// Log a breadcrumb message.
  Future<void> log(String message);
}
