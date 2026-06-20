import 'tile.dart';
import 'tile_grid.dart';

/// A single straight run of 3+ same-color tiles, horizontal or vertical.
/// Overlapping runs (the arms of an L/T shape) are reported as separate matches;
/// use [MatchDetector.matchedCells] for the de-duplicated set to clear.
class TileMatch {
  const TileMatch({
    required this.cells,
    required this.color,
    required this.horizontal,
  });

  final List<GridPos> cells;
  final TileColor color;
  final bool horizontal;

  int get length => cells.length;
}

/// Finds maximal straight runs of 3+ identical tiles in a [TileGrid]. Pure and
/// allocation-light; the cascade resolver calls this repeatedly per move.
class MatchDetector {
  const MatchDetector();

  /// All horizontal and vertical runs of length >= 3. Nulls never match.
  List<TileMatch> findMatches(TileGrid grid) {
    final List<TileMatch> matches = <TileMatch>[];

    // Horizontal runs.
    for (int y = 0; y < grid.height; y++) {
      int runStart = 0;
      for (int x = 1; x <= grid.width; x++) {
        final TileColor? prev = grid.at(x - 1, y);
        final TileColor? cur = x < grid.width ? grid.at(x, y) : null;
        final bool sameRun = cur != null && cur == prev;
        if (!sameRun) {
          final int runLen = x - runStart;
          if (prev != null && runLen >= 3) {
            matches.add(TileMatch(
              color: prev,
              horizontal: true,
              cells: <GridPos>[
                for (int rx = runStart; rx < x; rx++) GridPos(rx, y),
              ],
            ));
          }
          runStart = x;
        }
      }
    }

    // Vertical runs.
    for (int x = 0; x < grid.width; x++) {
      int runStart = 0;
      for (int y = 1; y <= grid.height; y++) {
        final TileColor? prev = grid.at(x, y - 1);
        final TileColor? cur = y < grid.height ? grid.at(x, y) : null;
        final bool sameRun = cur != null && cur == prev;
        if (!sameRun) {
          final int runLen = y - runStart;
          if (prev != null && runLen >= 3) {
            matches.add(TileMatch(
              color: prev,
              horizontal: false,
              cells: <GridPos>[
                for (int ry = runStart; ry < y; ry++) GridPos(x, ry),
              ],
            ));
          }
          runStart = y;
        }
      }
    }

    return matches;
  }

  /// The de-duplicated set of all matched cells (union of every run), which is
  /// what actually gets cleared.
  Set<GridPos> matchedCells(TileGrid grid) {
    final Set<GridPos> cells = <GridPos>{};
    for (final TileMatch m in findMatches(grid)) {
      cells.addAll(m.cells);
    }
    return cells;
  }

  /// Cheap existence check (used by swap validation and no-moves detection).
  bool hasMatch(TileGrid grid) {
    // Horizontal.
    for (int y = 0; y < grid.height; y++) {
      int run = 1;
      for (int x = 1; x < grid.width; x++) {
        final TileColor? cur = grid.at(x, y);
        if (cur != null && cur == grid.at(x - 1, y)) {
          if (++run >= 3) {
            return true;
          }
        } else {
          run = 1;
        }
      }
    }
    // Vertical.
    for (int x = 0; x < grid.width; x++) {
      int run = 1;
      for (int y = 1; y < grid.height; y++) {
        final TileColor? cur = grid.at(x, y);
        if (cur != null && cur == grid.at(x, y - 1)) {
          if (++run >= 3) {
            return true;
          }
        } else {
          run = 1;
        }
      }
    }
    return false;
  }
}
