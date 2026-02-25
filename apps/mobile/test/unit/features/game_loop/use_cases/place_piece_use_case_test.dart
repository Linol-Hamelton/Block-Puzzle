import 'package:block_puzzle_mobile/domain/gameplay/basic_move_validator.dart';
import 'package:block_puzzle_mobile/domain/gameplay/board_state.dart';
import 'package:block_puzzle_mobile/domain/gameplay/move.dart';
import 'package:block_puzzle_mobile/domain/gameplay/piece.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/place_piece_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlacePieceUseCase', () {
    const PlacePieceUseCase useCase = PlacePieceUseCase(
      moveValidator: BasicMoveValidator(),
    );

    test('returns success and adds cells to board', () {
      final BoardState board = BoardState.empty(size: 8);
      const Move move = Move(
        piece: Piece(
          id: 'l2',
          cells: <PieceCellOffset>[
            PieceCellOffset(dx: 0, dy: 0),
            PieceCellOffset(dx: 1, dy: 0),
          ],
        ),
        anchorX: 2,
        anchorY: 3,
      );

      final result = useCase.execute(boardState: board, move: move);

      expect(result.isSuccess, isTrue);
      expect(result.placedCellCount, 2);
      expect(result.boardState.occupiedCells,
          contains(const BoardCell(x: 2, y: 3)));
      expect(result.boardState.occupiedCells,
          contains(const BoardCell(x: 3, y: 3)));
    });

    test('returns failure for invalid placement and keeps board', () {
      final BoardState board = BoardState.empty(size: 8);
      const Move move = Move(
        piece: Piece(
          id: 'horizontal_2',
          cells: <PieceCellOffset>[
            PieceCellOffset(dx: 0, dy: 0),
            PieceCellOffset(dx: 1, dy: 0),
          ],
        ),
        anchorX: 7,
        anchorY: 3,
      );

      final result = useCase.execute(boardState: board, move: move);

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, equals('out_of_bounds'));
      expect(result.boardState.occupiedCells, isEmpty);
    });
  });
}
