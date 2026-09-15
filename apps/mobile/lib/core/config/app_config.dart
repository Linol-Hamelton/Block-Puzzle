import 'app_environment.dart';

class AppConfig {
  const AppConfig({
    required this.appName,
    required this.environment,
    required this.buildFlavor,
    required this.appVersion,
    required this.bundledRemoteConfigVersion,
    required this.remoteConfigTtl,
    this.configApiBaseUrl,
    this.analyticsApiBaseUrl,
  });

  factory AppConfig.fromEnvironment() {
    final AppEnvironment environment = AppEnvironment.fromWire(
      const String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'dev',
      ),
    );

    // Each key is read as a compile-time constant with a literal name.
    //
    // `String.fromEnvironment(someVariable)` cannot be const-evaluated, and in
    // AOT it silently yields the default instead of the value that was passed
    // with --dart-define. It used to be read through a helper taking the key as
    // a parameter, so JIT and AOT disagreed: a build carrying
    // APP_ENV=prod --dart-define=APP_FLAVOR=stage ran as `stage` in debug and
    // as `release` once compiled. Ordinary prod/release builds were unaffected,
    // because there the fallback happens to equal the intended value - which is
    // why nothing looked wrong.
    const String explicitFlavor = String.fromEnvironment('APP_FLAVOR');
    const String configApiUrl = String.fromEnvironment('CONFIG_API_BASE_URL');
    const String analyticsApiUrl =
        String.fromEnvironment('ANALYTICS_API_BASE_URL');
    return AppConfig(
      appName: const String.fromEnvironment(
        'APP_NAME',
        defaultValue: 'Lumina Blocks',
      ),
      environment: environment,
      buildFlavor: BuildFlavor.fromWire(
        explicitFlavor.trim().isNotEmpty
            ? explicitFlavor.trim()
            : _defaultFlavorForEnvironment(environment),
      ),
      appVersion: const String.fromEnvironment(
        'APP_VERSION',
        defaultValue: '1.0.0+1',
      ),
      bundledRemoteConfigVersion: const String.fromEnvironment(
        'BUNDLED_REMOTE_CONFIG_VERSION',
        defaultValue: 'bundled_config_v1',
      ),
      remoteConfigTtl: const Duration(
        minutes: int.fromEnvironment(
          'REMOTE_CONFIG_TTL_MINUTES',
          defaultValue: 30,
        ),
      ),
      configApiBaseUrl: _nullIfBlank(configApiUrl),
      analyticsApiBaseUrl: _nullIfBlank(analyticsApiUrl),
    );
  }

  final String appName;
  final AppEnvironment environment;
  final BuildFlavor buildFlavor;
  final String appVersion;
  final String bundledRemoteConfigVersion;
  final Duration remoteConfigTtl;
  final String? configApiBaseUrl;
  final String? analyticsApiBaseUrl;

  bool get hasConfigApi =>
      configApiBaseUrl != null && configApiBaseUrl!.trim().isNotEmpty;

  bool get hasAnalyticsApi =>
      analyticsApiBaseUrl != null && analyticsApiBaseUrl!.trim().isNotEmpty;

  /// Whether the composition root should wire the debug-only adapters
  /// (`DebugIapStoreService`, `DebugAnalyticsTracker`,
  /// `InMemoryRemoteConfigRepository`, `NoopCrashReporter`).
  ///
  /// This lives here, rather than inline in the container, so that the choice
  /// is testable without building a DI graph. It is the single most dangerous
  /// piece of configuration in the app: [AppEnvironment.dev] and
  /// [BuildFlavor.debug] are the defaults, so a build that forgets to pass
  /// `--dart-define` resolves the debug adapters and will simulate purchases
  /// and send no telemetry while looking like a release. See DEC-0007.
  bool get useDebugAdapters =>
      environment.isDevelopment && buildFlavor.isDebug;

  /// Normalises an already-read compile-time value.
  ///
  /// Takes the value, never the key: a helper that reads
  /// `String.fromEnvironment(key)` from a parameter cannot be const-evaluated
  /// and loses the define in AOT. See the comment in [AppConfig.fromEnvironment].
  static String? _nullIfBlank(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _defaultFlavorForEnvironment(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.dev:
        return 'debug';
      case AppEnvironment.stage:
        return 'stage';
      case AppEnvironment.prod:
        return 'release';
    }
  }
}
