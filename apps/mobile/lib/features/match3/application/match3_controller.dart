import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/device/haptics_controller.dart';
import '../../../data/analytics/analytics_tracker.dart';
import '../../../domain/match3/match3_engine.dart';
import '../../../domain/match3/tile.dart';
import '../../../domain/match3/tile_grid.dart';
import '../../game_loop/audio/game_sfx_player.dart';
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
  bool _started = false;
  bool _gameEndEmitted = false;
  bool _disposed = false;
  int _bestScore = 0;
  String _roundId = 'match3_0';
  DateTime? _startedAt;

  /// Set by the Flame view to receive engine events for visual juice.
  void Function(Match3Event event)? onVisualEvent;

  Match3Engine get engine => _engine;
  TileGrid get grid => _engine.grid;
  int get score => _engine.score;
  int get movesUsed => _engine.movesUsed;
  int? get movesLeft => _engine.movesLeft;
  int get colorCount => _engine.colorCount;
  bool get isGameOver => _engine.isGameOver;
  int get bestScore => _bestScore > _engine.score ? _bestScore : _engine.score;

  /// Loads the best score + any resume snapshot, then resumes or starts.
  Future<void> initialize() async {
    if (_started) {
      return;
    }
    _started = true;
    _bestScore = await (_store?.loadBestScore() ?? Future<int>.value(0));
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
    unawaited(_store?.clearSnapshot());
    _engine = Match3Engine(seed: _seed);
    _engine.start();
    _beginRound();
    _consumeEvents();
    notifyListeners();
  }

  /// Attempts the player's swap. Returns true if it was a legal move.
  bool trySwap(GridPos a, GridPos b) {
    if (_disposed || _engine.isGameOver) {
      return false;
    }
    final bool ok = _engine.swap(a, b);
    _consumeEvents();
    notifyListeners();
    return ok;
  }

  /// Persists the in-progress game (call on app pause). No-op when idle.
  void saveActiveGame() {
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
    _disposed = true;
    onVisualEvent = null;
    super.dispose();
  }
}
