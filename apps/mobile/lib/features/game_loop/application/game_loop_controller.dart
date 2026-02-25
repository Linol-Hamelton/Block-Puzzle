import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../data/analytics/analytics_tracker.dart';
import '../../../data/remote_config/remote_config_repository.dart';
import '../../../domain/generator/difficulty_tuner.dart';
import '../../../domain/generator/piece_generation_service.dart';
import '../../../domain/gameplay/board_state.dart';
import '../../../domain/gameplay/move.dart';
import '../../../domain/gameplay/piece.dart';
import '../../../domain/scoring/score_state.dart';
import '../../../domain/session/session_state.dart';
import '../../monetization/ad_guardrail_decision.dart';
import '../../monetization/ad_guardrail_policy.dart';
import '../../monetization/ad_placement.dart';
import '../../monetization/ad_service.dart';
import '../../monetization/ad_show_result.dart';
import 'game_loop_view_state.dart';
import 'use_cases/clear_lines_use_case.dart';
import 'use_cases/compute_score_use_case.dart';
import 'use_cases/place_piece_use_case.dart';

class MoveProcessingResult {
  const MoveProcessingResult({
    required this.isSuccess,
    required this.clearedLines,
    required this.clearedCells,
    required this.comboStreak,
    required this.totalScore,
    required this.isGameOver,
    this.failureReason,
  });

  final bool isSuccess;
  final int clearedLines;
  final Set<BoardCell> clearedCells;
  final int comboStreak;
  final int totalScore;
  final bool isGameOver;
  final String? failureReason;

  factory MoveProcessingResult.success({
    required int clearedLines,
    required Set<BoardCell> clearedCells,
    required int comboStreak,
    required int totalScore,
    required bool isGameOver,
  }) {
    return MoveProcessingResult(
      isSuccess: true,
      clearedLines: clearedLines,
      clearedCells: clearedCells,
      comboStreak: comboStreak,
      totalScore: totalScore,
      isGameOver: isGameOver,
    );
  }

  factory MoveProcessingResult.failure(String reason) {
    return MoveProcessingResult(
      isSuccess: false,
      clearedLines: 0,
      clearedCells: <BoardCell>{},
      comboStreak: 0,
      totalScore: 0,
      isGameOver: false,
      failureReason: reason,
    );
  }
}

class RewardedReviveResult {
  const RewardedReviveResult({
    required this.isSuccess,
    this.failureReason,
  });

  final bool isSuccess;
  final String? failureReason;

  factory RewardedReviveResult.success() {
    return const RewardedReviveResult(isSuccess: true);
  }

  factory RewardedReviveResult.failure(String reason) {
    return RewardedReviveResult(
      isSuccess: false,
      failureReason: reason,
    );
  }
}

class GameLoopController {
  static const String _tutorialStepWelcome = 'welcome_drag_piece';
  static const String _tutorialStepClearLine = 'goal_clear_line';
  static const String _tutorialStepComboChain = 'goal_combo_chain';
  static const String _tutorialFlow = 'onboarding_v1';
  static const String _tutorialStatusShown = 'shown';
  static const String _tutorialStatusCompleted = 'completed';
  static const String _tutorialStatusSkipped = 'skipped';

  GameLoopController({
    required this.placePieceUseCase,
    required this.clearLinesUseCase,
    required this.computeScoreUseCase,
    required this.pieceGenerationService,
    required this.difficultyTuner,
    required this.remoteConfigRepository,
    required this.analyticsTracker,
    required this.adService,
    required this.adGuardrailPolicy,
    required this.logger,
  });

  final PlacePieceUseCase placePieceUseCase;
  final ClearLinesUseCase clearLinesUseCase;
  final ComputeScoreUseCase computeScoreUseCase;
  final PieceGenerationService pieceGenerationService;
  final DifficultyTuner difficultyTuner;
  final RemoteConfigRepository remoteConfigRepository;
  final AnalyticsTracker analyticsTracker;
  final AdService adService;
  final AdGuardrailPolicy adGuardrailPolicy;
  final AppLogger logger;

  final ValueNotifier<GameLoopViewState> _stateNotifier =
      ValueNotifier<GameLoopViewState>(GameLoopViewState.initial());

  Map<String, Object?> _remoteConfig = <String, Object?>{};
  SessionState _sessionState = SessionState.initial;
  final List<DateTime> _interstitialImpressionHistoryUtc = <DateTime>[];
  bool _initialized = false;
  bool _onboardingEnabled = true;
  bool _onboardingCompleted = false;
  int _onboardingMoveCount = 0;
  bool _bannerRequestedInSession = false;
  bool _rewardedReviveUsedInCurrentGame = false;
  int _currentGameNumber = 0;
  int? _lastInterstitialRound;
  DateTime? _sessionStartedAt;
  DateTime? _gameStartedAt;
  String? _sessionId;
  String _abBucket = 'control';
  Map<String, String> _abExperimentVariants = <String, String>{};

  ValueListenable<GameLoopViewState> get stateListenable => _stateNotifier;
  GameLoopViewState get state => _stateNotifier.value;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _remoteConfig = await remoteConfigRepository.getCached();
    _onboardingEnabled = _readBoolConfig(
      'onboarding.enabled',
      fallback: true,
    );
    _abBucket = _readStringConfig(
      'ab.bucket',
      fallback: 'control',
    );
    _abExperimentVariants = _collectAbExperimentVariants();
    await adService.preload();

    _initialized = true;
    _sessionStartedAt = DateTime.now().toUtc();
    _sessionId = 'session_${_sessionStartedAt!.millisecondsSinceEpoch}';

    logger.info('Game loop initialized with config: $_remoteConfig');
    await analyticsTracker.track(
      'session_start',
      params: <String, Object?>{
        'session_id': _sessionId,
        'app_version': 'dev-local',
        'platform': defaultTargetPlatform.name,
        'ab_bucket': _abBucket,
      },
    );
    await _trackAbExperimentExposures();
    await analyticsTracker.track('game_loop_initialized');

    await startNewGame();
  }

  Future<void> startNewGame() async {
    _currentGameNumber += 1;
    _gameStartedAt = DateTime.now().toUtc();
    _rewardedReviveUsedInCurrentGame = false;
    final int nextGamesPlayed = state.gamesPlayed + 1;
    final bool shouldShowOnboarding =
        _onboardingEnabled && !_onboardingCompleted && nextGamesPlayed == 1;
    final BoardState emptyBoard = GameLoopViewState.initial().boardState;

    _sessionState = SessionState(
      roundsPlayed: nextGamesPlayed,
      currentScore: 0,
      movesPlayed: 0,
    );
    final int level = _resolveLevel(totalScore: 0);
    final int colorThemeIndex = _resolveColorThemeIndex(level);

    final List<Piece> rack = _nextRackPieces(
      boardState: emptyBoard,
      maxAttempts: 24,
    );
    _onboardingMoveCount = 0;

    _stateNotifier.value = state.copyWith(
      boardState: emptyBoard,
      scoreState: ScoreState.initial,
      rackPieces: rack,
      level: level,
      colorThemeIndex: colorThemeIndex,
      isGameOver: false,
      canUseRewardedRevive: false,
      isBannerVisible: adGuardrailPolicy.isBannerEnabled(_remoteConfig),
      isOnboardingVisible: shouldShowOnboarding,
      onboardingStepId: shouldShowOnboarding ? _tutorialStepWelcome : null,
      onboardingTitle: shouldShowOnboarding ? 'Welcome to Classic Mode' : null,
      onboardingDescription: shouldShowOnboarding
          ? 'Drag any piece from the rack onto the board to start your run.'
          : null,
      gamesPlayed: nextGamesPlayed,
      movesPlayed: 0,
      resetOnboarding: !shouldShowOnboarding,
      resetGameOverReason: true,
    );

    if (shouldShowOnboarding) {
      await _trackTutorialStep(
        stepId: _tutorialStepWelcome,
        status: _tutorialStatusShown,
      );
    }

    if (state.isBannerVisible && !_bannerRequestedInSession) {
      final AdShowResult bannerResult = await adService.showBanner(
        placement: AdPlacement.gameHudBanner,
      );
      if (bannerResult.isShown) {
        _bannerRequestedInSession = true;
        await _trackAdImpression(
          placement: AdPlacement.gameHudBanner,
          adType: 'banner',
          adResult: bannerResult,
        );
      }
    }

    await analyticsTracker.track(
      'game_start',
      params: <String, Object?>{
        'round_id': _currentGameNumber,
        'mode': 'classic',
        'config_version': 'in_memory_v1',
        'board_size': state.boardState.size,
        'rack_size': rack.length,
        'level': level,
      },
    );
  }

  bool canPlacePiece({
    required Piece piece,
    required int anchorX,
    required int anchorY,
  }) {
    final PlacePieceResult result = placePieceUseCase.execute(
      boardState: state.boardState,
      move: Move(
        piece: piece,
        anchorX: anchorX,
        anchorY: anchorY,
      ),
    );
    return result.isSuccess;
  }

  Future<MoveProcessingResult> processMove(Move move) async {
    if (state.isGameOver) {
      return MoveProcessingResult.failure('game_over');
    }

    final bool pieceExistsInRack =
        state.rackPieces.any((Piece piece) => piece.id == move.piece.id);
    if (!pieceExistsInRack) {
      return MoveProcessingResult.failure('piece_not_in_rack');
    }

    final PlacePieceResult placeResult = placePieceUseCase.execute(
      boardState: state.boardState,
      move: move,
    );

    if (!placeResult.isSuccess) {
      await analyticsTracker.track(
        'move_rejected',
        params: <String, Object?>{
          'reason': placeResult.failureReason,
          'piece_id': move.piece.id,
          'anchor_x': move.anchorX,
          'anchor_y': move.anchorY,
        },
      );
      return MoveProcessingResult.failure(
        placeResult.failureReason ?? 'invalid_move',
      );
    }

    final lineResult = clearLinesUseCase.execute(
      boardState: placeResult.boardState,
    );
    final ScoreState nextScore = computeScoreUseCase.execute(
      previous: state.scoreState,
      clearedLines: lineResult.clearedTotal,
    );

    List<Piece> nextRack = List<Piece>.from(state.rackPieces)
      ..removeWhere((Piece piece) => piece.id == move.piece.id);
    if (nextRack.isEmpty) {
      nextRack = _nextRackPieces(
        boardState: lineResult.boardState,
        maxAttempts: 24,
      );
    }

    final bool hasFutureMoves = _hasAnyValidMove(
      boardState: lineResult.boardState,
      rackPieces: nextRack,
    );
    final bool isGameOver = !hasFutureMoves;
    final int nextBestScore = nextScore.totalScore > state.bestScore
        ? nextScore.totalScore
        : state.bestScore;
    final int nextMovesPlayed = state.movesPlayed + 1;
    final int previousLevel = state.level;
    final int nextLevel = _resolveLevel(totalScore: nextScore.totalScore);
    final bool levelUp = nextLevel > previousLevel;
    final int nextColorThemeIndex = _resolveColorThemeIndex(nextLevel);
    final double boardFillPct = lineResult.boardState.occupiedCells.length /
        (lineResult.boardState.size * lineResult.boardState.size);

    _sessionState = SessionState(
      roundsPlayed: state.gamesPlayed,
      currentScore: nextScore.totalScore,
      movesPlayed: nextMovesPlayed,
    );

    _stateNotifier.value = state.copyWith(
      boardState: lineResult.boardState,
      scoreState: nextScore,
      rackPieces: nextRack,
      level: nextLevel,
      colorThemeIndex: nextColorThemeIndex,
      isGameOver: isGameOver,
      canUseRewardedRevive: isGameOver ? _isRewardedReviveAvailable() : false,
      bestScore: nextBestScore,
      movesPlayed: nextMovesPlayed,
      gameOverReason: isGameOver ? 'no_valid_moves' : null,
      resetGameOverReason: !isGameOver,
    );

    await analyticsTracker.track(
      'move_made',
      params: <String, Object?>{
        'round_id': _currentGameNumber,
        'piece_type': move.piece.id,
        'piece_id': move.piece.id,
        'anchor_x': move.anchorX,
        'anchor_y': move.anchorY,
        'lines_cleared': lineResult.clearedTotal,
        'cleared_lines': lineResult.clearedTotal,
        'combo_index': nextScore.comboStreak,
        'combo_streak': nextScore.comboStreak,
        'score_total': nextScore.totalScore,
        'moves_played': nextMovesPlayed,
        'board_fill_pct': boardFillPct,
      },
    );

    await _handleOnboardingAfterMove(
      clearedLines: lineResult.clearedTotal,
      comboStreak: nextScore.comboStreak,
    );

    if (levelUp) {
      await analyticsTracker.track(
        'level_up',
        params: <String, Object?>{
          'round_id': _currentGameNumber,
          'from_level': previousLevel,
          'to_level': nextLevel,
          'score_total': nextScore.totalScore,
        },
      );
    }

    if (lineResult.clearedTotal > 0) {
      await analyticsTracker.track(
        'line_clear',
        params: <String, Object?>{
          'round_id': _currentGameNumber,
          'count': lineResult.clearedTotal,
          'score_total': nextScore.totalScore,
        },
      );
    }

    if (isGameOver) {
      if (state.isOnboardingVisible) {
        await _completeOnboarding(
          stepId: state.onboardingStepId ?? _tutorialFlow,
          status: _tutorialStatusSkipped,
          dropoffReason: 'game_over',
        );
      }
      await _trackGameEnd(
        reason: 'no_valid_moves',
        score: nextScore.totalScore,
      );
      await _maybeShowInterstitialAfterGameEnd();
    }

    return MoveProcessingResult.success(
      clearedLines: lineResult.clearedTotal,
      clearedCells: lineResult.clearedCells,
      comboStreak: nextScore.comboStreak,
      totalScore: nextScore.totalScore,
      isGameOver: isGameOver,
    );
  }

  Future<RewardedReviveResult> useRewardedRevive() async {
    if (!state.isGameOver) {
      return RewardedReviveResult.failure('round_not_over');
    }
    if (!_isRewardedReviveAvailable()) {
      return RewardedReviveResult.failure('revive_not_available');
    }

    final AdShowResult adResult = await adService.showRewarded(
      placement: AdPlacement.gameOverRewardedRevive,
      rewardType: 'revive',
      rewardValue: 1,
    );
    if (adResult.isShown) {
      await _trackAdImpression(
        placement: AdPlacement.gameOverRewardedRevive,
        adType: 'rewarded',
        adResult: adResult,
      );
    }

    if (!adResult.isShown || !adResult.rewardGranted) {
      return RewardedReviveResult.failure(
        adResult.reason ?? 'rewarded_not_completed',
      );
    }

    await analyticsTracker.track(
      'ad_rewarded',
      params: <String, Object?>{
        'reward_type': 'revive',
        'reward_value': 1,
      },
    );

    final _ReviveSnapshot? reviveSnapshot = _buildReviveSnapshot();
    if (reviveSnapshot == null) {
      logger.warn('Rewarded revive failed: no valid board state found');
      return RewardedReviveResult.failure('revive_no_valid_state');
    }

    _rewardedReviveUsedInCurrentGame = true;

    _stateNotifier.value = state.copyWith(
      boardState: reviveSnapshot.boardState,
      rackPieces: reviveSnapshot.rackPieces,
      isGameOver: false,
      canUseRewardedRevive: false,
      gameOverReason: null,
      resetGameOverReason: true,
    );

    await analyticsTracker.track(
      'revive_applied',
      params: <String, Object?>{
        'round_id': _currentGameNumber,
        'method': 'rewarded',
        'score_total': state.scoreState.totalScore,
        'moves_played': state.movesPlayed,
      },
    );

    return RewardedReviveResult.success();
  }

  Future<void> dismissOnboarding({
    String reason = 'manual_dismiss',
  }) async {
    if (!state.isOnboardingVisible) {
      return;
    }
    await _completeOnboarding(
      stepId: state.onboardingStepId ?? _tutorialFlow,
      status: _tutorialStatusSkipped,
      dropoffReason: reason,
    );
  }

  Future<void> _maybeShowInterstitialAfterGameEnd() async {
    final DateTime nowUtc = DateTime.now().toUtc();
    _pruneInterstitialHistory(nowUtc);

    final AdGuardrailDecision decision = adGuardrailPolicy.evaluateInterstitial(
      remoteConfig: _remoteConfig,
      roundsPlayed: state.gamesPlayed,
      lastInterstitialRound: _lastInterstitialRound,
      nowUtc: nowUtc,
      interstitialHistoryUtc: _interstitialImpressionHistoryUtc,
    );
    if (!decision.allow) {
      logger.info('Interstitial blocked by guardrail: ${decision.reason}');
      return;
    }

    final AdShowResult adResult = await adService.showInterstitial(
      placement: AdPlacement.gameOverInterstitial,
    );
    if (!adResult.isShown) {
      logger.warn(
          'Interstitial not shown: ${adResult.status} ${adResult.reason}');
      return;
    }

    _lastInterstitialRound = state.gamesPlayed;
    _interstitialImpressionHistoryUtc.add(nowUtc);
    await _trackAdImpression(
      placement: AdPlacement.gameOverInterstitial,
      adType: 'interstitial',
      adResult: adResult,
    );
  }

  bool _hasAnyValidMove({
    required BoardState boardState,
    required List<Piece> rackPieces,
  }) {
    for (final Piece piece in rackPieces) {
      for (int y = 0; y < boardState.size; y++) {
        for (int x = 0; x < boardState.size; x++) {
          final PlacePieceResult result = placePieceUseCase.execute(
            boardState: boardState,
            move: Move(
              piece: piece,
              anchorX: x,
              anchorY: y,
            ),
          );
          if (result.isSuccess) {
            return true;
          }
        }
      }
    }
    return false;
  }

  List<Piece> _nextRackPieces({
    required BoardState boardState,
    int maxAttempts = 10,
  }) {
    final difficultyProfile = difficultyTuner.resolve(
      sessionState: _sessionState,
      remoteConfig: _remoteConfig,
    );

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final List<Piece> candidate = pieceGenerationService
          .nextTriplet(
            boardState: boardState,
            profile: difficultyProfile,
          )
          .pieces;
      if (_hasAnyValidMove(boardState: boardState, rackPieces: candidate)) {
        return candidate;
      }
    }

    return pieceGenerationService
        .nextTriplet(
          boardState: boardState,
          profile: difficultyProfile,
        )
        .pieces;
  }

  int _resolveLevel({
    required int totalScore,
  }) {
    final int levelScoreStep =
        (_remoteConfig['progression.level_score_step'] as num?)?.toInt() ?? 140;
    final int clampedStep = levelScoreStep.clamp(60, 2000);
    return 1 + (totalScore ~/ clampedStep);
  }

  int _resolveColorThemeIndex(int level) {
    const int paletteCount = 6;
    if (level <= 1) {
      return 0;
    }
    return (level - 1) % paletteCount;
  }

  Future<void> _handleOnboardingAfterMove({
    required int clearedLines,
    required int comboStreak,
  }) async {
    if (_onboardingCompleted || !state.isOnboardingVisible) {
      return;
    }

    _onboardingMoveCount += 1;
    final String? currentStep = state.onboardingStepId;
    if (currentStep == null) {
      return;
    }

    if (currentStep == _tutorialStepWelcome) {
      await _trackTutorialStep(
        stepId: _tutorialStepWelcome,
        status: _tutorialStatusCompleted,
      );
      await _activateOnboardingStep(
        stepId: _tutorialStepClearLine,
        title: 'Clear Your First Line',
        description:
            'Fill a full row or column. Line clears give score boosts and open space.',
      );
      return;
    }

    if (currentStep == _tutorialStepClearLine) {
      if (clearedLines > 0) {
        await _trackTutorialStep(
          stepId: _tutorialStepClearLine,
          status: _tutorialStatusCompleted,
        );
        await _activateOnboardingStep(
          stepId: _tutorialStepComboChain,
          title: 'Chain a Combo',
          description:
              'Try to clear lines in consecutive moves to build combo multipliers.',
        );
        return;
      }
      if (_onboardingMoveCount >= _onboardingMaxGuidedMoves()) {
        await _completeOnboarding(
          stepId: _tutorialStepClearLine,
          status: _tutorialStatusSkipped,
          dropoffReason: 'max_guided_moves_reached',
        );
      }
      return;
    }

    if (currentStep == _tutorialStepComboChain) {
      if (comboStreak > 1) {
        await _trackTutorialStep(
          stepId: _tutorialStepComboChain,
          status: _tutorialStatusCompleted,
        );
        await _completeOnboarding(
          stepId: _tutorialFlow,
          status: _tutorialStatusCompleted,
        );
        return;
      }
      if (_onboardingMoveCount >= _onboardingMaxGuidedMoves()) {
        await _completeOnboarding(
          stepId: _tutorialStepComboChain,
          status: _tutorialStatusSkipped,
          dropoffReason: 'max_guided_moves_reached',
        );
      }
    }
  }

  Future<void> _activateOnboardingStep({
    required String stepId,
    required String title,
    required String description,
  }) async {
    if (_onboardingCompleted) {
      return;
    }
    _stateNotifier.value = state.copyWith(
      isOnboardingVisible: true,
      onboardingStepId: stepId,
      onboardingTitle: title,
      onboardingDescription: description,
    );
    await _trackTutorialStep(
      stepId: stepId,
      status: _tutorialStatusShown,
    );
  }

  Future<void> _completeOnboarding({
    required String stepId,
    required String status,
    String? dropoffReason,
  }) async {
    if (_onboardingCompleted) {
      return;
    }
    _onboardingCompleted = true;
    _onboardingMoveCount = 0;
    _stateNotifier.value = state.copyWith(
      isOnboardingVisible: false,
      resetOnboarding: true,
    );
    await _trackTutorialStep(
      stepId: stepId,
      status: status,
      dropoffReason: dropoffReason,
    );
  }

  Future<void> _trackTutorialStep({
    required String stepId,
    required String status,
    String? dropoffReason,
  }) async {
    await analyticsTracker.track(
      'tutorial_step',
      params: <String, Object?>{
        'step_id': stepId,
        'status': status,
        if (dropoffReason != null) 'dropoff_reason': dropoffReason,
      },
    );
  }

  int _onboardingMaxGuidedMoves() {
    final int value = _readIntConfig(
      'onboarding.max_guided_moves',
      fallback: 8,
    );
    return value.clamp(2, 40);
  }

  Map<String, String> _collectAbExperimentVariants() {
    return <String, String>{
      'tutorial_onboarding': _readStringConfig(
        'ab.tutorial_variant',
        fallback: _onboardingEnabled ? 'guided_v1' : 'off',
      ),
      'offer_strategy': _readStringConfig(
        'ab.offer_strategy_variant',
        fallback: _readStringConfig(
          'iap.rollout_strategy',
          fallback: 'cosmetics_first',
        ),
      ),
      'difficulty_curve': _readStringConfig(
        'ab.difficulty_variant',
        fallback: 'balanced_v1',
      ),
    };
  }

  Future<void> _trackAbExperimentExposures() async {
    for (final MapEntry<String, String> entry
        in _abExperimentVariants.entries) {
      await analyticsTracker.track(
        'ab_experiment_exposure',
        params: <String, Object?>{
          'experiment_id': entry.key,
          'variant_id': entry.value,
          'source': 'remote_config',
        },
      );
    }
  }

  bool _readBoolConfig(
    String key, {
    required bool fallback,
  }) {
    final Object? rawValue = _remoteConfig[key];
    if (rawValue is bool) {
      return rawValue;
    }
    if (rawValue is String) {
      final String normalized = rawValue.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    if (rawValue is num) {
      return rawValue > 0;
    }
    return fallback;
  }

  int _readIntConfig(
    String key, {
    required int fallback,
  }) {
    final Object? rawValue = _remoteConfig[key];
    if (rawValue is int) {
      return rawValue;
    }
    if (rawValue is num) {
      return rawValue.toInt();
    }
    if (rawValue is String) {
      return int.tryParse(rawValue) ?? fallback;
    }
    return fallback;
  }

  String _readStringConfig(
    String key, {
    required String fallback,
  }) {
    final Object? rawValue = _remoteConfig[key];
    if (rawValue is String && rawValue.trim().isNotEmpty) {
      return rawValue.trim();
    }
    return fallback;
  }

  bool _isRewardedReviveAvailable() {
    if (_rewardedReviveUsedInCurrentGame) {
      return false;
    }
    return adGuardrailPolicy.isRewardedReviveEnabled(_remoteConfig);
  }

  _ReviveSnapshot? _buildReviveSnapshot() {
    final int baseClearCells =
        adGuardrailPolicy.rewardedReviveClearCells(_remoteConfig);

    for (int attempt = 0; attempt < 3; attempt++) {
      final int cellsToClear = baseClearCells + (attempt * 2);
      final BoardState candidateBoard = _clearCellsForRevive(
        boardState: state.boardState,
        cellsToClear: cellsToClear,
      );
      final List<Piece> candidateRack = _nextRackPieces(
        boardState: candidateBoard,
        maxAttempts: 40,
      );
      final bool hasMove = _hasAnyValidMove(
        boardState: candidateBoard,
        rackPieces: candidateRack,
      );
      if (hasMove) {
        return _ReviveSnapshot(
          boardState: candidateBoard,
          rackPieces: candidateRack,
        );
      }
    }

    return null;
  }

  BoardState _clearCellsForRevive({
    required BoardState boardState,
    required int cellsToClear,
  }) {
    if (boardState.occupiedCells.isEmpty) {
      return boardState;
    }

    final double center = (boardState.size - 1) / 2;
    final List<BoardCell> sorted = boardState.occupiedCells.toList()
      ..sort((BoardCell a, BoardCell b) {
        final num aDist = (a.x - center).abs() + (a.y - center).abs();
        final num bDist = (b.x - center).abs() + (b.y - center).abs();
        return aDist.compareTo(bDist);
      });

    final Set<BoardCell> toRemove = sorted.take(cellsToClear).toSet();
    return boardState.removeCells((BoardCell cell) => toRemove.contains(cell));
  }

  Future<void> _trackAdImpression({
    required AdPlacement placement,
    required String adType,
    required AdShowResult adResult,
  }) async {
    final Map<String, Object?> params = <String, Object?>{
      'placement': placement.wireName,
      'ad_type': adType,
      'network': adResult.network,
    };
    if (adResult.ecpmUsd != null) {
      params['ecpm_usd'] = adResult.ecpmUsd!;
    }
    await analyticsTracker.track(
      'ad_impression',
      params: params,
    );
  }

  Future<void> _trackGameEnd({
    required String reason,
    required int score,
  }) async {
    final int durationSec = _gameStartedAt == null
        ? 0
        : DateTime.now().toUtc().difference(_gameStartedAt!).inSeconds;
    await analyticsTracker.track(
      'game_end',
      params: <String, Object?>{
        'round_id': _currentGameNumber,
        'end_reason': reason,
        'score': score,
        'duration_sec': durationSec,
      },
    );
  }

  void _pruneInterstitialHistory(DateTime nowUtc) {
    final int windowMinutes =
        (_remoteConfig['ads.interstitial_window_minutes'] as num?)?.toInt() ??
            10;
    final DateTime windowStart = nowUtc.subtract(
      Duration(minutes: windowMinutes),
    );
    _interstitialImpressionHistoryUtc.removeWhere(
      (DateTime ts) => ts.isBefore(windowStart),
    );
  }

  Future<void> _trackSessionEnd() async {
    final DateTime? startedAt = _sessionStartedAt;
    if (startedAt == null) {
      return;
    }
    final int durationSec =
        DateTime.now().toUtc().difference(startedAt).inSeconds;
    await analyticsTracker.track(
      'session_end',
      params: <String, Object?>{
        'session_id': _sessionId ?? 'unknown_session',
        'duration_sec': durationSec,
        'rounds_played': state.gamesPlayed,
      },
    );
  }

  void dispose() {
    unawaited(_trackSessionEnd());
    _stateNotifier.dispose();
  }
}

class _ReviveSnapshot {
  const _ReviveSnapshot({
    required this.boardState,
    required this.rackPieces,
  });

  final BoardState boardState;
  final List<Piece> rackPieces;
}
