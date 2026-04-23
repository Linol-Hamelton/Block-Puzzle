import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/remote_config_reader.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/observability/guardrail_alert_evaluator.dart';
import '../../../core/observability/session_observability_tracker.dart';
import '../../../data/analytics/analytics_tracker.dart';
import '../../../data/remote_config/remote_config_repository.dart';
import '../../../data/remote_config/remote_config_snapshot.dart';
import '../../../domain/generator/difficulty_tuner.dart';
import '../../../domain/generator/piece_generation_service.dart';
import '../../../domain/gameplay/board_state.dart';
import '../../../domain/gameplay/move.dart';
import '../../../domain/gameplay/piece.dart';
import '../../../domain/progression/player_progress_repository.dart';
import '../../../domain/progression/player_progress_state.dart';
import '../../../domain/progression/progression_snapshots.dart';
import '../../../domain/scoring/score_state.dart';
import '../../../domain/session/game_session_repository.dart';
import '../../../domain/session/game_snapshot.dart';
import '../../../domain/session/session_state.dart';
import '../../monetization/ad_guardrail_decision.dart';
import '../../monetization/ad_guardrail_policy.dart';
import '../../monetization/ad_placement.dart';
import '../../monetization/ad_service.dart';
import '../../monetization/ad_show_result.dart';
import '../../monetization/iap_store_service.dart';
import 'game_loop_phase.dart';
import 'game_loop_view_state.dart';
import 'models/models.dart';
import 'services/ab_experiment_service.dart';
import 'services/onboarding_flow_controller.dart';
import 'services/progression_sync_service.dart';
import 'services/share_flow_service.dart';
import 'use_cases/clear_lines_use_case.dart';
import 'use_cases/compute_score_use_case.dart';
import 'use_cases/place_piece_use_case.dart';

class GameLoopController {
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
    required this.logger,
    this.appVersion = 'dev-local',
    GuardrailAlertEvaluator? guardrailAlertEvaluator,
    SessionObservabilityTracker? observabilityTracker,
    DateTime Function()? nowUtcProvider,
    PlayerProgressRepository? playerProgressRepository,
    GameSessionRepository? gameSessionRepository,
    ABExperimentService? abExperimentService,
    ProgressionSyncService? progressionSyncService,
    ShareFlowService? shareFlowService,
    OnboardingFlowController? onboardingFlowController,
  })  : gameSessionRepository = gameSessionRepository ?? _NoopGameSessionRepository(),
        abExperimentService = abExperimentService ?? ABExperimentService(
          analyticsTracker: analyticsTracker,
          logger: logger,
        ),
        progressionSyncService = progressionSyncService ?? ProgressionSyncService(
          playerProgressRepository: playerProgressRepository!,
          analyticsTracker: analyticsTracker,
          logger: logger,
          nowUtcProvider: nowUtcProvider,
        ),
        shareFlowService = shareFlowService ?? ShareFlowService(
          analyticsTracker: analyticsTracker,
          hashtag: '#BlockPuzzle',
        ),
        onboardingFlowController = onboardingFlowController ?? OnboardingFlowController(
          playerProgressRepository: playerProgressRepository!,
          analyticsTracker: analyticsTracker,
          logger: logger,
        ),
        _guardrailAlertEvaluator =
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
  final RemoteConfigRepository remoteConfigRepository;
  final IapStoreService iapStoreService;
  final GameSessionRepository gameSessionRepository;
  final ProgressionSyncService progressionSyncService;
  final ABExperimentService abExperimentService;
  final ShareFlowService shareFlowService;
  final OnboardingFlowController onboardingFlowController;
  final AppLogger logger;
  final String appVersion;
  final GuardrailAlertEvaluator _guardrailAlertEvaluator;
  final SessionObservabilityTracker _observabilityTracker;
  final DateTime Function() _nowUtc;

  final ValueNotifier<GameLoopViewState> _stateNotifier =
      ValueNotifier<GameLoopViewState>(GameLoopViewState.initial());

  Map<String, Object?> _remoteConfig = <String, Object?>{};
  late RemoteConfigReader _configReader = const RemoteConfigReader(<String, Object?>{});
  String _remoteConfigVersion = 'bundled_config_v1';
  SessionState _sessionState = SessionState.initial;
  final List<DateTime> _interstitialImpressionHistoryUtc = <DateTime>[];
  bool _initialized = false;
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
  Set<String> _ownedIapProductIds = <String>{};
  final List<_UndoSnapshot> _undoHistory = <_UndoSnapshot>[];

  PlayerProgressState get _playerProgressState => progressionSyncService.state;

  ValueListenable<GameLoopViewState> get stateListenable => _stateNotifier;
  GameLoopViewState get state => _stateNotifier.value;
  String get blocksVisualPreset => _resolveBlocksVisualPreset();

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final RemoteConfigSnapshot remoteConfigSnapshot =
        await remoteConfigRepository.fetchLatestSnapshot();
    _remoteConfig = remoteConfigSnapshot.config;
    _configReader = RemoteConfigReader(_remoteConfig);
    _remoteConfigVersion = remoteConfigSnapshot.version;
    onboardingFlowController.configure(_configReader);
    onboardingFlowController.configure(_configReader);
    progressionSyncService.configure(_configReader);
    _rewardedToolsHintCost = _configReader.readInt(
      'progression.rewarded_tools_hint_cost',
      fallback: 1,
    ).clamp(1, 20);
    _rewardedToolsUndoCost = _configReader.readInt(
      'progression.rewarded_tools_undo_cost',
      fallback: 1,
    ).clamp(1, 20);
    _undoHistoryLimit = _configReader.readInt(
      'progression.undo_history_limit',
      fallback: 1,
    ).clamp(1, 5);
    _rewardedToolsIapEnabled = _configReader.readBool(
      'iap.rewarded_tools_unlimited_enabled',
      fallback: true,
    );
    _rewardedToolsUnlimitedSku = _configReader.readString(
      'iap.rewarded_tools_unlimited_sku',
      fallback: 'utility_tools_pass',
    );
    _shareFlowEnabled = _configReader.readBool(
      'social.share_enabled',
      fallback: true,
    );
    abExperimentService.configure(_configReader);
    _abBucket = abExperimentService.abBucket;
    _uxVariant = abExperimentService.uxVariant;
    _difficultyVariant = abExperimentService.difficultyVariant;
    
    final int initialRewardedToolsCredits = _configReader.readInt(
      'progression.rewarded_tools_initial_credits',
      fallback: 3,
    ).clamp(0, 500);
    await progressionSyncService.loadAndSync(
      initialRewardedToolsCredits: initialRewardedToolsCredits,
    );
    onboardingFlowController.restoreFromProgress(_playerProgressState);

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
        'app_version': appVersion,
        'platform': defaultTargetPlatform.name,
        'ab_bucket': _abBucket,
        'ux_variant': _uxVariant,
        'difficulty_variant': _difficultyVariant,
      },
    );
    await abExperimentService.trackExposures();
    await analyticsTracker.track('game_loop_initialized');

    final GameSnapshot? snapshot = await gameSessionRepository.loadSnapshot();

    await startNewGame(snapshot: snapshot);
  }

  Future<void> startNewGame({GameSnapshot? snapshot}) async {
    await progressionSyncService.syncForCurrentDay();
    await _refreshOwnedIapProducts();

    _currentGameNumber += 1;
    _observabilityTracker.onRoundStarted();
    _gameStartedAt = _nowUtc();
    _rewardedReviveUsedInCurrentGame = false;
    _undoHistory.clear();
    final int nextGamesPlayed = snapshot != null ? snapshot.gamesPlayed : state.gamesPlayed + 1;
    final bool shouldShowOnboarding =
        onboardingFlowController.shouldShowForGame(nextGamesPlayed) && snapshot == null;
    final BoardState initialBoard = snapshot?.boardState ?? GameLoopViewState.initial().boardState;

    _sessionState = SessionState(
      roundsPlayed: nextGamesPlayed,
      currentScore: snapshot?.scoreState.totalScore ?? 0,
      movesPlayed: snapshot?.movesPlayed ?? 0,
    );
    final int level = snapshot?.level ?? _resolveLevel(totalScore: 0);
    final int colorThemeIndex = _resolveColorThemeIndex(level);

    final List<Piece> rack = snapshot?.rackPieces ?? _nextRackPieces(
      boardState: initialBoard,
      maxAttempts: 24,
    );
    if (snapshot == null) {
      onboardingFlowController.resetMoveCount();
    }

    _stateNotifier.value = state.copyWith(
      boardState: initialBoard,
      scoreState: snapshot?.scoreState ?? ScoreState.initial,
      rackPieces: rack,
      level: level,
      colorThemeIndex: colorThemeIndex,
      uxVariant: _uxVariant,
      phase: GameLoopPhase.playing,
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
      dailyGoals: progressionSyncService.buildDailyGoalsSnapshot(),
      streak: progressionSyncService.buildStreakSnapshot(),
      bestScore: _playerProgressState.bestScore,
      onboardingStepId: shouldShowOnboarding ? onboardingFlowController.initialStepId : null,
      onboardingTitle: shouldShowOnboarding ? onboardingFlowController.initialTitle : null,
      onboardingDescription: shouldShowOnboarding
          ? onboardingFlowController.initialDescription
          : null,
      resetHintSuggestion: true,
      gamesPlayed: nextGamesPlayed,
      movesPlayed: snapshot?.movesPlayed ?? 0,
      resetOnboarding: !shouldShowOnboarding,
      resetGameOverReason: true,
    );

    if (shouldShowOnboarding) {
      await onboardingFlowController.trackStepShown(
        onboardingFlowController.initialStepId,
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
        'config_version': _remoteConfigVersion,
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

    final DailyGoalsSnapshot dailyGoalsBefore =
        progressionSyncService.buildDailyGoalsSnapshot();
    await progressionSyncService.applyAfterMove(
      clearedLines: lineResult.clearedTotal,
      scoreDelta: scoreDelta,
      bestScore: nextBestScore,
    );
    final DailyGoalsSnapshot dailyGoalsAfter =
        progressionSyncService.buildDailyGoalsSnapshot();
    await progressionSyncService.trackNewGoalCompletions(
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
      phase: isGameOver ? GameLoopPhase.gameOver : GameLoopPhase.playing,
      isGameOver: isGameOver,
      canUseRewardedRevive: isGameOver ? (adGuardrailPolicy.isRewardedReviveEnabled(_remoteConfig) && !_rewardedReviveUsedInCurrentGame) : false,
      canUseRewardedHint: _canUseRewardedHintForState(
        isGameOver: isGameOver,
        rackPieces: nextRack,
      ),
      canUseRewardedUndo: _canUseRewardedUndoForState(),
      rewardedToolsCredits: _playerProgressState.rewardedToolsCredits,
      hasUnlimitedRewardedTools: _hasUnlimitedRewardedToolsAccess,
      dailyGoals: dailyGoalsAfter,
      streak: progressionSyncService.buildStreakSnapshot(),
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

    final OnboardingUpdate? onboardingUpdate =
        await onboardingFlowController.handleAfterMove(
      currentStepId: state.onboardingStepId,
      isOnboardingVisible: state.isOnboardingVisible,
      clearedLines: lineResult.clearedTotal,
      comboStreak: nextScore.comboStreak,
      progressState: _playerProgressState,
    );

    if (onboardingUpdate != null) {
      if (onboardingUpdate.type == OnboardingUpdateType.advanceStep) {
        progressionSyncService.updateState(
          await onboardingFlowController.activateStep(
            stepId: onboardingUpdate.stepId!,
            progressState: _playerProgressState,
          ),
        );
        _stateNotifier.value = state.copyWith(
          onboardingStepId: onboardingUpdate.stepId,
          onboardingTitle: onboardingUpdate.title,
          onboardingDescription: onboardingUpdate.description,
        );
      } else if (onboardingUpdate.type == OnboardingUpdateType.complete) {
        _stateNotifier.value = state.copyWith(
          isOnboardingVisible: false,
          resetOnboarding: true,
        );
      }
    }

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
        await onboardingFlowController.completeOnGameOver(
          currentStepId: state.onboardingStepId,
          progressState: _playerProgressState,
        );
        _stateNotifier.value = state.copyWith(
          isOnboardingVisible: false,
          resetOnboarding: true,
        );
      }
      await _trackGameEnd(
        reason: 'no_valid_moves',
        score: nextScore.totalScore,
      );
      await gameSessionRepository.clearSnapshot();
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
      phase: GameLoopPhase.playing,
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

    final String source = await progressionSyncService.consumeCredits(
      cost: _rewardedToolsHintCost,
      hasUnlimitedAccess: _hasUnlimitedRewardedToolsAccess,
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
    final String source = await progressionSyncService.consumeCredits(
      cost: _rewardedToolsUndoCost,
      hasUnlimitedAccess: _hasUnlimitedRewardedToolsAccess,
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
      phase: GameLoopPhase.playing,
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
    return shareFlowService.buildShareText(state);
  }

  Future<void> trackShareScoreTapped({
    required String channel,
  }) async {
    await shareFlowService.trackShareTapped(
      channel: channel,
      roundId: _currentGameNumber,
      state: state,
      uxVariant: _uxVariant,
      difficultyVariant: _difficultyVariant,
    );
  }

  Future<void> trackShareScoreResult({
    required String channel,
    required bool success,
    String? failureReason,
  }) async {
    await shareFlowService.trackShareResult(
      channel: channel,
      success: success,
      roundId: _currentGameNumber,
      state: state,
      uxVariant: _uxVariant,
      difficultyVariant: _difficultyVariant,
      failureReason: failureReason,
    );
  }

  void pauseGame() {
    if (state.phase == GameLoopPhase.playing) {
      _stateNotifier.value = state.copyWith(phase: GameLoopPhase.paused);
      final GameSnapshot snapshot = GameSnapshot(
        boardState: state.boardState,
        scoreState: state.scoreState,
        rackPieces: state.rackPieces,
        level: state.level,
        movesPlayed: state.movesPlayed,
        gamesPlayed: state.gamesPlayed,
      );
      gameSessionRepository.saveSnapshot(snapshot);
      logger.info('Game paused: saved snapshot');
    }
  }

  void resumeGame() {
    if (state.phase == GameLoopPhase.paused) {
      _stateNotifier.value = state.copyWith(phase: GameLoopPhase.playing);
      logger.info('Game resumed');
    }
  }

  Future<void> dismissOnboarding({
    String reason = 'manual_dismiss',
  }) async {
    if (!state.isOnboardingVisible) {
      return;
    }
    await onboardingFlowController.dismiss(
      currentStepId: state.onboardingStepId,
      progressState: _playerProgressState,
      reason: reason,
    );
    _stateNotifier.value = state.copyWith(
      isOnboardingVisible: false,
      resetOnboarding: true,
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

  Future<void> _refreshOwnedIapProducts() async {
    try {
      final Set<String> nextOwnedProductIds =
          await iapStoreService.loadOwnedProductIds();
      _ownedIapProductIds = nextOwnedProductIds;
      if (!setEquals(
        nextOwnedProductIds,
        _playerProgressState.ownedProductIds,
      )) {
        await progressionSyncService.updateOwnedIapProducts(nextOwnedProductIds);
      }
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



  String _resolveBlocksVisualPreset() {
    final String value = _configReader.readString(
      'visual.blocks_preset',
      fallback: _playerProgressState.settings.selectedBlocksPreset,
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
    unawaited(
      _trackSessionEnd().whenComplete(analyticsTracker.close),
    );
    _stateNotifier.dispose();
  }
}

class _NoopGameSessionRepository implements GameSessionRepository {
  @override
  Future<GameSnapshot?> loadSnapshot() async => null;
  @override
  Future<void> saveSnapshot(GameSnapshot snapshot) async {}
  @override
  Future<void> clearSnapshot() async {}
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
