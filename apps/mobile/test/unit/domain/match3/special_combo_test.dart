import 'package:block_puzzle_mobile/domain/match3/special_combo.dart';
import 'package:block_puzzle_mobile/domain/match3/special_resolver.dart';
import 'package:block_puzzle_mobile/domain/match3/tile.dart';
import 'package:block_puzzle_mobile/domain/match3/tile_grid.dart';
import 'package:flutter_test/flutter_test.dart';

/// The swap matrix: what two effect gems do when the player puts them together.
///
/// Every case is asserted on the cells the chain actually clears, not on the
/// prepared board, because the prepared board is an implementation detail. The
/// combos work by painting effects and letting the ordinary chain run, and this
/// is what proves that detour produces the shapes the genre promises.
void main() {
  const SpecialCombo combo = SpecialCombo();
  const SpecialResolver resolver = SpecialResolver();

  /// A board of one colour, with [specials] written on top. Matches are
  /// irrelevant here - a combo is a move in its own right.
  TileGrid boardOf(
    int size, {
    Map<GridPos, Tile> overrides = const <GridPos, Tile>{},
    TileColor fill = TileColor.ruby,
  }) {
    TileGrid grid = TileGrid(
      width: size,
      height: size,
      cells: List<Tile?>.filled(size * size, Tile(fill)),
    );
    overrides.forEach((GridPos p, Tile tile) {
      grid = grid.withCell(p.x, p.y, tile);
    });
    return grid;
  }

  Set<GridPos> fire(TileGrid grid, GridPos a, GridPos b) {
    final ComboOutcome? outcome = combo.prepare(grid, a, b);
    expect(outcome, isNotNull, reason: 'expected $a x $b to combine');
    return resolver
        .resolve(
          outcome!.grid,
          outcome.trigger,
          colorBombTarget: outcome.colorBombTarget,
        )
        .cells;
  }

  group('what counts as a combo', () {
    test('two ordinary gems do not', () {
      final TileGrid grid = boardOf(5);
      expect(
        combo.isComboSwap(grid, const GridPos(0, 0), const GridPos(1, 0)),
        isFalse,
      );
      expect(combo.prepare(grid, const GridPos(0, 0), const GridPos(1, 0)),
          isNull);
    });

    test('a line gem and an ordinary gem do not', () {
      // Deliberate: otherwise a fumbled drag spends a bonus for nothing. It
      // still has to form a match, which the engine checks separately.
      final TileGrid grid = boardOf(5, overrides: <GridPos, Tile>{
        const GridPos(0, 0): const Tile(TileColor.ruby, SpecialKind.lineHorizontal),
      });
      expect(
        combo.isComboSwap(grid, const GridPos(0, 0), const GridPos(1, 0)),
        isFalse,
      );
    });

    test('a colour bomb and an ordinary gem do', () {
      final TileGrid grid = boardOf(5, overrides: <GridPos, Tile>{
        const GridPos(0, 0): const Tile(TileColor.ruby, SpecialKind.colorBomb),
      });
      expect(
        combo.isComboSwap(grid, const GridPos(0, 0), const GridPos(1, 0)),
        isTrue,
      );
    });

    test('any two effect gems do', () {
      final TileGrid grid = boardOf(5, overrides: <GridPos, Tile>{
        const GridPos(0, 0): const Tile(TileColor.ruby, SpecialKind.bomb),
        const GridPos(1, 0): const Tile(TileColor.ruby, SpecialKind.lineVertical),
      });
      expect(
        combo.isComboSwap(grid, const GridPos(0, 0), const GridPos(1, 0)),
        isTrue,
      );
    });
  });

  group('the matrix', () {
    test('two line gems clear a row and a column', () {
      final TileGrid grid = boardOf(5, overrides: <GridPos, Tile>{
        const GridPos(1, 1): const Tile(TileColor.ruby, SpecialKind.lineVertical),
        const GridPos(2, 1): const Tile(TileColor.ruby, SpecialKind.lineHorizontal),
      });

      final Set<GridPos> cleared =
          fire(grid, const GridPos(1, 1), const GridPos(2, 1));

      // Row 1 and column 2, whatever orientations the two gems arrived with.
      expect(cleared, hasLength(9));
      for (int i = 0; i < 5; i++) {
        expect(cleared, contains(GridPos(i, 1)));
        expect(cleared, contains(GridPos(2, i)));
      }
      expect(
        combo.prepare(grid, const GridPos(1, 1), const GridPos(2, 1))!.kind,
        ComboKind.cross,
      );
    });

    test('a line gem and a bomb clear three rows and three columns', () {
      final TileGrid grid = boardOf(5, overrides: <GridPos, Tile>{
        const GridPos(2, 2): const Tile(TileColor.ruby, SpecialKind.bomb),
        const GridPos(3, 2): const Tile(TileColor.ruby, SpecialKind.lineHorizontal),
      });

      final Set<GridPos> cleared =
          fire(grid, const GridPos(2, 2), const GridPos(3, 2));

      expect(cleared, hasLength(19));
      for (int x = 0; x < 5; x++) {
        for (final int y in <int>[1, 2, 3]) {
          expect(cleared, contains(GridPos(x, y)));
        }
      }
      for (final int x in <int>[1, 3]) {
        expect(cleared, contains(GridPos(x, 0)));
        expect(cleared, contains(GridPos(x, 4)));
      }
    });

    test('two bombs clear a 5x5, corners included', () {
      final TileGrid grid = boardOf(5, overrides: <GridPos, Tile>{
        const GridPos(2, 2): const Tile(TileColor.ruby, SpecialKind.bomb),
        const GridPos(3, 2): const Tile(TileColor.ruby, SpecialKind.bomb),
      });

      final Set<GridPos> cleared =
          fire(grid, const GridPos(2, 2), const GridPos(3, 2));

      // Centred on (2,2), a 5x5 is the whole board.
      expect(cleared, hasLength(25));
      expect(cleared, contains(const GridPos(0, 0)));
      expect(cleared, contains(const GridPos(4, 4)));
    });

    test('two bombs in a corner clip instead of reaching off the board', () {
      final TileGrid grid = boardOf(5, overrides: <GridPos, Tile>{
        const GridPos(0, 0): const Tile(TileColor.ruby, SpecialKind.bomb),
        const GridPos(1, 0): const Tile(TileColor.ruby, SpecialKind.bomb),
      });

      final Set<GridPos> cleared =
          fire(grid, const GridPos(0, 0), const GridPos(1, 0));

      expect(cleared, hasLength(9));
      expect(cleared, contains(const GridPos(2, 2)));
      expect(cleared, isNot(contains(const GridPos(3, 0))));
    });

    test('a colour bomb on an ordinary gem takes that colour off the board',
        () {
      final TileGrid grid = boardOf(5, overrides: <GridPos, Tile>{
        const GridPos(0, 0): const Tile(TileColor.ruby, SpecialKind.colorBomb),
        const GridPos(1, 0): const Tile(TileColor.amber),
        const GridPos(4, 2): const Tile(TileColor.amber),
        const GridPos(0, 4): const Tile(TileColor.amber),
      });

      final Set<GridPos> cleared =
          fire(grid, const GridPos(0, 0), const GridPos(1, 0));

      expect(cleared, <GridPos>{
        const GridPos(0, 0),
        const GridPos(1, 0),
        const GridPos(4, 2),
        const GridPos(0, 4),
      });
      expect(
        combo.prepare(grid, const GridPos(0, 0), const GridPos(1, 0))!.kind,
        ComboKind.colorPick,
      );
    });

    test('a colour bomb and a line gem turn that colour into line gems', () {
      final TileGrid grid = boardOf(5, overrides: <GridPos, Tile>{
        const GridPos(0, 0): const Tile(TileColor.ruby, SpecialKind.colorBomb),
        const GridPos(1, 0):
            const Tile(TileColor.amber, SpecialKind.lineHorizontal),
        const GridPos(4, 2): const Tile(TileColor.amber),
        const GridPos(0, 4): const Tile(TileColor.amber),
      });

      final Set<GridPos> cleared =
          fire(grid, const GridPos(0, 0), const GridPos(1, 0));

      // Column 1 from (1,0), row 2 from (4,2), row 4 from (0,4), plus the
      // colour bomb's own cell.
      expect(cleared, hasLength(14));
      for (int i = 0; i < 5; i++) {
        expect(cleared, contains(GridPos(1, i)));
        expect(cleared, contains(GridPos(i, 2)));
        expect(cleared, contains(GridPos(i, 4)));
      }
    });

    test('a colour bomb and a bomb turn that colour into bombs', () {
      final TileGrid grid = boardOf(5, overrides: <GridPos, Tile>{
        const GridPos(0, 0): const Tile(TileColor.ruby, SpecialKind.colorBomb),
        const GridPos(1, 0): const Tile(TileColor.amber, SpecialKind.bomb),
        const GridPos(4, 2): const Tile(TileColor.amber),
        const GridPos(0, 4): const Tile(TileColor.amber),
      });

      final Set<GridPos> cleared =
          fire(grid, const GridPos(0, 0), const GridPos(1, 0));

      expect(cleared, hasLength(16));
      expect(cleared, contains(const GridPos(2, 1)));
      expect(cleared, contains(const GridPos(3, 3)));
      expect(cleared, isNot(contains(const GridPos(2, 4))));
    });

    test('two colour bombs take the board', () {
      final TileGrid grid = boardOf(5, overrides: <GridPos, Tile>{
        const GridPos(0, 0): const Tile(TileColor.ruby, SpecialKind.colorBomb),
        const GridPos(1, 0): const Tile(TileColor.amber, SpecialKind.colorBomb),
      });

      final Set<GridPos> cleared =
          fire(grid, const GridPos(0, 0), const GridPos(1, 0));

      expect(cleared, hasLength(25));
      expect(
        combo.prepare(grid, const GridPos(0, 0), const GridPos(1, 0))!.kind,
        ComboKind.wipe,
      );
    });
  });

  group('edges', () {
    test('a hole makes the pair no combo at all', () {
      TileGrid grid = boardOf(5, overrides: <GridPos, Tile>{
        const GridPos(0, 0): const Tile(TileColor.ruby, SpecialKind.colorBomb),
      });
      grid = grid.clearedAt(<GridPos>[const GridPos(1, 0)]);
      expect(
        combo.isComboSwap(grid, const GridPos(0, 0), const GridPos(1, 0)),
        isFalse,
      );
      expect(
        combo.prepare(grid, const GridPos(0, 0), const GridPos(1, 0)),
        isNull,
      );
    });

    test('every combo terminates', () {
      // A board that is nothing but effect gems: the pathological case for a
      // chain that feeds itself.
      const List<SpecialKind> kinds = <SpecialKind>[
        SpecialKind.lineHorizontal,
        SpecialKind.lineVertical,
        SpecialKind.bomb,
        SpecialKind.colorBomb,
      ];
      for (final SpecialKind first in kinds) {
        for (final SpecialKind second in kinds) {
          final TileGrid grid = boardOf(5, overrides: <GridPos, Tile>{
            for (int y = 0; y < 5; y++)
              for (int x = 0; x < 5; x++)
                GridPos(x, y): Tile(TileColor.ruby, kinds[(x + y) % 4]),
            const GridPos(2, 2): Tile(TileColor.ruby, first),
            const GridPos(3, 2): Tile(TileColor.ruby, second),
          });

          final Set<GridPos> cleared =
              fire(grid, const GridPos(2, 2), const GridPos(3, 2));

          expect(cleared.length, lessThanOrEqualTo(25),
              reason: '$first x $second cleared more cells than exist');
          expect(cleared, isNotEmpty, reason: '$first x $second did nothing');
        }
      }
    });
  });
}
