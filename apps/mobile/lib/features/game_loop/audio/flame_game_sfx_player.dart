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
  static const String _audioPrefix = 'assets/audio/';

  bool _initialized = false;
  Future<void>? _preloadFuture;
  final Map<String, AudioPool> _pools = <String, AudioPool>{};

  @override
  Future<void> preload() async {
    if (_initialized && _pools.isNotEmpty) {
      return;
    }

    final Future<void>? inFlight = _preloadFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final Future<void> preloadTask = _initializeAudio();
    _preloadFuture = preloadTask;
    await preloadTask;
  }

  Future<void> _initializeAudio() async {
    try {
      FlameAudio.updatePrefix(_audioPrefix);
      await FlameAudio.audioCache.loadAll(
        <String>[_piecePlaced, _invalidMove, _lineClear, _combo, _gameOver],
      );

      await _rebuildPools();
      _initialized = true;
      _logger.info('SFX loaded: flame_audio pools');
    } catch (error) {
      _initialized = false;
      await _disposePools();
      _logger.warn('SFX preload failed: $error');
    } finally {
      _preloadFuture = null;
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
    final double normalizedVolume = volume.clamp(0, 1).toDouble();

    try {
      await preload();
      if (!_initialized) {
        return;
      }

      final AudioPool? pool = _pools[fileName];
      if (pool == null) {
        _logger.warn('SFX pool missing for $fileName');
        return;
      }

      await pool.start(volume: normalizedVolume);
    } catch (error) {
      _logger.warn('SFX play failed for $fileName: $error; recovering');
      await _recoverAndRetry(
        fileName: fileName,
        volume: normalizedVolume,
      );
    }
  }

  Future<void> _recoverAndRetry({
    required String fileName,
    required double volume,
  }) async {
    try {
      _initialized = false;
      await _disposePools();
      await preload();
      if (!_initialized) {
        return;
      }

      final AudioPool? pool = _pools[fileName];
      if (pool == null) {
        return;
      }
      await pool.start(volume: volume);
    } catch (retryError) {
      _logger.warn('SFX retry failed for $fileName: $retryError');
    }
  }

  Future<void> _rebuildPools() async {
    await _disposePools();

    _pools[_piecePlaced] = await FlameAudio.createPool(
      _piecePlaced,
      minPlayers: 2,
      maxPlayers: 8,
    );
    _pools[_invalidMove] = await FlameAudio.createPool(
      _invalidMove,
      minPlayers: 1,
      maxPlayers: 4,
    );
    _pools[_lineClear] = await FlameAudio.createPool(
      _lineClear,
      minPlayers: 1,
      maxPlayers: 4,
    );
    _pools[_combo] = await FlameAudio.createPool(
      _combo,
      minPlayers: 1,
      maxPlayers: 4,
    );
    _pools[_gameOver] = await FlameAudio.createPool(
      _gameOver,
      minPlayers: 1,
      maxPlayers: 2,
    );
  }

  Future<void> _disposePools() async {
    if (_pools.isEmpty) {
      return;
    }
    final List<Future<void>> disposeTasks = _pools.values
        .map((AudioPool pool) => pool.dispose())
        .toList(growable: false);
    _pools.clear();
    try {
      await Future.wait(disposeTasks);
    } catch (error) {
      _logger.warn('SFX pool dispose failed: $error');
    }
  }
}
