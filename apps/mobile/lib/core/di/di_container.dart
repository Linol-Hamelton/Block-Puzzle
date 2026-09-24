import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../features/diagnostics/diagnostics_screen.dart';
import '../../features/diagnostics/frame_timing_recorder.dart';
import '../../core/audio/music_controller.dart';
import '../../core/audio/music_playlist_manager.dart';
import '../../core/config/app_environment.dart';
import '../../core/config/remote_config_reader.dart';
import '../../core/device/haptics_controller.dart';
import '../../infra/billing/cloud_functions_receipt_validator.dart';
import '../../infra/billing/google_play_billing_service.dart';
import '../../infra/monitoring/crash_reporter.dart';
import '../../infra/monitoring/firebase_crash_reporter.dart';
import '../../infra/monitoring/noop_crash_reporter.dart';
import '../../data/analytics/analytics_tracker.dart';
import '../../data/analytics/debug_analytics_tracker.dart';
import '../../data/analytics/firebase_analytics_tracker.dart';
import '../../data/analytics/validated_analytics_tracker.dart';
import '../../data/progression/cloud_player_progress_repository.dart';
import '../../data/remote_config/firebase_remote_config_repository.dart';
import '../../data/remote_config/in_memory_remote_config_repository.dart';
import '../../data/remote_config/remote_config_repository.dart';
import '../../data/repositories/hive_game_session_repository.dart';
import '../../data/repositories/hive_player_progress_repository.dart';
import '../../domain/generator/basic_difficulty_tuner.dart';
import '../../domain/generator/basic_piece_generation_service.dart';
import '../../domain/generator/difficulty_tuner.dart';
import '../../domain/generator/piece_generation_service.dart';
import '../../domain/gameplay/basic_line_clear_service.dart';
import '../../domain/gameplay/basic_move_validator.dart';
import '../../domain/gameplay/line_clear_service.dart';
import '../../domain/gameplay/move_validator.dart';
import '../../domain/progression/player_progress_repository.dart';
import '../../domain/scoring/basic_score_service.dart';
import '../../domain/scoring/score_service.dart';
import '../../domain/session/game_session_repository.dart';
import '../../features/game_modes/game_mode_availability.dart';
import '../../features/game_loop/audio/flame_game_sfx_player.dart';
import '../../features/game_loop/audio/game_sfx_player.dart';
import '../../features/game_loop/application/game_loop_controller.dart';
import '../../features/game_loop/application/services/ab_experiment_service.dart';
import '../../features/game_loop/application/services/onboarding_flow_controller.dart';
import '../../features/game_loop/application/services/progression_sync_service.dart';
import '../../features/game_loop/application/services/share_flow_service.dart';
import '../../features/game_loop/application/use_cases/clear_lines_use_case.dart';
import '../../features/game_loop/application/use_cases/compute_score_use_case.dart';
import '../../features/game_loop/application/use_cases/place_piece_use_case.dart';
import '../../features/game_loop/presentation/block_puzzle_game.dart';
import '../../features/monetization/ad_guardrail_policy.dart';
import '../../features/monetization/ad_service.dart';
import '../../features/monetization/basic_ad_guardrail_policy.dart';
import '../../features/monetization/disabled_ad_service.dart';
import '../../features/monetization/debug_iap_store_service.dart';
import '../../features/monetization/debug_ad_service.dart';
import '../../features/monetization/iap_store_service.dart';
import '../../features/monetization/local_catalog_iap_store_service.dart';
import '../../features/store/application/store_availability.dart';
import '../../features/store/application/store_controller.dart';
import '../../features/match3/application/match3_session_store.dart';
import '../../features/tetris/application/tetris_session_store.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies({
  AppConfig? overrideAppConfig,
  RemoteConfigRepository? overrideRemoteConfigRepository,
}) async {
  if (sl.isRegistered<AppConfig>()) {
    return;
  }

  final AppConfig appConfig = overrideAppConfig ?? AppConfig.fromEnvironment();
  final AppLogger logger = AppLogger();
  final bool useDebugAdapters = appConfig.useDebugAdapters;

  // A release binary must never resolve the debug adapters. Without
  // `--dart-define` the environment falls back to dev/debug, which would give a
  // shipped build DebugIapStoreService (simulated purchases) and
  // NoopCrashReporter (no telemetry) while everything still looks normal.
  // Fail loudly here instead of discovering it from store reviews. See DEC-0007.
  if (kReleaseMode && useDebugAdapters) {
    throw StateError(
      'Release build resolved the debug adapters: APP_ENV='
      '${appConfig.environment.wireName}, APP_FLAVOR='
      '${appConfig.buildFlavor.wireName}. Pass --dart-define=APP_ENV=prod '
      '--dart-define=APP_FLAVOR=release when building for distribution.',
    );
  }

  final RemoteConfigRepository bootstrapRemoteConfigRepository =
      overrideRemoteConfigRepository ??
          (useDebugAdapters
              ? InMemoryRemoteConfigRepository(appConfig: appConfig)
              : FirebaseRemoteConfigRepository(
                  appConfig: appConfig,
                  logger: logger,
                ));
  final Map<String, Object?> bootstrapRemoteConfig =
      await bootstrapRemoteConfigRepository.getCached();
  final RemoteConfigReader bootstrapConfigReader =
      RemoteConfigReader(bootstrapRemoteConfig);
  final bool isStoreEnabled = bootstrapConfigReader.readBool(
    'iap.store_enabled',
    fallback: false,
  );
  final bool includeBundle = _resolveIapBundleEnabled(bootstrapRemoteConfig);
  final bool includeUtilityPass = bootstrapConfigReader.readBool(
    'iap.rewarded_tools_unlimited_enabled',
    fallback: false,
  );

  sl.registerSingleton<AppConfig>(
    appConfig,
  );
  sl.registerSingleton<AppLogger>(logger);
  sl.registerSingleton<HapticsController>(HapticsController());
  sl.registerLazySingleton<MusicPlaylistManager>(
    () => MusicPlaylistManager(logger: sl()),
    dispose: (MusicPlaylistManager manager) => manager.dispose(),
  );
  sl.registerLazySingleton<MusicController>(
    () => MusicController(logger: sl(), playlistManager: sl()),
    dispose: (MusicController controller) => controller.dispose(),
  );
  sl.registerLazySingleton<CrashReporter>(
    () => useDebugAdapters ? const NoopCrashReporter() : const FirebaseCrashReporter(),
  );
  sl.registerLazySingleton<GameSfxPlayer>(
    () => FlameGameSfxPlayer(
      logger: sl(),
      musicController: sl<MusicController>(),
    ),
    dispose: (GameSfxPlayer player) => player.dispose(),
  );
  sl.registerLazySingleton<AdService>(
    () => useDebugAdapters
        ? DebugAdService(logger: sl())
        : const DisabledAdService(),
  );
  sl.registerLazySingleton<RemoteConfigRepository>(
    () => bootstrapRemoteConfigRepository,
  );
  sl.registerLazySingleton<PlayerProgressRepository>(
    () => CloudPlayerProgressRepository(
      localRepository: HivePlayerProgressRepository(logger: sl()),
      logger: sl(),
    ),
  );
  sl.registerLazySingleton<GameSessionRepository>(
    () => HiveGameSessionRepository(logger: sl()),
  );
  sl.registerLazySingleton<IapStoreService>(
    () {
      if (useDebugAdapters) {
        return DebugIapStoreService(
          includeBundle: includeBundle,
          includeUtilityPass: includeUtilityPass,
          storeEnabled: isStoreEnabled,
        );
      }
      // Real Google Play Billing + server-side receipt validation in
      // production. Stage/QA release builds use the local catalog so they can
      // be exercised without Play Console SKUs configured.
      if (appConfig.environment.isProduction) {
        return GooglePlayBillingService(
          playerProgressRepository: sl(),
          remoteConfigRepository: sl(),
          receiptValidator: CloudFunctionsReceiptValidator(logger: sl()),
          logger: sl(),
        );
      }
      return LocalCatalogIapStoreService(
        playerProgressRepository: sl(),
        remoteConfigRepository: sl(),
        logger: sl(),
      );
    },
  );
  // The DEC-0002 kill switches finally get a consumer. Resolved from the same
  // bootstrap config the rest of the container uses, so a mode disabled
  // remotely is closed from the first frame rather than after a later fetch.
  sl.registerSingleton<GameModeAvailability>(
    GameModeAvailability(bootstrapConfigReader),
  );
  // DEC-0026 / DEC-0028: Store and monetization surfaces availability gate.
  sl.registerSingleton<StoreAvailability>(
    StoreAvailability(bootstrapConfigReader),
  );

  sl.registerLazySingleton<AdGuardrailPolicy>(
    BasicAdGuardrailPolicy.new,
  );
  sl.registerLazySingleton<AnalyticsTracker>(
    () => useDebugAdapters
        ? DebugAnalyticsTracker(logger: sl())
        : ValidatedAnalyticsTracker(
            inner: FirebaseAnalyticsTracker(logger: sl()),
            logger: sl(),
          ),
  );

  sl.registerLazySingleton<MoveValidator>(BasicMoveValidator.new);
  sl.registerLazySingleton<LineClearService>(BasicLineClearService.new);
  sl.registerLazySingleton<ScoreService>(BasicScoreService.new);
  sl.registerLazySingleton<PieceGenerationService>(
    () => BasicPieceGenerationService(moveValidator: sl()),
  );
  sl.registerLazySingleton<DifficultyTuner>(BasicDifficultyTuner.new);

  sl.registerLazySingleton<PlacePieceUseCase>(
    () => PlacePieceUseCase(moveValidator: sl()),
  );
  sl.registerLazySingleton<ClearLinesUseCase>(
    () => ClearLinesUseCase(lineClearService: sl()),
  );
  sl.registerLazySingleton<ComputeScoreUseCase>(
    () => ComputeScoreUseCase(scoreService: sl()),
  );

  sl.registerFactory<ABExperimentService>(
    () => ABExperimentService(
      analyticsTracker: sl(),
      logger: sl(),
    ),
  );

  sl.registerLazySingleton<ShareFlowService>(
    () => ShareFlowService(
      analyticsTracker: sl(),
      hashtag: ShareFlowService.normalizeHashtag(
        bootstrapConfigReader.readString(
          'social.share_score_hashtag',
          fallback: '#BlockPuzzle',
        ),
      ),
    ),
  );
  sl.registerFactory<OnboardingFlowController>(
    () => OnboardingFlowController(
      playerProgressRepository: sl(),
      analyticsTracker: sl(),
      logger: sl(),
    ),
  );

  sl.registerFactory<ProgressionSyncService>(
    () => ProgressionSyncService(
      playerProgressRepository: sl(),
      analyticsTracker: sl(),
      logger: sl(),
    ),
  );

  sl.registerFactory<GameLoopController>(
    () => GameLoopController(
      placePieceUseCase: sl(),
      clearLinesUseCase: sl(),
      computeScoreUseCase: sl(),
      pieceGenerationService: sl(),
      difficultyTuner: sl(),
      remoteConfigRepository: sl(),
      analyticsTracker: sl(),
      adService: sl(),
      adGuardrailPolicy: sl(),
      iapStoreService: sl(),
      gameSessionRepository: sl(),
      progressionSyncService: sl(),
      abExperimentService: sl(),
      shareFlowService: sl(),
      onboardingFlowController: sl(),
      logger: sl(),
      appVersion: sl<AppConfig>().appVersion,
    ),
  );

  sl.registerFactory<BlockPuzzleGame>(
    () => BlockPuzzleGame(
      controller: sl(),
      sfxPlayer: sl(),
      haptics: sl(),
    ),
  );

  sl.registerLazySingleton<TetrisSessionStore>(
    () => TetrisSessionStore(logger: sl()),
  );

  sl.registerLazySingleton<Match3SessionStore>(
    () => Match3SessionStore(logger: sl()),
  );

  sl.registerFactory<StoreController>(
    () => StoreController(
      iapStoreService: sl(),
      remoteConfigRepository: sl(),
      playerProgressRepository: sl(),
      analyticsTracker: sl(),
      logger: sl(),
    ),
  );

  if (kDiagnosticsEnabled) {
    sl.registerLazySingleton<FrameTimingRecorder>(
      () => FrameTimingRecorder(capacity: 3600),
    );
  }
}

bool _resolveIapBundleEnabled(Map<String, Object?> config) {
  final Object? bundleEnabledRaw = config['iap.bundle_enabled'];
  if (bundleEnabledRaw is bool) {
    return bundleEnabledRaw;
  }
  if (bundleEnabledRaw is num) {
    return bundleEnabledRaw > 0;
  }
  if (bundleEnabledRaw is String) {
    final String normalized = bundleEnabledRaw.trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }
  }

  final String rolloutStrategy =
      (config['iap.rollout_strategy'] as String?)?.trim() ?? 'cosmetics_first';
  return rolloutStrategy == 'cosmetics_bundle' ||
      rolloutStrategy == 'bundle_first';
}

@visibleForTesting
Future<void> resetDependencies() async {
  await sl.reset();
}
