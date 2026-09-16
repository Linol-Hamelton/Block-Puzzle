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
  return TileGrid.ofColors(
      width: w,
    height: h,
    colors: <TileColor?>[for (final List<TileColor> row in rows) ...row],
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
          TileGrid.ofColors(
      width: 1, height: 3, colors: <TileColor?>[r, null, c]);
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
      // Two plain runs of exactly three, deliberately not touching: a vertical
      // one in column 0 and a horizontal one in row 2. Neither earns a bonus,
      // so nothing is left behind to change how the columns fall.
      //
      // They drop by different amounts - column 0 by three, the rest by one -
      // and the citrine at (0,0) lands beside the two already sitting in row 3.
      // The chained match is made entirely of surviving tiles, so this asserts
      // gravity and not the refill's dice.
      final CascadeResolver resolver =
          CascadeResolver(spawner: TileSpawner(seed: 11));
      final TileGrid grid = g(<List<TileColor>>[
        <TileColor>[c, m, e, m],
        <TileColor>[r, e, c, r],
        <TileColor>[r, m, m, m],
        <TileColor>[r, c, c, e],
      ]);

      final CascadeOutcome outcome = resolver.resolve(grid);

      expect(outcome.cascadeCount, greaterThanOrEqualTo(2));
      expect(outcome.totalCleared, greaterThanOrEqualTo(8));
      // Deeper cascade steps carry a higher level (multiplier).
      expect(outcome.steps[1].cascadeLevel, 2);
      expect(outcome.steps[1].cleared, containsAll(<GridPos>[
        const GridPos(0, 3),
        const GridPos(1, 3),
        const GridPos(2, 3),
      ]));
      expect(detector.hasMatch(outcome.grid), isFalse);
    });
  });

  group('CascadeResolver bonus gems', () {
    test('a run of four leaves a line gem along the run', () {
      final CascadeResolver resolver =
          CascadeResolver(spawner: TileSpawner(seed: 3));
      final TileGrid grid = g(<List<TileColor>>[
        <TileColor>[r, r, r, r, c],
        <TileColor>[m, c, e, m, c],
        <TileColor>[c, m, c, e, m],
        <TileColor>[e, c, m, c, e],
      ]);

      final CascadeStep step = resolver.resolve(grid).steps.first;

      expect(step.spawned, hasLength(1));
      final Tile bonus = step.spawned.values.single;
      expect(bonus.special, SpecialKind.lineHorizontal);
      expect(bonus.color, r);
      // The cell it occupies was part of the shape that earned it.
      expect(step.cleared, contains(step.spawned.keys.single));
    });

    test('the bonus lands under the player finger when they earned it', () {
      final CascadeResolver resolver =
          CascadeResolver(spawner: TileSpawner(seed: 3));
      final TileGrid grid = g(<List<TileColor>>[
        <TileColor>[r, r, r, r, c],
        <TileColor>[m, c, e, m, c],
        <TileColor>[c, m, c, e, m],
        <TileColor>[e, c, m, c, e],
      ]);

      final CascadeStep plain = resolver.resolve(grid).steps.first;
      final CascadeStep moved =
          resolver.resolve(grid, swapped: const GridPos(0, 0)).steps.first;

      // Left to itself the gem appears mid-run; told where the player acted, it
      // appears there instead.
      expect(plain.spawned.keys.single, isNot(const GridPos(0, 0)));
      expect(moved.spawned.keys.single, const GridPos(0, 0));
    });

    test('a crossing shape leaves a bomb at the crossing', () {
      final CascadeResolver resolver =
          CascadeResolver(spawner: TileSpawner(seed: 3));
      // An L: ruby down column 0 and along row 2, meeting at (0,2).
      final TileGrid grid = g(<List<TileColor>>[
        <TileColor>[r, m, c, e],
        <TileColor>[r, c, m, c],
        <TileColor>[r, r, r, m],
        <TileColor>[c, e, c, e],
      ]);

      final CascadeStep step = resolver.resolve(grid).steps.first;

      expect(step.spawned.keys.single, const GridPos(0, 2));
      expect(step.spawned.values.single.special, SpecialKind.bomb);
      // Both arms were one shape, so the whole L cleared as one step.
      expect(step.cleared, hasLength(5));
    });

    test('a run of five leaves a colour bomb', () {
      final CascadeResolver resolver =
          CascadeResolver(spawner: TileSpawner(seed: 3));
      final TileGrid grid = g(<List<TileColor>>[
        <TileColor>[r, r, r, r, r],
        <TileColor>[m, c, e, m, c],
        <TileColor>[c, m, c, e, m],
      ]);

      final CascadeStep step = resolver.resolve(grid).steps.first;

      expect(step.spawned.values.single.special, SpecialKind.colorBomb);
    });

    test('the bonus gem survives the clear that created it', () {
      final CascadeResolver resolver =
          CascadeResolver(spawner: TileSpawner(seed: 3));
      final TileGrid grid = g(<List<TileColor>>[
        <TileColor>[r, m, c, e],
        <TileColor>[r, c, m, c],
        <TileColor>[r, r, r, m],
        <TileColor>[c, e, c, e],
      ]);

      final CascadeOutcome outcome = resolver.resolve(grid);

      // It is somewhere on the settled board, wherever gravity put it - a gem
      // that vanished with its own match would be worse than no gem at all.
      final bool survives = outcome.grid.filledPositions.any(
        (GridPos p) => outcome.grid.specialAt(p) == SpecialKind.bomb,
      );
      expect(survives, isTrue);
    });
  });

  group('CascadeResolver detonation', () {
    test('a match containing a line gem clears that whole line', () {
      final CascadeResolver resolver =
          CascadeResolver(spawner: TileSpawner(seed: 7));
      // A plain ruby triple across the top; the middle one is a vertical line
      // gem, so matching the triple sweeps all of column 1 with it.
      TileGrid grid = g(<List<TileColor>>[
        <TileColor>[r, r, r, c],
        <TileColor>[m, c, e, m],
        <TileColor>[c, m, c, e],
        <TileColor>[e, c, m, c],
      ]);
      grid = grid.withSpecialAt(const GridPos(1, 0), SpecialKind.lineVertical);

      final CascadeStep step = resolver.resolve(grid).steps.first;

      expect(step.triggered, contains(SpecialKind.lineVertical));
      expect(step.cleared, containsAll(<GridPos>[
        const GridPos(1, 0),
        const GridPos(1, 1),
        const GridPos(1, 2),
        const GridPos(1, 3),
      ]));
      // A run of three earns nothing, so this step is detonation and nothing
      // else.
      expect(step.spawned, isEmpty);
      expect(step.gained, greaterThan(0));
    });

    test('a seeded blast clears without any match at all', () {
      final CascadeResolver resolver =
          CascadeResolver(spawner: TileSpawner(seed: 7));
      // Deliberately match-free: only the seed can make anything happen.
      TileGrid grid = g(<List<TileColor>>[
        <TileColor>[r, m, r, m],
        <TileColor>[m, r, m, r],
        <TileColor>[r, m, r, m],
        <TileColor>[m, r, m, r],
      ]);
      grid = grid.withSpecialAt(const GridPos(0, 1), SpecialKind.lineHorizontal);

      final CascadeOutcome outcome = resolver.resolve(
        grid,
        detonate: <GridPos>[const GridPos(0, 1)],
      );

      expect(outcome.hadMatch, isTrue);
      expect(outcome.steps.first.cascadeLevel, 1);
      expect(outcome.steps.first.cleared, containsAll(<GridPos>[
        const GridPos(0, 1),
        const GridPos(3, 1),
      ]));
      // A seeded step is not a match, so it earns no bonus gem.
      expect(outcome.steps.first.spawned, isEmpty);
    });

    test('an empty seed resolves to nothing rather than looping', () {
      final CascadeResolver resolver =
          CascadeResolver(spawner: TileSpawner(seed: 7));
      final TileGrid grid = g(<List<TileColor>>[
        <TileColor>[r, m, r, m],
        <TileColor>[m, r, m, r],
        <TileColor>[r, m, r, m],
        <TileColor>[m, r, m, r],
      ]);

      final CascadeOutcome outcome =
          resolver.resolve(grid, detonate: const <GridPos>[]);

      expect(outcome.hadMatch, isFalse);
    });
  });
}
