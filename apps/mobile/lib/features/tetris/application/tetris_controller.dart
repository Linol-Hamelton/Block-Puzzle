import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/device/haptics_controller.dart';
import '../../../data/analytics/analytics_tracker.dart';
import '../../../domain/tetris/tetris_engine.dart';
import '../../../domain/tetris/tetromino.dart';
import '../../game_loop/audio/game_sfx_player.dart';
import 'tetris_session_store.dart';

/// Owns the [TetrisEngine] and bridges it to the UI: the Flame game drives
/// [tick]; on-screen controls call [input]. Engine events become SFX, haptics,
/// and analytics; HUD-relevant changes notify listeners. Persists a resume
/// snapshot and the best score via [TetrisSessionStore].
///
/// Rendering reads [engine] directly each frame (board/active/ghost), so the
/// notifier only fires when HUD state could have changed — never per gravity
/// frame.
class TetrisController extends ChangeNotifier {
  TetrisController({
    int? seed,
    required GameSfxPlayer sfx,
    required HapticsController haptics,
    AnalyticsTracker? analyticsTracker,
    TetrisSessionStore? store,
    VoidCallback? onGameOver,
  })  : _seed = seed,
        _sfx = sfx,
        _haptics = haptics,
        _analytics = analyticsTracker,
        _store = store,
        _onGameOver = onGameOver,
        _engine = TetrisEngine(seed: seed);

  final int? _seed;
  final GameSfxPlayer _sfx;
  final HapticsController _haptics;
  final AnalyticsTracker? _analytics;
  final TetrisSessionStore? _store;
  final VoidCallback? _onGameOver;

  TetrisEngine _engine;
  bool _started = false;
  int _bestScore = 0;
  String _roundId = 'tetris_0';
  DateTime? _startedAt;

  TetrisEngine get engine => _engine;
  int get score => _engine.score;
  int get level => _engine.level;
  int get lines => _engine.linesCleared;
  int get bestScore => _bestScore > _engine.score ? _bestScore : _engine.score;
  bool get isGameOver => _engine.isGameOver;
  TetrominoType? get hold => _engine.hold;
  List<TetrominoType> get nextQueue => _engine.nextQueue;

  /// Loads the best score + any resume snapshot, then resumes or starts.
  Future<void> initialize() async {
    if (_started) {
      return;
    }
    _started = true;
    _bestScore = await (_store?.loadBestScore() ?? Future<int>.value(0));
    final Map<String, Object?>? snapshot = await _store?.loadSnapshot();
    if (snapshot != null) {
      _engine.restore(snapshot);
    } else {
      _engine.start();
    }
    _beginRound();
    _consumeEvents();
    notifyListeners();
  }

  void restart() {
    unawaited(_store?.clearSnapshot());
    _engine = TetrisEngine(seed: _seed);
    _engine.start();
    _beginRound();
    _consumeEvents();
    notifyListeners();
  }

  void input(TetrisInput intent) {
    if (_engine.isGameOver) {
      return;
    }
    _engine.applyInput(intent);
    _consumeEvents();
    notifyListeners();
  }

  /// Advances gravity/lock by [delta] (driven from the Flame frame loop).
  void tick(Duration delta) {
    if (!_started || _engine.isGameOver) {
      return;
    }
    _engine.tick(delta);
    if (_consumeEvents()) {
      notifyListeners();
    }
  }

  /// Persists the in-progress game (call on app pause). No-op when idle.
  void saveActiveGame() {
    final TetrisSessionStore? store = _store;
    if (store == null || !_engine.hasActiveGame) {
      return;
    }
    unawaited(store.saveSnapshot(_engine.toSnapshot()));
  }

  void _beginRound() {
    _startedAt = DateTime.now();
    _roundId = 'tetris_${_startedAt!.microsecondsSinceEpoch}';
    _track('game_start', <String, Object?>{
      'round_id': _roundId,
      'mode': 'tetris',
      'config_version': 'tetris_v1',
      'game_id': 'tetris',
    });
  }

  bool _consumeEvents() {
    final List<TetrisEvent> events = _engine.drainEvents();
    if (events.isEmpty) {
      return false;
    }
    for (final TetrisEvent event in events) {
      _handle(event);
    }
    return true;
  }

  void _handle(TetrisEvent event) {
    switch (event.type) {
      case TetrisEventType.spawn:
      case TetrisEventType.move:
      case TetrisEventType.softDrop:
        break;
      case TetrisEventType.rotate:
      case TetrisEventType.hold:
        unawaited(_haptics.selectionClick());
        break;
      case TetrisEventType.hardDrop:
        unawaited(_haptics.mediumImpact());
        break;
      case TetrisEventType.lock:
        unawaited(_sfx.playPiecePlaced());
        unawaited(_haptics.lightImpact());
        break;
      case TetrisEventType.lineClear:
        unawaited(_sfx.playLineClear(clearedLines: event.value));
        unawaited(_haptics.heavyImpact());
        _track('line_clear', <String, Object?>{
          'count': event.value,
          'game_id': 'tetris',
          'round_id': _roundId,
          'score_total': _engine.score,
        });
        break;
      case TetrisEventType.levelUp:
        unawaited(_haptics.mediumImpact());
        break;
      case TetrisEventType.gameOver:
        unawaited(_sfx.playGameOver());
        unawaited(_haptics.heavyImpact());
        _onGameEnd();
        break;
    }
  }

  void _onGameEnd() {
    final int finalScore = _engine.score;
    if (finalScore > _bestScore) {
      _bestScore = finalScore;
    }
    unawaited(_store?.saveBestScore(finalScore));
    unawaited(_store?.clearSnapshot());
    final int duration = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inSeconds;
    _track('game_end', <String, Object?>{
      'round_id': _roundId,
      'end_reason': 'top_out',
      'score': finalScore,
      'duration_sec': duration,
      'level': _engine.level,
      'lines': _engine.linesCleared,
      'game_id': 'tetris',
    });
    _onGameOver?.call();
  }

  void _track(String name, Map<String, Object?> params) {
    final AnalyticsTracker? analytics = _analytics;
    if (analytics == null) {
      return;
    }
    unawaited(analytics.track(name, params: params));
  }
}
