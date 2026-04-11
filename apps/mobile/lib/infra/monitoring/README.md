# infra/monitoring

Phase 1 Week 1.

Crash and ANR reporting layer. Implementations:
- `CrashReporter` abstraction — `recordError`, `recordFlutterError`, `setUserId`, `setCustomKey`, `log`
- `FirebaseCrashReporter` — production implementation
- `NoopCrashReporter` — dev-flavor implementation
- `runZonedGuarded` wrapper in [../../app/bootstrap.dart](../../app/bootstrap.dart) delegates `FlutterError.onError` and `PlatformDispatcher.instance.onError` to the active reporter

Empty in Phase 0.
