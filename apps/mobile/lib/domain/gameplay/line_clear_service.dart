import 'board_state.dart';

class LineClearResult {
  const LineClearResult({
    required this.boardState,
    required this.clearedRows,
    required this.clearedColumns,
    required this.clearedCells,
  });

  final BoardState boardState;
  final int clearedRows;
  final int clearedColumns;
  final Set<BoardCell> clearedCells;

  int get clearedTotal => clearedRows + clearedColumns;
}

abstract interface class LineClearService {
  LineClearResult apply({
    required BoardState boardState,
  });
}
