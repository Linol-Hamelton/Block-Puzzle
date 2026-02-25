import 'package:get_it/get_it.dart';

import '../../data/analytics/analytics_tracker.dart';
import '../../data/analytics/debug_analytics_tracker.dart';
import '../../data/remote_config/in_memory_remote_config_repository.dart';
import '../../data/remote_config/remote_config_repository.dart';
import '../../data/repositories/in_memory_player_progress_repository.dart';
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
import '../../features/game_loop/audio/flame_game_sfx_player.dart';
import '../../features/game_loop/audio/game_sfx_player.dart';
import '../../features/game_loop/application/game_loop_controller.dart';
import '../../features/game_loop/application/use_cases/clear_lines_use_case.dart';
import '../../features/game_loop/application/use_cases/compute_score_use_case.dart';
import '../../features/game_loop/application/use_cases/place_piece_use_case.dart';
import '../../features/game_loop/presentation/block_puzzle_game.dart';
import '../../features/monetization/ad_guardrail_policy.dart';
import '../../features/monetization/ad_service.dart';
import '../../features/monetization/basic_ad_guardrail_policy.dart';
import '../../features/monetization/debug_iap_store_service.dart';
import '../../features/monetization/debug_ad_service.dart';
import '../../features/monetization/iap_store_service.dart';
import '../../features/store/application/store_controller.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<AppConfig>()) {
    return;
  }

  final InMemoryRemoteConfigRepository inMemoryRemoteConfigRepository =
      InMemoryRemoteConfigRepository();
  final Map<String, Object?> bootstrapRemoteConfig =
      await inMemoryRemoteConfigRepository.getCached();
  final bool includeBundle = _resolveIapBundleEnabled(bootstrapRemoteConfig);

  sl.registerSingleton<AppConfig>(
    const AppConfig(
      appName: 'Block Puzzle',
      environment: 'dev',
    ),
  );
  sl.registerLazySingleton<AppLogger>(AppLogger.new);
  sl.registerLazySingleton<GameSfxPlayer>(
    () => FlameGameSfxPlayer(logger: sl()),
  );
  sl.registerLazySingleton<AdService>(
    () => DebugAdService(logger: sl()),
  );
  sl.registerLazySingleton<RemoteConfigRepository>(
    () => inMemoryRemoteConfigRepository,
  );
  sl.registerLazySingleton<PlayerProgressRepository>(
    InMemoryPlayerProgressRepository.new,
  );
  sl.registerLazySingleton<IapStoreService>(
    () => DebugIapStoreService(
      includeBundle: includeBundle,
    ),
  );
  sl.registerLazySingleton<AdGuardrailPolicy>(
    BasicAdGuardrailPolicy.new,
  );
  sl.registerLazySingleton<AnalyticsTracker>(
    () => DebugAnalyticsTracker(logger: sl()),
  );

  sl.registerLazySingleton<MoveValidator>(BasicMoveValidator.new);
  sl.registerLazySingleton<LineClearService>(BasicLineClearService.new);
  sl.registerLazySingleton<ScoreService>(BasicScoreService.new);
  sl.registerLazySingleton<PieceGenerationService>(
    BasicPieceGenerationService.new,
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
      playerProgressRepository: sl(),
      logger: sl(),
    ),
  );

  sl.registerFactory<BlockPuzzleGame>(
    () => BlockPuzzleGame(
      controller: sl(),
      sfxPlayer: sl(),
    ),
  );

  sl.registerFactory<StoreController>(
    () => StoreController(
      iapStoreService: sl(),
      analyticsTracker: sl(),
      logger: sl(),
    ),
  );
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
