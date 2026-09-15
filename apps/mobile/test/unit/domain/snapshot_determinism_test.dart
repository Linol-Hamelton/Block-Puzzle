import 'package:block_puzzle_mobile/domain/match3/match3_engine.dart';
import 'package:block_puzzle_mobile/domain/match3/tile.dart';
import 'package:block_puzzle_mobile/domain/shared/deterministic_random.dart';
import 'package:block_puzzle_mobile/domain/tetris/seven_bag_randomizer.dart';
import 'package:block_puzzle_mobile/domain/tetris/tetris_engine.dart';
import 'package:block_puzzle_mobile/domain/tetris/tetromino.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reproduces the defect the Codex audit found (F6): a run restored from its
/// snapshot did not continue the same game.
///
/// The snapshots carried the board but not the generator feeding it, so the
/// piece queue and the cascade refills restarted from a fresh sequence. A
/// player who backgrounded the app came back to a different game, and two
/// players sharing a daily seed diverged the moment one of them resumed.
void main() {
  group('DeterministicRandom', () {
    test('the same state produces the same sequence', () {
      final DeterministicRandom a = DeterministicRandom(42);
      final List<int> first = List<int>.generate(20, (_) => a.nextInt(1000));

      final DeterministicRandom b = DeterministicRandom(42);
      final List<int> second = List<int>.generate(20, (_) => b.nextInt(1000));

      expect(second, first);
    });

    test('a captured state resumes mid-sequence exactly', () {
      final DeterministicRandom source = DeterministicRandom(7);
      for (int i = 0; i < 13; i++) {
        source.nextInt(100);
      }
      final int captured = source.state;
      final List<int> expected =
          List<int>.generate(10, (_) => source.nextInt(100));

      final DeterministicRandom resumed =
          DeterministicRandom.fromState(captured);
      final List<int> actual =
          List<int>.generate(10, (_) => resumed.nextInt(100));

      expect(actual, expected);
    });

    test('different seeds diverge', () {
      final List<int> a =
          List<int>.generate(10, (_) => DeterministicRandom(1).nextInt(1000));
      final DeterministicRandom two = DeterministicRandom(2);
      final List<int> b = List<int>.generate(10, (_) => two.nextInt(1000));
      expect(a, isNot(b));
    });

    test('a zero seed does not collapse the generator', () {
      // xorshift has zero as a fixed point; seeding with it would return the
      // same value forever.
      final DeterministicRandom rng = DeterministicRandom(0);
      final Set<int> values = <int>{
        for (int i = 0; i < 10; i++) rng.nextInt(1000),
      };
      expect(values.length, greaterThan(1));
    });
  });

  group('SevenBagRandomizer', () {
    test('a restored bag deals the same pieces', () {
      final SevenBagRandomizer original = SevenBagRandomizer(seed: 42);
      for (int i = 0; i < 9; i++) {
        original.next();
      }
      final List<TetrominoType> expected = original.peek(5);

      final SevenBagRandomizer restored =
          SevenBagRandomizer.fromJson(original.toJson());

      expect(restored.peek(5), expected);
      expect(
        List<TetrominoType>.generate(14, (_) => restored.next()),
        List<TetrominoType>.generate(14, (_) => original.next()),
      );
    });

    test('a run without an explicit seed is still resumable', () {
      // A seed is recorded even when the caller did not supply one, so an
      // ordinary run can be resumed exactly.
      final SevenBagRandomizer original = SevenBagRandomizer();
      original.next();
      final SevenBagRandomizer restored =
          SevenBagRandomizer.fromJson(original.toJson());

      expect(restored.peek(7), original.peek(7));
    });

    test('a malformed payload falls back instead of throwing', () {
      expect(
        () => SevenBagRandomizer.fromJson(<String, Object?>{'seed': 'nope'}),
        returnsNormally,
      );
      expect(() => SevenBagRandomizer.fromJson(null), returnsNormally);
    });
  });

  group('TetrisEngine snapshot', () {
    test('restoring keeps the next queue identical', () {
      // The audit's probe: seed 42, queue [l,t,j,s,i] became [o,l,t,j,s].
      final TetrisEngine engine = TetrisEngine(seed: 42)..start();
      for (int i = 0; i < 3; i++) {
        engine.applyInput(TetrisInput.hardDrop);
      }
      final List<TetrominoType> before = engine.nextQueue;

      final TetrisEngine restored = TetrisEngine(seed: 99)
        ..restore(engine.toSnapshot());

      expect(
        restored.nextQueue,
        before,
        reason: 'the resumed run must show the same upcoming pieces',
      );
    });

    test('the snapshot declares its version', () {
      final TetrisEngine engine = TetrisEngine(seed: 1)..start();
      expect(engine.toSnapshot()['version'], TetrisEngine.snapshotVersion);
    });

    test('a version 1 snapshot without a bag still loads', () {
      final TetrisEngine engine = TetrisEngine(seed: 1)..start();
      final Map<String, Object?> legacy =
          Map<String, Object?>.from(engine.toSnapshot())
            ..remove('bag')
            ..remove('version');

      final TetrisEngine restored = TetrisEngine(seed: 2);
      expect(() => restored.restore(legacy), returnsNormally);
      expect(restored.isStarted, isTrue);
    });
  });

  group('Match3Engine snapshot', () {
    test('the same swap resolves the same way after a restore', () {
      // The audit's probe: an identical legal swap produced different boards
      // from the original engine and from one restored out of its snapshot.
      final Match3Engine original = Match3Engine(seed: 42)..start();
      final Map<String, Object?> snapshot = original.toSnapshot();

      final Match3Engine restored = Match3Engine(seed: 7)..restore(snapshot);

      expect(
        restored.grid.toJson(),
        original.grid.toJson(),
        reason: 'the restored board must match before any move is made',
      );

      // Find a swap that is legal on this board and play it on both.
      bool played = false;
      for (int y = 0; y < original.grid.height && !played; y++) {
        for (int x = 0; x < original.grid.width - 1 && !played; x++) {
          final Match3Engine probe = Match3Engine(seed: 7)..restore(snapshot);
          if (!probe.swap(GridPos(x, y), GridPos(x + 1, y))) {
            continue;
          }
          original.swap(GridPos(x, y), GridPos(x + 1, y));
          restored.swap(GridPos(x, y), GridPos(x + 1, y));
          played = true;
        }
      }

      expect(played, isTrue, reason: 'the seeded board should offer a legal swap');
      expect(
        restored.grid.toJson(),
        original.grid.toJson(),
        reason: 'refills after the swap must come from the same sequence',
      );
      expect(restored.score, original.score);
    });

    test('the snapshot declares its version', () {
      final Match3Engine engine = Match3Engine(seed: 1)..start();
      expect(engine.toSnapshot()['version'], Match3Engine.snapshotVersion);
    });

    test('a version 1 snapshot without a spawner still loads', () {
      final Match3Engine engine = Match3Engine(seed: 1)..start();
      final Map<String, Object?> legacy =
          Map<String, Object?>.from(engine.toSnapshot())
            ..remove('spawner')
            ..remove('version');

      final Match3Engine restored = Match3Engine(seed: 2);
      expect(() => restored.restore(legacy), returnsNormally);
    });
  });
}
