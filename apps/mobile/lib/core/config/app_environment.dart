enum AppEnvironment {
  dev,
  stage,
  prod;

  static AppEnvironment fromWire(String rawValue) {
    switch (rawValue.trim().toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'stage':
      case 'staging':
        return AppEnvironment.stage;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.dev;
    }
  }
}

enum BuildFlavor {
  debug,
  stage,
  release;

  static BuildFlavor fromWire(String rawValue) {
    switch (rawValue.trim().toLowerCase()) {
      case 'release':
      case 'prod':
      case 'production':
        return BuildFlavor.release;
      case 'stage':
      case 'staging':
        return BuildFlavor.stage;
      case 'debug':
      case 'dev':
      case 'development':
      default:
        return BuildFlavor.debug;
    }
  }
}

extension AppEnvironmentX on AppEnvironment {
  String get wireName {
    switch (this) {
      case AppEnvironment.dev:
        return 'dev';
      case AppEnvironment.stage:
        return 'stage';
      case AppEnvironment.prod:
        return 'prod';
    }
  }

  bool get isDevelopment => this == AppEnvironment.dev;

  bool get isStage => this == AppEnvironment.stage;

  bool get isProduction => this == AppEnvironment.prod;
}

extension BuildFlavorX on BuildFlavor {
  String get wireName {
    switch (this) {
      case BuildFlavor.debug:
        return 'debug';
      case BuildFlavor.stage:
        return 'stage';
      case BuildFlavor.release:
        return 'release';
    }
  }

  bool get isDebug => this == BuildFlavor.debug;

  bool get isStage => this == BuildFlavor.stage;

  bool get isRelease => this == BuildFlavor.release;
}
