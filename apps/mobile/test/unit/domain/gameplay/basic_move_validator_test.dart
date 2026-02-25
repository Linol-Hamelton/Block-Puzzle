import 'package:block_puzzle_mobile/domain/gameplay/basic_move_validator.dart';
import 'package:block_puzzle_mobile/domain/gameplay/board_state.dart';
import 'package:block_puzzle_mobile/domain/gameplay/move.dart';
import 'package:block_puzzle_mobile/domain/gameplay/piece.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BasicMoveValidator', () {
    const BasicMoveValidator validator = BasicMoveValidator();

    test('returns valid for legal placement', () {
      final BoardState board = BoardState.empty(size: 8);
      const Move move = Move(
        piece: Piece(
          id: 'single',
          cells: <PieceCellOffset>[PieceCellOffset(dx: 0, dy: 0)],
        ),
        anchorX: 3,
        anchorY: 4,
      );

      final result = validator.validate(boardState: board, move: move);

      expect(result.isValid, isTrue);
      expect(result.reason, isNull);
    });

    test('returns out_of_bounds for invalid placement', () {
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
        anchorY: 0,
      );

      final result = validator.validate(boardState: board, move: move);

      expect(result.isValid, isFalse);
      expect(result.reason, equals('out_of_bounds'));
    });

    test('returns cell_occupied when target cell is taken', () {
      final BoardState board = BoardState(
        size: 8,
        occupiedCells: <BoardCell>{
          const BoardCell(x: 1, y: 1),
        },
      );
      const Move move = Move(
        piece: Piece(
          id: 'single',
          cells: <PieceCellOffset>[PieceCellOffset(dx: 0, dy: 0)],
        ),
        anchorX: 1,
        anchorY: 1,
      );

      final result = validator.validate(boardState: board, move: move);

      expect(result.isValid, isFalse);
      expect(result.reason, equals('cell_occupied'));
    });
  });
}
