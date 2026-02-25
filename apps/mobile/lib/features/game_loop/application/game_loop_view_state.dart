import '../../../domain/gameplay/board_state.dart';
import '../../../domain/gameplay/piece.dart';
import '../../../domain/scoring/score_state.dart';

class GameLoopViewState {
  const GameLoopViewState({
    required this.boardState,
    required this.scoreState,
    required this.rackPieces,
    required this.level,
    required this.colorThemeIndex,
    required this.isGameOver,
    required this.canUseRewardedRevive,
    required this.isBannerVisible,
    required this.bestScore,
    required this.gamesPlayed,
    required this.movesPlayed,
    this.gameOverReason,
  });

  final BoardState boardState;
  final ScoreState scoreState;
  final List<Piece> rackPieces;
  final int level;
  final int colorThemeIndex;
  final bool isGameOver;
  final bool canUseRewardedRevive;
  final bool isBannerVisible;
  final int bestScore;
  final int gamesPlayed;
  final int movesPlayed;
  final String? gameOverReason;

  factory GameLoopViewState.initial() {
    return GameLoopViewState(
      boardState: BoardState(size: 8, occupiedCells: <BoardCell>{}),
      scoreState: ScoreState.initial,
      rackPieces: <Piece>[],
      level: 1,
      colorThemeIndex: 0,
      isGameOver: false,
      canUseRewardedRevive: false,
      isBannerVisible: false,
      bestScore: 0,
      gamesPlayed: 0,
      movesPlayed: 0,
    );
  }

  GameLoopViewState copyWith({
    BoardState? boardState,
    ScoreState? scoreState,
    List<Piece>? rackPieces,
    int? level,
    int? colorThemeIndex,
    bool? isGameOver,
    bool? canUseRewardedRevive,
    bool? isBannerVisible,
    int? bestScore,
    int? gamesPlayed,
    int? movesPlayed,
    String? gameOverReason,
    bool resetGameOverReason = false,
  }) {
    return GameLoopViewState(
      boardState: boardState ?? this.boardState,
      scoreState: scoreState ?? this.scoreState,
      rackPieces: rackPieces ?? this.rackPieces,
      level: level ?? this.level,
      colorThemeIndex: colorThemeIndex ?? this.colorThemeIndex,
      isGameOver: isGameOver ?? this.isGameOver,
      canUseRewardedRevive: canUseRewardedRevive ?? this.canUseRewardedRevive,
      isBannerVisible: isBannerVisible ?? this.isBannerVisible,
      bestScore: bestScore ?? this.bestScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      movesPlayed: movesPlayed ?? this.movesPlayed,
      gameOverReason:
          resetGameOverReason ? null : (gameOverReason ?? this.gameOverReason),
    );
  }
}
