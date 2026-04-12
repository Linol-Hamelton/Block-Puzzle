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

    final String explicitFlavor = _readOptionalEnvironmentValue('APP_FLAVOR') ?? '';
    return AppConfig(
      appName: const String.fromEnvironment(
        'APP_NAME',
        defaultValue: 'Lumina Blocks',
      ),
      environment: environment,
      buildFlavor: BuildFlavor.fromWire(
        explicitFlavor.isNotEmpty
            ? explicitFlavor
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
      configApiBaseUrl: _readOptionalEnvironmentValue('CONFIG_API_BASE_URL'),
      analyticsApiBaseUrl:
          _readOptionalEnvironmentValue('ANALYTICS_API_BASE_URL'),
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

  static String? _readOptionalEnvironmentValue(String key) {
    final String value = String.fromEnvironment(key, defaultValue: '').trim();
    return value.isEmpty ? null : value;
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
