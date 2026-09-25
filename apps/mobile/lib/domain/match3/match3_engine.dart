import 'cascade_resolver.dart';
import 'match3_progression.dart';
import 'match_detector.dart';
import 'special_combo.dart';
import 'swap_validator.dart';
import 'tile.dart';
import 'tile_grid.dart';
import 'tile_spawner.dart';

enum Match3EventType {
  /// A legal swap was accepted (before the cascade resolves).
  swap,

  /// An attempted swap created no match and was reverted.
  invalidSwap,

  /// One clear step resolved. [Match3Event.value] = tiles cleared,
  /// [Match3Event.detail] = cascade level (1 for the swap's own match, 2+ for
  /// chained matches).
  match,

  /// A bonus gem was earned. [Match3Event.special] says which.
  specialSpawned,

  /// Two effect gems were swapped together. [Match3Event.combo] says which
  /// combination fired.
  combo,

  /// A round target was reached. [Match3Event.value] = the round just
  /// completed, [Match3Event.detail] = moves granted for it.
  roundComplete,

  /// The board had no legal move and was reshuffled.
  shuffle,

  /// The run ended (out of moves).
  gameOver,
}

/// A discrete model event for the presentation layer (SFX, haptics, juice,
/// analytics). Mirrors `TetrisEvent`.
class Match3Event {
  const Match3Event(this.type, [this.value = 0, this.detail = 0, this.points = 0])
      : special = null,
        combo = null;

  const Match3Event.spawned(this.special)
      : type = Match3EventType.specialSpawned,
        value = 0,
        detail = 0,
        points = 0,
        combo = null;

  const Match3Event.combined(this.combo)
      : type = Match3EventType.combo,
        value = 0,
        detail = 0,
        points = 0,
        special = null;

  final Match3EventType type;
  final int value;
  final int detail;
  final int points;

  /// Set on [Match3EventType.specialSpawned].
  final SpecialKind? special;

  /// Set on [Match3EventType.combo].
  final ComboKind? combo;
}

/// Pure-domain Match-3 rules engine. Holds the mutable run state and advances it
/// via [swap] (the only player input). No Flutter/Flame dependencies; rendering
/// and gesture handling live in the presentation layer. Events accumulate and
/// are drained by the caller via [drainEvents].
///
/// A run is move-limited: each accepted swap spends one move and the run ends
/// when the budget runs out. The budget is not fixed - completing a round pays
/// out more moves ([Match3Progression]) - so the run lasts exactly as long as
/// the player keeps earning it. Mid-run dead ends (no legal swap) are resolved
/// by reshuffling, so the board is always playable until the moves are gone.
class Match3Engine {
  Match3Engine({
    int? seed,
    this.width = 8,
    this.height = 8,
    int colorCount = 6,
    this.moveLimit = Match3Progression.defaultStartingMoves,
    this.progression = const Match3Progression(),
  })  : assert(width >= 3 && height >= 3, 'board must be at least 3x3'),
        assert(moveLimit == null || moveLimit > 0, 'moveLimit must be > 0'),
        _spawner = TileSpawner(seed: seed, colorCount: colorCount),
        _grid = TileGrid(width: width, height: height) {
    _resolver = CascadeResolver(detector: _detector, spawner: _spawner);
  }

  final int width;
  final int height;

  /// Moves the run opens with; null = endless (never ends on its own, dead ends
  /// still reshuffle). Round payouts are added on top of it.
  final int? moveLimit;

  final Match3Progression progression;

  TileSpawner _spawner;
  final SwapValidator _validator = const SwapValidator();
  final MatchDetector _detector = const MatchDetector();
  final SpecialCombo _combo = const SpecialCombo();
  late CascadeResolver _resolver;

  TileGrid _grid;
  int _score = 0;
  int _movesUsed = 0;
  int _bonusMoves = 0;
  int _round = 1;
  bool _started = false;
  bool _gameOver = false;

  /// Cells cleared by the most recent swap (union across its cascade steps),
  /// with the color each held at clear time — for the view's particle bursts.
  final List<({GridPos pos, TileColor color})> _lastCleared =
      <({GridPos pos, TileColor color})>[];

  final List<Match3Event> _events = <Match3Event>[];

  /// The board the moment the player's swap landed, before anything cleared,
  /// and the steps the cascade then took.
  ///
  /// The engine resolves a whole cascade inside [swap], so by the time the
  /// caller looks, the board is already settled. These two hold the frames in
  /// between so the view can play the cascade out instead of cutting to the
  /// end - four chained matches used to be indistinguishable from one.
  TileGrid? _lastSwapGrid;
  List<CascadeStep> _lastSteps = const <CascadeStep>[];

  // ── Public state ──
  TileGrid get grid => _grid;
  int get score => _score;
  int get movesUsed => _movesUsed;

  /// Moves the run has been granted in total: the opening budget plus every
  /// round payout so far. Null when the run is endless.
  int? get moveBudget => moveLimit == null ? null : moveLimit! + _bonusMoves;

  int? get movesLeft {
    final int? budget = moveBudget;
    return budget == null ? null : (budget - _movesUsed).clamp(0, budget);
  }

  /// The round in progress, 1-based.
  int get round => _round;

  /// Total score that completes the round in progress.
  int get roundTarget => progression.targetForRound(_round);

  /// Score the current round started from.
  int get roundFloor => progression.floorForRound(_round);

  /// How far into the current round the run is, 0..1 — what a HUD bar shows.
  double get roundProgress => progression.progressInRound(_score, _round);

  bool get isStarted => _started;
  bool get isGameOver => _gameOver;
  bool get hasActiveGame => _started && !_gameOver;
  int get colorCount => _spawner.colorCount;
  List<({GridPos pos, TileColor color})> get lastCleared =>
      List<({GridPos pos, TileColor color})>.unmodifiable(_lastCleared);

  /// The board as it stood immediately after the last accepted swap, before
  /// the cascade ran. Null before the first move of a run.
  TileGrid? get lastSwapGrid => _lastSwapGrid;

  /// The steps the last accepted swap resolved into, each carrying the board it
  /// left behind. Empty for a move that cleared nothing.
  List<CascadeStep> get lastSteps =>
      List<CascadeStep>.unmodifiable(_lastSteps);

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
  /// made; the cascade is resolved and a move is spent.
  ///
  /// A move is legal when the exchange creates a match, or when the two gems
  /// combine ([SpecialCombo.isComboSwap]) - two effect gems always do, and a
  /// colour bomb also combines with an ordinary gem. Returns false for a
  /// non-adjacent pair (no-op) or an adjacent pair that does neither (reverted,
  /// emits [Match3EventType.invalidSwap]).
  bool swap(GridPos a, GridPos b) {
    if (!hasActiveGame) {
      return false;
    }
    if (!_validator.isAdjacent(a, b)) {
      return false;
    }

    final TileGrid exchanged = _grid.swapped(a, b);
    final ComboOutcome? combo = _combo.isComboSwap(_grid, a, b)
        ? _combo.prepare(exchanged, a, b)
        : null;
    if (combo == null && !_detector.hasMatch(exchanged)) {
      _events.add(const Match3Event(Match3EventType.invalidSwap));
      return false;
    }

    _grid = combo?.grid ?? exchanged;
    _lastSwapGrid = _grid;
    _events.add(const Match3Event(Match3EventType.swap));
    if (combo != null) {
      _events.add(Match3Event.combined(combo.kind));
    }

    final CascadeOutcome outcome = _resolver.resolve(
      _grid,
      // The gem the player dragged ends up at b, so a bonus their move earned
      // appears there rather than somewhere down the run.
      swapped: b,
      detonate: combo?.trigger,
      colorBombTarget: combo?.colorBombTarget,
    );
    _grid = outcome.grid;
    _lastSteps = outcome.steps;
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
      for (final Tile bonus in step.spawned.values) {
        _events.add(Match3Event.spawned(bonus.special));
      }
    }

    _movesUsed += 1;
    _advanceRounds();
    _ensurePlayable();

    if (movesLeft == 0) {
      _gameOver = true;
      _events.add(const Match3Event(Match3EventType.gameOver));
    }
    return true;
  }

  /// True if any legal move exists on the current board.
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

  /// Pays out every round the current score has reached.
  ///
  /// A loop and not an `if`: one big cascade can cross two thresholds at once,
  /// and the player should be paid for both. It terminates because each round
  /// costs strictly more than the last.
  void _advanceRounds() {
    while (_score >= progression.targetForRound(_round)) {
      final int completed = _round;
      _round += 1;
      _bonusMoves += progression.movesPerRound;
      _events.add(Match3Event(
        Match3EventType.roundComplete,
        completed,
        progression.movesPerRound,
      ));
    }
  }

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

  /// One legal move, or null.
  ///
  /// Combos count as moves here, not just colour matches. A board can hold no
  /// matching swap at all and still be perfectly playable because a colour bomb
  /// is sitting on it - and a re-roll would have destroyed that gem while
  /// calling the board a dead end.
  (GridPos, GridPos)? _findAnyMove() {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final GridPos here = GridPos(x, y);
        if (x + 1 < width) {
          final GridPos right = GridPos(x + 1, y);
          if (_combo.isComboSwap(_grid, here, right) ||
              _validator.producesMatch(_grid, here, right)) {
            return (here, right);
          }
        }
        if (y + 1 < height) {
          final GridPos down = GridPos(x, y + 1);
          if (_combo.isComboSwap(_grid, here, down) ||
              _validator.producesMatch(_grid, here, down)) {
            return (here, down);
          }
        }
      }
    }
    return null;
  }

  /// Version of the snapshot format.
  ///
  /// 1: grid and counters only, with the spawner restarted on restore.
  /// 2: carries the spawner, so refills continue the same sequence.
  /// 3: carries the round and the moves earned by finishing rounds.
  static const int snapshotVersion = 3;

  /// Serializes the live run for resume-after-kill.
  ///
  /// The spawner state is part of it. Without it the board was restored but the
  /// generator was not, so the same legal swap resolved into a different board
  /// before and after a resume - the cascade refilled from a fresh sequence.
  Map<String, Object?> toSnapshot() => <String, Object?>{
        'version': snapshotVersion,
        'grid': _grid.toJson(),
        'score': _score,
        'moves_used': _movesUsed,
        'move_limit': moveLimit,
        'bonus_moves': _bonusMoves,
        'round': _round,
        'spawner': _spawner.toJson(),
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
    // A snapshot written before rounds existed carries neither field. The round
    // follows from the score, and the payout follows from the round, so such a
    // run resumes where it actually stands instead of back at round one with a
    // budget it has already spent.
    final Object? storedRound = json['round'];
    _round = storedRound is int && storedRound >= 1
        ? storedRound
        : progression.roundForScore(_score);
    final Object? storedBonus = json['bonus_moves'];
    _bonusMoves = storedBonus is int && storedBonus >= 0
        ? storedBonus
        : (_round - 1) * progression.movesPerRound;
    // Restore the spawner before anything can refill. A version 1 snapshot has
    // no 'spawner' and fromJson returns a fresh one, so such a run resumes with
    // a restarted sequence exactly as it did before rather than failing to load.
    final Object? rawSpawner = json['spawner'];
    _spawner = TileSpawner.fromJson(
      rawSpawner is Map ? rawSpawner.cast<String, Object?>() : null,
      colorCount: _spawner.colorCount,
    );
    _resolver = CascadeResolver(detector: _detector, spawner: _spawner);
    // A corrupt/partial snapshot grid (holes, or no legal move) is made playable
    // rather than resuming into an unplayable state.
    if (!_grid.isFull) {
      _grid = _spawner.refill(_grid);
    }
    _ensurePlayable();
    if (movesLeft == 0) {
      _gameOver = true;
    }
  }
}
