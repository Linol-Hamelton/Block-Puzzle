import 'package:block_puzzle_mobile/domain/match3/swap_validator.dart';
import 'package:block_puzzle_mobile/domain/match3/tile.dart';
import 'package:block_puzzle_mobile/domain/match3/tile_grid.dart';
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
  const SwapValidator validator = SwapValidator();

  group('SwapValidator.isAdjacent', () {
    test('orthogonal neighbors are adjacent', () {
      expect(validator.isAdjacent(const GridPos(0, 0), const GridPos(1, 0)),
          isTrue);
      expect(validator.isAdjacent(const GridPos(0, 0), const GridPos(0, 1)),
          isTrue);
    });

    test('diagonal, same, and distant cells are not adjacent', () {
      expect(validator.isAdjacent(const GridPos(0, 0), const GridPos(1, 1)),
          isFalse);
      expect(validator.isAdjacent(const GridPos(0, 0), const GridPos(0, 0)),
          isFalse);
      expect(validator.isAdjacent(const GridPos(0, 0), const GridPos(2, 0)),
          isFalse);
    });
  });

  group('SwapValidator.producesMatch', () {
    // No pre-existing match; swapping (2,0)<->(2,1) completes row 0 into r,r,r.
    final TileGrid grid = g(<List<TileColor>>[
      <TileColor>[r, r, m],
      <TileColor>[c, m, r],
      <TileColor>[m, c, e],
    ]);

    test('true when the swap completes a run', () {
      expect(
        validator.producesMatch(grid, const GridPos(2, 0), const GridPos(2, 1)),
        isTrue,
      );
      expect(
        validator.isLegalSwap(grid, const GridPos(2, 0), const GridPos(2, 1)),
        isTrue,
      );
    });

    test('false when the swap creates no run', () {
      expect(
        validator.producesMatch(grid, const GridPos(0, 0), const GridPos(1, 0)),
        isFalse,
      );
    });

    test('a non-adjacent match-producing pair is not a legal swap', () {
      // (2,1) holds r; (0,0)/(1,0) are r — but they are not adjacent to it.
      expect(
        validator.isLegalSwap(grid, const GridPos(0, 0), const GridPos(2, 1)),
        isFalse,
      );
    });
  });
}
