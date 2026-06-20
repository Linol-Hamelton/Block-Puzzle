import 'package:block_puzzle_mobile/domain/match3/tile.dart';
import 'package:block_puzzle_mobile/domain/match3/tile_grid.dart';
import 'package:flutter_test/flutter_test.dart';

const TileColor r = TileColor.ruby;
const TileColor m = TileColor.amber;
const TileColor c = TileColor.citrine;
const TileColor e = TileColor.emerald;

void main() {
  group('TileGrid', () {
    test('at / inBounds respect the rectangle', () {
      final TileGrid grid =
          TileGrid(width: 2, height: 2, cells: <TileColor?>[r, m, c, e]);
      expect(grid.at(0, 0), r);
      expect(grid.at(1, 1), e);
      expect(grid.inBounds(2, 0), isFalse);
      expect(grid.at(2, 0), isNull);
    });

    test('swapped exchanges two cells without mutating the original', () {
      final TileGrid grid =
          TileGrid(width: 2, height: 2, cells: <TileColor?>[r, m, c, e]);
      final TileGrid swapped =
          grid.swapped(const GridPos(0, 0), const GridPos(1, 0));
      expect(swapped.at(0, 0), m);
      expect(swapped.at(1, 0), r);
      // Original is untouched.
      expect(grid.at(0, 0), r);
      expect(grid.at(1, 0), m);
    });

    test('clearedAt nulls the given cells', () {
      final TileGrid grid =
          TileGrid(width: 2, height: 2, cells: <TileColor?>[r, m, c, e]);
      final TileGrid cleared =
          grid.clearedAt(<GridPos>[const GridPos(0, 0), const GridPos(1, 1)]);
      expect(cleared.at(0, 0), isNull);
      expect(cleared.at(1, 1), isNull);
      expect(cleared.at(1, 0), m);
      expect(cleared.isFull, isFalse);
    });

    test('isFull is true only when every cell is set', () {
      expect(
        TileGrid(width: 2, height: 1, cells: <TileColor?>[r, m]).isFull,
        isTrue,
      );
      expect(
        TileGrid(width: 2, height: 1, cells: <TileColor?>[r, null]).isFull,
        isFalse,
      );
    });

    test('toJson / fromJson round-trips', () {
      final TileGrid grid =
          TileGrid(width: 2, height: 2, cells: <TileColor?>[r, null, c, e]);
      final TileGrid restored = TileGrid.fromJson(grid.toJson());
      expect(restored.width, 2);
      expect(restored.height, 2);
      expect(restored.at(0, 0), r);
      expect(restored.at(1, 0), isNull);
      expect(restored.at(0, 1), c);
      expect(restored.at(1, 1), e);
    });
  });
}
