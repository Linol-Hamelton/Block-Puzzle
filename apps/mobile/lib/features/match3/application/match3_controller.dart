import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/device/haptics_controller.dart';
import '../../../data/analytics/analytics_tracker.dart';
import '../../../domain/match3/match3_engine.dart';
import '../../../domain/match3/tile.dart';
import '../../../domain/match3/tile_grid.dart';
import '../../game_loop/audio/game_sfx_player.dart';
import 'cascade_playback.dart';
import 'match3_session_store.dart';

/// Owns the [Match3Engine] and bridges it to the UI. The Flame view forwards
/// board taps/swipes to [trySwap]; engine events become SFX, haptics, and
/// analytics; HUD-relevant changes notify listeners. Persists a resume snapshot
/// and the best score via [Match3SessionStore]. Mirrors `TetrisController`, but
/// Match-3 has no clock — there is no [tick]; the engine advances only on swaps.
class Match3Controller extends ChangeNotifier {
  Match3Controller({
    int? seed,
    required GameSfxPlayer sfx,
    required HapticsController haptics,
    AnalyticsTracker? analyticsTracker,
    Match3SessionStore? store,
    VoidCallback? onGameOver,
  })  : _seed = seed,
        _sfx = sfx,
        _haptics = haptics,
        _analytics = analyticsTracker,
        _store = store,
        _onGameOver = onGameOver,
        _engine = Match3Engine(seed: seed);

  final int? _seed;
  final GameSfxPlayer _sfx;
  final HapticsController _haptics;
  final AnalyticsTracker? _analytics;
  final Match3SessionStore? _store;
  final VoidCallback? _onGameOver;

  Match3Engine _engine;
  final CascadePlayback _playback = const CascadePlayback();
  List<CascadeFrame> _frames = const <CascadeFrame>[];
  int _frameIndex = 0;
  int _frameSerial = 0;
  Timer? _frameTimer;
  bool _playbackPaused = false;
  Duration _remainingHold = Duration.zero;
  DateTime? _frameHoldStartedAt;
  bool _started = false;
  bool _gameEndEmitted = false;
  bool _disposed = false;
  int _bestScore = 0;
  int _sessionStartBestScore = 0;
  String _roundId = 'match3_0';
  DateTime? _startedAt;

  /// Set by the Flame view to receive engine events for visual juice.
  void Function(Match3Event event)? onVisualEvent;

  Match3Engine get engine => _engine;

  /// The settled board. This is the rules' view of the world and is always up
  /// to date, even mid-animation.
  TileGrid get grid => _engine.grid;

  /// The board the player is currently looking at.
  ///
  /// While a cascade is playing this trails [grid] by a few hundred
  /// milliseconds, walking the steps the move actually took. Everything that
  /// draws the board reads this; everything that decides anything reads [grid].
  TileGrid get displayGrid => _currentFrame?.grid ?? _engine.grid;

  /// Cells charging up to clear on the board being shown.
  Set<GridPos> get ignitingCells =>
      _currentFrame?.igniting ?? const <GridPos>{};

  /// Cells that cleared on the way into the current frame, with their colours.
  Map<GridPos, TileColor> get frameBurst =>
      _currentFrame?.burst ?? const <GridPos, TileColor>{};

  /// Increments on every frame change, so a view can time its own animation
  /// against the frame without polling the clock.
  int get frameSerial => _frameSerial;
  bool get isPlaybackPaused => _playbackPaused;

  /// How long the current frame is held. Zero when nothing is playing.
  Duration get frameHold => _currentFrame?.hold ?? Duration.zero;

  /// True while a cascade is playing out. Input is refused: accepting a second
  /// swap against a board the player cannot see yet is how a match-3 starts
  /// feeling like it is fighting back.
  bool get isBusy => _frames.isNotEmpty;

  CascadeFrame? get _currentFrame =>
      _frameIndex >= 0 && _frameIndex < _frames.length
          ? _frames[_frameIndex]
          : null;
  int get score => _engine.score;
  int get movesUsed => _engine.movesUsed;
  int? get movesLeft => _engine.movesLeft;
  int get round => _engine.round;
  int get roundTarget => _engine.roundTarget;
  int get roundFloor => _engine.roundFloor;
  double get roundProgress => _engine.roundProgress;
  int get colorCount => _engine.colorCount;
  bool get isGameOver => _engine.isGameOver;
  int get bestScore => _bestScore > _engine.score ? _bestScore : _engine.score;
  int get sessionStartBestScore => _sessionStartBestScore;
  bool get isNewRecord => _engine.score > _sessionStartBestScore && _engine.score > 0;

  /// Loads the best score + any resume snapshot, then resumes or starts.
  Future<void> initialize() async {
    if (_started) {
      return;
    }
    _started = true;
    _bestScore = await (_store?.loadBestScore() ?? Future<int>.value(0));
    _sessionStartBestScore = _bestScore;
    final Map<String, Object?>? snapshot = await _store?.loadSnapshot();
    final bool resumed = snapshot != null;
    if (snapshot != null) {
      _engine.restore(snapshot);
    } else {
      _engine.start();
    }
    _beginRound(resumed: resumed);
    _consumeEvents();
    notifyListeners();
  }

  void restart() {
    _flushPlayback();
    unawaited(_store?.clearSnapshot());
    _engine = Match3Engine(seed: _seed);
    _engine.start();
    _beginRound();
    _consumeEvents();
    notifyListeners();
  }

  /// Attempts the player's swap. Returns true if it was a legal move.
  bool trySwap(GridPos a, GridPos b) {
    if (_disposed || _engine.isGameOver || isBusy) {
      return false;
    }
    final bool ok = _engine.swap(a, b);
    final List<Match3Event> events = _engine.drainEvents();

    final TileGrid? swapGrid = _engine.lastSwapGrid;
    final List<CascadeFrame> frames = ok && swapGrid != null
        ? _playback.build(
            swapGrid: swapGrid,
            steps: _engine.lastSteps,
            finalGrid: _engine.grid,
            events: events,
          )
        : const <CascadeFrame>[];

    if (frames.isEmpty) {
      for (final Match3Event event in events) {
        _handle(event);
      }
      notifyListeners();
    } else {
      _startPlayback(frames);
    }
    return ok;
  }

  /// Pauses the cascade playback timer while preserving remaining hold duration.
  void pausePlayback() {
    if (_disposed || _playbackPaused) {
      return;
    }
    _playbackPaused = true;
    if (_frameTimer != null) {
      _frameTimer?.cancel();
      _frameTimer = null;
      if (_frameHoldStartedAt != null) {
        final Duration elapsed = DateTime.now().difference(_frameHoldStartedAt!);
        if (elapsed < _remainingHold) {
          _remainingHold -= elapsed;
        } else {
          _remainingHold = Duration.zero;
        }
      }
    }
  }

  /// Resumes the cascade playback timer with the remaining hold duration.
  void resumePlayback() {
    if (_disposed || !_playbackPaused) {
      return;
    }
    _playbackPaused = false;
    if (_frames.isNotEmpty && _frameTimer == null) {
      _frameHoldStartedAt = DateTime.now();
      _frameTimer = Timer(_remainingHold, _advanceFrame);
    }
  }

  void _startPlayback(List<CascadeFrame> frames) {
    _frameTimer?.cancel();
    _playbackPaused = false;
    _frames = frames;
    _frameIndex = -1;
    _advanceFrame();
  }

  void _advanceFrame() {
    if (_disposed) {
      return;
    }
    _frameIndex += 1;
    if (_frameIndex >= _frames.length) {
      _frames = const <CascadeFrame>[];
      _frameIndex = 0;
      _frameTimer = null;
      _playbackPaused = false;
      notifyListeners();
      return;
    }
    final CascadeFrame frame = _frames[_frameIndex];
    _frameSerial += 1;
    for (final Match3Event event in frame.events) {
      _handle(event);
    }
    notifyListeners();
    _frameHoldStartedAt = DateTime.now();
    _remainingHold = frame.hold;
    if (!_playbackPaused) {
      _frameTimer = Timer(frame.hold, _advanceFrame);
    }
  }

  /// Ends the animation at once, releasing anything it had left to say.
  ///
  /// The engine is already settled - the playback is only catching the eye up -
  /// so this never changes the outcome of a move. Called before persisting and
  /// on teardown, mirroring `TetrisEngine.flushPendingClear`.
  void _flushPlayback() {
    _frameTimer?.cancel();
    _frameTimer = null;
    _playbackPaused = false;
    if (_frames.isEmpty) {
      return;
    }
    for (int i = _frameIndex + 1; i < _frames.length; i++) {
      for (final Match3Event event in _frames[i].events) {
        _handle(event);
      }
    }
    _frames = const <CascadeFrame>[];
    _frameIndex = 0;
    notifyListeners();
  }

  /// Persists the in-progress game (call on app pause). No-op when idle.
  void saveActiveGame() {
    // Settle the animation first: what gets written is the engine's state, and
    // leaving a timer alive across a pause would advance it against a dead view.
    _flushPlayback();
    final Match3SessionStore? store = _store;
    if (store == null || !_engine.hasActiveGame) {
      return;
    }
    unawaited(store.saveSnapshot(_engine.toSnapshot()));
  }

  void _beginRound({bool resumed = false}) {
    _gameEndEmitted = false;
    _startedAt = DateTime.now();
    _roundId = 'match3_${_startedAt!.microsecondsSinceEpoch}';
    _track('game_start', <String, Object?>{
      'round_id': _roundId,
      'mode': 'match3',
      'config_version': 'match3_v1',
      'game_id': 'match3',
      'resumed': resumed,
    });
  }

  bool _consumeEvents() {
    final List<Match3Event> events = _engine.drainEvents();
    if (events.isEmpty) {
      return false;
    }
    for (final Match3Event event in events) {
      _handle(event);
    }
    return true;
  }

  void _handle(Match3Event event) {
    switch (event.type) {
      case Match3EventType.swap:
        unawaited(_sfx.playHold());
        unawaited(_haptics.selectionClick());
        break;
      case Match3EventType.invalidSwap:
        unawaited(_sfx.playInvalidMove());
        unawaited(_haptics.lightImpact());
        break;
      case Match3EventType.match:
        // value = tiles cleared, detail = cascade level.
        unawaited(_sfx.playLineClear(clearedLines: (event.value / 3).ceil()));
        if (event.detail >= 2) {
          unawaited(_sfx.playCombo(comboStreak: event.detail));
          unawaited(_haptics.heavyImpact());
        } else {
          unawaited(_haptics.lightImpact());
        }
        _track('line_clear', <String, Object?>{
          'count': event.value,
          'game_id': 'match3',
          'round_id': _roundId,
          'score_total': _engine.score,
          'cascade': event.detail,
        });
        break;
      case Match3EventType.specialSpawned:
        unawaited(_sfx.playPiecePlaced());
        unawaited(_haptics.selectionClick());
        _track('match3_special_spawned', <String, Object?>{
          'game_id': 'match3',
          'round_id': _roundId,
          'special': event.special?.name ?? 'none',
          'round': _engine.round,
        });
        break;
      case Match3EventType.combo:
        unawaited(_sfx.playCombo(comboStreak: 3));
        unawaited(_haptics.heavyImpact());
        _track('match3_combo', <String, Object?>{
          'game_id': 'match3',
          'round_id': _roundId,
          'combo': event.combo?.name ?? 'none',
          'round': _engine.round,
        });
        break;
      case Match3EventType.roundComplete:
        unawaited(_sfx.playLineClear(clearedLines: 4));
        unawaited(_haptics.heavyImpact());
        _track('match3_round_complete', <String, Object?>{
          'game_id': 'match3',
          'round_id': _roundId,
          // value = the round just completed, detail = moves it paid out.
          'round': event.value,
          'moves_granted': event.detail,
          'moves_used': _engine.movesUsed,
          'score_total': _engine.score,
        });
        break;
      case Match3EventType.shuffle:
        unawaited(_sfx.playPiecePlaced());
        unawaited(_haptics.mediumImpact());
        break;
      case Match3EventType.gameOver:
        unawaited(_sfx.playGameOver());
        unawaited(_haptics.heavyImpact());
        _onGameEnd();
        break;
    }
    onVisualEvent?.call(event);
  }

  void _onGameEnd() {
    final int finalScore = _engine.score;
    if (finalScore > _bestScore) {
      _bestScore = finalScore;
    }
    unawaited(_store?.saveBestScore(finalScore));
    unawaited(_store?.clearSnapshot());
    if (!_gameEndEmitted) {
      _gameEndEmitted = true;
      final int duration = _startedAt == null
          ? 0
          : DateTime.now().difference(_startedAt!).inSeconds;
      _track('game_end', <String, Object?>{
        'round_id': _roundId,
        'end_reason': 'out_of_moves',
        'score': finalScore,
        'duration_sec': duration,
        'moves_used': _engine.movesUsed,
        'rounds_cleared': _engine.round - 1,
        'game_id': 'match3',
      });
    }
    _onGameOver?.call();
  }

  void _track(String name, Map<String, Object?> params) {
    final AnalyticsTracker? analytics = _analytics;
    if (analytics == null) {
      return;
    }
    unawaited(analytics.track(name, params: params));
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _frameTimer = null;
    _playbackPaused = false;
    _frames = const <CascadeFrame>[];
    _disposed = true;
    onVisualEvent = null;
    super.dispose();
  }
}
