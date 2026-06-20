import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';

/// Background-music controller (looping) built on `FlameAudio.bgm`. The
/// enabled state is persisted; failures are non-fatal (music simply stays
/// silent and logs a warning).
class MusicController {
  MusicController({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;
  static const String _enabledKey = 'music_enabled';
  static const String _track = 'music_loop.wav';
  static const String _audioPrefix = 'assets/audio/';

  bool _enabled = true;
  bool _playing = false;
  SharedPreferences? _prefs;

  bool get isEnabled => _enabled;

  Future<SharedPreferences> _prefsInstance() async {
    final SharedPreferences? cached = _prefs;
    if (cached != null) {
      return cached;
    }
    final SharedPreferences created = await SharedPreferences.getInstance();
    _prefs = created;
    return created;
  }

  /// Loads the persisted enabled flag (default on). Call before [play].
  Future<void> loadPreference() async {
    try {
      final SharedPreferences prefs = await _prefsInstance();
      _enabled = prefs.getBool(_enabledKey) ?? true;
    } catch (error) {
      _logger.warn('Music preference load failed: $error');
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      final SharedPreferences prefs = await _prefsInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (error) {
      _logger.warn('Music preference save failed: $error');
    }
    // Enabling only persists the preference (the active game screen starts
    // playback); disabling stops any current playback immediately.
    if (!value) {
      await stop();
    }
  }

  Future<void> play() async {
    if (!_enabled) {
      return;
    }
    try {
      FlameAudio.updatePrefix(_audioPrefix);
      await FlameAudio.bgm.play(_track, volume: 0.32);
      _playing = true;
    } catch (error) {
      _logger.warn('Music play failed: $error');
    }
  }

  Future<void> stop() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (error) {
      _logger.warn('Music stop failed: $error');
    }
    _playing = false;
  }

  Future<void> pause() async {
    if (!_playing) {
      return;
    }
    try {
      await FlameAudio.bgm.pause();
    } catch (error) {
      _logger.warn('Music pause failed: $error');
    }
  }

  Future<void> resume() async {
    if (!_enabled || !_playing) {
      return;
    }
    try {
      await FlameAudio.bgm.resume();
    } catch (error) {
      _logger.warn('Music resume failed: $error');
    }
  }
}
