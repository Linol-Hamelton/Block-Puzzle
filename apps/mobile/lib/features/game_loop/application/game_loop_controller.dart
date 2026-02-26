import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/observability/guardrail_alert_evaluator.dart';
import '../../../core/observability/session_observability_tracker.dart';
import '../../../data/analytics/analytics_tracker.dart';
import '../../../data/remote_config/remote_config_repository.dart';
import '../../../domain/generator/difficulty_tuner.dart';
import '../../../domain/generator/piece_generation_service.dart';
import '../../../domain/gameplay/board_state.dart';
import '../../../domain/gameplay/move.dart';
import '../../../domain/gameplay/piece.dart';
import '../../../domain/progression/player_progress_repository.dart';
import '../../../domain/progression/player_progress_state.dart';
import '../../../domain/progression/progression_snapshots.dart';
import '../../../domain/scoring/score_state.dart';
import '../../../domain/session/session_state.dart';
import '../../monetization/ad_guardrail_decision.dart';
import '../../monetization/ad_guardrail_policy.dart';
import '../../monetization/ad_placement.dart';
import '../../monetization/ad_service.dart';
import '../../monetization/ad_show_result.dart';
import '../../monetization/iap_store_service.dart';
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

class RewardedHintResult {
  const RewardedHintResult({
    required this.isSuccess,
    this.hintSuggestion,
    this.failureReason,
  });

  final bool isSuccess;
  final HintSuggestion? hintSuggestion;
  final String? failureReason;

  factory RewardedHintResult.success(HintSuggestion hintSuggestion) {
    return RewardedHintResult(
      isSuccess: true,
      hintSuggestion: hintSuggestion,
    );
  }

  factory RewardedHintResult.failure(String reason) {
    return RewardedHintResult(
      isSuccess: false,
      failureReason: reason,
    );
  }
}

class RewardedUndoResult {
  const RewardedUndoResult({
    required this.isSuccess,
    this.failureReason,
  });

  final bool isSuccess;
  final String? failureReason;

  factory RewardedUndoResult.success() {
    return const RewardedUndoResult(isSuccess: true);
  }

  factory RewardedUndoResult.failure(String reason) {
    return RewardedUndoResult(
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
  static const String _dailyGoalMoves = 'daily_moves';
  static const String _dailyGoalLines = 'daily_lines_cleared';
  static const String _dailyGoalScore = 'daily_score';
  static const String _hintCostSourceEarned = 'earned_credits';
  static const String _hintCostSourceIap = 'iap_unlimited';
  static const String _defaultShareHashtag = '#BlockPuzzle';

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
    required this.iapStoreService,
    required this.playerProgressRepository,
    required this.logger,
    GuardrailAlertEvaluator? guardrailAlertEvaluator,
    SessionObservabilityTracker? observabilityTracker,
    DateTime Function()? nowUtcProvider,
  })  : _guardrailAlertEvaluator =
            guardrailAlertEvaluator ?? const GuardrailAlertEvaluator(),
        _observabilityTracker =
            observabilityTracker ?? SessionObservabilityTracker(),
        _nowUtc = nowUtcProvider ?? (() => DateTime.now().toUtc());

  final PlacePieceUseCase placePieceUseCase;
  final ClearLinesUseCase clearLinesUseCase;
  final ComputeScoreUseCase computeScoreUseCase;
  final PieceGenerationService pieceGenerationService;
  final DifficultyTuner difficultyTuner;
  final RemoteConfigRepository remoteConfigRepository;
  final AnalyticsTracker analyticsTracker;
  final AdService adService;
  final AdGuardrailPolicy adGuardrailPolicy;
  final IapStoreService iapStoreService;
  final PlayerProgressRepository playerProgressRepository;
  final AppLogger logger;
  final GuardrailAlertEvaluator _guardrailAlertEvaluator;
  final SessionObservabilityTracker _observabilityTracker;
  final DateTime Function() _nowUtc;

  final ValueNotifier<GameLoopViewState> _stateNotifier =
      ValueNotifier<GameLoopViewState>(GameLoopViewState.initial());

  Map<String, Object?> _remoteConfig = <String, Object?>{};
  SessionState _sessionState = SessionState.initial;
  final List<DateTime> _interstitialImpressionHistoryUtc = <DateTime>[];
  bool _initialized = false;
  bool _onboardingEnabled = true;
  bool _onboardingCompleted = false;
  int _onboardingMoveCount = 0;
  bool _streakEnabled = true;
  int _dailyGoalMovesTarget = 18;
  int _dailyGoalLinesTarget = 6;
  int _dailyGoalScoreTarget = 350;
  int _dailyGoalRewardCredits = 1;
  int _rewardedToolsHintCost = 1;
  int _rewardedToolsUndoCost = 1;
  int _undoHistoryLimit = 1;
  bool _rewardedToolsIapEnabled = true;
  String _rewardedToolsUnlimitedSku = 'utility_tools_pass';
  bool _bannerRequestedInSession = false;
  bool _rewardedReviveUsedInCurrentGame = false;
  int _currentGameNumber = 0;
  int? _lastInterstitialRound;
  DateTime? _sessionStartedAt;
  DateTime? _gameStartedAt;
  String? _sessionId;
  String _abBucket = 'control';
  String _uxVariant = 'hud_standard_v1';
  String _difficultyVariant = 'balanced_v1';
  bool _shareFlowEnabled = true;
  String _shareHashtag = _defaultShareHashtag;
  Map<String, String> _abExperimentVariants = <String, String>{};
  Set<String> _ownedIapProductIds = <String>{};
  final List<_UndoSnapshot> _undoHistory = <_UndoSnapshot>[];
  PlayerProgressState _playerProgressState = PlayerProgressState.initialForDay(
    DateTime.utc(1970, 1, 1),
  );

  ValueListenable<GameLoopViewState> get stateListenable => _stateNotifier;
  GameLoopViewState get state => _stateNotifier.value;
  String get blocksVisualPreset => _resolveBlocksVisualPreset();

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _remoteConfig = await remoteConfigRepository.getCached();
    _onboardingEnabled = _readBoolConfig(
      'onboarding.enabled',
      fallback: true,
    );
    _streakEnabled = _readBoolConfig(
      'progression.streak_enabled',
      fallback: true,
    );
    _dailyGoalMovesTarget = _readIntConfig(
      'progression.daily_goal_moves_target',
      fallback: 18,
    ).clamp(1, 500);
    _dailyGoalLinesTarget = _readIntConfig(
      'progression.daily_goal_lines_target',
      fallback: 6,
    ).clamp(1, 100);
    _dailyGoalScoreTarget = _readIntConfig(
      'progression.daily_goal_score_target',
      fallback: 350,
    ).clamp(20, 50000);
    _dailyGoalRewardCredits = _readIntConfig(
      'progression.daily_goal_reward_credits',
      fallback: 1,
    ).clamp(0, 50);
    _rewardedToolsHintCost = _readIntConfig(
      'progression.rewarded_tools_hint_cost',
      fallback: 1,
    ).clamp(1, 20);
    _rewardedToolsUndoCost = _readIntConfig(
      'progression.rewarded_tools_undo_cost',
      fallback: 1,
    ).clamp(1, 20);
    _undoHistoryLimit = _readIntConfig(
      'progression.undo_history_limit',
      fallback: 1,
    ).clamp(1, 5);
    _rewardedToolsIapEnabled = _readBoolConfig(
      'iap.rewarded_tools_unlimited_enabled',
      fallback: true,
    );
    _rewardedToolsUnlimitedSku = _readStringConfig(
      'iap.rewarded_tools_unlimited_sku',
      fallback: 'utility_tools_pass',
    );
    _abBucket = _readStringConfig(
      'ab.bucket',
      fallback: 'control',
    );
    _uxVariant = _readStringConfig(
      'ab.ux_variant',
      fallback: 'hud_standard_v1',
    );
    _difficultyVariant = _readStringConfig(
      'ab.difficulty_variant',
      fallback: 'balanced_v1',
    );
    _shareFlowEnabled = _readBoolConfig(
      'social.share_enabled',
      fallback: true,
    );
    _shareHashtag = _normalizeShareHashtag(
      _readStringConfig(
        'social.share_score_hashtag',
        fallback: _defaultShareHashtag,
      ),
    );
    _abExperimentVariants = _collectAbExperimentVariants();
    await _loadAndSyncProgressForCurrentDay();
    await _refreshOwnedIapProducts();
    await adService.preload();

    _initialized = true;
    _sessionStartedAt = _nowUtc();
    _sessionId = 'session_${_sessionStartedAt!.millisecondsSinceEpoch}';
    _observabilityTracker.startSession(
      sessionId: _sessionId!,
    );

    logger.info('Game loop initialized with config: $_remoteConfig');
    await analyticsTracker.track(
      'session_start',
      params: <String, Object?>{
        'session_id': _sessionId,
        'app_version': 'dev-local',
        'platform': defaultTargetPlatform.name,
        'ab_bucket': _abBucket,
        'ux_variant': _uxVariant,
        'difficulty_variant': _difficultyVariant,
      },
    );
    await _trackAbExperimentExposures();
    await analyticsTracker.track('game_loop_initialized');

    await startNewGame();
  }

  Future<void> startNewGame() async {
    await _syncProgressForCurrentDay();
    await _refreshOwnedIapProducts();

    _currentGameNumber += 1;
    _observabilityTracker.onRoundStarted();
    _gameStartedAt = _nowUtc();
    _rewardedReviveUsedInCurrentGame = false;
    _undoHistory.clear();
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
      uxVariant: _uxVariant,
      isShareFlowEnabled: _shareFlowEnabled,
      isGameOver: false,
      canUseRewardedRevive: false,
      canUseRewardedHint: _canUseRewardedHintForState(
        isGameOver: false,
        rackPieces: rack,
      ),
      canUseRewardedUndo: _canUseRewardedUndoForState(),
      rewardedToolsCredits: _playerProgressState.rewardedToolsCredits,
      hasUnlimitedRewardedTools: _hasUnlimitedRewardedToolsAccess,
      isBannerVisible: adGuardrailPolicy.isBannerEnabled(_remoteConfig),
      isOnboardingVisible: shouldShowOnboarding,
      dailyGoals: _buildDailyGoalsSnapshot(),
      streak: _buildStreakSnapshot(),
      onboardingStepId: shouldShowOnboarding ? _tutorialStepWelcome : null,
      onboardingTitle: shouldShowOnboarding ? 'Welcome to Classic Mode' : null,
      onboardingDescription: shouldShowOnboarding
          ? 'Drag any piece from the rack onto the board to start your run.'
          : null,
      resetHintSuggestion: true,
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
        'ux_variant': _uxVariant,
        'difficulty_variant': _difficultyVariant,
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

    _observabilityTracker.onMoveAttempt();

    final bool pieceExistsInRack =
        state.rackPieces.any((Piece piece) => piece.id == move.piece.id);
    if (!pieceExistsInRack) {
      _observabilityTracker.onMoveRejected();
      return MoveProcessingResult.failure('piece_not_in_rack');
    }

    final PlacePieceResult placeResult = placePieceUseCase.execute(
      boardState: state.boardState,
      move: move,
    );

    if (!placeResult.isSuccess) {
      _observabilityTracker.onMoveRejected();
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

    _pushUndoSnapshot();

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
    final int scoreDelta = nextScore.totalScore - state.scoreState.totalScore;
    final int previousLevel = state.level;
    final int nextLevel = _resolveLevel(totalScore: nextScore.totalScore);
    final bool levelUp = nextLevel > previousLevel;
    final int nextColorThemeIndex = _resolveColorThemeIndex(nextLevel);
    final double boardFillPct = lineResult.boardState.occupiedCells.length /
        (lineResult.boardState.size * lineResult.boardState.size);

    final DailyGoalsSnapshot dailyGoalsBefore = _buildDailyGoalsSnapshot();
    await _applyProgressAfterMove(
      clearedLines: lineResult.clearedTotal,
      scoreDelta: scoreDelta,
    );
    final DailyGoalsSnapshot dailyGoalsAfter = _buildDailyGoalsSnapshot();
    await _trackNewGoalCompletions(
      before: dailyGoalsBefore,
      after: dailyGoalsAfter,
    );

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
      canUseRewardedHint: _canUseRewardedHintForState(
        isGameOver: isGameOver,
        rackPieces: nextRack,
      ),
      canUseRewardedUndo: _canUseRewardedUndoForState(),
      rewardedToolsCredits: _playerProgressState.rewardedToolsCredits,
      hasUnlimitedRewardedTools: _hasUnlimitedRewardedToolsAccess,
      dailyGoals: dailyGoalsAfter,
      streak: _buildStreakSnapshot(),
      bestScore: nextBestScore,
      movesPlayed: nextMovesPlayed,
      gameOverReason: isGameOver ? 'no_valid_moves' : null,
      resetHintSuggestion: true,
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
      canUseRewardedHint: _canUseRewardedHintForState(
        isGameOver: false,
        rackPieces: reviveSnapshot.rackPieces,
      ),
      canUseRewardedUndo: _canUseRewardedUndoForState(),
      rewardedToolsCredits: _playerProgressState.rewardedToolsCredits,
      hasUnlimitedRewardedTools: _hasUnlimitedRewardedToolsAccess,
      gameOverReason: null,
      resetHintSuggestion: true,
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

  Future<RewardedHintResult> useRewardedHint() async {
    await _refreshOwnedIapProducts();
    if (state.isGameOver) {
      return RewardedHintResult.failure('round_over');
    }
    if (!_hasRewardedToolsForCost(_rewardedToolsHintCost)) {
      return RewardedHintResult.failure('insufficient_tools_credits');
    }

    final HintSuggestion? suggestion = _findHintSuggestion(
      boardState: state.boardState,
      rackPieces: state.rackPieces,
    );
    if (suggestion == null) {
      return RewardedHintResult.failure('no_valid_move');
    }

    final String source = await _consumeRewardedToolsCreditsIfNeeded(
      cost: _rewardedToolsHintCost,
    );

    _stateNotifier.value = state.copyWith(
      hintSuggestion: suggestion,
      canUseRewardedHint: _canUseRewardedHintForState(
        isGameOver: state.isGameOver,
        rackPieces: state.rackPieces,
      ),
      canUseRewardedUndo: _canUseRewardedUndoForState(),
      rewardedToolsCredits: _playerProgressState.rewardedToolsCredits,
      hasUnlimitedRewardedTools: _hasUnlimitedRewardedToolsAccess,
    );

    await analyticsTracker.track(
      'rewarded_hint_used',
      params: <String, Object?>{
        'round_id': _currentGameNumber,
        'cost': _rewardedToolsHintCost,
        'source': source,
        'credits_after': _playerProgressState.rewardedToolsCredits,
        'piece_id': suggestion.piece.id,
        'anchor_x': suggestion.anchorX,
        'anchor_y': suggestion.anchorY,
      },
    );

    return RewardedHintResult.success(suggestion);
  }

  Future<RewardedUndoResult> useRewardedUndo() async {
    await _refreshOwnedIapProducts();
    if (_undoHistory.isEmpty) {
      return RewardedUndoResult.failure('undo_not_available');
    }
    if (!_hasRewardedToolsForCost(_rewardedToolsUndoCost)) {
      return RewardedUndoResult.failure('insufficient_tools_credits');
    }

    final _UndoSnapshot snapshot = _undoHistory.removeLast();
    final String source = await _consumeRewardedToolsCreditsIfNeeded(
      cost: _rewardedToolsUndoCost,
    );

    _sessionState = SessionState(
      roundsPlayed: state.gamesPlayed,
      currentScore: snapshot.scoreState.totalScore,
      movesPlayed: snapshot.movesPlayed,
    );

    _stateNotifier.value = state.copyWith(
      boardState: snapshot.boardState,
      scoreState: snapshot.scoreState,
      rackPieces: snapshot.rackPieces,
      level: snapshot.level,
      colorThemeIndex: snapshot.colorThemeIndex,
      isGameOver: false,
      canUseRewardedRevive: false,
      canUseRewardedHint: _canUseRewardedHintForState(
        isGameOver: false,
        rackPieces: snapshot.rackPieces,
      ),
      canUseRewardedUndo: _canUseRewardedUndoForState(),
      rewardedToolsCredits: _playerProgressState.rewardedToolsCredits,
      hasUnlimitedRewardedTools: _hasUnlimitedRewardedToolsAccess,
      movesPlayed: snapshot.movesPlayed,
      gameOverReason: null,
      resetHintSuggestion: true,
      resetGameOverReason: true,
    );

    await analyticsTracker.track(
      'rewarded_undo_used',
      params: <String, Object?>{
        'round_id': _currentGameNumber,
        'cost': _rewardedToolsUndoCost,
        'source': source,
        'credits_after': _playerProgressState.rewardedToolsCredits,
        'moves_after': snapshot.movesPlayed,
      },
    );

    return RewardedUndoResult.success();
  }

  String buildShareScoreText() {
    final int score = state.scoreState.totalScore;
    final int best = state.bestScore;
    final int level = state.level;
    final int moves = state.movesPlayed;
    final int goalsCompleted = state.dailyGoals.completedCount;
    final int goalsTotal = state.dailyGoals.totalCount;

    return 'I scored $score in Lumina Blocks! '
        'Best: $best, Level: $level, Moves: $moves, '
        'Daily goals: $goalsCompleted/$goalsTotal. '
        'Can you beat it? $_shareHashtag';
  }

  Future<void> trackShareScoreTapped({
    required String channel,
  }) async {
    await analyticsTracker.track(
      'share_score_tapped',
      params: <String, Object?>{
        'round_id': _currentGameNumber,
        'channel': channel,
        'score_total': state.scoreState.totalScore,
        'best_score': state.bestScore,
        'level': state.level,
        'moves_played': state.movesPlayed,
        'daily_goals_completed': state.dailyGoals.completedCount,
        'daily_goals_total': state.dailyGoals.totalCount,
        'ux_variant': _uxVariant,
        'difficulty_variant': _difficultyVariant,
      },
    );
  }

  Future<void> trackShareScoreResult({
    required String channel,
    required bool success,
    String? failureReason,
  }) async {
    await analyticsTracker.track(
      'share_score_result',
      params: <String, Object?>{
        'round_id': _currentGameNumber,
        'channel': channel,
        'success': success,
        if (failureReason != null) 'failure_reason': failureReason,
        'score_total': state.scoreState.totalScore,
        'best_score': state.bestScore,
        'level': state.level,
        'moves_played': state.movesPlayed,
        'daily_goals_completed': state.dailyGoals.completedCount,
        'daily_goals_total': state.dailyGoals.totalCount,
        'ux_variant': _uxVariant,
        'difficulty_variant': _difficultyVariant,
      },
    );
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
    final DateTime nowUtc = _nowUtc();
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

  void _pushUndoSnapshot() {
    _undoHistory.add(
      _UndoSnapshot(
        boardState: state.boardState,
        scoreState: state.scoreState,
        rackPieces: List<Piece>.from(state.rackPieces),
        level: state.level,
        colorThemeIndex: state.colorThemeIndex,
        movesPlayed: state.movesPlayed,
      ),
    );

    if (_undoHistory.length > _undoHistoryLimit) {
      _undoHistory.removeAt(0);
    }
  }

  HintSuggestion? _findHintSuggestion({
    required BoardState boardState,
    required List<Piece> rackPieces,
  }) {
    HintSuggestion? bestSuggestion;
    int bestRank = -999999;

    for (final Piece piece in rackPieces) {
      for (int y = 0; y < boardState.size; y++) {
        for (int x = 0; x < boardState.size; x++) {
          final PlacePieceResult placement = placePieceUseCase.execute(
            boardState: boardState,
            move: Move(
              piece: piece,
              anchorX: x,
              anchorY: y,
            ),
          );
          if (!placement.isSuccess) {
            continue;
          }

          final clearResult = clearLinesUseCase.execute(
            boardState: placement.boardState,
          );
          final int occupiedAfter = clearResult.boardState.occupiedCells.length;
          final int rank = (clearResult.clearedTotal * 1000) - occupiedAfter;

          if (rank > bestRank) {
            bestRank = rank;
            bestSuggestion = HintSuggestion(
              piece: piece,
              anchorX: x,
              anchorY: y,
              estimatedClearedLines: clearResult.clearedTotal,
            );
          }
        }
      }
    }

    return bestSuggestion;
  }

  bool get _hasUnlimitedRewardedToolsAccess {
    if (!_rewardedToolsIapEnabled) {
      return false;
    }
    return _ownedIapProductIds.contains(_rewardedToolsUnlimitedSku);
  }

  bool _hasRewardedToolsForCost(int cost) {
    if (_hasUnlimitedRewardedToolsAccess) {
      return true;
    }
    return _playerProgressState.rewardedToolsCredits >= cost;
  }

  bool _canUseRewardedHintForState({
    required bool isGameOver,
    required List<Piece> rackPieces,
  }) {
    if (isGameOver) {
      return false;
    }
    if (!_hasRewardedToolsForCost(_rewardedToolsHintCost)) {
      return false;
    }
    return rackPieces.isNotEmpty;
  }

  bool _canUseRewardedUndoForState() {
    if (!_hasRewardedToolsForCost(_rewardedToolsUndoCost)) {
      return false;
    }
    return _undoHistory.isNotEmpty;
  }

  Future<String> _consumeRewardedToolsCreditsIfNeeded({
    required int cost,
  }) async {
    if (_hasUnlimitedRewardedToolsAccess) {
      return _hintCostSourceIap;
    }

    final int nextCredits =
        (_playerProgressState.rewardedToolsCredits - cost).clamp(0, 100000);
    _playerProgressState = _playerProgressState.copyWith(
      rewardedToolsCredits: nextCredits,
    );
    await playerProgressRepository.save(_playerProgressState);
    return _hintCostSourceEarned;
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

  Future<void> _loadAndSyncProgressForCurrentDay() async {
    final DateTime todayUtc = PlayerProgressState.normalizeDayKeyUtc(_nowUtc());
    final int initialRewardedToolsCredits = _readIntConfig(
      'progression.rewarded_tools_initial_credits',
      fallback: 3,
    ).clamp(0, 500);
    _playerProgressState = await playerProgressRepository.load() ??
        PlayerProgressState.initialForDay(
          todayUtc,
          initialRewardedToolsCredits: initialRewardedToolsCredits,
        );

    if (!_streakEnabled) {
      _playerProgressState = _playerProgressState.copyWith(
        streakCurrentDays: 0,
        streakBestDays: 0,
      );
    }

    await _syncProgressForCurrentDay();
    await playerProgressRepository.save(_playerProgressState);
  }

  Future<void> _syncProgressForCurrentDay() async {
    final DateTime todayUtc = PlayerProgressState.normalizeDayKeyUtc(_nowUtc());
    if (_playerProgressState.dayKeyUtc == todayUtc) {
      return;
    }

    final int dayDelta =
        todayUtc.difference(_playerProgressState.dayKeyUtc).inDays;
    int nextStreakCurrent = _playerProgressState.streakCurrentDays;
    int nextStreakBest = _playerProgressState.streakBestDays;
    String streakReason = 'same_day';

    if (_streakEnabled) {
      if (dayDelta == 1) {
        nextStreakCurrent = (_playerProgressState.streakCurrentDays + 1).clamp(
          1,
          10000,
        );
        streakReason = 'continued';
      } else {
        nextStreakCurrent = 1;
        streakReason = 'reset_gap';
      }
      if (nextStreakCurrent > nextStreakBest) {
        nextStreakBest = nextStreakCurrent;
      }
    } else {
      nextStreakCurrent = 0;
      nextStreakBest = 0;
      streakReason = 'disabled';
    }

    _playerProgressState = _playerProgressState.copyWith(
      dayKeyUtc: todayUtc,
      streakCurrentDays: nextStreakCurrent,
      streakBestDays: nextStreakBest,
      dailyMoves: 0,
      dailyLinesCleared: 0,
      dailyScoreEarned: 0,
    );
    await playerProgressRepository.save(_playerProgressState);
    await _trackStreakUpdated(reason: streakReason);
  }

  DailyGoalsSnapshot _buildDailyGoalsSnapshot() {
    return DailyGoalsSnapshot(
      movesProgress: _playerProgressState.dailyMoves,
      movesTarget: _dailyGoalMovesTarget,
      linesProgress: _playerProgressState.dailyLinesCleared,
      linesTarget: _dailyGoalLinesTarget,
      scoreProgress: _playerProgressState.dailyScoreEarned,
      scoreTarget: _dailyGoalScoreTarget,
    );
  }

  StreakSnapshot _buildStreakSnapshot() {
    return StreakSnapshot(
      currentDays: _streakEnabled ? _playerProgressState.streakCurrentDays : 0,
      bestDays: _streakEnabled ? _playerProgressState.streakBestDays : 0,
    );
  }

  Future<void> _applyProgressAfterMove({
    required int clearedLines,
    required int scoreDelta,
  }) async {
    _playerProgressState = _playerProgressState.copyWith(
      dailyMoves: _playerProgressState.dailyMoves + 1,
      dailyLinesCleared: _playerProgressState.dailyLinesCleared + clearedLines,
      dailyScoreEarned: _playerProgressState.dailyScoreEarned + scoreDelta,
    );
    await playerProgressRepository.save(_playerProgressState);
  }

  Future<void> _trackNewGoalCompletions({
    required DailyGoalsSnapshot before,
    required DailyGoalsSnapshot after,
  }) async {
    int newlyCompletedGoals = 0;
    if (!before.movesCompleted && after.movesCompleted) {
      newlyCompletedGoals += 1;
      await _trackDailyGoalProgress(
        goalId: _dailyGoalMoves,
        progress: after.movesProgress,
        target: after.movesTarget,
        completedGoals: after.completedCount,
      );
    }
    if (!before.linesCompleted && after.linesCompleted) {
      newlyCompletedGoals += 1;
      await _trackDailyGoalProgress(
        goalId: _dailyGoalLines,
        progress: after.linesProgress,
        target: after.linesTarget,
        completedGoals: after.completedCount,
      );
    }
    if (!before.scoreCompleted && after.scoreCompleted) {
      newlyCompletedGoals += 1;
      await _trackDailyGoalProgress(
        goalId: _dailyGoalScore,
        progress: after.scoreProgress,
        target: after.scoreTarget,
        completedGoals: after.completedCount,
      );
    }

    if (newlyCompletedGoals <= 0 || _dailyGoalRewardCredits <= 0) {
      return;
    }

    final int creditsEarned = newlyCompletedGoals * _dailyGoalRewardCredits;
    _playerProgressState = _playerProgressState.copyWith(
      rewardedToolsCredits:
          _playerProgressState.rewardedToolsCredits + creditsEarned,
    );
    await playerProgressRepository.save(_playerProgressState);

    await analyticsTracker.track(
      'rewarded_tools_credits_earned',
      params: <String, Object?>{
        'source': 'daily_goals',
        'goals_completed_now': newlyCompletedGoals,
        'credits_earned': creditsEarned,
        'credits_balance': _playerProgressState.rewardedToolsCredits,
      },
    );
  }

  Future<void> _trackDailyGoalProgress({
    required String goalId,
    required int progress,
    required int target,
    required int completedGoals,
  }) async {
    await analyticsTracker.track(
      'daily_goal_progress',
      params: <String, Object?>{
        'goal_id': goalId,
        'progress': progress,
        'target': target,
        'is_completed': progress >= target,
        'completed_goals': completedGoals,
        'total_goals': 3,
      },
    );
  }

  Future<void> _trackStreakUpdated({
    required String reason,
  }) async {
    await analyticsTracker.track(
      'streak_updated',
      params: <String, Object?>{
        'current_streak': _playerProgressState.streakCurrentDays,
        'best_streak': _playerProgressState.streakBestDays,
        'reason': reason,
      },
    );
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
        fallback: _difficultyVariant,
      ),
      'hud_ux': _readStringConfig(
        'ab.ux_variant',
        fallback: _uxVariant,
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

  Future<void> _refreshOwnedIapProducts() async {
    try {
      _ownedIapProductIds = await iapStoreService.loadOwnedProductIds();
    } catch (error) {
      _observabilityTracker.onRuntimeError();
      logger.warn('Failed to refresh IAP ownership: $error');
      unawaited(
        analyticsTracker.track(
          'ops_error',
          params: <String, Object?>{
            'source': 'game_loop_controller',
            'error_type': 'iap_ownership_refresh_failed',
            'message': '$error',
          },
        ),
      );
      _ownedIapProductIds = <String>{};
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

  String _normalizeShareHashtag(String rawValue) {
    final String trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return _defaultShareHashtag;
    }
    if (trimmed.startsWith('#')) {
      return trimmed;
    }
    return '#$trimmed';
  }

  String _resolveBlocksVisualPreset() {
    final String value = _readStringConfig(
      'visual.blocks_preset',
      fallback: 'soft',
    ).trim().toLowerCase();
    if (value == 'crystal') {
      return 'crystal';
    }
    return 'soft';
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
        : _nowUtc().difference(_gameStartedAt!).inSeconds;
    _observabilityTracker.onGameEnded(
      reason: reason,
      durationSec: durationSec,
    );
    await analyticsTracker.track(
      'game_end',
      params: <String, Object?>{
        'round_id': _currentGameNumber,
        'end_reason': reason,
        'score': score,
        'duration_sec': durationSec,
        'ux_variant': _uxVariant,
        'difficulty_variant': _difficultyVariant,
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
    final int durationSec = _nowUtc().difference(startedAt).inSeconds;
    final sessionSnapshot = _observabilityTracker.buildSnapshot(
      sessionDurationSec: durationSec,
      roundsPlayed: state.gamesPlayed,
    );
    final alerts = _guardrailAlertEvaluator.evaluate(
      snapshot: sessionSnapshot,
      remoteConfig: _remoteConfig,
    );
    await analyticsTracker.track(
      'ops_session_snapshot',
      params: sessionSnapshot.toAnalyticsPayload(
        alertCount: alerts.length,
      ),
    );
    for (final alert in alerts) {
      logger.warn(
        'Guardrail alert: ${alert.alertId} '
        '${alert.metricName} ${alert.comparator} '
        '${alert.threshold.toStringAsFixed(4)} (observed=${alert.observedValue.toStringAsFixed(4)})',
      );
      await analyticsTracker.track(
        'ops_alert_triggered',
        params: <String, Object?>{
          'session_id': _sessionId ?? 'unknown_session',
          'alert_id': alert.alertId,
          'severity': alert.severityWireName,
          'metric_name': alert.metricName,
          'comparator': alert.comparator,
          'threshold': alert.threshold,
          'observed_value': alert.observedValue,
          'rounds_played': state.gamesPlayed,
          'ux_variant': _uxVariant,
          'difficulty_variant': _difficultyVariant,
          'message': alert.message,
        },
      );
    }
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

class _UndoSnapshot {
  const _UndoSnapshot({
    required this.boardState,
    required this.scoreState,
    required this.rackPieces,
    required this.level,
    required this.colorThemeIndex,
    required this.movesPlayed,
  });

  final BoardState boardState;
  final ScoreState scoreState;
  final List<Piece> rackPieces;
  final int level;
  final int colorThemeIndex;
  final int movesPlayed;
}
