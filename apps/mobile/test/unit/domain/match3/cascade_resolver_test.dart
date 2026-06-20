import 'package:block_puzzle_mobile/domain/match3/cascade_resolver.dart';
import 'package:block_puzzle_mobile/domain/match3/match_detector.dart';
import 'package:block_puzzle_mobile/domain/match3/tile.dart';
import 'package:block_puzzle_mobile/domain/match3/tile_grid.dart';
import 'package:block_puzzle_mobile/domain/match3/tile_spawner.dart';
import 'package:flutter_test/flutter_test.dart';

const TileColor r = TileColor.ruby;
const TileColor m = TileColor.amber;
const TileColor c = TileColor.citrine;
const TileColor e = TileColor.emerald;

TileGrid g(List<List<TileColor>> rows) {
  final int h = rows.length;
  final int w = rows.first.length;
  return TileGrid(
    width: w,
    height: h,
    cells: <TileColor?>[for (final List<TileColor> row in rows) ...row],
  );
}

void main() {
  const MatchDetector detector = MatchDetector();

  group('CascadeResolver.applyGravity', () {
    test('non-null tiles fall to the bottom, holes rise to the top', () {
      final CascadeResolver resolver =
          CascadeResolver(spawner: TileSpawner(seed: 1));
      // Column: r (top), hole, c (bottom).
      final TileGrid grid =
          TileGrid(width: 1, height: 3, cells: <TileColor?>[r, null, c]);
      final TileGrid fallen = resolver.applyGravity(grid);
      expect(fallen.at(0, 0), isNull);
      expect(fallen.at(0, 1), r);
      expect(fallen.at(0, 2), c);
    });
  });

  group('CascadeResolver.resolve', () {
    test('clears a single match and settles to a match-free board', () {
      final CascadeResolver resolver =
          CascadeResolver(spawner: TileSpawner(seed: 5));
      final TileGrid grid = g(<List<TileColor>>[
        <TileColor>[r, r, r],
        <TileColor>[m, c, e],
        <TileColor>[c, e, m],
      ]);

      final CascadeOutcome outcome = resolver.resolve(grid);

      expect(outcome.hadMatch, isTrue);
      expect(outcome.steps.first.cleared, <GridPos>{
        const GridPos(0, 0),
        const GridPos(1, 0),
        const GridPos(2, 0),
      });
      expect(outcome.totalCleared, greaterThanOrEqualTo(3));
      expect(outcome.totalScore, greaterThan(0));
      // Invariant: the settled board never contains a match.
      expect(detector.hasMatch(outcome.grid), isFalse);
      expect(outcome.grid.isFull, isTrue);
    });

    test('a board with no match resolves to itself with no steps', () {
      final CascadeResolver resolver =
          CascadeResolver(spawner: TileSpawner(seed: 5));
      final TileGrid grid = g(<List<TileColor>>[
        <TileColor>[r, m, r],
        <TileColor>[m, r, m],
        <TileColor>[r, m, r],
      ]);
      final CascadeOutcome outcome = resolver.resolve(grid);
      expect(outcome.hadMatch, isFalse);
      expect(outcome.totalScore, 0);
    });

    test('a falling tile chains into a second match (cascade)', () {
      // L-shape clears 5 cells; differential column drops align a new amber
      // triple along the bottom row, guaranteeing at least a 2-deep cascade.
      final CascadeResolver resolver =
          CascadeResolver(spawner: TileSpawner(seed: 11));
      final TileGrid grid = g(<List<TileColor>>[
        <TileColor>[m, c, e, m],
        <TileColor>[r, e, c, r],
        <TileColor>[r, m, m, c],
        <TileColor>[r, r, r, e],
      ]);

      final CascadeOutcome outcome = resolver.resolve(grid);

      expect(outcome.cascadeCount, greaterThanOrEqualTo(2));
      expect(outcome.totalCleared, greaterThanOrEqualTo(8));
      // Deeper cascade steps carry a higher level (multiplier).
      expect(outcome.steps[1].cascadeLevel, 2);
      expect(detector.hasMatch(outcome.grid), isFalse);
    });
  });
}
