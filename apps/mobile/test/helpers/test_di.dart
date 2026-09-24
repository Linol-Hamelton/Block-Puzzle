import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:block_puzzle_mobile/core/audio/music_controller.dart';
import 'package:block_puzzle_mobile/core/audio/music_playlist_manager.dart';
import 'package:block_puzzle_mobile/core/config/app_config.dart';
import 'package:block_puzzle_mobile/core/config/app_environment.dart';
import 'package:block_puzzle_mobile/core/config/remote_config_reader.dart';
import 'package:block_puzzle_mobile/core/device/haptics_controller.dart';
import 'package:block_puzzle_mobile/core/di/di_container.dart';
import 'package:block_puzzle_mobile/core/logging/app_logger.dart';
import 'package:block_puzzle_mobile/data/analytics/analytics_tracker.dart';
import 'package:block_puzzle_mobile/data/analytics/debug_analytics_tracker.dart';
import 'package:block_puzzle_mobile/data/remote_config/in_memory_remote_config_repository.dart';
import 'package:block_puzzle_mobile/data/remote_config/remote_config_repository.dart';
import 'package:block_puzzle_mobile/data/repositories/in_memory_game_session_repository.dart';
import 'package:block_puzzle_mobile/data/repositories/in_memory_player_progress_repository.dart';
import 'package:block_puzzle_mobile/domain/gameplay/basic_line_clear_service.dart';
import 'package:block_puzzle_mobile/domain/gameplay/basic_move_validator.dart';
import 'package:block_puzzle_mobile/domain/gameplay/line_clear_service.dart';
import 'package:block_puzzle_mobile/domain/gameplay/move_validator.dart';
import 'package:block_puzzle_mobile/domain/generator/basic_difficulty_tuner.dart';
import 'package:block_puzzle_mobile/domain/generator/basic_piece_generation_service.dart';
import 'package:block_puzzle_mobile/domain/generator/difficulty_tuner.dart';
import 'package:block_puzzle_mobile/domain/generator/piece_generation_service.dart';
import 'package:block_puzzle_mobile/domain/progression/player_progress_repository.dart';
import 'package:block_puzzle_mobile/domain/scoring/basic_score_service.dart';
import 'package:block_puzzle_mobile/domain/scoring/score_service.dart';
import 'package:block_puzzle_mobile/domain/session/game_session_repository.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/game_loop_controller.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/services/ab_experiment_service.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/services/onboarding_flow_controller.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/services/progression_sync_service.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/services/share_flow_service.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/clear_lines_use_case.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/compute_score_use_case.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/place_piece_use_case.dart';
import 'package:block_puzzle_mobile/features/game_loop/audio/debug_game_sfx_player.dart';
import 'package:block_puzzle_mobile/features/game_loop/audio/game_sfx_player.dart';
import 'package:block_puzzle_mobile/features/game_loop/presentation/block_puzzle_game.dart';
import 'package:block_puzzle_mobile/features/game_modes/game_mode_availability.dart';
import 'package:block_puzzle_mobile/features/match3/application/match3_session_store.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_guardrail_policy.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_service.dart';
import 'package:block_puzzle_mobile/features/monetization/basic_ad_guardrail_policy.dart';
import 'package:block_puzzle_mobile/features/monetization/debug_ad_service.dart';
import 'package:block_puzzle_mobile/features/monetization/debug_iap_store_service.dart';
import 'package:block_puzzle_mobile/features/monetization/iap_store_service.dart';
import 'package:block_puzzle_mobile/features/store/application/store_availability.dart';
import 'package:block_puzzle_mobile/features/store/application/store_controller.dart';
import 'package:block_puzzle_mobile/features/tetris/application/tetris_session_store.dart';
import 'package:block_puzzle_mobile/infra/monitoring/crash_reporter.dart';
import 'package:block_puzzle_mobile/infra/monitoring/noop_crash_reporter.dart';

/// In-memory fake AudioPlayer that avoids native platform calls during tests.
class FakeAudioPlayer extends AudioPlayer {
  FakeAudioPlayer({super.playerId});

  final StreamController<void> completeController =
      StreamController<void>.broadcast();
  final StreamController<PlayerState> stateController =
      StreamController<PlayerState>.broadcast();

  double currentVolume = 1.0;
  ReleaseMode? configuredReleaseMode;
  AudioContext? configuredAudioContext;
  Source? currentSource;
  bool isPlayerPlaying = false;
  bool isPlayerPaused = false;
  bool isPlayerStopped = true;
  bool isPlayerDisposed = false;
  int playCallCount = 0;
  PlayerState _fakeState = PlayerState.stopped;

  @override
  PlayerState get state => _fakeState;

  @override
  Stream<PlayerState> get onPlayerStateChanged => stateController.stream;

  @override
  Stream<void> get onPlayerComplete => completeController.stream;

  void emitPlayerState(PlayerState newState) {
    _fakeState = newState;
    stateController.add(newState);
  }

  @override
  Future<void> setVolume(double volume) async {
    currentVolume = volume;
  }

  @override
  Future<void> setReleaseMode(ReleaseMode mode) async {
    configuredReleaseMode = mode;
  }

  @override
  Future<void> setAudioContext(AudioContext context) async {
    configuredAudioContext = context;
  }

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    currentSource = source;
    if (volume != null) {
      currentVolume = volume;
    }
    isPlayerPlaying = true;
    isPlayerPaused = false;
    isPlayerStopped = false;
    _fakeState = PlayerState.playing;
    playCallCount++;
  }

  @override
  Future<void> pause() async {
    isPlayerPlaying = false;
    isPlayerPaused = true;
    _fakeState = PlayerState.paused;
  }

  @override
  Future<void> resume() async {
    isPlayerPlaying = true;
    isPlayerPaused = false;
    _fakeState = PlayerState.playing;
    playCallCount++;
  }

  @override
  Future<void> stop() async {
    isPlayerPlaying = false;
    isPlayerPaused = false;
    isPlayerStopped = true;
    _fakeState = PlayerState.stopped;
  }

  @override
  Future<void> dispose() async {
    isPlayerDisposed = true;
    isPlayerPlaying = false;
    _fakeState = PlayerState.disposed;
    await completeController.close();
    await stateController.close();
  }
}

/// In-memory fake MusicPlaylistManager that switches tracks immediately without background crossfade timers.
class FakeMusicPlaylistManager extends MusicPlaylistManager {
  FakeMusicPlaylistManager({required super.logger})
      : super(
          playerA: FakeAudioPlayer(),
          playerB: FakeAudioPlayer(),
        );

  @override
  Future<void> crossfadeTo(int targetIndex) async {
    await play(trackIndex: targetIndex);
  }
}

/// Setup mock method call handlers for audioplayers channels.
void setupMockAudioChannels() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (MethodCall methodCall) async => 1,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (MethodCall methodCall) async => 1,
  );
}

/// Configures in-memory test dependencies in GetIt for widget and integration tests.
Future<void> configureTestDependencies({
  bool storeEnabled = true,
  bool classicEnabled = true,
  bool tetrisEnabled = true,
  bool match3Enabled = true,
  Map<String, Object?>? extraConfig,
}) async {
  await sl.reset();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  setupMockAudioChannels();

  const AppConfig appConfig = AppConfig(
    appName: 'Lumina Blocks',
    environment: AppEnvironment.dev,
    buildFlavor: BuildFlavor.debug,
    appVersion: '1.0.0+1',
    bundledRemoteConfigVersion: '1.0.0',
    remoteConfigTtl: Duration(hours: 1),
  );
  final AppLogger logger = AppLogger();

  final Map<String, Object?> configValues = <String, Object?>{
    'iap.store_enabled': storeEnabled,
    'feature_classic_enabled': classicEnabled,
    'feature_tetris_enabled': tetrisEnabled,
    'feature_match3_enabled': match3Enabled,
    'social.share_score_hashtag': '#BlockPuzzle',
    ...?extraConfig,
  };

  final RemoteConfigRepository remoteConfigRepository =
      InMemoryRemoteConfigRepository(
    appConfig: appConfig,
    initialConfig: configValues,
  );

  final RemoteConfigReader configReader = RemoteConfigReader(configValues);

  sl.registerSingleton<AppConfig>(appConfig);
  sl.registerSingleton<AppLogger>(logger);
  sl.registerSingleton<HapticsController>(HapticsController());

  sl.registerLazySingleton<MusicPlaylistManager>(
    () => FakeMusicPlaylistManager(logger: sl()),
    dispose: (MusicPlaylistManager m) => m.dispose(),
  );

  sl.registerLazySingleton<MusicController>(
    () => MusicController(logger: sl(), playlistManager: sl()),
    dispose: (MusicController c) => c.dispose(),
  );

  sl.registerLazySingleton<CrashReporter>(NoopCrashReporter.new);

  sl.registerLazySingleton<GameSfxPlayer>(
    () => DebugGameSfxPlayer(logger: sl()),
    dispose: (GameSfxPlayer p) => p.dispose(),
  );

  sl.registerLazySingleton<AdService>(
    () => DebugAdService(logger: sl()),
  );
  sl.registerLazySingleton<RemoteConfigRepository>(() => remoteConfigRepository);

  sl.registerLazySingleton<PlayerProgressRepository>(
    InMemoryPlayerProgressRepository.new,
  );

  sl.registerLazySingleton<GameSessionRepository>(
    InMemoryGameSessionRepository.new,
  );

  sl.registerLazySingleton<IapStoreService>(
    () => DebugIapStoreService(
      storeEnabled: storeEnabled,
      includeBundle: true,
      includeUtilityPass: false,
    ),
  );

  sl.registerSingleton<GameModeAvailability>(
    GameModeAvailability(configReader),
  );

  sl.registerSingleton<StoreAvailability>(
    StoreAvailability(configReader),
  );

  sl.registerLazySingleton<AdGuardrailPolicy>(BasicAdGuardrailPolicy.new);

  sl.registerLazySingleton<AnalyticsTracker>(
    () => DebugAnalyticsTracker(logger: sl()),
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
    () => ABExperimentService(analyticsTracker: sl(), logger: sl()),
  );

  sl.registerLazySingleton<ShareFlowService>(
    () => ShareFlowService(analyticsTracker: sl(), hashtag: '#BlockPuzzle'),
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
}

/// Resets all dependencies registered in GetIt.
Future<void> resetTestDependencies() async {
  await sl.reset();
}
