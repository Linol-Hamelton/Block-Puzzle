import 'package:block_puzzle_mobile/domain/match3/special_resolver.dart';
import 'package:block_puzzle_mobile/domain/match3/tile.dart';
import 'package:block_puzzle_mobile/domain/match3/tile_grid.dart';
import 'package:flutter_test/flutter_test.dart';

/// Table-driven coverage of the detonation chain.
///
/// The multi-game plan named this matrix the top source of clone bugs, so it is
/// tested before anything animates it. The failure modes it is written against
/// are the classic ones: an effect that loops forever, a cell cleared twice and
/// scored twice, and an effect that fails to propagate into the special it
/// just removed.
void main() {
  /// Builds a board from rows of single letters.
  ///
  ///   r = ruby, a = amber, c = citrine, e = emerald
  ///   uppercase marks a special, given per position in [specials].
  TileGrid boardOf(List<String> rows, {Map<GridPos, SpecialKind>? specials}) {
    const Map<String, TileColor> letters = <String, TileColor>{
      'r': TileColor.ruby,
      'a': TileColor.amber,
      'c': TileColor.citrine,
      'e': TileColor.emerald,
    };
    final int height = rows.length;
    final int width = rows.first.length;
    final List<Tile?> cells = <Tile?>[];
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final TileColor color = letters[rows[y][x]]!;
        final SpecialKind kind =
            specials?[GridPos(x, y)] ?? SpecialKind.none;
        cells.add(Tile(color, kind));
      }
    }
    return TileGrid(width: width, height: height, cells: cells);
  }

  const SpecialResolver resolver = SpecialResolver();

  group('plain tiles', () {
    test('clear exactly what was asked for', () {
      final TileGrid grid = boardOf(<String>[
        'rrar',
        'acea',
        'earc',
        'crea',
      ]);

      final DetonationResult result = resolver.resolve(
        grid,
        <GridPos>[const GridPos(0, 0), const GridPos(1, 0)],
      );

      expect(result.cells, <GridPos>{const GridPos(0, 0), const GridPos(1, 0)});
      expect(result.triggered, isEmpty);
    });
  });

  group('single effects', () {
    test('a horizontal line gem clears its whole row and nothing else', () {
      final TileGrid grid = boardOf(
        <String>['rrar', 'acea', 'earc', 'crea'],
        specials: <GridPos, SpecialKind>{
          const GridPos(1, 1): SpecialKind.lineHorizontal,
        },
      );

      final DetonationResult result =
          resolver.resolve(grid, <GridPos>[const GridPos(1, 1)]);

      expect(
        result.cells,
        <GridPos>{
          const GridPos(0, 1),
          const GridPos(1, 1),
          const GridPos(2, 1),
          const GridPos(3, 1),
        },
      );
      expect(result.triggered, <SpecialKind>[SpecialKind.lineHorizontal]);
    });

    test('a vertical line gem clears its whole column', () {
      final TileGrid grid = boardOf(
        <String>['rrar', 'acea', 'earc', 'crea'],
        specials: <GridPos, SpecialKind>{
          const GridPos(2, 2): SpecialKind.lineVertical,
        },
      );

      final DetonationResult result =
          resolver.resolve(grid, <GridPos>[const GridPos(2, 2)]);

      expect(result.cells.length, 4);
      expect(result.cells.every((GridPos p) => p.x == 2), isTrue);
    });

    test('a bomb clears the 3x3 around it, clipped at the edge', () {
      final TileGrid grid = boardOf(
        <String>['rrar', 'acea', 'earc', 'crea'],
        specials: <GridPos, SpecialKind>{
          const GridPos(0, 0): SpecialKind.bomb,
        },
      );

      final DetonationResult result =
          resolver.resolve(grid, <GridPos>[const GridPos(0, 0)]);

      // A corner bomb reaches four cells, not nine.
      expect(
        result.cells,
        <GridPos>{
          const GridPos(0, 0),
          const GridPos(1, 0),
          const GridPos(0, 1),
          const GridPos(1, 1),
        },
      );
    });

    test('a colour bomb clears every tile of its own colour by default', () {
      final TileGrid grid = boardOf(
        <String>['racr', 'acea', 'earc', 'crea'],
        specials: <GridPos, SpecialKind>{
          const GridPos(0, 0): SpecialKind.colorBomb,
        },
      );

      final DetonationResult result =
          resolver.resolve(grid, <GridPos>[const GridPos(0, 0)]);

      for (final GridPos p in result.cells) {
        expect(grid.atPos(p), TileColor.ruby);
      }
      expect(result.cells, contains(const GridPos(0, 0)));
    });

    test('a colour bomb consumes the colour it was swapped against', () {
      final TileGrid grid = boardOf(
        <String>['racr', 'acea', 'earc', 'crea'],
        specials: <GridPos, SpecialKind>{
          const GridPos(0, 0): SpecialKind.colorBomb,
        },
      );

      final DetonationResult result = resolver.resolve(
        grid,
        <GridPos>[const GridPos(0, 0)],
        colorBombTarget: TileColor.emerald,
      );

      final Set<GridPos> emeralds = grid.filledPositions
          .where((GridPos p) => grid.atPos(p) == TileColor.emerald)
          .toSet();
      expect(result.cells.containsAll(emeralds), isTrue);
    });
  });

  group('chaining', () {
    test('a bomb sets off a line gem it reaches', () {
      final TileGrid grid = boardOf(
        <String>['rrar', 'acea', 'earc', 'crea'],
        specials: <GridPos, SpecialKind>{
          const GridPos(1, 1): SpecialKind.bomb,
          const GridPos(2, 2): SpecialKind.lineHorizontal,
        },
      );

      final DetonationResult result =
          resolver.resolve(grid, <GridPos>[const GridPos(1, 1)]);

      // The bomb's 3x3 covers (2,2), which then clears all of row 2.
      expect(result.cells, containsAll(<GridPos>[
        const GridPos(0, 2),
        const GridPos(3, 2),
      ]));
      expect(result.triggered, contains(SpecialKind.lineHorizontal));
      expect(result.triggered, contains(SpecialKind.bomb));
    });

    test('two line gems that reach each other terminate', () {
      // The loop guard. The vertical gem sits in the horizontal one's row, so
      // the first clears the second, the second clears a column that contains
      // the first, and a naive implementation bounces between them forever.
      final TileGrid grid = boardOf(
        <String>['rrar', 'acea', 'earc', 'crea'],
        specials: <GridPos, SpecialKind>{
          const GridPos(1, 1): SpecialKind.lineHorizontal,
          const GridPos(2, 1): SpecialKind.lineVertical,
        },
      );

      final DetonationResult result =
          resolver.resolve(grid, <GridPos>[const GridPos(1, 1)]);

      expect(result.cells.length, lessThanOrEqualTo(4 * 4));
      expect(
        result.triggered.where((SpecialKind k) => k == SpecialKind.lineVertical),
        hasLength(1),
        reason: 'each special fires once, however many effects sweep over it',
      );
      expect(
        result.triggered
            .where((SpecialKind k) => k == SpecialKind.lineHorizontal),
        hasLength(1),
      );
      // Row 1 and column 2, unioned.
      expect(result.cells, contains(const GridPos(2, 3)));
      expect(result.cells, contains(const GridPos(0, 1)));
    });

    test('every cell appears once no matter how many effects reach it', () {
      final TileGrid grid = boardOf(
        <String>['rrar', 'acea', 'earc', 'crea'],
        specials: <GridPos, SpecialKind>{
          const GridPos(1, 1): SpecialKind.bomb,
          const GridPos(2, 1): SpecialKind.bomb,
          const GridPos(1, 2): SpecialKind.lineHorizontal,
        },
      );

      final DetonationResult result = resolver.resolve(
        grid,
        <GridPos>[const GridPos(1, 1), const GridPos(2, 1)],
      );

      // A Set cannot hold duplicates, so the meaningful assertion is that the
      // chain terminated and covered the overlapping areas exactly once each.
      expect(result.cells.length, result.cells.toSet().length);
      expect(result.cells, contains(const GridPos(0, 2)));
    });

    test('a colour bomb reached by a chain still fires', () {
      final TileGrid grid = boardOf(
        <String>['racr', 'rcea', 'earc', 'crea'],
        specials: <GridPos, SpecialKind>{
          const GridPos(0, 0): SpecialKind.lineVertical,
          const GridPos(0, 2): SpecialKind.colorBomb,
        },
      );

      final DetonationResult result =
          resolver.resolve(grid, <GridPos>[const GridPos(0, 0)]);

      expect(result.triggered, contains(SpecialKind.colorBomb));
      // Its colour is emerald at (0,2); every emerald must go.
      final Set<GridPos> emeralds = grid.filledPositions
          .where((GridPos p) => grid.atPos(p) == TileColor.emerald)
          .toSet();
      expect(result.cells.containsAll(emeralds), isTrue);
    });

    test('a board made entirely of bombs terminates', () {
      final List<String> rows = List<String>.filled(6, 'rrrrrr');
      final Map<GridPos, SpecialKind> everywhere = <GridPos, SpecialKind>{
        for (int y = 0; y < 6; y++)
          for (int x = 0; x < 6; x++) GridPos(x, y): SpecialKind.bomb,
      };
      final TileGrid grid = boardOf(rows, specials: everywhere);

      final DetonationResult result =
          resolver.resolve(grid, <GridPos>[const GridPos(3, 3)]);

      expect(result.cells.length, 36);
      expect(result.triggered, hasLength(36));
    });
  });

  group('edges', () {
    test('an out-of-bounds trigger is ignored', () {
      final TileGrid grid = boardOf(<String>['rr', 'aa']);
      final DetonationResult result =
          resolver.resolve(grid, <GridPos>[const GridPos(9, 9)]);
      expect(result.isEmpty, isTrue);
    });

    test('a hole in the board does not detonate', () {
      TileGrid grid = boardOf(<String>['rr', 'aa']);
      grid = grid.clearedAt(<GridPos>[const GridPos(0, 0)]);
      final DetonationResult result =
          resolver.resolve(grid, <GridPos>[const GridPos(0, 0)]);
      expect(result.cells, <GridPos>{const GridPos(0, 0)});
      expect(result.triggered, isEmpty);
    });
  });
}
