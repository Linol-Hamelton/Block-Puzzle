import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/device/haptics_controller.dart';
import '../../../domain/tetris/tetris_engine.dart';
import '../../../domain/tetris/tetromino.dart';
import '../../game_loop/audio/game_sfx_player.dart';

/// Owns the [TetrisEngine] and bridges it to the UI: the Flame game drives
/// [tick]; on-screen controls call [input]. Engine events are turned into SFX
/// and haptics here, and HUD-relevant changes notify listeners.
///
/// Rendering reads [engine] directly each frame (board/active/ghost), so the
/// notifier only fires when HUD state (score/level/lines/hold/next/game-over)
/// could have changed — never per gravity frame.
class TetrisController extends ChangeNotifier {
  TetrisController({
    int? seed,
    required GameSfxPlayer sfx,
    required HapticsController haptics,
    VoidCallback? onGameOver,
  })  : _seed = seed,
        _sfx = sfx,
        _haptics = haptics,
        _onGameOver = onGameOver,
        _engine = TetrisEngine(seed: seed);

  final int? _seed;
  final GameSfxPlayer _sfx;
  final HapticsController _haptics;
  final VoidCallback? _onGameOver;

  TetrisEngine _engine;
  bool _started = false;

  TetrisEngine get engine => _engine;
  int get score => _engine.score;
  int get level => _engine.level;
  int get lines => _engine.linesCleared;
  bool get isGameOver => _engine.isGameOver;
  TetrominoType? get hold => _engine.hold;
  List<TetrominoType> get nextQueue => _engine.nextQueue;

  void start() {
    if (_started) {
      return;
    }
    _started = true;
    _engine.start();
    _consumeEvents();
    notifyListeners();
  }

  void restart() {
    _engine = TetrisEngine(seed: _seed);
    _started = false;
    start();
  }

  void input(TetrisInput intent) {
    if (_engine.isGameOver) {
      return;
    }
    _engine.applyInput(intent);
    _consumeEvents();
    notifyListeners();
  }

  /// Advances gravity/lock by [delta] (driven from the Flame game loop).
  void tick(Duration delta) {
    if (!_started || _engine.isGameOver) {
      return;
    }
    _engine.tick(delta);
    if (_consumeEvents()) {
      notifyListeners();
    }
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
        unawaited(_haptics.selectionClick());
        break;
      case TetrisEventType.hold:
        unawaited(_haptics.selectionClick());
        break;
      case TetrisEventType.hardDrop:
        unawaited(_haptics.mediumImpact());
        break;
      case TetrisEventType.lock:
        // The place sound also covers a preceding hard drop (lock follows it).
        unawaited(_sfx.playPiecePlaced());
        unawaited(_haptics.lightImpact());
        break;
      case TetrisEventType.lineClear:
        unawaited(_sfx.playLineClear(clearedLines: event.value));
        unawaited(_haptics.heavyImpact());
        break;
      case TetrisEventType.levelUp:
        unawaited(_haptics.mediumImpact());
        break;
      case TetrisEventType.gameOver:
        unawaited(_sfx.playGameOver());
        unawaited(_haptics.heavyImpact());
        _onGameOver?.call();
        break;
    }
  }
}
