import 'package:block_puzzle_mobile/domain/match3/match_detector.dart';
import 'package:block_puzzle_mobile/domain/match3/tile.dart';
import 'package:block_puzzle_mobile/domain/match3/tile_grid.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shapes, and what each one is worth.
///
/// The detector finds straight runs. A player sees shapes: an L is one thing
/// that happened, not two matches that share a corner. Everything the mode
/// rewards hangs off getting that grouping right, so it is tested on its own
/// rather than through the cascade.
void main() {
  const MatchDetector detector = MatchDetector();

  /// r = ruby, a = amber, c = citrine, e = emerald, . = a hole.
  TileGrid boardOf(List<String> rows) {
    const Map<String, TileColor> letters = <String, TileColor>{
      'r': TileColor.ruby,
      'a': TileColor.amber,
      'c': TileColor.citrine,
      'e': TileColor.emerald,
    };
    return TileGrid.ofColors(
      width: rows.first.length,
      height: rows.length,
      colors: <TileColor?>[
        for (final String row in rows)
          for (int x = 0; x < row.length; x++) letters[row[x]],
      ],
    );
  }

  group('grouping', () {
    test('a lone run is one group with no crossing', () {
      final List<MatchGroup> groups = detector.findGroups(boardOf(<String>[
        'rrra',
        'acea',
        'ceac',
      ]));

      expect(groups, hasLength(1));
      expect(groups.single.cells, hasLength(3));
      expect(groups.single.intersections, isEmpty);
      expect(groups.single.color, TileColor.ruby);
    });

    test('two runs that do not touch stay two groups', () {
      final List<MatchGroup> groups = detector.findGroups(boardOf(<String>[
        'rrrc',
        'ecae',
        'aaac',
      ]));

      expect(groups, hasLength(2));
      expect(
        groups.map((MatchGroup g) => g.color).toSet(),
        <TileColor>{TileColor.ruby, TileColor.amber},
      );
    });

    test('an L is one group, not two matches sharing a corner', () {
      // Ruby down column 0 and along row 2, meeting at (0,2).
      final List<MatchGroup> groups = detector.findGroups(boardOf(<String>[
        'race',
        'rcac',
        'rrra',
      ]));

      expect(groups, hasLength(1));
      expect(groups.single.cells, hasLength(5));
      expect(groups.single.intersections, <GridPos>[const GridPos(0, 2)]);
    });

    test('a T crosses in the middle of its bar', () {
      final List<MatchGroup> groups = detector.findGroups(boardOf(<String>[
        'arca',
        'crce',
        'rrra',
      ]));

      expect(groups, hasLength(1));
      expect(groups.single.cells, hasLength(5));
      expect(groups.single.intersections, <GridPos>[const GridPos(1, 2)]);
    });

    test('a later run bridges two groups that were separate when it was found',
        () {
      // Runs are found by axis: both horizontal ones first, and they do not
      // touch each other, so they start as two groups. The vertical run joins
      // one of them and only then turns out to touch the other. Grouping has to
      // settle rather than make a single pass, or this reads as two shapes.
      final List<MatchGroup> groups = detector.findGroups(boardOf(<String>[
        'rrrac',
        'carac',
        'errra',
        'caeac',
      ]));

      expect(groups, hasLength(1));
      expect(groups.single.cells, hasLength(7));
      expect(groups.single.runs, hasLength(3));
      expect(
        groups.single.intersections,
        containsAll(<GridPos>[const GridPos(2, 0), const GridPos(2, 2)]),
      );
    });

    test('same-shaped runs of different colours never merge', () {
      final List<MatchGroup> groups = detector.findGroups(boardOf(<String>[
        'raaa',
        'rcec',
        'rcea',
      ]));

      expect(groups, hasLength(2));
      for (final MatchGroup group in groups) {
        expect(group.intersections, isEmpty);
      }
    });
  });

  group('what a shape is worth', () {
    MatchGroup only(List<String> rows) => detector.findGroups(boardOf(rows)).single;

    test('three is worth nothing but the clear', () {
      expect(only(<String>['rrra', 'acea', 'ceac']).reward, SpecialKind.none);
    });

    test('four gives a line gem along the run', () {
      expect(
        only(<String>['rrrra', 'aceac', 'ceace']).reward,
        SpecialKind.lineHorizontal,
      );
      expect(
        only(<String>['rac', 'rce', 'rea', 'rca', 'aec']).reward,
        SpecialKind.lineVertical,
      );
    });

    test('a crossing gives a bomb, beating either four-length arm', () {
      expect(
        only(<String>['race', 'rcac', 'rrra']).reward,
        SpecialKind.bomb,
      );
    });

    test('five gives a colour bomb', () {
      expect(
        only(<String>['rrrrr', 'aceac', 'ceace']).reward,
        SpecialKind.colorBomb,
      );
    });

    test('five that also crosses still gives the colour bomb', () {
      // The rarer, bigger shape must not pay out less than the plain five. This
      // is the case that was backwards: checking the crossing first handed a
      // six-cell shape the weaker gem.
      final MatchGroup group = only(<String>[
        'arcae',
        'arcae',
        'rrrrr',
        'ecaec',
      ]);

      expect(group.intersections, isNotEmpty);
      expect(group.longestRun.length, 5);
      expect(group.reward, SpecialKind.colorBomb);
    });
  });

  group('where the bonus appears', () {
    test('under the cell the player moved, when the shape contains it', () {
      final MatchGroup group =
          detector.findGroups(boardOf(<String>['rrrra', 'aceac', 'ceace']))
              .single;

      expect(
        group.spawnPosition(swapped: const GridPos(3, 0)),
        const GridPos(3, 0),
      );
    });

    test('at the crossing when the player did not touch the shape', () {
      final MatchGroup group =
          detector.findGroups(boardOf(<String>['race', 'rcac', 'rrra']))
              .single;

      expect(group.spawnPosition(), const GridPos(0, 2));
      // A cell the player moved somewhere else does not drag the gem out of the
      // shape that earned it.
      expect(
        group.spawnPosition(swapped: const GridPos(3, 0)),
        const GridPos(0, 2),
      );
    });

    test('mid-run for a plain line', () {
      final MatchGroup group =
          detector.findGroups(boardOf(<String>['rrrra', 'aceac', 'ceace']))
              .single;

      expect(group.spawnPosition(), const GridPos(2, 0));
    });
  });
}
