import 'package:block_puzzle_mobile/core/logging/app_logger.dart';
import 'package:block_puzzle_mobile/data/analytics/analytics_tracker.dart';
import 'package:block_puzzle_mobile/data/remote_config/remote_config_repository.dart';
import 'package:block_puzzle_mobile/data/remote_config/remote_config_snapshot.dart';
import 'package:block_puzzle_mobile/data/repositories/in_memory_player_progress_repository.dart';
import 'package:block_puzzle_mobile/domain/generator/difficulty_profile.dart';
import 'package:block_puzzle_mobile/domain/generator/difficulty_tuner.dart';
import 'package:block_puzzle_mobile/domain/generator/piece_generation_service.dart';
import 'package:block_puzzle_mobile/domain/generator/piece_triplet.dart';
import 'package:block_puzzle_mobile/domain/gameplay/basic_line_clear_service.dart';
import 'package:block_puzzle_mobile/domain/gameplay/basic_move_validator.dart';
import 'package:block_puzzle_mobile/domain/gameplay/board_state.dart';
import 'package:block_puzzle_mobile/domain/gameplay/move.dart';
import 'package:block_puzzle_mobile/domain/gameplay/piece.dart';
import 'package:block_puzzle_mobile/domain/scoring/basic_score_service.dart';
import 'package:block_puzzle_mobile/domain/session/session_state.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/game_loop_controller.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/models/models.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/clear_lines_use_case.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/compute_score_use_case.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/place_piece_use_case.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_guardrail_decision.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_guardrail_policy.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_placement.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_service.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_show_result.dart';
import 'package:block_puzzle_mobile/features/monetization/debug_iap_store_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameLoopController', () {
    test('shows onboarding on first game and tracks tutorial step', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
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
        pieceGenerationService: _SingleCellPieceGenerationService(),
        difficultyTuner: const _DefaultDifficultyTuner(),
        remoteConfigRepository: const _InMemoryRemoteConfigRepository(),
        analyticsTracker: analytics,
        adService: const _NoopAdService(),
        adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
        iapStoreService: DebugIapStoreService(),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        logger: AppLogger(),
      );

      await controller.initialize();

      expect(controller.state.isOnboardingVisible, isTrue);
      expect(controller.state.onboardingStepId, 'welcome_drag_piece');
      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'tutorial_step' &&
              event.params['step_id'] == 'welcome_drag_piece' &&
              event.params['status'] == 'shown',
        ),
        isTrue,
      );
    });

    test('dismissOnboarding hides overlay and tracks skipped status', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
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
        pieceGenerationService: _SingleCellPieceGenerationService(),
        difficultyTuner: const _DefaultDifficultyTuner(),
        remoteConfigRepository: const _InMemoryRemoteConfigRepository(),
        analyticsTracker: analytics,
        adService: const _NoopAdService(),
        adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
        iapStoreService: DebugIapStoreService(),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        logger: AppLogger(),
      );

      await controller.initialize();
      await controller.dismissOnboarding(reason: 'test_dismiss');

      expect(controller.state.isOnboardingVisible, isFalse);
      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'tutorial_step' &&
              event.params['status'] == 'skipped' &&
              event.params['dropoff_reason'] == 'test_dismiss',
        ),
        isTrue,
      );
    });

    test('tracks ab experiment exposures from remote config', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
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
        pieceGenerationService: _SingleCellPieceGenerationService(),
        difficultyTuner: const _DefaultDifficultyTuner(),
        remoteConfigRepository: const _AbVariantRemoteConfigRepository(),
        analyticsTracker: analytics,
        adService: const _NoopAdService(),
        adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
        iapStoreService: DebugIapStoreService(),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        logger: AppLogger(),
      );

      await controller.initialize();

      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'session_start' &&
              event.params['ab_bucket'] == 'variant_a' &&
              event.params['ux_variant'] == 'hud_focus_v1' &&
              event.params['difficulty_variant'] == 'fairness_bias_v1',
        ),
        isTrue,
      );
      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'ab_experiment_exposure' &&
              event.params['experiment_id'] == 'offer_strategy' &&
              event.params['variant_id'] == 'cosmetics_first_v2',
        ),
        isTrue,
      );
      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'ab_experiment_exposure' &&
              event.params['experiment_id'] == 'hud_ux' &&
              event.params['variant_id'] == 'hud_focus_v1',
        ),
        isTrue,
      );
      expect(controller.state.uxVariant, 'hud_focus_v1');
      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'game_start' &&
              event.params['ux_variant'] == 'hud_focus_v1' &&
              event.params['difficulty_variant'] == 'fairness_bias_v1',
        ),
        isTrue,
      );
    });

    test('builds share text and tracks share events', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
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
        pieceGenerationService: _SingleCellPieceGenerationService(),
        difficultyTuner: const _DefaultDifficultyTuner(),
        remoteConfigRepository: const _InMemoryRemoteConfigRepository(),
        analyticsTracker: analytics,
        adService: const _NoopAdService(),
        adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
        iapStoreService: DebugIapStoreService(),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        logger: AppLogger(),
      );

      await controller.initialize();
      final Move? move = _firstValidMove(controller);
      expect(move, isNotNull);
      await controller.processMove(move!);

      final String shareText = controller.buildShareScoreText();
      expect(shareText, contains('Lumina Blocks'));
      expect(shareText, contains('#BlockPuzzle'));

      await controller.trackShareScoreTapped(channel: 'clipboard');
      await controller.trackShareScoreResult(
        channel: 'clipboard',
        success: true,
      );

      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'share_score_tapped' &&
              event.params['channel'] == 'clipboard',
        ),
        isTrue,
      );
      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'share_score_result' &&
              event.params['channel'] == 'clipboard' &&
              event.params['success'] == true,
        ),
        isTrue,
      );
    });

    test('disables share flow from remote config', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
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
        pieceGenerationService: _SingleCellPieceGenerationService(),
        difficultyTuner: const _DefaultDifficultyTuner(),
        remoteConfigRepository: const _ShareDisabledRemoteConfigRepository(),
        analyticsTracker: analytics,
        adService: const _NoopAdService(),
        adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
        iapStoreService: DebugIapStoreService(),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        logger: AppLogger(),
      );

      await controller.initialize();

      expect(controller.state.isShareFlowEnabled, isFalse);
    });

    test('plays 10+ moves without failure using predictable rack', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
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
        pieceGenerationService: _SingleCellPieceGenerationService(),
        difficultyTuner: const _DefaultDifficultyTuner(),
        remoteConfigRepository: const _InMemoryRemoteConfigRepository(),
        analyticsTracker: analytics,
        adService: const _NoopAdService(),
        adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
        iapStoreService: DebugIapStoreService(),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        logger: AppLogger(),
      );

      await controller.initialize();

      int successMoves = 0;
      for (int i = 0; i < 12; i++) {
        if (controller.state.isGameOver) {
          break;
        }

        final Move? move = _firstValidMove(controller);
        expect(move, isNotNull, reason: 'Expected at least one valid move');

        final MoveProcessingResult result = await controller.processMove(move!);
        expect(result.isSuccess, isTrue);
        successMoves += 1;
      }

      expect(successMoves, greaterThanOrEqualTo(10));
      expect(controller.state.movesPlayed, greaterThanOrEqualTo(10));
      expect(
        analytics.events.any((String event) => event == 'game_start'),
        isTrue,
      );
      expect(
        analytics.events.where((String event) => event == 'move_made').length,
        greaterThanOrEqualTo(10),
      );
    });

    test('updates daily goals and tracks completion event', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
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
        pieceGenerationService: _SingleCellPieceGenerationService(),
        difficultyTuner: const _DefaultDifficultyTuner(),
        remoteConfigRepository: const _DailyGoalsRemoteConfigRepository(),
        analyticsTracker: analytics,
        adService: const _NoopAdService(),
        adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
        iapStoreService: DebugIapStoreService(),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        logger: AppLogger(),
      );

      await controller.initialize();
      final Move? move = _firstValidMove(controller);
      expect(move, isNotNull);
      await controller.processMove(move!);

      expect(
          controller.state.dailyGoals.movesProgress, greaterThanOrEqualTo(1));
      expect(
          controller.state.dailyGoals.completedCount, greaterThanOrEqualTo(1));
      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'daily_goal_progress' &&
              event.params['goal_id'] == 'daily_moves' &&
              event.params['is_completed'] == true,
        ),
        isTrue,
      );
    });

    test('uses rewarded hint via earned credits', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
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
        pieceGenerationService: _SingleCellPieceGenerationService(),
        difficultyTuner: const _DefaultDifficultyTuner(),
        remoteConfigRepository: const _HintUndoRemoteConfigRepository(),
        analyticsTracker: analytics,
        adService: const _NoopAdService(),
        adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
        iapStoreService: DebugIapStoreService(),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        logger: AppLogger(),
      );

      await controller.initialize();
      final int creditsBefore = controller.state.rewardedToolsCredits;
      final RewardedHintResult result = await controller.useRewardedHint();

      expect(result.isSuccess, isTrue);
      expect(controller.state.hintSuggestion, isNotNull);
      expect(controller.state.rewardedToolsCredits, creditsBefore - 1);
      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'rewarded_hint_used' &&
              event.params['source'] == 'earned_credits',
        ),
        isTrue,
      );
    });

    test('earns tools credits when daily goal is completed', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
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
        pieceGenerationService: _SingleCellPieceGenerationService(),
        difficultyTuner: const _DefaultDifficultyTuner(),
        remoteConfigRepository: const _DailyGoalRewardCreditsRemoteConfig(),
        analyticsTracker: analytics,
        adService: const _NoopAdService(),
        adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
        iapStoreService: DebugIapStoreService(),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        logger: AppLogger(),
      );

      await controller.initialize();
      expect(controller.state.rewardedToolsCredits, 0);
      final Move? move = _firstValidMove(controller);
      expect(move, isNotNull);

      await controller.processMove(move!);

      expect(controller.state.dailyGoals.movesCompleted, isTrue);
      expect(controller.state.rewardedToolsCredits, 2);
      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'rewarded_tools_credits_earned' &&
              event.params['source'] == 'daily_goals' &&
              event.params['credits_earned'] == 2 &&
              event.params['credits_balance'] == 2,
        ),
        isTrue,
      );
    });

    test('rejects rewarded hint when no credits and no unlimited access',
        () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
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
        pieceGenerationService: _SingleCellPieceGenerationService(),
        difficultyTuner: const _DefaultDifficultyTuner(),
        remoteConfigRepository:
            const _NoCreditsHintUndoRemoteConfigRepository(),
        analyticsTracker: analytics,
        adService: const _NoopAdService(),
        adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
        iapStoreService: DebugIapStoreService(),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        logger: AppLogger(),
      );

      await controller.initialize();

      final RewardedHintResult result = await controller.useRewardedHint();

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, 'insufficient_tools_credits');
      expect(controller.state.hintSuggestion, isNull);
      expect(
        analytics.trackedEvents.any(
          (event) => event.name == 'rewarded_hint_used',
        ),
        isFalse,
      );
    });

    test('uses rewarded undo and restores previous board state', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
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
        pieceGenerationService: _SingleCellPieceGenerationService(),
        difficultyTuner: const _DefaultDifficultyTuner(),
        remoteConfigRepository: const _HintUndoRemoteConfigRepository(),
        analyticsTracker: analytics,
        adService: const _NoopAdService(),
        adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
        iapStoreService: DebugIapStoreService(),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        logger: AppLogger(),
      );

      await controller.initialize();
      final Move? move = _firstValidMove(controller);
      expect(move, isNotNull);
      await controller.processMove(move!);
      expect(controller.state.movesPlayed, 1);

      final RewardedUndoResult undoResult = await controller.useRewardedUndo();

      expect(undoResult.isSuccess, isTrue);
      expect(controller.state.movesPlayed, 0);
      expect(controller.state.boardState.occupiedCells, isEmpty);
      expect(
        analytics.trackedEvents.any(
          (event) => event.name == 'rewarded_undo_used',
        ),
        isTrue,
      );
    });

    test('uses rewarded hint via iap unlimited access without spending credits',
        () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
      final DebugIapStoreService iapService = DebugIapStoreService();
      final product = (await iapService.loadCatalog()).firstWhere(
        (item) => item.id == 'utility_tools_pass',
      );
      await iapService.purchase(product: product);

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
        pieceGenerationService: _SingleCellPieceGenerationService(),
        difficultyTuner: const _DefaultDifficultyTuner(),
        remoteConfigRepository:
            const _IapUnlimitedHintUndoRemoteConfigRepository(),
        analyticsTracker: analytics,
        adService: const _NoopAdService(),
        adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
        iapStoreService: iapService,
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        logger: AppLogger(),
      );

      await controller.initialize();
      final int creditsBefore = controller.state.rewardedToolsCredits;
      final RewardedHintResult result = await controller.useRewardedHint();

      expect(result.isSuccess, isTrue);
      expect(controller.state.hasUnlimitedRewardedTools, isTrue);
      expect(controller.state.rewardedToolsCredits, creditsBefore);
      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'rewarded_hint_used' &&
              event.params['source'] == 'iap_unlimited',
        ),
        isTrue,
      );
    });

    test('increments streak when user returns the next day', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
      final InMemoryPlayerProgressRepository progressRepository =
          InMemoryPlayerProgressRepository();
      DateTime nowUtc = DateTime.utc(2026, 2, 24, 10, 0, 0);

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
        pieceGenerationService: _SingleCellPieceGenerationService(),
        difficultyTuner: const _DefaultDifficultyTuner(),
        remoteConfigRepository: const _InMemoryRemoteConfigRepository(),
        analyticsTracker: analytics,
        adService: const _NoopAdService(),
        adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
        iapStoreService: DebugIapStoreService(),
        playerProgressRepository: progressRepository,
        logger: AppLogger(),
        nowUtcProvider: () => nowUtc,
      );

      await controller.initialize();
      expect(controller.state.streak.currentDays, 1);

      nowUtc = DateTime.utc(2026, 2, 25, 9, 0, 0);
      await controller.startNewGame();

      expect(controller.state.streak.currentDays, 2);
      expect(controller.state.streak.bestDays, greaterThanOrEqualTo(2));
      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'streak_updated' &&
              event.params['reason'] == 'continued' &&
              event.params['current_streak'] == 2,
        ),
        isTrue,
      );
    });

    test('emits ops snapshot and alert on runtime guardrail violation',
        () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
      DateTime nowUtc = DateTime.utc(2026, 2, 25, 10, 0, 0);

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
        pieceGenerationService: _SingleCellPieceGenerationService(),
        difficultyTuner: const _DefaultDifficultyTuner(),
        remoteConfigRepository:
            const _ObservabilityAlertRemoteConfigRepository(),
        analyticsTracker: analytics,
        adService: const _NoopAdService(),
        adGuardrailPolicy: const _AllowAllAdGuardrailPolicy(),
        iapStoreService: _FailingIapStoreService(),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        logger: AppLogger(),
        nowUtcProvider: () => nowUtc,
      );

      await controller.initialize();
      nowUtc = nowUtc.add(const Duration(seconds: 45));
      controller.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'ops_session_snapshot' &&
              (event.params['runtime_error_count'] as int? ?? 0) >= 1,
        ),
        isTrue,
      );
      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'ops_alert_triggered' &&
              event.params['alert_id'] == 'runtime_errors_high',
        ),
        isTrue,
      );
    });
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

class _SingleCellPieceGenerationService implements PieceGenerationService {
  int _counter = 0;

  @override
  void setSeed(int? seed) {}

  @override
  PieceTriplet nextTriplet({
    required BoardState boardState,
    required DifficultyProfile profile,
  }) {
    Piece buildPiece() {
      _counter += 1;
      return Piece(
        id: 'single_$_counter',
        cells: const <PieceCellOffset>[PieceCellOffset(dx: 0, dy: 0)],
      );
    }

    return PieceTriplet(
      pieces: <Piece>[
        buildPiece(),
        buildPiece(),
        buildPiece(),
      ],
    );
  }
}

class _DefaultDifficultyTuner implements DifficultyTuner {
  const _DefaultDifficultyTuner();

  @override
  DifficultyProfile resolve({
    required SessionState sessionState,
    required Map<String, Object?> remoteConfig,
  }) {
    return DifficultyProfile.initial;
  }
}

class _InMemoryRemoteConfigRepository implements RemoteConfigRepository {
  const _InMemoryRemoteConfigRepository();

  @override
  Future<Map<String, Object?>> fetchLatest() async {
    return getCached();
  }

  @override
  Future<Map<String, Object?>> getCached() async {
    return <String, Object?>{
      'difficulty.hard_piece_weight': 0.2,
      'difficulty.max_hard_pieces_per_triplet': 1,
    };
  }

  @override
  Future<RemoteConfigSnapshot> fetchLatestSnapshot() async {
    return _testSnapshot(await getCached());
  }

  @override
  Future<RemoteConfigSnapshot> getCachedSnapshot() async {
    return _testSnapshot(await getCached());
  }

  @override
  Future<void> applySnapshot(RemoteConfigSnapshot snapshot) async {}

  @override
  Future<RemoteConfigSnapshot?> getRollbackSnapshot() async {
    return null;
  }
}

class _AbVariantRemoteConfigRepository implements RemoteConfigRepository {
  const _AbVariantRemoteConfigRepository();

  @override
  Future<Map<String, Object?>> fetchLatest() async {
    return getCached();
  }

  @override
  Future<Map<String, Object?>> getCached() async {
    return <String, Object?>{
      'difficulty.hard_piece_weight': 0.2,
      'difficulty.max_hard_pieces_per_triplet': 1,
      'ab.bucket': 'variant_a',
      'ab.tutorial_variant': 'guided_v2',
      'ab.offer_strategy_variant': 'cosmetics_first_v2',
      'ab.difficulty_variant': 'fairness_bias_v1',
      'ab.ux_variant': 'hud_focus_v1',
    };
  }

  @override
  Future<RemoteConfigSnapshot> fetchLatestSnapshot() async {
    return _testSnapshot(await getCached(), version: 'ab_variant_test');
  }

  @override
  Future<RemoteConfigSnapshot> getCachedSnapshot() async {
    return _testSnapshot(await getCached(), version: 'ab_variant_test');
  }

  @override
  Future<void> applySnapshot(RemoteConfigSnapshot snapshot) async {}

  @override
  Future<RemoteConfigSnapshot?> getRollbackSnapshot() async {
    return null;
  }
}

class _DailyGoalsRemoteConfigRepository implements RemoteConfigRepository {
  const _DailyGoalsRemoteConfigRepository();

  @override
  Future<Map<String, Object?>> fetchLatest() async {
    return getCached();
  }

  @override
  Future<Map<String, Object?>> getCached() async {
    return <String, Object?>{
      'difficulty.hard_piece_weight': 0.2,
      'difficulty.max_hard_pieces_per_triplet': 1,
      'progression.daily_goal_moves_target': 1,
      'progression.daily_goal_lines_target': 200,
      'progression.daily_goal_score_target': 5000,
      'progression.streak_enabled': true,
    };
  }

  @override
  Future<RemoteConfigSnapshot> fetchLatestSnapshot() async {
    return _testSnapshot(await getCached(), version: 'daily_goals_test');
  }

  @override
  Future<RemoteConfigSnapshot> getCachedSnapshot() async {
    return _testSnapshot(await getCached(), version: 'daily_goals_test');
  }

  @override
  Future<void> applySnapshot(RemoteConfigSnapshot snapshot) async {}

  @override
  Future<RemoteConfigSnapshot?> getRollbackSnapshot() async {
    return null;
  }
}

class _HintUndoRemoteConfigRepository implements RemoteConfigRepository {
  const _HintUndoRemoteConfigRepository();

  @override
  Future<Map<String, Object?>> fetchLatest() async {
    return getCached();
  }

  @override
  Future<Map<String, Object?>> getCached() async {
    return <String, Object?>{
      'difficulty.hard_piece_weight': 0.2,
      'difficulty.max_hard_pieces_per_triplet': 1,
      'progression.rewarded_tools_initial_credits': 3,
      'progression.rewarded_tools_hint_cost': 1,
      'progression.rewarded_tools_undo_cost': 1,
      'progression.undo_history_limit': 1,
      'iap.rewarded_tools_unlimited_enabled': true,
      'iap.rewarded_tools_unlimited_sku': 'utility_tools_pass',
    };
  }

  @override
  Future<RemoteConfigSnapshot> fetchLatestSnapshot() async {
    return _testSnapshot(await getCached(), version: 'hint_undo_test');
  }

  @override
  Future<RemoteConfigSnapshot> getCachedSnapshot() async {
    return _testSnapshot(await getCached(), version: 'hint_undo_test');
  }

  @override
  Future<void> applySnapshot(RemoteConfigSnapshot snapshot) async {}

  @override
  Future<RemoteConfigSnapshot?> getRollbackSnapshot() async {
    return null;
  }
}

class _ShareDisabledRemoteConfigRepository implements RemoteConfigRepository {
  const _ShareDisabledRemoteConfigRepository();

  @override
  Future<Map<String, Object?>> fetchLatest() async {
    return getCached();
  }

  @override
  Future<Map<String, Object?>> getCached() async {
    return <String, Object?>{
      'difficulty.hard_piece_weight': 0.2,
      'difficulty.max_hard_pieces_per_triplet': 1,
      'social.share_enabled': false,
    };
  }

  @override
  Future<RemoteConfigSnapshot> fetchLatestSnapshot() async {
    return _testSnapshot(await getCached(), version: 'share_disabled_test');
  }

  @override
  Future<RemoteConfigSnapshot> getCachedSnapshot() async {
    return _testSnapshot(await getCached(), version: 'share_disabled_test');
  }

  @override
  Future<void> applySnapshot(RemoteConfigSnapshot snapshot) async {}

  @override
  Future<RemoteConfigSnapshot?> getRollbackSnapshot() async {
    return null;
  }
}

class _NoCreditsHintUndoRemoteConfigRepository
    implements RemoteConfigRepository {
  const _NoCreditsHintUndoRemoteConfigRepository();

  @override
  Future<Map<String, Object?>> fetchLatest() async {
    return getCached();
  }

  @override
  Future<Map<String, Object?>> getCached() async {
    return <String, Object?>{
      'difficulty.hard_piece_weight': 0.2,
      'difficulty.max_hard_pieces_per_triplet': 1,
      'progression.rewarded_tools_initial_credits': 0,
      'progression.rewarded_tools_hint_cost': 1,
      'progression.rewarded_tools_undo_cost': 1,
      'progression.undo_history_limit': 1,
      'iap.rewarded_tools_unlimited_enabled': false,
      'iap.rewarded_tools_unlimited_sku': 'utility_tools_pass',
    };
  }

  @override
  Future<RemoteConfigSnapshot> fetchLatestSnapshot() async {
    return _testSnapshot(await getCached(), version: 'no_credits_test');
  }

  @override
  Future<RemoteConfigSnapshot> getCachedSnapshot() async {
    return _testSnapshot(await getCached(), version: 'no_credits_test');
  }

  @override
  Future<void> applySnapshot(RemoteConfigSnapshot snapshot) async {}

  @override
  Future<RemoteConfigSnapshot?> getRollbackSnapshot() async {
    return null;
  }
}

class _DailyGoalRewardCreditsRemoteConfig implements RemoteConfigRepository {
  const _DailyGoalRewardCreditsRemoteConfig();

  @override
  Future<Map<String, Object?>> fetchLatest() async {
    return getCached();
  }

  @override
  Future<Map<String, Object?>> getCached() async {
    return <String, Object?>{
      'difficulty.hard_piece_weight': 0.2,
      'difficulty.max_hard_pieces_per_triplet': 1,
      'progression.daily_goal_moves_target': 1,
      'progression.daily_goal_lines_target': 500,
      'progression.daily_goal_score_target': 10000,
      'progression.daily_goal_reward_credits': 2,
      'progression.rewarded_tools_initial_credits': 0,
      'progression.streak_enabled': true,
    };
  }

  @override
  Future<RemoteConfigSnapshot> fetchLatestSnapshot() async {
    return _testSnapshot(await getCached(), version: 'goal_reward_test');
  }

  @override
  Future<RemoteConfigSnapshot> getCachedSnapshot() async {
    return _testSnapshot(await getCached(), version: 'goal_reward_test');
  }

  @override
  Future<void> applySnapshot(RemoteConfigSnapshot snapshot) async {}

  @override
  Future<RemoteConfigSnapshot?> getRollbackSnapshot() async {
    return null;
  }
}

class _IapUnlimitedHintUndoRemoteConfigRepository
    implements RemoteConfigRepository {
  const _IapUnlimitedHintUndoRemoteConfigRepository();

  @override
  Future<Map<String, Object?>> fetchLatest() async {
    return getCached();
  }

  @override
  Future<Map<String, Object?>> getCached() async {
    return <String, Object?>{
      'difficulty.hard_piece_weight': 0.2,
      'difficulty.max_hard_pieces_per_triplet': 1,
      'progression.rewarded_tools_initial_credits': 0,
      'progression.rewarded_tools_hint_cost': 1,
      'progression.rewarded_tools_undo_cost': 1,
      'progression.undo_history_limit': 1,
      'iap.rewarded_tools_unlimited_enabled': true,
      'iap.rewarded_tools_unlimited_sku': 'utility_tools_pass',
    };
  }

  @override
  Future<RemoteConfigSnapshot> fetchLatestSnapshot() async {
    return _testSnapshot(await getCached(), version: 'iap_unlimited_test');
  }

  @override
  Future<RemoteConfigSnapshot> getCachedSnapshot() async {
    return _testSnapshot(await getCached(), version: 'iap_unlimited_test');
  }

  @override
  Future<void> applySnapshot(RemoteConfigSnapshot snapshot) async {}

  @override
  Future<RemoteConfigSnapshot?> getRollbackSnapshot() async {
    return null;
  }
}

class _ObservabilityAlertRemoteConfigRepository
    implements RemoteConfigRepository {
  const _ObservabilityAlertRemoteConfigRepository();

  @override
  Future<Map<String, Object?>> fetchLatest() async {
    return getCached();
  }

  @override
  Future<Map<String, Object?>> getCached() async {
    return <String, Object?>{
      'difficulty.hard_piece_weight': 0.2,
      'difficulty.max_hard_pieces_per_triplet': 1,
      'ops.alerting.enabled': true,
      'ops.alerting.max_runtime_error_count': 0,
    };
  }

  @override
  Future<RemoteConfigSnapshot> fetchLatestSnapshot() async {
    return _testSnapshot(await getCached(), version: 'ops_alert_test');
  }

  @override
  Future<RemoteConfigSnapshot> getCachedSnapshot() async {
    return _testSnapshot(await getCached(), version: 'ops_alert_test');
  }

  @override
  Future<void> applySnapshot(RemoteConfigSnapshot snapshot) async {}

  @override
  Future<RemoteConfigSnapshot?> getRollbackSnapshot() async {
    return null;
  }
}

class _MemoryAnalyticsTracker implements AnalyticsTracker {
  final List<_TrackedAnalyticsEvent> trackedEvents = <_TrackedAnalyticsEvent>[];

  List<String> get events =>
      trackedEvents.map((event) => event.name).toList(growable: false);

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {
    trackedEvents.add(
      _TrackedAnalyticsEvent(
        name: eventName,
        params: Map<String, Object?>.from(params),
      ),
    );
  }

  @override
  Future<void> flush({
    bool force = false,
  }) async {}

  @override
  Future<void> close() async {}
}

class _TrackedAnalyticsEvent {
  const _TrackedAnalyticsEvent({
    required this.name,
    required this.params,
  });

  final String name;
  final Map<String, Object?> params;
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

class _FailingIapStoreService extends DebugIapStoreService {
  @override
  Future<Set<String>> loadOwnedProductIds() async {
    throw StateError('iap_load_failed');
  }
}

RemoteConfigSnapshot _testSnapshot(
  Map<String, Object?> config, {
  String version = 'game_loop_test_snapshot',
}) {
  return RemoteConfigSnapshot(
    version: version,
    config: Map<String, Object?>.from(config),
    fetchedAtUtc: DateTime.utc(2026, 2, 25),
    ttl: const Duration(minutes: 30),
    source: RemoteConfigSource.cache,
  );
}
