import 'cascade_resolver.dart';
import 'match_detector.dart';
import 'swap_validator.dart';
import 'tile.dart';
import 'tile_grid.dart';
import 'tile_spawner.dart';

enum Match3EventType {
  /// A legal swap was accepted (before the cascade resolves).
  swap,

  /// An attempted swap created no match and was reverted.
  invalidSwap,

  /// One clear step resolved. [value] = tiles cleared, [detail] = cascade level
  /// (1 for the swap's own match, 2+ for chained matches).
  match,

  /// The board had no legal move and was reshuffled.
  shuffle,

  /// The run ended (move limit reached).
  gameOver,
}

/// A discrete model event for the presentation layer (SFX, haptics, juice,
/// analytics). Mirrors `TetrisEvent`.
class Match3Event {
  const Match3Event(this.type, [this.value = 0, this.detail = 0]);

  final Match3EventType type;
  final int value;
  final int detail;
}

/// Pure-domain Match-3 rules engine. Holds the mutable run state and advances it
/// via [swap] (the only player input). No Flutter/Flame dependencies; rendering
/// and gesture handling live in the presentation layer. Events accumulate and
/// are drained by the caller via [drainEvents].
///
/// A run is move-limited by default: each accepted swap consumes one move, and
/// the run ends when [moveLimit] is reached. Mid-run dead ends (no legal swap)
/// are resolved by reshuffling, so the board is always playable until then.
class Match3Engine {
  Match3Engine({
    int? seed,
    this.width = 8,
    this.height = 8,
    int colorCount = 6,
    this.moveLimit = 30,
  })  : assert(width >= 3 && height >= 3, 'board must be at least 3x3'),
        assert(moveLimit == null || moveLimit > 0, 'moveLimit must be > 0'),
        _spawner = TileSpawner(seed: seed, colorCount: colorCount),
        _grid = TileGrid(width: width, height: height) {
    _resolver = CascadeResolver(detector: _detector, spawner: _spawner);
  }

  final int width;
  final int height;

  /// Max accepted swaps before the run ends; null = endless (never ends on its
  /// own, dead ends still reshuffle).
  final int? moveLimit;

  final TileSpawner _spawner;
  final SwapValidator _validator = const SwapValidator();
  final MatchDetector _detector = const MatchDetector();
  late final CascadeResolver _resolver;

  TileGrid _grid;
  int _score = 0;
  int _movesUsed = 0;
  bool _started = false;
  bool _gameOver = false;

  /// Cells cleared by the most recent swap (union across its cascade steps),
  /// with the color each held at clear time — for the view's particle bursts.
  final List<({GridPos pos, TileColor color})> _lastCleared =
      <({GridPos pos, TileColor color})>[];

  final List<Match3Event> _events = <Match3Event>[];

  // ── Public state ──
  TileGrid get grid => _grid;
  int get score => _score;
  int get movesUsed => _movesUsed;
  int? get movesLeft =>
      moveLimit == null ? null : (moveLimit! - _movesUsed).clamp(0, moveLimit!);
  bool get isStarted => _started;
  bool get isGameOver => _gameOver;
  bool get hasActiveGame => _started && !_gameOver;
  int get colorCount => _spawner.colorCount;
  List<({GridPos pos, TileColor color})> get lastCleared =>
      List<({GridPos pos, TileColor color})>.unmodifiable(_lastCleared);

  /// Begins the run: fills a starting board with no pre-existing match and at
  /// least one legal move. Idempotent.
  void start() {
    if (_started) {
      return;
    }
    _started = true;
    _grid = _spawner.fillInitial(width, height);
    _ensurePlayable();
  }

  /// Attempts to swap the tiles at [a] and [b]. Returns true if a legal move was
  /// made (adjacent + creates a match); the cascade is resolved and a move is
  /// consumed. Returns false for a non-adjacent pair (no-op) or an adjacent pair
  /// that makes no match (reverted, emits [Match3EventType.invalidSwap]).
  bool swap(GridPos a, GridPos b) {
    if (!hasActiveGame) {
      return false;
    }
    if (!_validator.isAdjacent(a, b)) {
      return false;
    }
    if (!_validator.producesMatch(_grid, a, b)) {
      _events.add(const Match3Event(Match3EventType.invalidSwap));
      return false;
    }

    _grid = _grid.swapped(a, b);
    _events.add(const Match3Event(Match3EventType.swap));

    final CascadeOutcome outcome = _resolver.resolve(_grid);
    _grid = outcome.grid;
    _score += outcome.totalScore;
    _lastCleared
      ..clear()
      ..addAll(<({GridPos pos, TileColor color})>[
        for (final CascadeStep step in outcome.steps)
          for (final MapEntry<GridPos, TileColor> e
              in step.clearedColors.entries)
            (pos: e.key, color: e.value),
      ]);
    for (final CascadeStep step in outcome.steps) {
      _events.add(Match3Event(
        Match3EventType.match,
        step.cleared.length,
        step.cascadeLevel,
      ));
    }

    _movesUsed += 1;
    _ensurePlayable();

    if (moveLimit != null && _movesUsed >= moveLimit!) {
      _gameOver = true;
      _events.add(const Match3Event(Match3EventType.gameOver));
    }
    return true;
  }

  /// True if any legal swap exists on the current board.
  bool hasPossibleMove() => _findAnyMove() != null;

  /// Returns a hint: one legal (a, b) swap, or null if the board is a dead end.
  (GridPos, GridPos)? findHint() => _findAnyMove();

  /// Drains accumulated events since the last call.
  List<Match3Event> drainEvents() {
    final List<Match3Event> drained = List<Match3Event>.of(_events);
    _events.clear();
    return drained;
  }

  // ── Internals ──

  /// Ensures the board has at least one legal move, reshuffling if not. A reshuffle
  /// re-rolls the whole board (no pre-existing match) and emits a shuffle event.
  void _ensurePlayable() {
    if (hasPossibleMove()) {
      return;
    }
    // Bounded re-roll; with >= 3 colors a playable board is found almost always
    // on the first try, but cap attempts so this can never spin forever.
    for (int attempt = 0; attempt < 64; attempt++) {
      _grid = _spawner.fillInitial(width, height);
      if (hasPossibleMove()) {
        break;
      }
    }
    _events.add(const Match3Event(Match3EventType.shuffle));
  }

  (GridPos, GridPos)? _findAnyMove() {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final GridPos here = GridPos(x, y);
        if (x + 1 < width) {
          final GridPos right = GridPos(x + 1, y);
          if (_validator.producesMatch(_grid, here, right)) {
            return (here, right);
          }
        }
        if (y + 1 < height) {
          final GridPos down = GridPos(x, y + 1);
          if (_validator.producesMatch(_grid, here, down)) {
            return (here, down);
          }
        }
      }
    }
    return null;
  }

  Map<String, Object?> toSnapshot() => <String, Object?>{
        'grid': _grid.toJson(),
        'score': _score,
        'moves_used': _movesUsed,
        'move_limit': moveLimit,
      };

  /// Restores a run from [toSnapshot]. Marks the engine started; ensures the
  /// restored board is playable (reshuffles a dead-end snapshot).
  void restore(Map<String, Object?> json) {
    _started = true;
    _gameOver = false;
    _grid = TileGrid.fromJson(
      (json['grid'] as Map?)?.cast<String, Object?>() ?? <String, Object?>{},
    );
    _score = json['score'] as int? ?? 0;
    _movesUsed = json['moves_used'] as int? ?? 0;
    // A corrupt/partial snapshot grid (holes, or no legal move) is made playable
    // rather than resuming into an unplayable state.
    if (!_grid.isFull) {
      _grid = _spawner.refill(_grid);
    }
    _ensurePlayable();
    if (moveLimit != null && _movesUsed >= moveLimit!) {
      _gameOver = true;
    }
  }
}
