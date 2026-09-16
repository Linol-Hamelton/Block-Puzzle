import 'match3_scoring.dart';
import 'match_detector.dart';
import 'special_resolver.dart';
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
    required this.boardAfter,
    this.spawned = const <GridPos, Tile>{},
    this.triggered = const <SpecialKind>[],
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

  /// Bonus gems this step earned, at the cell each one occupies afterwards.
  /// These positions are in [cleared] too: the shape is removed and the gem
  /// takes its place.
  final Map<GridPos, Tile> spawned;

  /// Effects that fired this step, in the order they went off.
  final List<SpecialKind> triggered;

  /// The settled board at the end of this step: cleared, bonus written in,
  /// gravity applied, holes refilled.
  ///
  /// The resolver runs the whole cascade in one call, so without this the view
  /// only ever saw the final board and a four-step chain looked exactly like a
  /// single match. Keeping the intermediate boards is what lets the cascade be
  /// played back one step at a time instead of asserted in a caption.
  final TileGrid boardAfter;
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

  /// Every bonus gem the move created, oldest step first.
  List<Tile> get totalSpawned => <Tile>[
        for (final CascadeStep s in steps) ...s.spawned.values,
      ];
}

/// Drives the clear → gravity → refill → re-detect loop until the board is
/// stable. This is the deterministic heart of Match-3; it is validated by
/// table-driven unit tests before any animation work.
class CascadeResolver {
  CascadeResolver({
    MatchDetector detector = const MatchDetector(),
    SpecialResolver specials = const SpecialResolver(),
    required TileSpawner spawner,
  })  : _detector = detector,
        _specials = specials,
        _spawner = spawner;

  final MatchDetector _detector;
  final SpecialResolver _specials;
  final TileSpawner _spawner;

  /// Resolves [grid] fully, returning the settled board and a per-step record.
  ///
  /// [swapped] is the cell the player moved into, so a bonus earned by their
  /// move appears under their finger instead of somewhere down the run.
  ///
  /// [detonate] seeds the first step with a blast that owes nothing to a match
  /// - the combo produced by swapping two effect gems. When it is given, level
  /// one clears those cells and whatever they set off, and the ordinary
  /// match-driven loop takes over from level two.
  CascadeOutcome resolve(
    TileGrid grid, {
    GridPos? swapped,
    Iterable<GridPos>? detonate,
    TileColor? colorBombTarget,
  }) {
    final List<CascadeStep> steps = <CascadeStep>[];
    TileGrid current = grid;
    int level = 0;
    Iterable<GridPos>? seeded = detonate;

    while (true) {
      Set<GridPos> matched;
      List<MatchGroup> groups = const <MatchGroup>[];
      int longestRun = 0;
      TileColor? target;

      if (seeded != null) {
        matched = seeded.where((GridPos p) => grid.inBounds(p.x, p.y)).toSet();
        target = colorBombTarget;
        seeded = null;
        if (matched.isEmpty) {
          break;
        }
      } else {
        groups = _detector.findGroups(current);
        if (groups.isEmpty) {
          break;
        }
        matched = <GridPos>{
          for (final MatchGroup group in groups) ...group.cells,
        };
        for (final MatchGroup group in groups) {
          final int run = group.longestRun.length;
          if (run > longestRun) {
            longestRun = run;
          }
        }
      }

      level += 1;

      // What each shape earned. Worked out before the clear, because the reward
      // depends on the shape and the shape is about to stop existing.
      final Map<GridPos, Tile> spawned = <GridPos, Tile>{};
      for (final MatchGroup group in groups) {
        final SpecialKind reward = group.reward;
        if (reward == SpecialKind.none) {
          continue;
        }
        final GridPos at =
            group.spawnPosition(swapped: level == 1 ? swapped : null);
        spawned[at] = Tile(group.color, reward);
      }

      // Effects among the matched cells go off, and their effects go off, all
      // through one queue so a cell is cleared once however many reach it.
      final DetonationResult blast = _specials.resolve(
        current,
        matched,
        colorBombTarget: target,
      );
      final Set<GridPos> cleared = blast.cells;

      final Map<GridPos, TileColor> clearedColors = <GridPos, TileColor>{
        for (final GridPos p in cleared)
          if (current.atPos(p) != null) p: current.atPos(p)!,
      };

      final int gained = Match3Scoring.clearScore(
        clearedCount: cleared.length,
        longestRun: longestRun,
        cascadeLevel: level,
        specialsTriggered: blast.triggered.length,
      );

      current = current.clearedAt(cleared);
      // The bonus gem takes the place of the cell that earned it, after that
      // cell has been cleared. It then falls with the board like any other
      // tile, which is why it is written before gravity and not after.
      for (final MapEntry<GridPos, Tile> entry in spawned.entries) {
        current = current.withCell(entry.key.x, entry.key.y, entry.value);
      }
      current = applyGravity(current);
      current = _spawner.refill(current);

      steps.add(CascadeStep(
        cleared: cleared,
        clearedColors: clearedColors,
        cascadeLevel: level,
        longestRun: longestRun,
        gained: gained,
        spawned: spawned,
        triggered: blast.triggered,
        boardAfter: current,
      ));
    }

    return CascadeOutcome(grid: current, steps: steps);
  }

  /// Collapses each column so non-null tiles fall to the bottom, leaving the
  /// holes at the top (to be refilled). Stable within a column (preserves order).
  TileGrid applyGravity(TileGrid grid) {
    final List<Tile?> next =
        List<Tile?>.filled(grid.width * grid.height, null);
    int index(int x, int y) => (y * grid.width) + x;
    for (int x = 0; x < grid.width; x++) {
      int writeY = grid.height - 1;
      for (int y = grid.height - 1; y >= 0; y--) {
        // Gravity carries the whole tile, so a special that survives a clear
        // falls with its effect intact rather than landing as a plain gem.
        final Tile? c = grid.tileAt(x, y);
        if (c != null) {
          next[index(x, writeY)] = c;
          writeY -= 1;
        }
      }
    }
    return TileGrid(width: grid.width, height: grid.height, cells: next);
  }
}
