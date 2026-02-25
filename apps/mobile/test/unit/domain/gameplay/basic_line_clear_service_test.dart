import 'package:block_puzzle_mobile/domain/gameplay/basic_line_clear_service.dart';
import 'package:block_puzzle_mobile/domain/gameplay/board_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BasicLineClearService', () {
    const BasicLineClearService service = BasicLineClearService();

    test('clears a full row', () {
      final BoardState board = BoardState(
        size: 4,
        occupiedCells: <BoardCell>{
          const BoardCell(x: 0, y: 0),
          const BoardCell(x: 1, y: 0),
          const BoardCell(x: 2, y: 0),
          const BoardCell(x: 3, y: 0),
          const BoardCell(x: 2, y: 2),
        },
      );

      final result = service.apply(boardState: board);

      expect(result.clearedRows, 1);
      expect(result.clearedColumns, 0);
      expect(result.clearedCells.length, 4);
      expect(result.clearedCells, contains(const BoardCell(x: 3, y: 0)));
      expect(result.boardState.occupiedCells,
          contains(const BoardCell(x: 2, y: 2)));
      expect(result.boardState.occupiedCells.length, 1);
    });

    test('clears full row and full column simultaneously', () {
      final BoardState board = BoardState(
        size: 3,
        occupiedCells: <BoardCell>{
          const BoardCell(x: 0, y: 1),
          const BoardCell(x: 1, y: 1),
          const BoardCell(x: 2, y: 1),
          const BoardCell(x: 2, y: 0),
          const BoardCell(x: 2, y: 2),
          const BoardCell(x: 0, y: 0),
        },
      );

      final result = service.apply(boardState: board);

      expect(result.clearedRows, 1);
      expect(result.clearedColumns, 1);
      expect(result.clearedTotal, 2);
      expect(result.clearedCells.length, 5);
      expect(result.boardState.occupiedCells,
          equals(<BoardCell>{const BoardCell(x: 0, y: 0)}));
    });
  });
}
