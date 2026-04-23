import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/domain/gameplay/board_state.dart';

void main() {
  group('BoardState', () {
    test('empty board has no occupied cells', () {
      final board = BoardState.empty();

      expect(board.occupiedCells, isEmpty);
      expect(board.size, 8);
    });

    test('empty factory accepts custom size', () {
      final board = BoardState.empty(size: 10);

      expect(board.size, 10);
      expect(board.occupiedCells, isEmpty);
    });

    test('isInBounds returns true for valid cells', () {
      final board = BoardState.empty(size: 8);

      expect(board.isInBounds(const BoardCell(x: 0, y: 0)), isTrue);
      expect(board.isInBounds(const BoardCell(x: 7, y: 7)), isTrue);
      expect(board.isInBounds(const BoardCell(x: 3, y: 5)), isTrue);
    });

    test('isInBounds returns false for out-of-range cells', () {
      final board = BoardState.empty(size: 8);

      expect(board.isInBounds(const BoardCell(x: -1, y: 0)), isFalse);
      expect(board.isInBounds(const BoardCell(x: 0, y: -1)), isFalse);
      expect(board.isInBounds(const BoardCell(x: 8, y: 0)), isFalse);
      expect(board.isInBounds(const BoardCell(x: 0, y: 8)), isFalse);
      expect(board.isInBounds(const BoardCell(x: 100, y: 100)), isFalse);
    });

    test('placeCells adds cells to the board', () {
      final board = BoardState.empty();
      final updated = board.placeCells(const <BoardCell>[
        BoardCell(x: 0, y: 0),
        BoardCell(x: 1, y: 0),
      ]);

      expect(updated.occupiedCells.length, 2);
      expect(updated.isOccupied(const BoardCell(x: 0, y: 0)), isTrue);
      expect(updated.isOccupied(const BoardCell(x: 1, y: 0)), isTrue);
      expect(updated.isOccupied(const BoardCell(x: 2, y: 0)), isFalse);
    });

    test('placeCells does not mutate original board', () {
      final original = BoardState.empty();
      original.placeCells(const <BoardCell>[BoardCell(x: 0, y: 0)]);

      expect(original.occupiedCells, isEmpty,
          reason: 'Original board should remain immutable');
    });

    test('removeCells removes matching cells', () {
      final board = BoardState(
        size: 8,
        occupiedCells: const <BoardCell>{
          BoardCell(x: 0, y: 0),
          BoardCell(x: 1, y: 0),
          BoardCell(x: 2, y: 0),
        },
      );

      final updated = board.removeCells(
          (BoardCell cell) => cell.x == 1 && cell.y == 0);

      expect(updated.occupiedCells.length, 2);
      expect(updated.isOccupied(const BoardCell(x: 0, y: 0)), isTrue);
      expect(updated.isOccupied(const BoardCell(x: 1, y: 0)), isFalse);
      expect(updated.isOccupied(const BoardCell(x: 2, y: 0)), isTrue);
    });

    test('removeCells with no matches returns same cell set', () {
      final board = BoardState(
        size: 8,
        occupiedCells: const <BoardCell>{BoardCell(x: 5, y: 5)},
      );

      final updated = board.removeCells((_) => false);

      expect(updated.occupiedCells.length, 1);
      expect(updated.isOccupied(const BoardCell(x: 5, y: 5)), isTrue);
    });

    test('duplicate cells are deduplicated', () {
      final board = BoardState.empty().placeCells(const <BoardCell>[
        BoardCell(x: 0, y: 0),
        BoardCell(x: 0, y: 0),
        BoardCell(x: 0, y: 0),
      ]);

      expect(board.occupiedCells.length, 1);
    });
  });

  group('BoardCell equality', () {
    test('cells with same coordinates are equal', () {
      const a = BoardCell(x: 3, y: 5);
      const b = BoardCell(x: 3, y: 5);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('cells with different coordinates are not equal', () {
      const a = BoardCell(x: 3, y: 5);
      const b = BoardCell(x: 5, y: 3);

      expect(a, isNot(equals(b)));
    });

    test('cells work correctly in Sets', () {
      final set = <BoardCell>{
        const BoardCell(x: 0, y: 0),
        const BoardCell(x: 0, y: 0),
        const BoardCell(x: 1, y: 0),
      };

      expect(set.length, 2);
    });
  });
}
