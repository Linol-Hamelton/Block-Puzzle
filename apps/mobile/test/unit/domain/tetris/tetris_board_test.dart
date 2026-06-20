import 'package:block_puzzle_mobile/domain/tetris/falling_piece.dart';
import 'package:block_puzzle_mobile/domain/tetris/tetris_board.dart';
import 'package:block_puzzle_mobile/domain/tetris/tetromino.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a board with explicit cell content for deterministic tests.
TetrisBoard boardWith(
  int width,
  int height,
  void Function(List<TetrominoType?> cells, int Function(int, int) idx) fill,
) {
  final List<TetrominoType?> cells =
      List<TetrominoType?>.filled(width * height, null);
  int idx(int x, int y) => (y * width) + x;
  fill(cells, idx);
  return TetrisBoard(width: width, height: height, cells: cells);
}

void main() {
  group('TetrisBoard bounds & collision', () {
    test('walls and floor collide; above-top does not', () {
      final TetrisBoard board = TetrisBoard(width: 10, height: 20);
      // Off the left wall.
      expect(
        board.collides(const FallingPiece(
          type: TetrominoType.o,
          rotationIndex: 0,
          originX: -1,
          originY: 0,
        )),
        isTrue,
      );
      // Below the floor.
      expect(
        board.collides(const FallingPiece(
          type: TetrominoType.o,
          rotationIndex: 0,
          originX: 0,
          originY: 20,
        )),
        isTrue,
      );
      // Partly above the top (negative y) is allowed.
      expect(
        board.collides(const FallingPiece(
          type: TetrominoType.o,
          rotationIndex: 0,
          originX: 4,
          originY: -1,
        )),
        isFalse,
      );
    });
  });

  group('line clear + gravity collapse', () {
    test('clears a single full row and leaves the field empty', () {
      final TetrisBoard board = boardWith(10, 20, (cells, idx) {
        for (int x = 0; x < 10; x++) {
          cells[idx(x, 19)] = TetrominoType.i;
        }
      });
      final LineClearOutcome outcome = board.clearFullRows();
      expect(outcome.clearedRows, 1);
      for (int x = 0; x < 10; x++) {
        expect(outcome.board.isFilled(x, 19), isFalse);
      }
    });

    test('collapses a floating block down onto the cleared row', () {
      final TetrisBoard board = boardWith(10, 20, (cells, idx) {
        for (int x = 0; x < 10; x++) {
          cells[idx(x, 19)] = TetrominoType.i; // full bottom row
        }
        cells[idx(0, 18)] = TetrominoType.t; // a single floating block above
      });
      final LineClearOutcome outcome = board.clearFullRows();
      expect(outcome.clearedRows, 1);
      // The floating block falls to the bottom.
      expect(outcome.board.cellAt(0, 19), TetrominoType.t);
      expect(outcome.board.isFilled(1, 19), isFalse);
    });

    test('clears two full rows at once', () {
      final TetrisBoard board = boardWith(10, 20, (cells, idx) {
        for (int x = 0; x < 10; x++) {
          cells[idx(x, 18)] = TetrominoType.z;
          cells[idx(x, 19)] = TetrominoType.z;
        }
      });
      final LineClearOutcome outcome = board.clearFullRows();
      expect(outcome.clearedRows, 2);
      for (int y = 0; y < 20; y++) {
        for (int x = 0; x < 10; x++) {
          expect(outcome.board.isFilled(x, y), isFalse);
        }
      }
    });

    test('no clear when no row is full', () {
      final TetrisBoard board = boardWith(10, 20, (cells, idx) {
        for (int x = 0; x < 9; x++) {
          cells[idx(x, 19)] = TetrominoType.l; // one short of full
        }
      });
      final LineClearOutcome outcome = board.clearFullRows();
      expect(outcome.clearedRows, 0);
    });
  });

  group('dropDistance', () {
    test('an empty column drops to the floor', () {
      final TetrisBoard board = TetrisBoard(width: 10, height: 20);
      const FallingPiece piece = FallingPiece(
        type: TetrominoType.o,
        rotationIndex: 0,
        originX: 4,
        originY: 0,
      );
      // O occupies rows 0..1; bottom cells at y=1; floor at y=19 → drop 18.
      expect(board.dropDistance(piece), 18);
    });
  });

  group('serialization', () {
    test('round-trips through JSON', () {
      final TetrisBoard board = boardWith(10, 20, (cells, idx) {
        cells[idx(3, 19)] = TetrominoType.s;
      });
      final TetrisBoard restored = TetrisBoard.fromJson(board.toJson());
      expect(restored.cellAt(3, 19), TetrominoType.s);
      expect(restored.width, 10);
      expect(restored.height, 20);
    });
  });
}
