import 'board_state.dart';
import 'line_clear_service.dart';

class BasicLineClearService implements LineClearService {
  const BasicLineClearService();

  @override
  LineClearResult apply({
    required BoardState boardState,
  }) {
    final Set<int> fullRows = <int>{};
    final Set<int> fullColumns = <int>{};

    for (int row = 0; row < boardState.size; row++) {
      final bool rowIsFull = List<bool>.generate(
        boardState.size,
        (int column) => boardState.isOccupied(BoardCell(x: column, y: row)),
      ).every((bool value) => value);
      if (rowIsFull) {
        fullRows.add(row);
      }
    }

    for (int column = 0; column < boardState.size; column++) {
      final bool columnIsFull = List<bool>.generate(
        boardState.size,
        (int row) => boardState.isOccupied(BoardCell(x: column, y: row)),
      ).every((bool value) => value);
      if (columnIsFull) {
        fullColumns.add(column);
      }
    }

    if (fullRows.isEmpty && fullColumns.isEmpty) {
      return LineClearResult(
        boardState: boardState,
        clearedRows: 0,
        clearedColumns: 0,
        clearedCells: <BoardCell>{},
      );
    }

    final Set<BoardCell> clearedCells = boardState.occupiedCells
        .where(
          (BoardCell cell) =>
              fullRows.contains(cell.y) || fullColumns.contains(cell.x),
        )
        .toSet();

    final BoardState clearedBoard = boardState.removeCells(
      (BoardCell cell) =>
          fullRows.contains(cell.y) || fullColumns.contains(cell.x),
    );

    return LineClearResult(
      boardState: clearedBoard,
      clearedRows: fullRows.length,
      clearedColumns: fullColumns.length,
      clearedCells: clearedCells,
    );
  }
}
