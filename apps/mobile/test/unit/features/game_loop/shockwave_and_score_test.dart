import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/domain/gameplay/board_state.dart';
import 'package:block_puzzle_mobile/features/game_loop/presentation/block_puzzle_game.dart';

void main() {
  group('computeClearedCentroid', () {
    final Vector2 origin = Vector2(50, 100);
    const double cellSize = 40.0;

    test('empty cells returns board origin', () {
      final Vector2 c = computeClearedCentroid(
        cells: <BoardCell>{},
        boardOrigin: origin,
        cellSize: cellSize,
      );
      expect(c.x, origin.x);
      expect(c.y, origin.y);
    });

    test('single cell centroid is cell center', () {
      final Vector2 c = computeClearedCentroid(
        cells: <BoardCell>{const BoardCell(x: 2, y: 5)},
        boardOrigin: origin,
        cellSize: cellSize,
      );
      expect(c.x, origin.x + (2.5 * cellSize));
      expect(c.y, origin.y + (5.5 * cellSize));
    });

    test('horizontal line centroid is horizontal midpoint', () {
      final Set<BoardCell> row = <BoardCell>{
        for (int x = 0; x < 8; x++) BoardCell(x: x, y: 3),
      };
      final Vector2 c = computeClearedCentroid(
        cells: row,
        boardOrigin: origin,
        cellSize: cellSize,
      );
      // sum(0..7) = 28, / 8 = 3.5; + 0.5 = 4.0
      expect(c.x, origin.x + (4.0 * cellSize));
      expect(c.y, origin.y + (3.5 * cellSize));
    });

    test('vertical line centroid is vertical midpoint', () {
      final Set<BoardCell> col = <BoardCell>{
        for (int y = 0; y < 8; y++) BoardCell(x: 4, y: y),
      };
      final Vector2 c = computeClearedCentroid(
        cells: col,
        boardOrigin: origin,
        cellSize: cellSize,
      );
      expect(c.x, origin.x + (4.5 * cellSize));
      expect(c.y, origin.y + (4.0 * cellSize));
    });

    test('intersecting lines centroid matches arithmetic mean', () {
      final Set<BoardCell> cross = <BoardCell>{
        for (int x = 0; x < 8; x++) BoardCell(x: x, y: 0),
        for (int y = 1; y < 8; y++) BoardCell(x: 0, y: y),
      };
      final Vector2 c = computeClearedCentroid(
        cells: cross,
        boardOrigin: origin,
        cellSize: cellSize,
      );
      const double avgX = (28 + 0) / 15.0;
      const double avgY = (0 + 28) / 15.0;
      expect(c.x, closeTo(origin.x + ((avgX + 0.5) * cellSize), 1e-4));
      expect(c.y, closeTo(origin.y + ((avgY + 0.5) * cellSize), 1e-4));
    });
  });

  group('ShockwaveRingComponent lifecycle', () {
    test('completes animation after duration without leaking', () {
      final ShockwaveRingComponent ring = ShockwaveRingComponent(
        center: Vector2(100, 100),
        boardRect: const Rect.fromLTWH(0, 0, 300, 300),
        duration: 0.8,
      );
      ring.update(0.4);
      expect(ring.isFinished, isFalse);

      // Advance past duration (0.4 + 0.45 = 0.85 >= 0.8)
      ring.update(0.45);
      expect(ring.isFinished, isTrue);
    });
  });

  group('ScorePopComponent lifecycle and slot independence', () {
    test('completes animation after duration without leaking', () {
      final ScorePopComponent pop = ScorePopComponent(
        text: '+40',
        startPosition: Vector2(100, 100),
        duration: 0.8,
      );
      pop.update(0.4);
      expect(pop.isFinished, isFalse);

      // Advance past duration (0.4 + 0.45 = 0.85 >= 0.8)
      pop.update(0.45);
      expect(pop.isFinished, isTrue);
    });

    test('ScorePopComponent is independent from ComboPulseComponent', () {
      final ScorePopComponent scorePop = ScorePopComponent(
        text: '+100',
        startPosition: Vector2(150, 200),
      );
      final ComboPulseComponent comboPulse = ComboPulseComponent(
        text: 'Combo x2',
        startPosition: Vector2(100, 50),
      );
      expect(scorePop.text, '+100');
      expect(comboPulse.text, 'Combo x2');
      expect(scorePop.priority, isNot(equals(comboPulse.priority)));
    });

    test('ScorePopComponent renders cleanly without throwing across animation phases', () {
      final ScorePopComponent scorePop = ScorePopComponent(
        text: '+250',
        startPosition: Vector2(120, 180),
        duration: 0.85,
      );
      final PictureRecorder recorder = PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Render at t=0
      scorePop.render(canvas);

      // Render at mid-point (overshoot peak)
      scorePop.update(0.425);
      scorePop.render(canvas);

      // Render near completion (fade out)
      scorePop.update(0.35);
      scorePop.render(canvas);

      final Picture picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });
  });
}
