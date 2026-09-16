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

/// A set of runs that touch each other, treated as one shape.
///
/// A plain match is a single run. An L or a T is two runs - one horizontal, one
/// vertical - sharing a cell, and it has to be recognised as one shape or the
/// player sees two ordinary matches where the genre has taught them to expect a
/// bonus.
class MatchGroup {
  MatchGroup({
    required this.runs,
    required this.cells,
    required this.color,
  });

  final List<TileMatch> runs;
  final Set<GridPos> cells;
  final TileColor color;

  /// Cells where a horizontal and a vertical run cross.
  List<GridPos> get intersections {
    final List<GridPos> crossings = <GridPos>[];
    for (final TileMatch h in runs.where((TileMatch r) => r.horizontal)) {
      for (final TileMatch v in runs.where((TileMatch r) => !r.horizontal)) {
        for (final GridPos p in h.cells) {
          if (v.cells.contains(p)) {
            crossings.add(p);
          }
        }
      }
    }
    return crossings;
  }

  TileMatch get longestRun =>
      runs.reduce((TileMatch a, TileMatch b) => b.length > a.length ? b : a);

  /// What this shape awards, by the conventions the genre has trained players
  /// on: five in a line is the strongest, a crossing beats a four, and a four
  /// beats a three.
  ///
  /// The order of these tests is the rule, not an implementation detail. A run
  /// of five that also has a crossing arm is a bigger shape than either on its
  /// own, so it must not pay out *less* than the plain five would - checking
  /// the crossing first would have handed the rarer shape the weaker gem.
  SpecialKind get reward {
    final int longest = longestRun.length;
    if (longest >= 5) {
      return SpecialKind.colorBomb;
    }
    if (intersections.isNotEmpty) {
      return SpecialKind.bomb;
    }
    if (longest == 4) {
      return longestRun.horizontal
          ? SpecialKind.lineHorizontal
          : SpecialKind.lineVertical;
    }
    return SpecialKind.none;
  }

  /// Where the bonus gem appears.
  ///
  /// Under the player's finger when possible - [swapped] is the cell they moved
  /// - because a gem that materialises somewhere else reads as a glitch. Failing
  /// that, the crossing of an L or T, and otherwise the middle of the run.
  GridPos spawnPosition({GridPos? swapped}) {
    if (swapped != null && cells.contains(swapped)) {
      return swapped;
    }
    final List<GridPos> crossings = intersections;
    if (crossings.isNotEmpty) {
      return crossings.first;
    }
    final List<GridPos> line = longestRun.cells;
    return line[line.length ~/ 2];
  }
}

/// Groups runs into shapes and works out what each one awards.
extension MatchGrouping on MatchDetector {
  /// Runs that share a cell become one [MatchGroup].
  List<MatchGroup> findGroups(TileGrid grid) {
    final List<TileMatch> runs = findMatches(grid);
    final List<MatchGroup> groups = <MatchGroup>[];

    for (final TileMatch run in runs) {
      MatchGroup? host;
      for (final MatchGroup candidate in groups) {
        if (candidate.color != run.color) {
          continue;
        }
        if (run.cells.any(candidate.cells.contains)) {
          host = candidate;
          break;
        }
      }
      if (host == null) {
        groups.add(MatchGroup(
          runs: <TileMatch>[run],
          cells: run.cells.toSet(),
          color: run.color,
        ));
        continue;
      }
      host.runs.add(run);
      host.cells.addAll(run.cells);
    }

    // A third run can bridge two groups that were separate when it was added,
    // so merge until nothing else touches. Boards are small; this settles in a
    // pass or two.
    bool merged = true;
    while (merged) {
      merged = false;
      for (int i = 0; i < groups.length && !merged; i++) {
        for (int j = i + 1; j < groups.length && !merged; j++) {
          if (groups[i].color != groups[j].color) {
            continue;
          }
          if (!groups[i].cells.any(groups[j].cells.contains)) {
            continue;
          }
          groups[i].runs.addAll(groups[j].runs);
          groups[i].cells.addAll(groups[j].cells);
          groups.removeAt(j);
          merged = true;
        }
      }
    }

    return groups;
  }
}
