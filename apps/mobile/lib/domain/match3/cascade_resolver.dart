import 'match3_scoring.dart';
import 'match_detector.dart';
import 'tile.dart';
import 'tile_grid.dart';
import 'tile_spawner.dart';

/// One step of a cascade: the cells cleared, plus the metadata the presentation
/// and scoring layers need.
class CascadeStep {
  const CascadeStep({
    required this.cleared,
    required this.clearedColors,
    required this.cascadeLevel,
    required this.longestRun,
    required this.gained,
  });

  /// Cells removed in this step (pre-gravity positions).
  final Set<GridPos> cleared;

  /// Color of each cleared cell, captured before removal (so the presentation
  /// layer can spawn matching-colored particles after the board has settled).
  final Map<GridPos, TileColor> clearedColors;

  /// 1 for the swap's own match, 2 for the first chained match, etc.
  final int cascadeLevel;

  /// Length of the longest single run cleared this step.
  final int longestRun;

  /// Points awarded for this step.
  final int gained;
}

/// The full result of resolving a board to a stable (match-free) state.
class CascadeOutcome {
  const CascadeOutcome({required this.grid, required this.steps});

  /// The settled board (guaranteed match-free; no nulls if the input was full).
  final TileGrid grid;

  /// The cascade steps in order; empty if the input had no matches.
  final List<CascadeStep> steps;

  bool get hadMatch => steps.isNotEmpty;
  int get cascadeCount => steps.length;
  int get totalCleared =>
      steps.fold(0, (int sum, CascadeStep s) => sum + s.cleared.length);
  int get totalScore => steps.fold(0, (int sum, CascadeStep s) => sum + s.gained);
}

/// Drives the clear → gravity → refill → re-detect loop until the board is
/// stable. This is the deterministic heart of Match-3; it is validated by
/// table-driven unit tests before any animation work.
class CascadeResolver {
  CascadeResolver({
    MatchDetector detector = const MatchDetector(),
    required TileSpawner spawner,
  })  : _detector = detector,
        _spawner = spawner;

  final MatchDetector _detector;
  final TileSpawner _spawner;

  /// Resolves [grid] fully, returning the settled board and a per-step record.
  CascadeOutcome resolve(TileGrid grid) {
    final List<CascadeStep> steps = <CascadeStep>[];
    TileGrid current = grid;
    int level = 0;

    while (true) {
      final List<TileMatch> matches = _detector.findMatches(current);
      if (matches.isEmpty) {
        break;
      }
      level += 1;

      final Set<GridPos> cleared = <GridPos>{};
      int longestRun = 0;
      for (final TileMatch m in matches) {
        cleared.addAll(m.cells);
        if (m.length > longestRun) {
          longestRun = m.length;
        }
      }
      final Map<GridPos, TileColor> clearedColors = <GridPos, TileColor>{
        for (final GridPos p in cleared)
          if (current.atPos(p) != null) p: current.atPos(p)!,
      };

      final int gained = Match3Scoring.clearScore(
        clearedCount: cleared.length,
        longestRun: longestRun,
        cascadeLevel: level,
      );

      steps.add(CascadeStep(
        cleared: cleared,
        clearedColors: clearedColors,
        cascadeLevel: level,
        longestRun: longestRun,
        gained: gained,
      ));

      current = current.clearedAt(cleared);
      current = applyGravity(current);
      current = _spawner.refill(current);
    }

    return CascadeOutcome(grid: current, steps: steps);
  }

  /// Collapses each column so non-null tiles fall to the bottom, leaving the
  /// holes at the top (to be refilled). Stable within a column (preserves order).
  TileGrid applyGravity(TileGrid grid) {
    final List<TileColor?> next =
        List<TileColor?>.filled(grid.width * grid.height, null);
    int index(int x, int y) => (y * grid.width) + x;
    for (int x = 0; x < grid.width; x++) {
      int writeY = grid.height - 1;
      for (int y = grid.height - 1; y >= 0; y--) {
        final TileColor? c = grid.at(x, y);
        if (c != null) {
          next[index(x, writeY)] = c;
          writeY -= 1;
        }
      }
    }
    return TileGrid(width: grid.width, height: grid.height, cells: next);
  }
}
