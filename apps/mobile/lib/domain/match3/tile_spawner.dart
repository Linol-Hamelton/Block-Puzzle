import 'dart:math';

import 'tile.dart';
import 'tile_grid.dart';

/// Produces tiles for the initial board and for refilling after a cascade.
/// Seeded for deterministic boards (daily challenge / replay) and unit tests.
class TileSpawner {
  TileSpawner({int? seed, int colorCount = 6})
      : assert(colorCount >= 3 && colorCount <= TileColor.values.length,
            'colorCount must be in 3..${TileColor.values.length}'),
        _random = Random(seed),
        _colors = TileColor.values.sublist(0, colorCount);

  final Random _random;
  final List<TileColor> _colors;

  int get colorCount => _colors.length;

  /// A uniformly-random color from the active palette.
  TileColor next() => _colors[_random.nextInt(_colors.length)];

  /// Builds a starting board with **no pre-existing match**: each cell avoids a
  /// color that would complete a run of three with its already-placed left or
  /// top neighbors. (Solvability — that a legal move exists — is enforced by the
  /// engine, which reshuffles if the fresh board is a dead end.)
  TileGrid fillInitial(int width, int height) {
    final List<TileColor?> cells = List<TileColor?>.filled(width * height, null);
    int index(int x, int y) => (y * width) + x;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final TileColor? left2 = x >= 2 ? cells[index(x - 1, y)] : null;
        final TileColor? leftMatch =
            (x >= 2 && cells[index(x - 1, y)] == cells[index(x - 2, y)])
                ? left2
                : null;
        final TileColor? upMatch =
            (y >= 2 && cells[index(x, y - 1)] == cells[index(x, y - 2)])
                ? cells[index(x, y - 1)]
                : null;
        TileColor color = next();
        // Reroll until it doesn't extend a pair into a triple. The palette has
        // >= 3 colors, so a valid choice always exists.
        while (color == leftMatch || color == upMatch) {
          color = next();
        }
        cells[index(x, y)] = color;
      }
    }
    return TileGrid(width: width, height: height, cells: cells);
  }

  /// Fills every null cell of [grid] (the holes left after gravity) with fresh
  /// random tiles. New matches are allowed — they drive the cascade.
  TileGrid refill(TileGrid grid) {
    TileGrid result = grid;
    for (int y = 0; y < grid.height; y++) {
      for (int x = 0; x < grid.width; x++) {
        if (result.at(x, y) == null) {
          result = result.withCell(x, y, next());
        }
      }
    }
    return result;
  }
}
