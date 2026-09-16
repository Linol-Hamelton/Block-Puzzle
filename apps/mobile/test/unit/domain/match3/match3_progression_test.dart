import 'package:block_puzzle_mobile/domain/match3/match3_progression.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shape of the round curve.
///
/// These are not tests of arithmetic for its own sake. The design claim is that
/// a run always ends: each round costs more than the last while the payout stays
/// flat, so the moves cannot outrun the targets. If that stops being true the
/// mode becomes endless by accident and the score stops meaning anything.
void main() {
  const Match3Progression progression = Match3Progression();

  group('targets', () {
    test('round one is the base target', () {
      expect(progression.targetForRound(1), progression.baseTarget);
    });

    test('each round costs more than the one before it', () {
      int previousCost = 0;
      for (int round = 1; round <= 40; round++) {
        final int cost = progression.targetForRound(round) -
            progression.floorForRound(round);
        expect(cost, greaterThan(previousCost),
            reason: 'round $round did not cost more than round ${round - 1}');
        previousCost = cost;
      }
    });

    test('the cost grows by exactly the configured step', () {
      for (int round = 2; round <= 20; round++) {
        final int cost = progression.targetForRound(round) -
            progression.targetForRound(round - 1);
        final int previous = progression.targetForRound(round - 1) -
            progression.floorForRound(round - 1);
        expect(cost - previous, progression.targetGrowth);
      }
    });

    test('a round below one is treated as round one', () {
      expect(progression.targetForRound(0), progression.targetForRound(1));
      expect(progression.targetForRound(-5), progression.targetForRound(1));
      expect(progression.floorForRound(1), 0);
      expect(progression.floorForRound(0), 0);
    });

    test('the payout cannot keep pace with the cost', () {
      // The termination argument, stated as a test. Beyond some round the cost
      // of one round exceeds anything the flat payout can fund, so no run is
      // endless however well it is played.
      const int generousScorePerMove = 600;
      int round = 1;
      while (round < 500) {
        final int cost = progression.targetForRound(round) -
            progression.floorForRound(round);
        if (cost > progression.movesPerRound * generousScorePerMove) {
          break;
        }
        round += 1;
      }
      expect(round, lessThan(500));
    });
  });

  group('reading a round back from a score', () {
    test('a fresh run is round one', () {
      expect(progression.roundForScore(0), 1);
      expect(progression.roundForScore(progression.baseTarget - 1), 1);
    });

    test('exactly on the target completes that round', () {
      expect(progression.roundForScore(progression.targetForRound(1)), 2);
      expect(progression.roundForScore(progression.targetForRound(3)), 4);
    });

    test('a score between targets names the round in progress', () {
      final int between =
          progression.targetForRound(2) + progression.targetGrowth;
      expect(progression.roundForScore(between), 3);
    });

    test('a nonsense score still terminates', () {
      expect(progression.roundForScore(-1), 1);
      expect(progression.roundForScore(1 << 40), greaterThan(1));
    });
  });

  group('progress within a round', () {
    test('runs from zero at the floor to one at the target', () {
      expect(progression.progressInRound(0, 1), 0);
      expect(progression.progressInRound(progression.targetForRound(1), 1), 1);
      expect(
        progression.progressInRound(progression.baseTarget ~/ 2, 1),
        closeTo(0.5, 0.01),
      );
    });

    test('is measured from the round floor, not from zero', () {
      final int floor = progression.floorForRound(3);
      final int span = progression.targetForRound(3) - floor;
      expect(progression.progressInRound(floor, 3), 0);
      expect(
        progression.progressInRound(floor + (span ~/ 2), 3),
        closeTo(0.5, 0.01),
      );
    });

    test('clamps rather than overflowing the bar', () {
      expect(progression.progressInRound(-100, 1), 0);
      expect(progression.progressInRound(1 << 30, 1), 1);
    });
  });
}
