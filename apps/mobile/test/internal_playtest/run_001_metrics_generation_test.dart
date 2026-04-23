import 'dart:convert';
import 'dart:io';

import 'package:block_puzzle_mobile/core/logging/app_logger.dart';
import 'package:block_puzzle_mobile/data/analytics/analytics_tracker.dart';
import 'package:block_puzzle_mobile/data/remote_config/in_memory_remote_config_repository.dart';
import 'package:block_puzzle_mobile/data/repositories/in_memory_player_progress_repository.dart';
import 'package:block_puzzle_mobile/domain/generator/basic_difficulty_tuner.dart';
import 'package:block_puzzle_mobile/domain/generator/basic_piece_generation_service.dart';
import 'package:block_puzzle_mobile/domain/gameplay/basic_line_clear_service.dart';
import 'package:block_puzzle_mobile/domain/gameplay/basic_move_validator.dart';
import 'package:block_puzzle_mobile/domain/gameplay/move.dart';
import 'package:block_puzzle_mobile/domain/gameplay/piece.dart';
import 'package:block_puzzle_mobile/domain/scoring/basic_score_service.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/game_loop_controller.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/clear_lines_use_case.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/compute_score_use_case.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/place_piece_use_case.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_guardrail_decision.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_guardrail_policy.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_placement.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_service.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_show_result.dart';
import 'package:block_puzzle_mobile/data/repositories/in_memory_game_session_repository.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/services/services.dart';
import 'package:block_puzzle_mobile/features/monetization/debug_iap_store_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate run_001 internal playtest metrics', () async {
    final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
    final InMemoryRemoteConfigRepository configRepository = InMemoryRemoteConfigRepository();
    final InMemoryPlayerProgressRepository progressRepository = InMemoryPlayerProgressRepository();
    final AppLogger logger = AppLogger();

    final GameLoopController controller = GameLoopController(
      placePieceUseCase: const PlacePieceUseCase(
        moveValidator: BasicMoveValidator(),
      ),
      clearLinesUseCase: const ClearLinesUseCase(
        lineClearService: BasicLineClearService(),
      ),
      computeScoreUseCase: const ComputeScoreUseCase(
        scoreService: BasicScoreService(),
      ),
      pieceGenerationService: BasicPieceGenerationService(),
      difficultyTuner: const BasicDifficultyTuner(),
      remoteConfigRepository: configRepository,
      analyticsTracker: analytics,
      adService: const _NoopAdService(),
      adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
      iapStoreService: DebugIapStoreService(),
      logger: logger,
      gameSessionRepository: InMemoryGameSessionRepository(),
      progressionSyncService: ProgressionSyncService(
        playerProgressRepository: progressRepository,
        analyticsTracker: analytics,
        logger: logger,
      ),
      abExperimentService: ABExperimentService(
        remoteConfigRepository: configRepository,
        analyticsTracker: analytics,
        logger: logger,
      ),
      shareFlowService: ShareFlowService(analyticsTracker: analytics),
      onboardingFlowController: OnboardingFlowController(
        playerProgressRepository: progressRepository,
        analyticsTracker: analytics,
        logger: logger,
      ),
    );

    const int sessions = 40;
    int earlyGameOverCount = 0;
    int totalMoves = 0;
    int comboMoves = 0;
    int lineClearMoves = 0;
    int totalDurationSec = 0;

    await controller.initialize();

    for (int session = 0; session < sessions; session++) {
      if (session > 0) {
        await controller.startNewGame();
      }

      int sessionMoves = 0;
      while (!controller.state.isGameOver && sessionMoves < 120) {
        final Move? move = _firstValidMove(controller);
        if (move == null) {
          break;
        }

        final dynamic result = await controller.processMove(move);
        if (!result.isSuccess) {
          break;
        }

        sessionMoves += 1;
        totalMoves += 1;

        if (result.comboStreak > 1) {
          comboMoves += 1;
        }
        if (result.clearedLines > 0) {
          lineClearMoves += 1;
        }
      }

      if (sessionMoves < 8) {
        earlyGameOverCount += 1;
      }

      final int estimatedSessionSec = 8 + (sessionMoves * 4);
      totalDurationSec += estimatedSessionSec;
    }

    final double avgMovesPerRun = totalMoves / sessions;
    final double earlyGameOverRate = earlyGameOverCount / sessions;
    final double comboMoveRate =
        totalMoves == 0 ? 0 : (comboMoves / totalMoves);
    final double lineClearRate =
        totalMoves == 0 ? 0 : (lineClearMoves / totalMoves);
    final double avgSessionMinutes = (totalDurationSec / sessions) / 60.0;

    final Map<String, Object?> metrics = <String, Object?>{
      'generated_at_utc': DateTime.now().toUtc().toIso8601String(),
      'target_moves_per_run': 14,
      'observed_early_gameover_rate': double.parse(
        earlyGameOverRate.toStringAsFixed(3),
      ),
      'observed_avg_moves_per_run': double.parse(
        avgMovesPerRun.toStringAsFixed(2),
      ),
      'avg_session_minutes': double.parse(
        avgSessionMinutes.toStringAsFixed(2),
      ),
      'combo_move_rate': double.parse(
        comboMoveRate.toStringAsFixed(3),
      ),
      'line_clear_rate': double.parse(
        lineClearRate.toStringAsFixed(3),
      ),
      'rewarded_opt_in_rate': 0.30,
      'sample_size_sessions': sessions,
      'notes': <String>[
        'generated_from automated internal playtest simulation',
        'rewarded_opt_in_rate is placeholder until ad flow instrumentation',
      ],
    };

    final Directory outputDir = Directory('../../data/dashboards');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final File outputFile =
        File('../../data/dashboards/internal_playtest_run_001_metrics.json');
    outputFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(metrics),
    );

    expect(outputFile.existsSync(), isTrue);
    expect(avgMovesPerRun, greaterThan(6));
  });
}

Move? _firstValidMove(GameLoopController controller) {
  for (final Piece piece in controller.state.rackPieces) {
    for (int y = 0; y < controller.state.boardState.size; y++) {
      for (int x = 0; x < controller.state.boardState.size; x++) {
        final bool canPlace = controller.canPlacePiece(
          piece: piece,
          anchorX: x,
          anchorY: y,
        );
        if (canPlace) {
          return Move(
            piece: piece,
            anchorX: x,
            anchorY: y,
          );
        }
      }
    }
  }
  return null;
}

class _MemoryAnalyticsTracker implements AnalyticsTracker {
  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {}

  @override
  Future<void> flush({
    bool force = false,
  }) async {}

  @override
  Future<void> close() async {}
}

class _NoopAdService implements AdService {
  const _NoopAdService();

  @override
  Future<void> preload() async {}

  @override
  Future<AdShowResult> showBanner({
    required AdPlacement placement,
  }) async {
    return AdShowResult.unavailable(network: 'test');
  }

  @override
  Future<AdShowResult> showInterstitial({
    required AdPlacement placement,
  }) async {
    return AdShowResult.unavailable(network: 'test');
  }

  @override
  Future<AdShowResult> showRewarded({
    required AdPlacement placement,
    required String rewardType,
    required int rewardValue,
  }) async {
    return AdShowResult.unavailable(network: 'test');
  }
}

class _AllowAllAdGuardrailPolicy implements AdGuardrailPolicy {
  const _AllowAllAdGuardrailPolicy();

  @override
  AdGuardrailDecision evaluateInterstitial({
    required Map<String, Object?> remoteConfig,
    required int roundsPlayed,
    required int? lastInterstitialRound,
    required DateTime nowUtc,
    required List<DateTime> interstitialHistoryUtc,
  }) {
    return AdGuardrailDecision.allow();
  }

  @override
  bool isBannerEnabled(Map<String, Object?> remoteConfig) => true;

  @override
  bool isRewardedReviveEnabled(Map<String, Object?> remoteConfig) => true;

  @override
  int rewardedReviveClearCells(Map<String, Object?> remoteConfig) => 6;
}
