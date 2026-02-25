import 'package:flame_audio/flame_audio.dart';

import '../../../core/logging/app_logger.dart';
import 'game_sfx_player.dart';

class FlameGameSfxPlayer implements GameSfxPlayer {
  FlameGameSfxPlayer({
    required AppLogger logger,
  }) : _logger = logger;

  final AppLogger _logger;

  static const String _piecePlaced = 'piece_placed.wav';
  static const String _invalidMove = 'invalid_move.wav';
  static const String _lineClear = 'line_clear.wav';
  static const String _combo = 'combo.wav';
  static const String _gameOver = 'game_over.wav';

  bool _initialized = false;

  @override
  Future<void> preload() async {
    if (_initialized) {
      return;
    }

    try {
      FlameAudio.audioCache.prefix = 'assets/audio/';
      await FlameAudio.audioCache.loadAll(
        <String>[
          _piecePlaced,
          _invalidMove,
          _lineClear,
          _combo,
          _gameOver,
        ],
      );
      _initialized = true;
      _logger.info('SFX loaded: flame_audio');
    } catch (error) {
      _logger.warn('SFX preload failed: $error');
    }
  }

  @override
  Future<void> playPiecePlaced() async => _play(_piecePlaced);

  @override
  Future<void> playInvalidMove() async => _play(_invalidMove);

  @override
  Future<void> playLineClear({
    required int clearedLines,
  }) async {
    await _play(_lineClear, volume: clearedLines > 1 ? 0.9 : 0.72);
  }

  @override
  Future<void> playCombo({
    required int comboStreak,
  }) async {
    final double volume = comboStreak >= 4 ? 1.0 : 0.82;
    await _play(_combo, volume: volume);
  }

  @override
  Future<void> playGameOver() async => _play(_gameOver, volume: 0.85);

  Future<void> _play(
    String fileName, {
    double volume = 0.75,
  }) async {
    try {
      await preload();
      await FlameAudio.play(fileName, volume: volume);
    } catch (error) {
      _logger.warn('SFX play failed for $fileName: $error');
    }
  }
}
