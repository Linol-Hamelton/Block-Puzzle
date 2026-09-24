import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';

import '../logging/app_logger.dart';

/// Manages background music playback using two independent [AudioPlayer] instances
/// to perform seamless equal-power crossfades between tracks in a cyclical playlist.
///
/// Implements DEC-0024 requirements:
/// - Direct dependency on `audioplayers` (no FlameAudio.bgm).
/// - Two independent players with isolated volume controls.
/// - 1.2s equal-power crossfade curve preserving acoustic loudness (gainA^2 + gainB^2 == 1.0).
/// - Android AudioFocus with explicit AudioContext configuration.
/// - Ducking (-3 dB for 150 ms) as a multiplier over the crossfade envelope.
/// - Single authority for volume: ducking never leaves tracks at incorrect volume.
class MusicPlaylistManager {
  MusicPlaylistManager({
    required AppLogger logger,
    List<String>? playlist,
    double baseVolume = 0.50,
    Duration crossfadeDuration = const Duration(milliseconds: 1200),
    AudioPlayer? playerA,
    AudioPlayer? playerB,
    AudioContext? audioContext,
    String audioPrefix = 'assets/audio/',
  })  : _logger = logger,
        _playlist = playlist != null && playlist.isNotEmpty
            ? List<String>.from(playlist)
            : const <String>[
                'music_menu.m4a',
                'music_classic.m4a',
                'music_tetris.m4a',
                'music_match3.m4a',
              ],
        _baseVolume = baseVolume,
        _crossfadeDuration = crossfadeDuration,
        _playerA = playerA ?? AudioPlayer(),
        _playerB = playerB ?? AudioPlayer(),
        _audioContext = audioContext ?? defaultAudioContext,
        _audioPrefix = audioPrefix;

  final AppLogger _logger;
  final List<String> _playlist;
  double _baseVolume;
  final Duration _crossfadeDuration;
  final AudioContext _audioContext;
  final String _audioPrefix;

  final AudioPlayer _playerA;
  final AudioPlayer _playerB;

  int _currentTrackIndex = 0;
  int _activePlayerIndex = 0; // 0 -> _playerA, 1 -> _playerB
  bool _enabled = true;
  bool _playing = false;
  bool _isPaused = false;
  bool _isCrossfading = false;
  double _crossfadeProgress = 0.0; // 0.0 to 1.0
  double _duckMultiplier = 1.0;
  bool _isDisposed = false;

  Timer? _crossfadeTimer;
  Timer? _duckTimer;
  Timer? _duckRecoveryTimer;
  DateTime? _lastDuckTime;
  StreamSubscription<void>? _completeSubA;
  StreamSubscription<void>? _completeSubB;
  StreamSubscription<PlayerState>? _stateSubA;
  StreamSubscription<PlayerState>? _stateSubB;

  static const int kTrackMenu = 0;
  static const int kTrackClassic = 1;
  static const int kTrackTetris = 2;
  static const int kTrackMatch3 = 3;

  /// Default explicit AudioContext for Android and iOS per DEC-0024/DEC-0028.
  static final AudioContext defaultAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      audioMode: AndroidAudioMode.normal,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const <AVAudioSessionOptions>{AVAudioSessionOptions.mixWithOthers},
    ),
  );

  /// Multiplier for -1.5 dB ducking per DEC-0028: 10^(-1.5/20) approx 0.84139514.
  static const double kDuckFactorMinus1_5dB = 0.84139514;

  /// Multiplier for -3 dB ducking: 10^(-3/20) approx 0.70794578.
  static const double kDuckFactorMinus3dB = 0.70794578;

  /// Default ducking duration per DEC-0024/DEC-0028.
  static const Duration kDefaultDuckDuration = Duration(milliseconds: 150);

  /// Coalescing window (100-120 ms) per DEC-0028.
  static const Duration kCoalescingWindow = Duration(milliseconds: 110);

  /// Recovery ramp duration (250 ms) per DEC-0028.
  static const Duration kRecoveryDuration = Duration(milliseconds: 250);

  bool get isEnabled => _enabled;
  bool get isPlaying => _playing;
  bool get isPaused => _isPaused;
  bool get isCrossfading => _isCrossfading;
  bool get isDisposed => _isDisposed;
  int get currentTrackIndex => _currentTrackIndex;
  double get duckMultiplier => _duckMultiplier;
  double get crossfadeProgress => _crossfadeProgress;
  double get baseVolume => _baseVolume;
  List<String> get playlist => List<String>.unmodifiable(_playlist);

  void setBaseVolume(double volume) {
    if (_isDisposed) {
      return;
    }
    _baseVolume = volume.clamp(0.0, 1.0);
    _applyCurrentVolumes();
  }

  AudioPlayer get activePlayer => _activePlayerIndex == 0 ? _playerA : _playerB;
  AudioPlayer get standbyPlayer => _activePlayerIndex == 0 ? _playerB : _playerA;

  /// Equal-power curve: gainA = cos(t * pi / 2), gainB = sin(t * pi / 2).
  ///
  /// Invariant: gainA^2 + gainB^2 == 1.0 at all t in [0.0, 1.0].
  /// At midpoint t = 0.5: gainA = gainB = sqrt(2)/2 approx 0.7071 (-3.01 dB),
  /// maintaining constant total acoustic energy with zero loudness dip.
  static ({double gainA, double gainB}) computeEqualPowerGains(double t) {
    final double clamped = t.clamp(0.0, 1.0);
    final double angle = clamped * (math.pi / 2.0);
    return (
      gainA: math.cos(angle),
      gainB: math.sin(angle),
    );
  }

  /// Configures both players with proper audio cache prefix, release mode,
  /// AudioContext (audio focus), and sets up track completion listeners.
  Future<void> initialize() async {
    if (_isDisposed) {
      return;
    }
    try {
      _playerA.audioCache = AudioCache(prefix: _audioPrefix);
      _playerB.audioCache = AudioCache(prefix: _audioPrefix);

      await _playerA.setReleaseMode(ReleaseMode.stop);
      await _playerB.setReleaseMode(ReleaseMode.stop);

      if (_enabled) {
        await _playerA.setAudioContext(_audioContext);
        await _playerB.setAudioContext(_audioContext);
      }

      await _completeSubA?.cancel();
      _completeSubA = _playerA.onPlayerComplete.listen((_) {
        unawaited(_onActiveTrackComplete(0));
      });

      await _completeSubB?.cancel();
      _completeSubB = _playerB.onPlayerComplete.listen((_) {
        unawaited(_onActiveTrackComplete(1));
      });

      await _stateSubA?.cancel();
      _stateSubA = _playerA.onPlayerStateChanged.listen((PlayerState state) {
        _onPlayerStateChanged(0, state);
      });

      await _stateSubB?.cancel();
      _stateSubB = _playerB.onPlayerStateChanged.listen((PlayerState state) {
        _onPlayerStateChanged(1, state);
      });
    } catch (error) {
      _logger.warn('MusicPlaylistManager initialize error: $error');
    }
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      unawaited(stop());
    } else {
      unawaited(_playerA.setAudioContext(_audioContext));
      unawaited(_playerB.setAudioContext(_audioContext));
    }
  }

  /// Starts playback of the playlist or switches to [trackIndex].
  ///
  /// If already playing the current track, this is a no-op to preserve playback
  /// across navigation transitions (DEC-0024 p.2).
  /// If called during an active crossfade, the pending crossfade is cancelled
  /// cleanly without leaking players or timers.
  Future<void> play({int? trackIndex}) async {
    if (_isDisposed || !_enabled || _playlist.isEmpty) {
      return;
    }

    // Cancel pending crossfade if play() is invoked mid-crossfade
    if (_isCrossfading) {
      _crossfadeTimer?.cancel();
      _crossfadeTimer = null;
      _isCrossfading = false;
      _crossfadeProgress = 0.0;
      try {
        await standbyPlayer.stop();
      } catch (_) {}
    }

    // Synchronize pause state with active player if underlying player was paused externally (F2)
    if (_playing && !_isPaused && activePlayer.state == PlayerState.paused) {
      _isPaused = true;
    }

    // Continuity across screen navigation: if already playing and no track switch requested
    if (_playing && !_isPaused) {
      if (trackIndex == null || trackIndex == _currentTrackIndex) {
        return;
      }
    }

    // If paused on the requested track, resume
    if (_playing && _isPaused) {
      if (trackIndex == null || trackIndex == _currentTrackIndex) {
        await resume();
        return;
      }
    }

    if (trackIndex != null && trackIndex >= 0 && trackIndex < _playlist.length) {
      _currentTrackIndex = trackIndex;
    }

    try {
      final String track = _playlist[_currentTrackIndex];
      _activePlayerIndex = 0;
      await _playerB.stop();
      await _playerA.setVolume(_effectiveVolumeFor(gain: 1.0));
      await _playerA.play(AssetSource(track));
      _playing = true;
      _isPaused = false;
      _logger.info('Music playing track: $track');
    } catch (error) {
      _logger.warn('Music play failed: $error');
    }
  }

  /// Cycles to the next track in the playlist with an equal-power crossfade.
  Future<void> nextTrack() async {
    if (_isDisposed || !_enabled || _playlist.isEmpty) {
      return;
    }
    final int nextIndex = (_currentTrackIndex + 1) % _playlist.length;
    await crossfadeTo(nextIndex);
  }

  /// Initiates a 1.2s equal-power crossfade to [targetTrackIndex].
  Future<void> crossfadeTo(int targetTrackIndex) async {
    if (_isDisposed || !_enabled || targetTrackIndex < 0 || targetTrackIndex >= _playlist.length) {
      return;
    }

    // If already crossfading, finalize the previous one first
    if (_isCrossfading) {
      _crossfadeTimer?.cancel();
      _finalizeCrossfade();
    }

    _isCrossfading = true;
    _crossfadeProgress = 0.0;
    _currentTrackIndex = targetTrackIndex;
    final String targetTrack = _playlist[targetTrackIndex];

    final AudioPlayer outgoing = activePlayer;
    final AudioPlayer incoming = standbyPlayer;

    try {
      await incoming.stop();
      await incoming.setVolume(0.0);
      await incoming.play(AssetSource(targetTrack));

      const int totalSteps = 24; // 50 ms interval over 1200 ms
      final int stepMs = _crossfadeDuration.inMilliseconds ~/ totalSteps;
      int currentStep = 0;

      _crossfadeTimer = Timer.periodic(Duration(milliseconds: stepMs), (Timer timer) {
        if (_isDisposed || !_isCrossfading) {
          timer.cancel();
          return;
        }

        currentStep++;
        final double t = (currentStep / totalSteps).clamp(0.0, 1.0);
        _crossfadeProgress = t;
        final ({double gainA, double gainB}) gains = computeEqualPowerGains(t);

        final double outVol = _effectiveVolumeFor(gain: gains.gainA);
        final double inVol = _effectiveVolumeFor(gain: gains.gainB);

        outgoing.setVolume(outVol).catchError((_) {});
        incoming.setVolume(inVol).catchError((_) {});

        if (currentStep >= totalSteps) {
          timer.cancel();
          _finalizeCrossfade();
        }
      });
    } catch (error) {
      _logger.warn('Crossfade failed: $error');
      _isCrossfading = false;
    }
  }

  void _finalizeCrossfade() {
    _crossfadeTimer?.cancel();
    _crossfadeTimer = null;
    _isCrossfading = false;
    _crossfadeProgress = 0.0;

    final AudioPlayer outgoing = activePlayer;
    final AudioPlayer incoming = standbyPlayer;

    outgoing.stop().catchError((_) {});
    incoming.setVolume(_effectiveVolumeFor(gain: 1.0)).catchError((_) {});

    // Switch active player pointer
    _activePlayerIndex = (_activePlayerIndex == 0) ? 1 : 0;
  }

  Future<void> _onActiveTrackComplete(int playerIndex) async {
    if (_isDisposed || !_playing || !_enabled || _isPaused) {
      return;
    }
    if (playerIndex == _activePlayerIndex) {
      await nextTrack();
    }
  }

  void _onPlayerStateChanged(int playerIndex, PlayerState state) {
    if (_isDisposed) {
      return;
    }
    final bool isTrackedPlayer = playerIndex == _activePlayerIndex ||
        (_isCrossfading && playerIndex == (_activePlayerIndex == 0 ? 1 : 0));
    if (!isTrackedPlayer) {
      return;
    }

    if (state == PlayerState.paused) {
      if (_playing && !_isPaused) {
        _isPaused = true;
        _logger.info('Player $playerIndex externally paused, synchronized _isPaused = true');
      }
    } else if (state == PlayerState.playing) {
      if (_playing && _isPaused) {
        _isPaused = false;
        _logger.info('Player $playerIndex externally resumed, synchronizing _isPaused = false');
      }
    }
  }

  /// Ducking per DEC-0024 / DEC-0028: reduces music volume by [factor] (-1.5 dB default)
  /// with a coalescing window (110 ms) and a 250 ms recovery ramp.
  ///
  /// Invariant: _duckMultiplier >= 0.70 at all times (guaranteed duck floor).
  /// Ducking is a multiplier applied on top of the envelope:
  /// V_effective = V_base * gain_crossfade * multiplier_duck.
  void duck({
    Duration duration = kDefaultDuckDuration,
    double factor = kDuckFactorMinus1_5dB,
  }) {
    if (_isDisposed || !_enabled || !_playing || _isPaused) {
      return;
    }
    final DateTime now = DateTime.now();
    if (_lastDuckTime != null && now.difference(_lastDuckTime!) < kCoalescingWindow) {
      // Coalescing window: suppress rapid re-triggering within 100-120 ms
      return;
    }
    _lastDuckTime = now;
    _duckRecoveryTimer?.cancel();
    _duckRecoveryTimer = null;

    final double clampedFactor = factor.clamp(0.70, 1.0);
    _duckMultiplier = clampedFactor;
    _applyCurrentVolumes();

    _duckTimer?.cancel();
    _duckTimer = Timer(duration, () {
      if (_isDisposed) {
        return;
      }
      _startDuckRecovery();
    });
  }

  void _startDuckRecovery() {
    _duckTimer = null;
    const int steps = 5;
    final int stepMs = kRecoveryDuration.inMilliseconds ~/ steps;
    final double startMultiplier = _duckMultiplier;
    final double delta = (1.0 - startMultiplier) / steps;
    int step = 0;

    _duckRecoveryTimer = Timer.periodic(Duration(milliseconds: stepMs), (Timer timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      step++;
      if (step >= steps) {
        _duckMultiplier = 1.0;
        _applyCurrentVolumes();
        timer.cancel();
        _duckRecoveryTimer = null;
      } else {
        _duckMultiplier = (startMultiplier + delta * step).clamp(0.70, 1.0);
        _applyCurrentVolumes();
      }
    });
  }

  void _applyCurrentVolumes() {
    if (_isDisposed || !_playing) {
      return;
    }
    if (_isCrossfading) {
      final ({double gainA, double gainB}) gains = computeEqualPowerGains(_crossfadeProgress);
      activePlayer.setVolume(_effectiveVolumeFor(gain: gains.gainA)).catchError((_) {});
      standbyPlayer.setVolume(_effectiveVolumeFor(gain: gains.gainB)).catchError((_) {});
    } else {
      activePlayer.setVolume(_effectiveVolumeFor(gain: 1.0)).catchError((_) {});
    }
  }

  double _effectiveVolumeFor({required double gain}) {
    return (_baseVolume * gain * _duckMultiplier).clamp(0.0, 1.0);
  }

  Future<void> pause() async {
    if (_isDisposed || !_playing || _isPaused) {
      return;
    }
    _isPaused = true;
    try {
      await _playerA.pause();
      await _playerB.pause();
    } catch (error) {
      _logger.warn('Music pause failed: $error');
    }
  }

  Future<void> resume() async {
    if (_isDisposed || !_enabled || !_playing || !_isPaused) {
      return;
    }
    _isPaused = false;
    try {
      await activePlayer.resume();
      if (_isCrossfading) {
        await standbyPlayer.resume();
      }
    } catch (error) {
      _logger.warn('Music resume failed: $error');
    }
  }

  Future<void> stop() async {
    _crossfadeTimer?.cancel();
    _crossfadeTimer = null;
    _duckTimer?.cancel();
    _duckTimer = null;
    _duckRecoveryTimer?.cancel();
    _duckRecoveryTimer = null;
    _lastDuckTime = null;
    _isCrossfading = false;
    _crossfadeProgress = 0.0;
    _duckMultiplier = 1.0;
    _playing = false;
    _isPaused = false;

    try {
      await _playerA.stop();
      await _playerB.stop();
    } catch (error) {
      _logger.warn('Music stop failed: $error');
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    await _completeSubA?.cancel();
    _completeSubA = null;
    await _completeSubB?.cancel();
    _completeSubB = null;
    await _stateSubA?.cancel();
    _stateSubA = null;
    await _stateSubB?.cancel();
    _stateSubB = null;
    await stop();
    try {
      await _playerA.dispose();
    } catch (_) {}
    try {
      await _playerB.dispose();
    } catch (_) {}
  }
}
