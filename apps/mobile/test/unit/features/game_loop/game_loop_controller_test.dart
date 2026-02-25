import 'package:block_puzzle_mobile/core/logging/app_logger.dart';
import 'package:block_puzzle_mobile/data/analytics/analytics_tracker.dart';
import 'package:block_puzzle_mobile/data/remote_config/remote_config_repository.dart';
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
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/clear_lines_use_case.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/compute_score_use_case.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/place_piece_use_case.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_guardrail_decision.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_guardrail_policy.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_placement.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_service.dart';
import 'package:block_puzzle_mobile/features/monetization/ad_show_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameLoopController', () {
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
}

class _MemoryAnalyticsTracker implements AnalyticsTracker {
  final List<String> events = <String>[];

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {
    events.add(eventName);
  }
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
