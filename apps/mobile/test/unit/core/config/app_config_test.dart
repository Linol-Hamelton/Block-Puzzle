import 'package:block_puzzle_mobile/core/config/app_config.dart';
import 'package:block_puzzle_mobile/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the adapter-selection rule behind DEC-0007.
///
/// The composition root wires either the real Firebase/Play adapters or the
/// debug stand-ins, and the whole decision reduces to [AppConfig.useDebugAdapters].
/// Getting it wrong is silent: a release binary with the debug adapters
/// simulates purchases and sends no telemetry while behaving normally. These
/// tests pin the rule so the default cannot drift back.
void main() {
  AppConfig configOf(AppEnvironment env, BuildFlavor flavor) => AppConfig(
        appName: 'Lumina Blocks',
        environment: env,
        buildFlavor: flavor,
        appVersion: '1.0.0+1',
        bundledRemoteConfigVersion: 'bundled_config_v1',
        remoteConfigTtl: const Duration(minutes: 30),
      );

  group('AppConfig.useDebugAdapters', () {
    test('is true only for dev + debug', () {
      expect(
        configOf(AppEnvironment.dev, BuildFlavor.debug).useDebugAdapters,
        isTrue,
      );
    });

    test('is false for every other environment and flavor combination', () {
      for (final AppEnvironment env in AppEnvironment.values) {
        for (final BuildFlavor flavor in BuildFlavor.values) {
          final bool isDevDebug =
              env == AppEnvironment.dev && flavor == BuildFlavor.debug;
          expect(
            configOf(env, flavor).useDebugAdapters,
            isDevDebug,
            reason: 'env=${env.wireName} flavor=${flavor.wireName} '
                'must ${isDevDebug ? '' : 'not '}use debug adapters',
          );
        }
      }
    });

    test('production release never uses debug adapters', () {
      expect(
        configOf(AppEnvironment.prod, BuildFlavor.release).useDebugAdapters,
        isFalse,
      );
    });
  });

  group('AppConfig.fromEnvironment defaults', () {
    test('falls back to dev/debug when no dart-define is passed', () {
      // This is the trap DEC-0007 is about: the fallback is the dangerous
      // value, so a distribution build that forgets --dart-define looks fine
      // and behaves like a debug build. The release workflows pass
      // APP_ENV=prod and APP_FLAVOR=release, and configureDependencies()
      // throws in release mode when this fallback is hit anyway.
      final AppConfig config = AppConfig.fromEnvironment();

      expect(config.environment, AppEnvironment.dev);
      expect(config.buildFlavor, BuildFlavor.debug);
      expect(config.useDebugAdapters, isTrue);
    });
  });

  group('flavor derivation', () {
    test('an explicit flavor wins over the environment default', () {
      expect(
        configOf(AppEnvironment.prod, BuildFlavor.debug).buildFlavor,
        BuildFlavor.debug,
      );
    });

    test('wire parsing is tolerant of the usual spellings', () {
      expect(AppEnvironment.fromWire('production'), AppEnvironment.prod);
      expect(AppEnvironment.fromWire(' PROD '), AppEnvironment.prod);
      expect(BuildFlavor.fromWire('release'), BuildFlavor.release);
      expect(BuildFlavor.fromWire('anything-unknown'), BuildFlavor.debug);
      expect(AppEnvironment.fromWire('anything-unknown'), AppEnvironment.dev);
    });
  });
}
