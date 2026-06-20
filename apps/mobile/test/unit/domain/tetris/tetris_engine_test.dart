import 'package:block_puzzle_mobile/domain/tetris/tetris_board.dart';
import 'package:block_puzzle_mobile/domain/tetris/tetris_engine.dart';
import 'package:flutter_test/flutter_test.dart';

int filledCells(TetrisBoard board) {
  int count = 0;
  for (int y = 0; y < board.height; y++) {
    for (int x = 0; x < board.width; x++) {
      if (board.isFilled(x, y)) {
        count += 1;
      }
    }
  }
  return count;
}

void main() {
  group('TetrisEngine lifecycle', () {
    test('start spawns an active piece at level 1', () {
      final TetrisEngine engine = TetrisEngine(seed: 1);
      engine.start();
      expect(engine.active, isNotNull);
      expect(engine.level, 1);
      expect(engine.isGameOver, isFalse);
      expect(
        engine.drainEvents().map((TetrisEvent e) => e.type),
        contains(TetrisEventType.spawn),
      );
    });

    test('moveRight shifts the active piece one column', () {
      final TetrisEngine engine = TetrisEngine(seed: 1)..start();
      final int before = engine.active!.originX;
      engine.applyInput(TetrisInput.moveRight);
      expect(engine.active!.originX, before + 1);
    });

    test('rotateCw advances the rotation index in open space', () {
      final TetrisEngine engine = TetrisEngine(seed: 1)..start();
      engine.applyInput(TetrisInput.rotateCw);
      expect(engine.active!.rotationIndex, 1);
    });

    test('hard drop locks four cells and spawns the next piece', () {
      final TetrisEngine engine = TetrisEngine(seed: 1)..start();
      engine.drainEvents();
      engine.applyInput(TetrisInput.hardDrop);

      expect(filledCells(engine.board), 4);
      expect(engine.active, isNotNull);
      expect(engine.isGameOver, isFalse);
      final List<TetrisEventType> events =
          engine.drainEvents().map((TetrisEvent e) => e.type).toList();
      expect(events, containsAll(<TetrisEventType>[
        TetrisEventType.hardDrop,
        TetrisEventType.lock,
        TetrisEventType.spawn,
      ]));
    });

    test('ghost sits at or below the active piece', () {
      final TetrisEngine engine = TetrisEngine(seed: 1)..start();
      expect(engine.ghost, isNotNull);
      expect(
        engine.ghost!.originY,
        greaterThanOrEqualTo(engine.active!.originY),
      );
    });

    test('a tick does not throw and keeps the run going', () {
      final TetrisEngine engine = TetrisEngine(seed: 1)..start();
      engine.tick(const Duration(milliseconds: 16));
      expect(engine.isGameOver, isFalse);
    });

    test('snapshot round-trips engine state', () {
      final TetrisEngine engine = TetrisEngine(seed: 5)..start();
      engine.applyInput(TetrisInput.hardDrop); // lock one piece
      final Map<String, Object?> snap = engine.toSnapshot();

      final TetrisEngine restored = TetrisEngine(seed: 99)..restore(snap);
      expect(restored.score, engine.score);
      expect(restored.level, engine.level);
      expect(restored.linesCleared, engine.linesCleared);
      expect(restored.isStarted, isTrue);
      expect(restored.isGameOver, isFalse);
      expect(restored.active, isNotNull);
      expect(filledCells(restored.board), filledCells(engine.board));
    });
  });
}
