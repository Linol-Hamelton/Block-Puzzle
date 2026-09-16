import 'package:block_puzzle_mobile/domain/tetris/falling_piece.dart';
import 'package:block_puzzle_mobile/domain/tetris/tetris_board.dart';
import 'package:block_puzzle_mobile/domain/tetris/tetris_engine.dart';
import 'package:block_puzzle_mobile/domain/tetris/tetromino.dart';
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

    test('line clear runs a delayed clearing phase (highlight -> collapse)', () {
      // 4-wide board, bottom row filled except column 0; a vertical I at
      // column 0 hard-drops to complete and clear the row.
      final List<TetrominoType?> cells =
          List<TetrominoType?>.filled(4 * 8, null);
      int idx(int x, int y) => (y * 4) + x;
      cells[idx(1, 7)] = TetrominoType.l;
      cells[idx(2, 7)] = TetrominoType.l;
      cells[idx(3, 7)] = TetrominoType.l;
      final TetrisBoard board =
          TetrisBoard(width: 4, height: 8, cells: cells);

      final TetrisEngine engine = TetrisEngine(width: 4, height: 8)
        ..restore(<String, Object?>{
          'board': board.toJson(),
          'active': const FallingPiece(
            type: TetrominoType.i,
            rotationIndex: 1,
            originX: -2,
            originY: 0,
          ).toJson(),
        });
      engine.drainEvents();

      engine.applyInput(TetrisInput.hardDrop);
      // Row is detected + scored, but held visible (not collapsed yet).
      expect(engine.isClearing, isTrue);
      expect(engine.clearingRows, contains(7));
      expect(engine.score, greaterThanOrEqualTo(100));
      final List<TetrisEventType> events =
          engine.drainEvents().map((TetrisEvent e) => e.type).toList();
      expect(events, contains(TetrisEventType.lineClear));

      // After the clear delay it collapses and a new piece spawns. The delay
      // is deliberately long enough to be seen - see lineClearDelay - so this
      // ticks well past it rather than encoding the exact number.
      engine.tick(const Duration(seconds: 1));
      expect(engine.isClearing, isFalse);
      expect(engine.active, isNotNull);
      expect(engine.linesCleared, 1);
    });

    test('a four-row clear is held longer than a single', () {
      // The rule, not the numbers: the rarest and most valuable clear in the
      // game must not go by in the same blink as the commonest one. A single
      // and a Tetris used to run for exactly the same 120ms.
      TetrisEngine engineWith(List<int> filledRows, TetrominoType spawn) {
        final List<TetrominoType?> cells =
            List<TetrominoType?>.filled(4 * 8, null);
        int idx(int x, int y) => (y * 4) + x;
        for (final int row in filledRows) {
          for (int x = 1; x < 4; x++) {
            cells[idx(x, row)] = TetrominoType.l;
          }
        }
        return TetrisEngine(width: 4, height: 8)
          ..restore(<String, Object?>{
            'board': TetrisBoard(width: 4, height: 8, cells: cells).toJson(),
            'active': FallingPiece(
              type: spawn,
              rotationIndex: 1,
              originX: -2,
              originY: 0,
            ).toJson(),
          });
      }

      // A vertical I in column 0 completes one row, or four at once.
      final TetrisEngine single = engineWith(<int>[7], TetrominoType.i)
        ..applyInput(TetrisInput.hardDrop);
      final TetrisEngine tetris =
          engineWith(<int>[4, 5, 6, 7], TetrominoType.i)
            ..applyInput(TetrisInput.hardDrop);

      expect(single.clearingRowCount, 1);
      expect(tetris.clearingRowCount, 4);

      // Tick both by the same amount: the single is done, the Tetris is not.
      single.tick(const Duration(milliseconds: 400));
      tetris.tick(const Duration(milliseconds: 400));
      expect(single.isClearing, isFalse);
      expect(tetris.isClearing, isTrue,
          reason: 'a Tetris holds longer than a single');

      tetris.tick(const Duration(seconds: 1));
      expect(tetris.isClearing, isFalse);
    });

    test('flushPendingClear collapses a pending clear immediately', () {
      // Same setup as the clearing test; flush instead of waiting the delay
      // (this is what saveActiveGame does so a mid-clear snapshot is committed).
      final List<TetrominoType?> cells =
          List<TetrominoType?>.filled(4 * 8, null);
      int idx(int x, int y) => (y * 4) + x;
      cells[idx(1, 7)] = TetrominoType.l;
      cells[idx(2, 7)] = TetrominoType.l;
      cells[idx(3, 7)] = TetrominoType.l;
      final TetrisEngine engine = TetrisEngine(width: 4, height: 8)
        ..restore(<String, Object?>{
          'board': TetrisBoard(width: 4, height: 8, cells: cells).toJson(),
          'active': const FallingPiece(
            type: TetrominoType.i,
            rotationIndex: 1,
            originX: -2,
            originY: 0,
          ).toJson(),
        });

      engine.applyInput(TetrisInput.hardDrop);
      expect(engine.isClearing, isTrue);

      engine.flushPendingClear();
      expect(engine.isClearing, isFalse);
      expect(engine.active, isNotNull);
      expect(engine.linesCleared, 1);
    });

    test('perfect clear (all-clear) emits a bonus event', () {
      // Empty 4-wide board; a horizontal I hard-drops to fill + clear the only
      // occupied row, emptying the board → Perfect Clear.
      final TetrisEngine engine = TetrisEngine(width: 4, height: 8)
        ..restore(<String, Object?>{
          'board': TetrisBoard(width: 4, height: 8).toJson(),
          'active': const FallingPiece(
            type: TetrominoType.i,
            rotationIndex: 0,
            originX: 0,
            originY: 0,
          ).toJson(),
        });

      engine.applyInput(TetrisInput.hardDrop);
      engine.tick(const Duration(seconds: 1));

      final List<TetrisEventType> events =
          engine.drainEvents().map((TetrisEvent e) => e.type).toList();
      expect(events, contains(TetrisEventType.perfectClear));
      expect(engine.board.isEmpty, isTrue);
    });

    test('revive clears the top and resumes after game over', () {
      // A completely full board blocks out the spawn → game over.
      final List<TetrominoType?> cells =
          List<TetrominoType?>.filled(4 * 8, TetrominoType.l);
      final TetrisBoard board =
          TetrisBoard(width: 4, height: 8, cells: cells);
      final TetrisEngine engine = TetrisEngine(width: 4, height: 8)
        ..restore(<String, Object?>{'board': board.toJson()});
      expect(engine.isGameOver, isTrue);

      final bool ok = engine.reviveClearTop(rows: 6);
      expect(ok, isTrue);
      expect(engine.isGameOver, isFalse);
      expect(engine.active, isNotNull);
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

    test('perfect clear is awarded on the zero-delay (instant) path', () {
      // With no clear animation delay the lock collapses immediately; the
      // all-clear bonus must still fire (regression for the fast-path bypass).
      final TetrisEngine engine =
          TetrisEngine(width: 4, height: 8, lineClearDelay: Duration.zero)
            ..restore(<String, Object?>{
              'board': TetrisBoard(width: 4, height: 8).toJson(),
              'active': const FallingPiece(
                type: TetrominoType.i,
                rotationIndex: 0,
                originX: 0,
                originY: 0,
              ).toJson(),
            });
      engine.drainEvents();

      engine.applyInput(TetrisInput.hardDrop); // no tick — collapses instantly

      expect(engine.isClearing, isFalse);
      expect(engine.board.isEmpty, isTrue);
      expect(
        engine.drainEvents().map((TetrisEvent e) => e.type),
        contains(TetrisEventType.perfectClear),
      );
    });

    test('rotating a T into a 3-corner slot is detected as a T-spin', () {
      // 4×6 board with a T-slot: side blocks at (0,5)/(2,5) and an overhang at
      // (0,3); a vertical T rotated CW drops its nub into the hole at (1,5).
      final List<TetrominoType?> cells =
          List<TetrominoType?>.filled(4 * 6, null);
      int idx(int x, int y) => (y * 4) + x;
      cells[idx(0, 3)] = TetrominoType.l;
      cells[idx(0, 5)] = TetrominoType.l;
      cells[idx(2, 5)] = TetrominoType.l;

      final TetrisEngine engine = TetrisEngine(
        width: 4,
        height: 6,
        lockDelay: const Duration(milliseconds: 50),
        lineClearDelay: Duration.zero,
      )..restore(<String, Object?>{
          'board': TetrisBoard(width: 4, height: 6, cells: cells).toJson(),
          'active': const FallingPiece(
            type: TetrominoType.t,
            rotationIndex: 1,
            originX: 0,
            originY: 3,
          ).toJson(),
        });
      engine.drainEvents();

      engine.applyInput(TetrisInput.rotateCw); // rotation is the last action
      engine.tick(const Duration(milliseconds: 60)); // lock-delay expires

      expect(
        engine.drainEvents().map((TetrisEvent e) => e.type),
        contains(TetrisEventType.tSpin),
      );
    });

    test('combo increments and emits on a second consecutive clear', () {
      // Restore mid-combo (_combo already 0); the next clear takes it to 1 and
      // must emit a combo event.
      final List<TetrominoType?> cells =
          List<TetrominoType?>.filled(4 * 8, null);
      int idx(int x, int y) => (y * 4) + x;
      cells[idx(1, 7)] = TetrominoType.l;
      cells[idx(2, 7)] = TetrominoType.l;
      cells[idx(3, 7)] = TetrominoType.l;

      final TetrisEngine engine = TetrisEngine(width: 4, height: 8)
        ..restore(<String, Object?>{
          'board': TetrisBoard(width: 4, height: 8, cells: cells).toJson(),
          'active': const FallingPiece(
            type: TetrominoType.i,
            rotationIndex: 1,
            originX: -2,
            originY: 0,
          ).toJson(),
          'combo': 0,
        });
      engine.drainEvents();

      engine.applyInput(TetrisInput.hardDrop);

      expect(
        engine.drainEvents().map((TetrisEvent e) => e.type),
        contains(TetrisEventType.combo),
      );
    });

    test('restore re-spawns when the snapshot active piece collides', () {
      // Bottom half full, top empty; the snapshot resumes into an O that
      // overlaps the stack. Restore must drop it and spawn a fresh piece rather
      // than resuming inside a collision.
      final List<TetrominoType?> cells =
          List<TetrominoType?>.filled(4 * 8, null);
      for (int y = 4; y < 8; y++) {
        for (int x = 0; x < 4; x++) {
          cells[(y * 4) + x] = TetrominoType.l;
        }
      }
      final TetrisEngine engine = TetrisEngine(width: 4, height: 8)
        ..restore(<String, Object?>{
          'board': TetrisBoard(width: 4, height: 8, cells: cells).toJson(),
          'active': const FallingPiece(
            type: TetrominoType.o,
            rotationIndex: 0,
            originX: 0,
            originY: 6, // overlaps the filled bottom rows
          ).toJson(),
        });

      expect(engine.isGameOver, isFalse);
      expect(engine.active, isNotNull);
      // Spawned cleanly at the top, not resumed inside the stack.
      expect(engine.active!.originY, lessThan(4));
    });
  });
}
