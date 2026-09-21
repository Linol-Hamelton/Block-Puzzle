import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';
import 'music_playlist_manager.dart';

/// Application-scoped controller for background music.
///
/// Wraps [MusicPlaylistManager] and integrates it with application lifecycle
/// ([WidgetsBindingObserver]) and persistent settings via [SharedPreferences].
///
/// No longer relies on `FlameAudio.bgm`. Music lives at the application level
/// and survives screen navigation across Menu, Classic, Tetris, and Match-3.
class MusicController with WidgetsBindingObserver {
  MusicController({
    required AppLogger logger,
    MusicPlaylistManager? playlistManager,
  })  : _logger = logger,
        _manager = playlistManager ?? MusicPlaylistManager(logger: logger);

  final AppLogger _logger;
  final MusicPlaylistManager _manager;
  static const String _enabledKey = 'music_enabled';

  bool _enabled = true;
  SharedPreferences? _prefs;
  bool _lifecycleRegistered = false;
  bool _wasPlayingBeforeBackground = false;
  bool _isDisposed = false;

  bool get isEnabled => _enabled;
  bool get isPlaying => _manager.isPlaying;
  bool get isPaused => _manager.isPaused;
  MusicPlaylistManager get playlistManager => _manager;

  Future<SharedPreferences> _prefsInstance() async {
    final SharedPreferences? cached = _prefs;
    if (cached != null) {
      return cached;
    }
    final SharedPreferences created = await SharedPreferences.getInstance();
    _prefs = created;
    return created;
  }

  /// Initializes the music manager, loads the persisted preference,
  /// attaches lifecycle listeners, and starts playback if music is enabled.
  Future<void> initialize() async {
    if (_isDisposed) {
      return;
    }
    await loadPreference();
    await _manager.initialize();
    _registerLifecycle();
    if (_enabled) {
      await _manager.play();
    }
  }

  void _registerLifecycle() {
    if (!_lifecycleRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleRegistered = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed || !_enabled) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        if (_wasPlayingBeforeBackground) {
          _wasPlayingBeforeBackground = false;
          unawaited(_manager.resume());
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_manager.isPlaying && !_manager.isPaused) {
          _wasPlayingBeforeBackground = true;
          unawaited(_manager.pause());
        }
        break;
    }
  }

  /// Loads the persisted enabled flag (default on).
  Future<void> loadPreference() async {
    try {
      final SharedPreferences prefs = await _prefsInstance();
      _enabled = prefs.getBool(_enabledKey) ?? true;
      _manager.setEnabled(_enabled);
    } catch (error) {
      _logger.warn('Music preference load failed: $error');
    }
  }

  /// Toggles music enabled state and persists the preference.
  ///
  /// Enabling begins/resumes playback; disabling stops playback immediately.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    _manager.setEnabled(value);
    try {
      final SharedPreferences prefs = await _prefsInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (error) {
      _logger.warn('Music preference save failed: $error');
    }

    if (value) {
      await play();
    } else {
      await stop();
    }
  }

  /// Starts playback of the music playlist.
  Future<void> play({int? trackIndex}) async {
    if (!_enabled || _isDisposed) {
      return;
    }
    await _manager.play(trackIndex: trackIndex);
  }

  /// Stops music playback.
  Future<void> stop() async {
    _wasPlayingBeforeBackground = false;
    await _manager.stop();
  }

  /// Pauses music playback.
  Future<void> pause() async {
    await _manager.pause();
  }

  /// Resumes music playback if enabled.
  Future<void> resume() async {
    if (!_enabled || _isDisposed) {
      return;
    }
    await _manager.resume();
  }

  /// Applies temporary ducking (-3 dB for 150 ms default) over the current volume.
  void duck({
    Duration duration = MusicPlaylistManager.kDefaultDuckDuration,
    double factor = MusicPlaylistManager.kDuckFactorMinus3dB,
  }) {
    if (!_enabled || _isDisposed) {
      return;
    }
    _manager.duck(duration: duration, factor: factor);
  }

  /// Releases resources, unregisters lifecycle hooks, and stops playback.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    if (_lifecycleRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _lifecycleRegistered = false;
    }
    await _manager.dispose();
  }
}
