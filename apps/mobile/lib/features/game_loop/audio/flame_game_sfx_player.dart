import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

import '../../../core/logging/app_logger.dart';
import 'game_sfx_player.dart';

class FlameGameSfxPlayer implements GameSfxPlayer {
  FlameGameSfxPlayer({
    required AppLogger logger,
    DateTime Function()? nowUtcProvider,
  })  : _logger = logger,
        _nowUtc = nowUtcProvider ?? (() => DateTime.now().toUtc());

  final AppLogger _logger;
  final DateTime Function() _nowUtc;

  static const String _piecePlaced = 'piece_placed.wav';
  static const String _invalidMove = 'invalid_move.wav';
  static const String _lineClear = 'line_clear.wav';
  static const String _combo = 'combo.wav';
  static const List<String> _comboSteps = <String>[
    'combo_01.wav',
    'combo_02.wav',
    'combo_03.wav',
    'combo_04.wav',
    'combo_05.wav',
    'combo_06.wav',
    'combo_07.wav',
  ];
  static const String _gameOver = 'game_over.wav';
  static const String _rotate = 'rotate.wav';
  static const String _hold = 'hold.wav';
  static const String _hardDrop = 'hard_drop.wav';
  static const String _audioPrefix = 'assets/audio/';

  static const Duration comboResetThreshold = Duration(milliseconds: 2500);

  DateTime? _lastComboTimeUtc;
  int _lastComboStep = 1;

  int get lastComboStep => _lastComboStep;

  /// Resolves the ladder step (1..7) based on [comboStreak] and [now].
  /// Resets to step 1 after [comboResetThreshold] (2.5s) without a combo.
  int resolveComboStep({
    required int comboStreak,
    required DateTime now,
  }) {
    if (_lastComboTimeUtc == null ||
        now.difference(_lastComboTimeUtc!) >= comboResetThreshold) {
      _lastComboTimeUtc = now;
      _lastComboStep = 1;
      return 1;
    }
    _lastComboTimeUtc = now;
    return _lastComboStep = comboStreak.clamp(1, 7);
  }

  bool _initialized = false;
  Future<void>? _preloadFuture;
  Future<void>? _sessionRefreshFuture;
  final _BoundedSfxRing _ring = _BoundedSfxRing(size: 6);

  @override
  bool isEnabled = true;

  @override
  Future<void> preload() async {
    if (_initialized) {
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

  @override
  Future<void> onAppResumed() async {
    final Future<void>? inFlight = _sessionRefreshFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final Future<void> refreshTask = _refreshAudioSession();
    _sessionRefreshFuture = refreshTask;
    await refreshTask;
  }

  Future<void> _initializeAudio() async {
    try {
      FlameAudio.updatePrefix(_audioPrefix);
      await FlameAudio.audioCache.loadAll(
        <String>[
          _piecePlaced,
          _invalidMove,
          _lineClear,
          _combo,
          ..._comboSteps,
          _gameOver,
          _rotate,
          _hold,
          _hardDrop,
        ],
      );

      await _ring.init(FlameAudio.audioCache);
      _initialized = true;
      _logger.info('SFX loaded: bounded low-latency ring');
    } catch (error) {
      _initialized = false;
      await _ring.dispose();
      _logger.warn('SFX preload failed: $error');
    } finally {
      _preloadFuture = null;
    }
  }

  Future<void> _refreshAudioSession() async {
    try {
      FlameAudio.updatePrefix(_audioPrefix);
      await _ring.init(FlameAudio.audioCache);
      _logger.info('SFX audio session refreshed');
    } catch (error) {
      _logger.warn('SFX session refresh failed: $error');
    } finally {
      _sessionRefreshFuture = null;
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
    final DateTime now = _nowUtc();
    final int step = resolveComboStep(comboStreak: comboStreak, now: now);
    final String fileName = _comboSteps[step - 1];
    final double volume = comboStreak >= 4 ? 1.0 : 0.82;
    await _play(fileName, volume: volume);
  }

  @override
  Future<void> playRotate() async => _play(_rotate, volume: 0.45);

  @override
  Future<void> playHold() async => _play(_hold, volume: 0.5);

  @override
  Future<void> playHardDrop() async => _play(_hardDrop, volume: 0.7);

  @override
  Future<void> playGameOver() async => _play(_gameOver, volume: 0.85);

  Future<void> _play(
    String fileName, {
    double volume = 0.75,
  }) async {
    if (!isEnabled) {
      return;
    }

    final double normalizedVolume = volume.clamp(0, 1).toDouble();

    try {
      await preload();
      if (!_initialized) {
        return;
      }
      await _ring.play(fileName, normalizedVolume);
    } catch (error) {
      _logger.warn('SFX play failed for $fileName: $error');
    }
  }
}

/// A strictly bounded, non-allocating ring of [AudioPlayer] instances.
///
/// Uses [PlayerMode.lowLatency] (SoundPool on Android) to avoid heavy MediaPlayer
/// overhead and prevent AudioFlinger track exhaustion (max 32 tracks on Android).
///
/// When all players in the ring are currently playing, new sounds steal the
/// oldest player in round-robin sequence without allocating new instances.
class _BoundedSfxRing {
  _BoundedSfxRing({this.size = 6});

  final int size;
  final List<AudioPlayer> _players = <AudioPlayer>[];
  int _cursor = 0;
  bool _initialized = false;

  Future<void> init(AudioCache cache) async {
    if (_initialized && _players.length == size) {
      return;
    }
    await dispose();
    for (int i = 0; i < size; i++) {
      final AudioPlayer player = AudioPlayer()..audioCache = cache;
      await player.setReleaseMode(ReleaseMode.stop);
      _players.add(player);
    }
    _initialized = true;
  }

  Future<void> play(String file, double volume) async {
    if (!_initialized || _players.isEmpty) {
      return;
    }
    final AudioPlayer player = _players[_cursor];
    _cursor = (_cursor + 1) % size;
    try {
      await player.stop();
      await player.setVolume(volume);
      await player.play(
        AssetSource(file),
        volume: volume,
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // Non-fatal: drop audio frame cleanly if platform audio is transiently unavailable
    }
  }

  Future<void> dispose() async {
    _initialized = false;
    final List<AudioPlayer> toDispose = List<AudioPlayer>.from(_players);
    _players.clear();
    for (final AudioPlayer p in toDispose) {
      try {
        await p.dispose();
      } catch (_) {}
    }
  }
}
