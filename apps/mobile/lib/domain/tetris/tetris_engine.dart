import 'falling_piece.dart';
import 'seven_bag_randomizer.dart';
import 'srs_rotation.dart';
import 'tetris_board.dart';
import 'tetris_scoring.dart';
import 'tetromino.dart';

enum TetrisInput {
  moveLeft,
  moveRight,
  softDrop,
  hardDrop,
  rotateCw,
  rotateCcw,
  hold,
}

enum TetrisEventType {
  spawn,
  move,
  rotate,
  softDrop,
  hardDrop,
  lock,
  lineClear,
  levelUp,
  hold,
  gameOver,
}

/// A discrete model event for the presentation/feedback layer to react to
/// (SFX, haptics, animation, analytics). [value] carries event-specific data:
/// cleared rows for [TetrisEventType.lineClear], new level for
/// [TetrisEventType.levelUp], dropped cells for [TetrisEventType.hardDrop].
class TetrisEvent {
  const TetrisEvent(this.type, [this.value = 0]);

  final TetrisEventType type;
  final int value;
}

/// Pure-domain Tetris rules engine. Holds the mutable run state and advances it
/// via [applyInput] (discrete intents) and [tick] (gravity + lock delay). No
/// Flutter/Flame dependencies; rendering and input UI live in the presentation
/// layer and drive this. Events are accumulated and drained by the caller via
/// [drainEvents].
class TetrisEngine {
  TetrisEngine({
    int? seed,
    int width = 10,
    int height = 20,
    int nextPreviewCount = 5,
    Duration lockDelay = const Duration(milliseconds: 500),
    int lockResetCap = 15,
  })  : _board = TetrisBoard(width: width, height: height),
        _bag = SevenBagRandomizer(seed: seed),
        _nextPreviewCount = nextPreviewCount,
        _lockDelayMs = lockDelay.inMilliseconds,
        _lockResetCap = lockResetCap;

  TetrisBoard _board;
  final SevenBagRandomizer _bag;
  final int _nextPreviewCount;
  final int _lockDelayMs;
  final int _lockResetCap;

  FallingPiece? _active;
  TetrominoType? _hold;
  bool _canHold = true;

  int _score = 0;
  int _linesCleared = 0;
  int _level = 1;
  int _combo = -1; // -1 = no active combo; 0 on first clearing placement
  bool _backToBack = false;
  bool _gameOver = false;
  bool _started = false;

  int _gravityAccumMs = 0;
  int _lockAccumMs = 0;
  int _lockResets = 0;
  bool _lastActionWasRotation = false;

  final List<TetrisEvent> _events = <TetrisEvent>[];

  // ── Public state ──
  TetrisBoard get board => _board;
  FallingPiece? get active => _active;
  TetrominoType? get hold => _hold;
  int get score => _score;
  int get linesCleared => _linesCleared;
  int get level => _level;
  bool get isGameOver => _gameOver;
  bool get isStarted => _started;
  bool get hasActiveGame => _started && !_gameOver && _active != null;

  List<TetrominoType> get nextQueue => _bag.peek(_nextPreviewCount);

  /// The active piece projected to its landing position (for the ghost render).
  FallingPiece? get ghost {
    final FallingPiece? piece = _active;
    if (piece == null) {
      return null;
    }
    return piece.movedBy(0, _board.dropDistance(piece));
  }

  /// Begins the run: queues the first piece. Idempotent.
  void start() {
    if (_started) {
      return;
    }
    _started = true;
    _spawnNext();
  }

  /// Drains accumulated events since the last call.
  List<TetrisEvent> drainEvents() {
    final List<TetrisEvent> drained = List<TetrisEvent>.of(_events);
    _events.clear();
    return drained;
  }

  void applyInput(TetrisInput input) {
    if (_gameOver || _active == null) {
      return;
    }
    switch (input) {
      case TetrisInput.moveLeft:
        _tryMove(-1, 0);
        break;
      case TetrisInput.moveRight:
        _tryMove(1, 0);
        break;
      case TetrisInput.softDrop:
        if (_tryMove(0, 1)) {
          _score += TetrisScoring.softDropScore(1);
          _events.add(const TetrisEvent(TetrisEventType.softDrop));
          _gravityAccumMs = 0;
        }
        break;
      case TetrisInput.hardDrop:
        _hardDrop();
        break;
      case TetrisInput.rotateCw:
        _tryRotate(1);
        break;
      case TetrisInput.rotateCcw:
        _tryRotate(-1);
        break;
      case TetrisInput.hold:
        _holdPiece();
        break;
    }
  }

  /// Advances gravity and lock-delay timers by [delta].
  void tick(Duration delta) {
    if (_gameOver || !_started || _active == null) {
      return;
    }
    final int ms = delta.inMilliseconds;
    if (ms <= 0) {
      return;
    }

    final int intervalMs = TetrisScoring.gravityInterval(_level).inMilliseconds;
    _gravityAccumMs += ms;
    while (_gravityAccumMs >= intervalMs) {
      _gravityAccumMs -= intervalMs;
      if (!_tryMove(0, 1)) {
        break;
      }
    }

    if (_isGrounded()) {
      _lockAccumMs += ms;
      if (_lockAccumMs >= _lockDelayMs) {
        _lockActivePiece();
      }
    } else {
      _lockAccumMs = 0;
    }
  }

  // ── Internals ──

  bool _isGrounded() {
    final FallingPiece? piece = _active;
    if (piece == null) {
      return false;
    }
    return _board.collides(piece.movedBy(0, 1));
  }

  bool _tryMove(int dx, int dy) {
    final FallingPiece? piece = _active;
    if (piece == null) {
      return false;
    }
    final FallingPiece moved = piece.movedBy(dx, dy);
    if (_board.collides(moved)) {
      return false;
    }
    _active = moved;
    _lastActionWasRotation = false;
    if (dx != 0) {
      _events.add(const TetrisEvent(TetrisEventType.move));
    }
    _onPieceShifted();
    return true;
  }

  bool _tryRotate(int direction) {
    final FallingPiece? piece = _active;
    if (piece == null) {
      return false;
    }
    final int from = piece.rotationIndex;
    final int to = (from + direction) & 3;
    final List<KickOffset> kicks = SrsRotation.kicksFor(piece.type, from, to);
    for (final KickOffset kick in kicks) {
      final FallingPiece candidate =
          piece.withRotation(to).movedBy(kick.x, kick.y);
      if (!_board.collides(candidate)) {
        _active = candidate;
        _lastActionWasRotation = true;
        _events.add(const TetrisEvent(TetrisEventType.rotate));
        _onPieceShifted();
        return true;
      }
    }
    return false;
  }

  /// Resets the lock-delay timer when the piece is moved/rotated while grounded,
  /// up to [_lockResetCap] times (guideline "infinity with cap").
  void _onPieceShifted() {
    if (_isGrounded() && _lockResets < _lockResetCap) {
      _lockAccumMs = 0;
      _lockResets += 1;
    }
  }

  void _hardDrop() {
    final FallingPiece? piece = _active;
    if (piece == null) {
      return;
    }
    final int distance = _board.dropDistance(piece);
    if (distance > 0) {
      _active = piece.movedBy(0, distance);
      _score += TetrisScoring.hardDropScore(distance);
    }
    _lastActionWasRotation = false;
    _events.add(TetrisEvent(TetrisEventType.hardDrop, distance));
    _lockActivePiece();
  }

  void _lockActivePiece() {
    final FallingPiece? piece = _active;
    if (piece == null) {
      return;
    }

    final TSpinType spin =
        (piece.type == TetrominoType.t && _lastActionWasRotation)
            ? _detectTSpin(piece)
            : TSpinType.none;

    // Top-out: a piece that locks entirely above the visible field ends the run.
    final bool anyVisible =
        piece.absoluteCells().any((TCell c) => c.y >= 0);
    _board = _board.lock(piece);
    _events.add(const TetrisEvent(TetrisEventType.lock));
    _active = null;

    if (!anyVisible) {
      _endGame();
      return;
    }

    final LineClearOutcome outcome = _board.clearFullRows();
    _board = outcome.board;
    _applyScoring(outcome.clearedRows, spin);

    _canHold = true;
    _spawnNext();
  }

  void _applyScoring(int rows, TSpinType spin) {
    _score += TetrisScoring.actionScore(
      rows: rows,
      level: _level,
      spin: spin,
      backToBack:
          _backToBack && TetrisScoring.isDifficult(rows: rows, spin: spin),
    );

    if (rows <= 0) {
      _combo = -1; // combo breaks on a non-clearing placement
      return;
    }

    _combo += 1;
    if (_combo > 0) {
      _score += TetrisScoring.comboScore(combo: _combo, level: _level);
    }
    _backToBack = TetrisScoring.isDifficult(rows: rows, spin: spin);

    final int previousLevel = _level;
    _linesCleared += rows;
    _level = TetrisScoring.levelForLines(_linesCleared);
    _events.add(TetrisEvent(TetrisEventType.lineClear, rows));
    if (_level != previousLevel) {
      _events.add(TetrisEvent(TetrisEventType.levelUp, _level));
    }
  }

  TSpinType _detectTSpin(FallingPiece piece) {
    final int cx = piece.originX + 1;
    final int cy = piece.originY + 1;
    bool filled(int x, int y) {
      if (x < 0 || x >= _board.width || y >= _board.height) {
        return true; // walls and floor count as filled
      }
      if (y < 0) {
        return false; // open space above the field
      }
      return _board.cellAt(x, y) != null;
    }

    final bool tl = filled(cx - 1, cy - 1);
    final bool tr = filled(cx + 1, cy - 1);
    final bool bl = filled(cx - 1, cy + 1);
    final bool br = filled(cx + 1, cy + 1);
    final int count =
        (tl ? 1 : 0) + (tr ? 1 : 0) + (bl ? 1 : 0) + (br ? 1 : 0);
    if (count < 3) {
      return TSpinType.none;
    }
    final (bool, bool) front = switch (piece.rotationIndex & 3) {
      0 => (tl, tr), // T points up
      1 => (tr, br), // right
      2 => (bl, br), // down
      _ => (tl, bl), // left
    };
    return (front.$1 && front.$2) ? TSpinType.full : TSpinType.mini;
  }

  void _holdPiece() {
    final FallingPiece? piece = _active;
    if (piece == null || !_canHold) {
      return;
    }
    final TetrominoType current = piece.type;
    final TetrominoType spawnType;
    if (_hold == null) {
      _hold = current;
      spawnType = _bag.next();
    } else {
      spawnType = _hold!;
      _hold = current;
    }
    _canHold = false;
    _events.add(const TetrisEvent(TetrisEventType.hold));
    _spawnPiece(spawnType);
  }

  void _spawnNext() {
    _spawnPiece(_bag.next());
  }

  void _spawnPiece(TetrominoType type) {
    final FallingPiece piece = _spawnPieceFor(type);
    _gravityAccumMs = 0;
    _lockAccumMs = 0;
    _lockResets = 0;
    _lastActionWasRotation = false;
    if (_board.collides(piece)) {
      // Block-out: no room to spawn.
      _active = piece;
      _endGame();
      return;
    }
    _active = piece;
    _events.add(const TetrisEvent(TetrisEventType.spawn));
  }

  FallingPiece _spawnPieceFor(TetrominoType type) {
    final int boxSize = Tetromino.of(type).boxSize;
    final int originX = ((_board.width - boxSize) / 2).floor();
    return FallingPiece(
      type: type,
      rotationIndex: 0,
      originX: originX,
      originY: 0,
    );
  }

  void _endGame() {
    _gameOver = true;
    _events.add(const TetrisEvent(TetrisEventType.gameOver));
  }

  /// Serializes the live run for resume-after-kill. The 7-bag is intentionally
  /// not serialized; on [restore] the upcoming pieces are re-rolled.
  Map<String, Object?> toSnapshot() {
    return <String, Object?>{
      'board': _board.toJson(),
      'active': _active?.toJson(),
      'hold': _hold?.name,
      'can_hold': _canHold,
      'score': _score,
      'lines': _linesCleared,
      'level': _level,
      'combo': _combo,
      'back_to_back': _backToBack,
    };
  }

  /// Restores a run from [toSnapshot]. Marks the engine started; spawns a fresh
  /// active piece if the snapshot had none.
  void restore(Map<String, Object?> json) {
    _started = true;
    _gameOver = false;
    _board = TetrisBoard.fromJson(
      (json['board'] as Map?)?.cast<String, Object?>() ?? <String, Object?>{},
    );
    final Object? rawActive = json['active'];
    _active = rawActive is Map
        ? FallingPiece.fromJson(rawActive.cast<String, Object?>())
        : null;
    _hold = _typeFromName(json['hold']);
    _canHold = json['can_hold'] as bool? ?? true;
    _score = json['score'] as int? ?? 0;
    _linesCleared = json['lines'] as int? ?? 0;
    _level = json['level'] as int? ?? 1;
    _combo = json['combo'] as int? ?? -1;
    _backToBack = json['back_to_back'] as bool? ?? false;
    _gravityAccumMs = 0;
    _lockAccumMs = 0;
    _lockResets = 0;
    _lastActionWasRotation = false;
    if (_active == null) {
      _spawnNext();
    }
  }

  static TetrominoType? _typeFromName(Object? name) {
    if (name is! String) {
      return null;
    }
    for (final TetrominoType t in TetrominoType.values) {
      if (t.name == name) {
        return t;
      }
    }
    return null;
  }
}
