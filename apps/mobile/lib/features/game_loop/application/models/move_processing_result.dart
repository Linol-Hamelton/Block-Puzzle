import '../../../../domain/gameplay/board_state.dart';

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
      clearedCells: const <BoardCell>{},
      comboStreak: 0,
      totalScore: 0,
      isGameOver: false,
      failureReason: reason,
    );
  }
}
