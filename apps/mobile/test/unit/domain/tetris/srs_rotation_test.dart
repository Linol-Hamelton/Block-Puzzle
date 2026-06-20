import 'package:block_puzzle_mobile/domain/tetris/falling_piece.dart';
import 'package:block_puzzle_mobile/domain/tetris/srs_rotation.dart';
import 'package:block_puzzle_mobile/domain/tetris/tetris_board.dart';
import 'package:block_puzzle_mobile/domain/tetris/tetromino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SrsRotation kick tables', () {
    test('O piece never kicks', () {
      expect(
        SrsRotation.kicksFor(TetrominoType.o, 0, 1),
        const <KickOffset>[KickOffset(0, 0)],
      );
    });

    test('180 turn has no kick (single identity test)', () {
      expect(
        SrsRotation.kicksFor(TetrominoType.t, 0, 2),
        const <KickOffset>[KickOffset(0, 0)],
      );
    });

    test('JLSTZ 0->R is converted from canonical y-up to board y-down', () {
      // Canonical (y-up): (0,0),(-1,0),(-1,+1),(0,-2),(-1,-2)
      // Board space (y-down) negates y.
      expect(
        SrsRotation.kicksFor(TetrominoType.t, 0, 1),
        const <KickOffset>[
          KickOffset(0, 0),
          KickOffset(-1, 0),
          KickOffset(-1, -1),
          KickOffset(0, 2),
          KickOffset(-1, 2),
        ],
      );
    });

    test('I 0->R is converted to board space', () {
      // Canonical (y-up): (0,0),(-2,0),(+1,0),(-2,-1),(+1,+2)
      expect(
        SrsRotation.kicksFor(TetrominoType.i, 0, 1),
        const <KickOffset>[
          KickOffset(0, 0),
          KickOffset(-2, 0),
          KickOffset(1, 0),
          KickOffset(-2, 1),
          KickOffset(1, -2),
        ],
      );
    });

    test('every JLSTZ single-step transition exposes 5 kick tests', () {
      const List<List<int>> transitions = <List<int>>[
        <int>[0, 1],
        <int>[1, 0],
        <int>[1, 2],
        <int>[2, 1],
        <int>[2, 3],
        <int>[3, 2],
        <int>[3, 0],
        <int>[0, 3],
      ];
      for (final List<int> tr in transitions) {
        expect(
          SrsRotation.kicksFor(TetrominoType.j, tr[0], tr[1]).length,
          5,
          reason: 'transition ${tr[0]}->${tr[1]}',
        );
      }
    });
  });

  group('rotation against geometry', () {
    test('T rotates freely in open space', () {
      final TetrisBoard board = TetrisBoard();
      const FallingPiece piece = FallingPiece(
        type: TetrominoType.t,
        rotationIndex: 0,
        originX: 3,
        originY: 4,
      );
      final FallingPiece rotated = piece.withRotation(1);
      expect(board.collides(rotated), isFalse);
      expect(rotated.absoluteCells().length, 4);
    });
  });
}
