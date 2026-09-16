import 'package:block_puzzle_mobile/domain/match3/match3_engine.dart';
import 'package:block_puzzle_mobile/domain/match3/match3_progression.dart';
import 'package:block_puzzle_mobile/domain/match3/match_detector.dart';
import 'package:block_puzzle_mobile/domain/match3/special_combo.dart';
import 'package:block_puzzle_mobile/domain/match3/tile.dart';
import 'package:block_puzzle_mobile/domain/match3/tile_grid.dart';
import 'package:flutter_test/flutter_test.dart';

const TileColor r = TileColor.ruby;
const TileColor m = TileColor.amber;
const TileColor c = TileColor.citrine;
const TileColor e = TileColor.emerald;

/// A settled 4×4 board with no pre-existing match. Swapping (2,0)<->(2,1)
/// completes the top row into r,r,r.
TileGrid craftBoard() => TileGrid.ofColors(
      width: 4,
      height: 4,
      colors: <TileColor?>[
        r, r, e, m, // y0
        m, c, r, c, // y1
        c, m, c, e, // y2
        e, c, m, r, // y3
      ],
    );

/// The same board with effects written onto named cells.
TileGrid craftBoardWith(Map<GridPos, SpecialKind> specials) {
  TileGrid grid = craftBoard();
  specials.forEach((GridPos p, SpecialKind kind) {
    grid = grid.withSpecialAt(p, kind);
  });
  return grid;
}

Map<String, Object?> snapshotOf(
  TileGrid grid, {
  int score = 0,
  int movesUsed = 0,
}) =>
    <String, Object?>{
      'grid': grid.toJson(),
      'score': score,
      'moves_used': movesUsed,
    };

Map<String, Object?> craftSnapshot({int score = 0, int movesUsed = 0}) =>
    snapshotOf(craftBoard(), score: score, movesUsed: movesUsed);

/// A progression where the first match ends round one and nothing else can
/// possibly end round two, so a test can assert on exactly one payout.
const Match3Progression oneRound = Match3Progression(
  movesPerRound: 3,
  baseTarget: 1,
  targetGrowth: 1 << 30,
);

void main() {
  const MatchDetector detector = MatchDetector();

  group('Match3Engine start', () {
    test('fills a playable board with no pre-existing match', () {
      final Match3Engine engine = Match3Engine(seed: 7)..start();
      expect(engine.isStarted, isTrue);
      expect(engine.grid.isFull, isTrue);
      expect(detector.hasMatch(engine.grid), isFalse);
      expect(engine.hasPossibleMove(), isTrue);
    });

    test('is deterministic for a given seed', () {
      final Match3Engine a = Match3Engine(seed: 7)..start();
      final Match3Engine b = Match3Engine(seed: 7)..start();
      for (int y = 0; y < a.height; y++) {
        for (int x = 0; x < a.width; x++) {
          expect(a.grid.at(x, y), b.grid.at(x, y));
        }
      }
    });

    test('opens on round one with the full budget', () {
      final Match3Engine engine = Match3Engine(seed: 7)..start();
      expect(engine.round, 1);
      expect(engine.movesLeft, Match3Progression.defaultStartingMoves);
      expect(engine.roundFloor, 0);
      expect(engine.roundProgress, 0);
    });
  });

  group('Match3Engine swap', () {
    test('a legal swap scores, consumes a move, and emits a match event', () {
      final Match3Engine engine =
          Match3Engine(width: 4, height: 4)..restore(craftSnapshot());
      engine.drainEvents();

      final bool ok =
          engine.swap(const GridPos(2, 0), const GridPos(2, 1));

      expect(ok, isTrue);
      expect(engine.score, greaterThan(0));
      expect(engine.movesUsed, 1);
      final List<Match3EventType> types =
          engine.drainEvents().map((Match3Event ev) => ev.type).toList();
      expect(types, contains(Match3EventType.swap));
      expect(types, contains(Match3EventType.match));
    });

    test('an adjacent swap that makes no match is reverted', () {
      final Match3Engine engine =
          Match3Engine(width: 4, height: 4)..restore(craftSnapshot());
      engine.drainEvents();

      final bool ok =
          engine.swap(const GridPos(0, 0), const GridPos(0, 1));

      expect(ok, isFalse);
      expect(engine.score, 0);
      expect(engine.movesUsed, 0);
      expect(
        engine.drainEvents().map((Match3Event ev) => ev.type),
        contains(Match3EventType.invalidSwap),
      );
    });

    test('a non-adjacent swap is a silent no-op', () {
      final Match3Engine engine =
          Match3Engine(width: 4, height: 4)..restore(craftSnapshot());
      engine.drainEvents();

      final bool ok =
          engine.swap(const GridPos(0, 0), const GridPos(3, 3));

      expect(ok, isFalse);
      expect(engine.movesUsed, 0);
      expect(engine.drainEvents(), isEmpty);
    });

    test('reaching the move limit ends the run', () {
      final Match3Engine engine = Match3Engine(width: 4, height: 4, moveLimit: 1)
        ..restore(craftSnapshot());
      engine.drainEvents();

      engine.swap(const GridPos(2, 0), const GridPos(2, 1));

      expect(engine.isGameOver, isTrue);
      expect(engine.movesLeft, 0);
      expect(
        engine.drainEvents().map((Match3Event ev) => ev.type),
        contains(Match3EventType.gameOver),
      );
      // No further swaps are accepted after game over.
      expect(engine.swap(const GridPos(0, 0), const GridPos(1, 0)), isFalse);
    });
  });

  group('Match3Engine combo swaps', () {
    test('a colour bomb spends itself on an ordinary gem with no match', () {
      // (0,0) and (1,0) are both ruby, so the exchange changes nothing and the
      // plain version of this swap is rejected. With a colour bomb there it is
      // a move: the only way to spend one deliberately.
      final Match3Engine engine = Match3Engine(width: 4, height: 4)
        ..restore(snapshotOf(craftBoardWith(<GridPos, SpecialKind>{
          const GridPos(0, 0): SpecialKind.colorBomb,
        })));
      engine.drainEvents();

      final bool ok = engine.swap(const GridPos(0, 0), const GridPos(1, 0));

      expect(ok, isTrue);
      expect(engine.movesUsed, 1);
      expect(engine.score, greaterThan(0));
      final List<Match3Event> events = engine.drainEvents();
      final Match3Event fired = events
          .firstWhere((Match3Event ev) => ev.type == Match3EventType.combo);
      expect(fired.combo, ComboKind.colorPick);
    });

    test('a line gem on an ordinary gem is still not a move', () {
      final Match3Engine engine = Match3Engine(width: 4, height: 4)
        ..restore(snapshotOf(craftBoardWith(<GridPos, SpecialKind>{
          const GridPos(0, 0): SpecialKind.lineHorizontal,
        })));
      engine.drainEvents();

      final bool ok = engine.swap(const GridPos(0, 0), const GridPos(1, 0));

      expect(ok, isFalse);
      expect(engine.movesUsed, 0);
      expect(
        engine.drainEvents().map((Match3Event ev) => ev.type),
        contains(Match3EventType.invalidSwap),
      );
    });

    test('a colour bomb keeps a dead board alive instead of re-rolling it', () {
      // Four colours in a pattern with no matching swap anywhere. Restoring it
      // plain proves it is genuinely a dead end...
      final TileGrid deadEnd = TileGrid.ofColors(
        width: 4,
        height: 4,
        colors: <TileColor?>[
          r, m, c, e,
          c, e, r, m,
          r, m, c, e,
          c, e, r, m,
        ],
      );
      final Match3Engine plain =
          Match3Engine(width: 4, height: 4)..restore(snapshotOf(deadEnd));
      expect(
        plain.drainEvents().map((Match3Event ev) => ev.type),
        contains(Match3EventType.shuffle),
        reason: 'the fixture is supposed to have no matching swap',
      );

      // ...and the same board with one colour bomb on it is not, because the
      // bomb combines with any neighbour. Re-rolling here would have destroyed
      // the gem while calling the board unplayable.
      TileGrid withBomb =
          deadEnd.withSpecialAt(const GridPos(1, 1), SpecialKind.colorBomb);
      final Match3Engine rescued =
          Match3Engine(width: 4, height: 4)..restore(snapshotOf(withBomb));
      expect(
        rescued.drainEvents().map((Match3Event ev) => ev.type),
        isNot(contains(Match3EventType.shuffle)),
      );
      expect(rescued.hasPossibleMove(), isTrue);
      withBomb = rescued.grid;
      expect(
        withBomb.specialAt(const GridPos(1, 1)),
        SpecialKind.colorBomb,
        reason: 'the bonus gem must still be there',
      );
    });
  });

  group('Match3Engine rounds', () {
    test('completing a round pays out moves', () {
      final Match3Engine engine = Match3Engine(
        width: 4,
        height: 4,
        moveLimit: 5,
        progression: oneRound,
      )..restore(craftSnapshot());
      engine.drainEvents();

      engine.swap(const GridPos(2, 0), const GridPos(2, 1));

      expect(engine.round, 2);
      // One move spent, three granted.
      expect(engine.movesLeft, 7);
      expect(engine.moveBudget, 8);
      final Match3Event payout = engine.drainEvents().firstWhere(
          (Match3Event ev) => ev.type == Match3EventType.roundComplete);
      expect(payout.value, 1, reason: 'the round just completed');
      expect(payout.detail, 3, reason: 'moves it paid out');
    });

    test('one big move can complete several rounds at once', () {
      // Rounds one point apart: a single match crosses many of them, and the
      // player has to be paid for every one rather than just the first.
      final Match3Engine engine = Match3Engine(
        width: 4,
        height: 4,
        moveLimit: 5,
        progression: const Match3Progression(
          movesPerRound: 1,
          baseTarget: 1,
          targetGrowth: 1,
        ),
      )..restore(craftSnapshot());
      engine.drainEvents();

      engine.swap(const GridPos(2, 0), const GridPos(2, 1));

      expect(engine.round, greaterThan(2));
      final List<Match3Event> payouts = engine
          .drainEvents()
          .where((Match3Event ev) => ev.type == Match3EventType.roundComplete)
          .toList();
      expect(payouts, hasLength(engine.round - 1));
      expect(engine.moveBudget, 5 + payouts.length);
    });

    test('a round that is not reached pays nothing', () {
      final Match3Engine engine = Match3Engine(
        width: 4,
        height: 4,
        moveLimit: 5,
      )..restore(craftSnapshot());
      engine.drainEvents();

      engine.swap(const GridPos(2, 0), const GridPos(2, 1));

      // A single small match is nowhere near the live round-one target.
      expect(engine.round, 1);
      expect(engine.movesLeft, 4);
      expect(
        engine.drainEvents().map((Match3Event ev) => ev.type),
        isNot(contains(Match3EventType.roundComplete)),
      );
    });

    test('the run ends when the granted budget is spent, not the opening one',
        () {
      final Match3Engine engine = Match3Engine(
        width: 4,
        height: 4,
        moveLimit: 1,
        progression: oneRound,
      )..restore(craftSnapshot());
      engine.drainEvents();

      engine.swap(const GridPos(2, 0), const GridPos(2, 1));

      // The opening move would have ended the run; finishing a round bought
      // three more, so it is still live.
      expect(engine.isGameOver, isFalse);
      expect(engine.movesLeft, 3);
    });
  });

  group('Match3Engine snapshot', () {
    test('round-trips score, moves, and the board', () {
      final Match3Engine engine =
          Match3Engine(width: 4, height: 4)..restore(craftSnapshot());
      engine.swap(const GridPos(2, 0), const GridPos(2, 1));
      final Map<String, Object?> snap = engine.toSnapshot();

      final Match3Engine restored =
          Match3Engine(width: 4, height: 4)..restore(snap);
      expect(restored.score, engine.score);
      expect(restored.movesUsed, engine.movesUsed);
      expect(restored.isStarted, isTrue);
      for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
          expect(restored.grid.at(x, y), engine.grid.at(x, y));
        }
      }
    });

    test('round-trips the round and the moves it paid out', () {
      final Match3Engine engine = Match3Engine(
        width: 4,
        height: 4,
        moveLimit: 5,
        progression: oneRound,
      )..restore(craftSnapshot());
      engine.swap(const GridPos(2, 0), const GridPos(2, 1));
      final Map<String, Object?> snap = engine.toSnapshot();
      expect(snap['version'], Match3Engine.snapshotVersion);

      final Match3Engine restored = Match3Engine(
        width: 4,
        height: 4,
        moveLimit: 5,
        progression: oneRound,
      )..restore(snap);

      expect(restored.round, engine.round);
      expect(restored.movesLeft, engine.movesLeft);
      expect(restored.moveBudget, engine.moveBudget);
    });

    test('a snapshot written before rounds existed derives them from the score',
        () {
      // Version 2 carried neither field. Resuming at round one would hand back
      // a budget the run had already spent.
      const Match3Progression live = Match3Progression();
      final int score = live.targetForRound(2) + 1;
      final Match3Engine engine = Match3Engine(width: 4, height: 4)
        ..restore(craftSnapshot(score: score, movesUsed: 4));

      expect(engine.round, 3);
      expect(
        engine.moveBudget,
        Match3Progression.defaultStartingMoves + (2 * live.movesPerRound),
      );
      expect(engine.movesLeft, engine.moveBudget! - 4);
    });

    test('an effect gem survives the round trip', () {
      final TileGrid crafted = craftBoardWith(<GridPos, SpecialKind>{
        const GridPos(3, 3): SpecialKind.bomb,
      });
      final Match3Engine engine =
          Match3Engine(width: 4, height: 4)..restore(snapshotOf(crafted));

      final Match3Engine restored = Match3Engine(width: 4, height: 4)
        ..restore(engine.toSnapshot());

      expect(restored.grid.specialAt(const GridPos(3, 3)), SpecialKind.bomb);
    });
  });
}
