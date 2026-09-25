import 'package:block_puzzle_mobile/core/audio/music_controller.dart';
import 'package:block_puzzle_mobile/core/audio/music_playlist_manager.dart';
import 'package:block_puzzle_mobile/core/config/app_config.dart';
import 'package:block_puzzle_mobile/core/config/app_environment.dart';
import 'package:block_puzzle_mobile/core/di/di_container.dart';
import 'package:block_puzzle_mobile/data/analytics/analytics_tracker.dart';
import 'package:block_puzzle_mobile/data/analytics/debug_analytics_tracker.dart';
import 'package:block_puzzle_mobile/data/analytics/firebase_analytics_tracker.dart';
import 'package:block_puzzle_mobile/data/analytics/validated_analytics_tracker.dart';
import 'package:block_puzzle_mobile/data/remote_config/in_memory_remote_config_repository.dart';
import 'package:block_puzzle_mobile/features/game_modes/game_mode_availability.dart';
import 'package:block_puzzle_mobile/features/store/application/store_availability.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_service.dart';
import 'package:block_puzzle_mobile/features/monetization/debug_ad_service.dart';
import 'package:block_puzzle_mobile/features/monetization/debug_iap_store_service.dart';
import 'package:block_puzzle_mobile/features/monetization/disabled_ad_service.dart';
import 'package:block_puzzle_mobile/features/monetization/iap_store_service.dart';
import 'package:block_puzzle_mobile/features/monetization/local_catalog_iap_store_service.dart';
import 'package:block_puzzle_mobile/infra/billing/google_play_billing_service.dart';
import 'package:block_puzzle_mobile/infra/monitoring/crash_reporter.dart';
import 'package:block_puzzle_mobile/infra/monitoring/firebase_crash_reporter.dart';
import 'package:block_puzzle_mobile/infra/monitoring/noop_crash_reporter.dart';
import 'package:block_puzzle_mobile/domain/progression/player_progress_state.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/services/ab_experiment_service.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/services/onboarding_flow_controller.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/services/progression_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Explicit verification test required by DEC-0007.
///
/// Proves that the composition root resolves real production adapters
/// in production/release configuration, local catalog in stage, and debug
/// adapters only in development/debug configuration.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppConfig makeConfig(AppEnvironment env, BuildFlavor flavor) => AppConfig(
        appName: 'Lumina Blocks',
        environment: env,
        buildFlavor: flavor,
        appVersion: '1.0.0+1',
        bundledRemoteConfigVersion: 'bundled_config_v1',
        remoteConfigTtl: const Duration(minutes: 30),
      );

  tearDown(() async {
    await resetDependencies();
  });

  group('DEC-0007: Composition root adapter resolution', () {
    test('production release wires production adapters and not debug stand-ins', () async {
      final AppConfig prodConfig = makeConfig(AppEnvironment.prod, BuildFlavor.release);
      final InMemoryRemoteConfigRepository stubRemoteConfig =
          InMemoryRemoteConfigRepository(appConfig: prodConfig);

      await configureDependencies(
        overrideAppConfig: prodConfig,
        overrideRemoteConfigRepository: stubRemoteConfig,
      );

      expect(sl.isRegistered<AppConfig>(), isTrue);
      expect(sl<AppConfig>().environment, AppEnvironment.prod);
      expect(sl<AppConfig>().buildFlavor, BuildFlavor.release);
      expect(sl<AppConfig>().useDebugAdapters, isFalse);

      // CrashReporter must be FirebaseCrashReporter, not NoopCrashReporter
      final CrashReporter crashReporter = sl<CrashReporter>();
      expect(crashReporter, isA<FirebaseCrashReporter>());
      expect(crashReporter, isNot(isA<NoopCrashReporter>()));

      // AdService must be DisabledAdService, not DebugAdService
      final AdService adService = sl<AdService>();
      expect(adService, isA<DisabledAdService>());
      expect(adService, isNot(isA<DebugAdService>()));

      // AnalyticsTracker must be ValidatedAnalyticsTracker wrapping FirebaseAnalyticsTracker
      final AnalyticsTracker tracker = sl<AnalyticsTracker>();
      expect(tracker, isA<ValidatedAnalyticsTracker>());
      expect(tracker, isNot(isA<DebugAnalyticsTracker>()));
      final ValidatedAnalyticsTracker validatedTracker = tracker as ValidatedAnalyticsTracker;
      expect(validatedTracker.inner, isA<FirebaseAnalyticsTracker>());

      // IapStoreService in production must be GooglePlayBillingService
      final IapStoreService iapService = sl<IapStoreService>();
      expect(iapService, isA<GooglePlayBillingService>());
      expect(iapService, isNot(isA<DebugIapStoreService>()));
      expect(iapService, isNot(isA<LocalCatalogIapStoreService>()));

      // Mode and store availability and audio must be registered
      expect(sl.isRegistered<GameModeAvailability>(), isTrue);
      expect(sl.isRegistered<StoreAvailability>(), isTrue);
      expect(sl.isRegistered<MusicPlaylistManager>(), isTrue);
      expect(sl.isRegistered<MusicController>(), isTrue);
    });

    test('stage release wires LocalCatalogIapStoreService and production CrashReporter', () async {
      final AppConfig stageConfig = makeConfig(AppEnvironment.stage, BuildFlavor.stage);
      final InMemoryRemoteConfigRepository stubRemoteConfig =
          InMemoryRemoteConfigRepository(appConfig: stageConfig);

      await configureDependencies(
        overrideAppConfig: stageConfig,
        overrideRemoteConfigRepository: stubRemoteConfig,
      );

      expect(sl<AppConfig>().useDebugAdapters, isFalse);
      expect(sl<CrashReporter>(), isA<FirebaseCrashReporter>());
      expect(sl<IapStoreService>(), isA<LocalCatalogIapStoreService>());
      expect(sl<IapStoreService>(), isNot(isA<DebugIapStoreService>()));
    });

    test('dev debug wires debug adapters for local development', () async {
      final AppConfig devConfig = makeConfig(AppEnvironment.dev, BuildFlavor.debug);
      final InMemoryRemoteConfigRepository stubRemoteConfig =
          InMemoryRemoteConfigRepository(appConfig: devConfig);

      await configureDependencies(
        overrideAppConfig: devConfig,
        overrideRemoteConfigRepository: stubRemoteConfig,
      );

      expect(sl<AppConfig>().useDebugAdapters, isTrue);
      expect(sl<CrashReporter>(), isA<NoopCrashReporter>());
      expect(sl<AdService>(), isA<DebugAdService>());
      expect(sl<AnalyticsTracker>(), isA<DebugAnalyticsTracker>());
      expect(sl<IapStoreService>(), isA<DebugIapStoreService>());
    });

    test('DEC-0016: ABExperimentService, OnboardingFlowController, ProgressionSyncService resolve as fresh factory instances', () async {
      final AppConfig devConfig = makeConfig(AppEnvironment.dev, BuildFlavor.debug);
      final InMemoryRemoteConfigRepository stubRemoteConfig =
          InMemoryRemoteConfigRepository(appConfig: devConfig);

      await configureDependencies(
        overrideAppConfig: devConfig,
        overrideRemoteConfigRepository: stubRemoteConfig,
      );

      final ABExperimentService exp1 = sl<ABExperimentService>();
      final ABExperimentService exp2 = sl<ABExperimentService>();
      expect(identical(exp1, exp2), isFalse);

      final OnboardingFlowController onb1 = sl<OnboardingFlowController>();
      onb1.restoreFromProgress(
        PlayerProgressState.initialForDay(DateTime.utc(2026, 9, 25)).copyWith(
          onboardingStatus: const OnboardingStatus(completed: true),
        ),
      );
      expect(onb1.isCompleted, isTrue);

      final OnboardingFlowController onb2 = sl<OnboardingFlowController>();
      expect(identical(onb1, onb2), isFalse);
      expect(onb2.isCompleted, isFalse);

      final ProgressionSyncService prog1 = sl<ProgressionSyncService>();
      final ProgressionSyncService prog2 = sl<ProgressionSyncService>();
      expect(identical(prog1, prog2), isFalse);
    });

    test('DEC-0007: throws StateError in release mode if debug adapters would be resolved', () async {
      final AppConfig devConfig = makeConfig(AppEnvironment.dev, BuildFlavor.debug);
      final InMemoryRemoteConfigRepository stubRemoteConfig =
          InMemoryRemoteConfigRepository(appConfig: devConfig);

      expect(
        () => configureDependencies(
          overrideAppConfig: devConfig,
          overrideRemoteConfigRepository: stubRemoteConfig,
          isReleaseModeOverride: true,
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Release build resolved the debug adapters'),
          ),
        ),
      );
    });
  });
}
