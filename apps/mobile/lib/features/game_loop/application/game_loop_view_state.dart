import '../../../domain/gameplay/board_state.dart';
import '../../../domain/gameplay/piece.dart';
import '../../../domain/progression/progression_snapshots.dart';
import '../../../domain/scoring/score_state.dart';
import 'game_loop_phase.dart';

class GameLoopViewState {
  const GameLoopViewState({
    required this.boardState,
    required this.scoreState,
    required this.rackPieces,
    required this.level,
    required this.colorThemeIndex,
    required this.uxVariant,
    required this.isShareFlowEnabled,
    required this.isGameOver,
    required this.canUseRewardedRevive,
    required this.canUseRewardedHint,
    required this.canUseRewardedUndo,
    required this.rewardedToolsCredits,
    required this.hasUnlimitedRewardedTools,
    required this.isBannerVisible,
    required this.isOnboardingVisible,
    required this.dailyGoals,
    required this.streak,
    required this.bestScore,
    required this.gamesPlayed,
    required this.movesPlayed,
    this.onboardingStepId,
    this.onboardingTitle,
    this.onboardingDescription,
    this.hintSuggestion,
    this.gameOverReason,
    required this.phase,
  });

  final GameLoopPhase phase;
  final BoardState boardState;
  final ScoreState scoreState;
  final List<Piece> rackPieces;
  final int level;
  final int colorThemeIndex;
  final String uxVariant;
  final bool isShareFlowEnabled;
  final bool isGameOver;
  final bool canUseRewardedRevive;
  final bool canUseRewardedHint;
  final bool canUseRewardedUndo;
  final int rewardedToolsCredits;
  final bool hasUnlimitedRewardedTools;
  final bool isBannerVisible;
  final bool isOnboardingVisible;
  final DailyGoalsSnapshot dailyGoals;
  final StreakSnapshot streak;
  final int bestScore;
  final int gamesPlayed;
  final int movesPlayed;
  final String? onboardingStepId;
  final String? onboardingTitle;
  final String? onboardingDescription;
  final HintSuggestion? hintSuggestion;
  final String? gameOverReason;

  factory GameLoopViewState.initial() {
    return GameLoopViewState(
      boardState: BoardState(size: 8, occupiedCells: <BoardCell>{}),
      scoreState: ScoreState.initial,
      rackPieces: <Piece>[],
      level: 1,
      colorThemeIndex: 0,
      uxVariant: 'hud_standard_v1',
      isShareFlowEnabled: true,
      isGameOver: false,
      canUseRewardedRevive: false,
      canUseRewardedHint: false,
      canUseRewardedUndo: false,
      rewardedToolsCredits: 0,
      hasUnlimitedRewardedTools: false,
      isBannerVisible: false,
      isOnboardingVisible: false,
      dailyGoals: DailyGoalsSnapshot.initial(),
      streak: StreakSnapshot.initial,
      bestScore: 0,
      gamesPlayed: 0,
      movesPlayed: 0,
      onboardingStepId: null,
      onboardingTitle: null,
      onboardingDescription: null,
      hintSuggestion: null,
      phase: GameLoopPhase.idle,
    );
  }

  GameLoopViewState copyWith({
    BoardState? boardState,
    ScoreState? scoreState,
    List<Piece>? rackPieces,
    int? level,
    int? colorThemeIndex,
    String? uxVariant,
    bool? isShareFlowEnabled,
    bool? isGameOver,
    bool? canUseRewardedRevive,
    bool? canUseRewardedHint,
    bool? canUseRewardedUndo,
    int? rewardedToolsCredits,
    bool? hasUnlimitedRewardedTools,
    bool? isBannerVisible,
    bool? isOnboardingVisible,
    DailyGoalsSnapshot? dailyGoals,
    StreakSnapshot? streak,
    int? bestScore,
    int? gamesPlayed,
    int? movesPlayed,
    String? onboardingStepId,
    String? onboardingTitle,
    String? onboardingDescription,
    HintSuggestion? hintSuggestion,
    String? gameOverReason,
    bool resetOnboarding = false,
    bool resetHintSuggestion = false,
    bool resetGameOverReason = false,
    GameLoopPhase? phase,
  }) {
    return GameLoopViewState(
      phase: phase ?? this.phase,
      boardState: boardState ?? this.boardState,
      scoreState: scoreState ?? this.scoreState,
      rackPieces: rackPieces ?? this.rackPieces,
      level: level ?? this.level,
      colorThemeIndex: colorThemeIndex ?? this.colorThemeIndex,
      uxVariant: uxVariant ?? this.uxVariant,
      isShareFlowEnabled: isShareFlowEnabled ?? this.isShareFlowEnabled,
      isGameOver: isGameOver ?? this.isGameOver,
      canUseRewardedRevive: canUseRewardedRevive ?? this.canUseRewardedRevive,
      canUseRewardedHint: canUseRewardedHint ?? this.canUseRewardedHint,
      canUseRewardedUndo: canUseRewardedUndo ?? this.canUseRewardedUndo,
      rewardedToolsCredits: rewardedToolsCredits ?? this.rewardedToolsCredits,
      hasUnlimitedRewardedTools:
          hasUnlimitedRewardedTools ?? this.hasUnlimitedRewardedTools,
      isBannerVisible: isBannerVisible ?? this.isBannerVisible,
      isOnboardingVisible: isOnboardingVisible ?? this.isOnboardingVisible,
      dailyGoals: dailyGoals ?? this.dailyGoals,
      streak: streak ?? this.streak,
      bestScore: bestScore ?? this.bestScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      movesPlayed: movesPlayed ?? this.movesPlayed,
      onboardingStepId:
          resetOnboarding ? null : (onboardingStepId ?? this.onboardingStepId),
      onboardingTitle:
          resetOnboarding ? null : (onboardingTitle ?? this.onboardingTitle),
      onboardingDescription: resetOnboarding
          ? null
          : (onboardingDescription ?? this.onboardingDescription),
      hintSuggestion:
          resetHintSuggestion ? null : (hintSuggestion ?? this.hintSuggestion),
      gameOverReason:
          resetGameOverReason ? null : (gameOverReason ?? this.gameOverReason),
    );
  }
}

class HintSuggestion {
  const HintSuggestion({
    required this.piece,
    required this.anchorX,
    required this.anchorY,
    required this.estimatedClearedLines,
  });

  final Piece piece;
  final int anchorX;
  final int anchorY;
  final int estimatedClearedLines;
}
