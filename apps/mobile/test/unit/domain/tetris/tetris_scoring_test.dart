import 'package:block_puzzle_mobile/domain/tetris/tetris_scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TetrisScoring line clears', () {
    test('guideline base scores at level 1', () {
      expect(TetrisScoring.lineClearScore(clearedRows: 1, level: 1), 100);
      expect(TetrisScoring.lineClearScore(clearedRows: 2, level: 1), 300);
      expect(TetrisScoring.lineClearScore(clearedRows: 3, level: 1), 500);
      expect(TetrisScoring.lineClearScore(clearedRows: 4, level: 1), 800);
    });

    test('scales with level', () {
      expect(TetrisScoring.lineClearScore(clearedRows: 4, level: 3), 2400);
    });

    test('back-to-back applies only to a Tetris', () {
      expect(
        TetrisScoring.lineClearScore(
            clearedRows: 4, level: 1, backToBack: true),
        1200,
      );
      // A single is not "difficult", so back-to-back does not multiply it.
      expect(
        TetrisScoring.lineClearScore(
            clearedRows: 1, level: 1, backToBack: true),
        100,
      );
    });
  });

  group('TetrisScoring drops & combo', () {
    test('soft and hard drop points', () {
      expect(TetrisScoring.softDropScore(5), 5);
      expect(TetrisScoring.hardDropScore(5), 10);
      expect(TetrisScoring.hardDropScore(-1), 0);
    });

    test('combo bonus', () {
      expect(TetrisScoring.comboScore(combo: 0, level: 1), 0);
      expect(TetrisScoring.comboScore(combo: 3, level: 2), 300);
    });
  });

  group('TetrisScoring level & gravity curve', () {
    test('level rises every 10 lines, starting at 1', () {
      expect(TetrisScoring.levelForLines(0), 1);
      expect(TetrisScoring.levelForLines(9), 1);
      expect(TetrisScoring.levelForLines(10), 2);
      expect(TetrisScoring.levelForLines(25), 3);
    });

    test('gravity is 1000ms at level 1 and strictly faster as level rises', () {
      expect(TetrisScoring.gravityInterval(1).inMilliseconds, 1000);
      expect(
        TetrisScoring.gravityInterval(2).inMilliseconds <
            TetrisScoring.gravityInterval(1).inMilliseconds,
        isTrue,
      );
      expect(
        TetrisScoring.gravityInterval(10).inMilliseconds <
            TetrisScoring.gravityInterval(5).inMilliseconds,
        isTrue,
      );
      // Always clamped to a renderable floor.
      expect(TetrisScoring.gravityInterval(20).inMilliseconds, greaterThanOrEqualTo(1));
    });
  });

  group('TetrisScoring T-spins', () {
    test('full T-spin base scores at level 1', () {
      expect(
          TetrisScoring.actionScore(rows: 0, level: 1, spin: TSpinType.full),
          400);
      expect(
          TetrisScoring.actionScore(rows: 1, level: 1, spin: TSpinType.full),
          800);
      expect(
          TetrisScoring.actionScore(rows: 2, level: 1, spin: TSpinType.full),
          1200);
      expect(
          TetrisScoring.actionScore(rows: 3, level: 1, spin: TSpinType.full),
          1600);
    });

    test('mini T-spin base scores at level 1', () {
      expect(
          TetrisScoring.actionScore(rows: 0, level: 1, spin: TSpinType.mini),
          100);
      expect(
          TetrisScoring.actionScore(rows: 1, level: 1, spin: TSpinType.mini),
          200);
    });

    test('T-spin scales with level and back-to-back', () {
      expect(
          TetrisScoring.actionScore(rows: 1, level: 2, spin: TSpinType.full),
          1600);
      expect(
          TetrisScoring.actionScore(
              rows: 1, level: 1, spin: TSpinType.full, backToBack: true),
          1200);
    });

    test('difficulty: a Tetris and line-clearing T-spins are difficult', () {
      expect(TetrisScoring.isDifficult(rows: 4), isTrue);
      expect(TetrisScoring.isDifficult(rows: 1), isFalse);
      expect(TetrisScoring.isDifficult(rows: 1, spin: TSpinType.full), isTrue);
      expect(TetrisScoring.isDifficult(rows: 0, spin: TSpinType.full), isFalse);
    });
  });
}
