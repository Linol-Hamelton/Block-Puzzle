import 'package:block_puzzle_mobile/domain/gameplay/basic_line_clear_service.dart';
import 'package:block_puzzle_mobile/domain/gameplay/board_state.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/clear_lines_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClearLinesUseCase', () {
    const ClearLinesUseCase useCase = ClearLinesUseCase(
      lineClearService: BasicLineClearService(),
    );

    test('clears full lines and returns cleared count', () {
      final BoardState board = BoardState(
        size: 3,
        occupiedCells: <BoardCell>{
          const BoardCell(x: 0, y: 1),
          const BoardCell(x: 1, y: 1),
          const BoardCell(x: 2, y: 1),
          const BoardCell(x: 0, y: 0),
        },
      );

      final result = useCase.execute(boardState: board);

      expect(result.clearedRows, 1);
      expect(result.clearedColumns, 0);
      expect(result.boardState.occupiedCells,
          equals(<BoardCell>{const BoardCell(x: 0, y: 0)}));
    });
  });
}
