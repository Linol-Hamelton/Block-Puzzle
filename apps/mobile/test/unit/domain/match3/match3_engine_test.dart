import 'package:block_puzzle_mobile/domain/match3/match3_engine.dart';
import 'package:block_puzzle_mobile/domain/match3/match_detector.dart';
import 'package:block_puzzle_mobile/domain/match3/tile.dart';
import 'package:block_puzzle_mobile/domain/match3/tile_grid.dart';
import 'package:flutter_test/flutter_test.dart';

const TileColor r = TileColor.ruby;
const TileColor m = TileColor.amber;
const TileColor c = TileColor.citrine;
const TileColor e = TileColor.emerald;

/// A settled 4×4 board with no pre-existing match. Swapping (2,0)<->(2,1)
/// completes the top row into r,r,r.
TileGrid craftBoard() => TileGrid(
      width: 4,
      height: 4,
      cells: <TileColor?>[
        r, r, e, m, // y0
        m, c, r, c, // y1
        c, m, c, e, // y2
        e, c, m, r, // y3
      ],
    );

Map<String, Object?> craftSnapshot({int score = 0, int movesUsed = 0}) =>
    <String, Object?>{
      'grid': craftBoard().toJson(),
      'score': score,
      'moves_used': movesUsed,
    };

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
  });
}
