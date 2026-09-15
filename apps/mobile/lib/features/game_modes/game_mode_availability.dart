import '../../core/config/remote_config_reader.dart';

/// The three playable modes, as the kill switches name them.
enum GameMode {
  classic('classic'),
  tetris('tetris'),
  match3('match3');

  const GameMode(this.id);

  /// Matches `game_id` in analytics and the middle word of the flag key.
  final String id;

  /// The Remote Config parameter that gates this mode.
  ///
  /// Already Firebase-safe, so [RemoteConfigKeyMap] passes it through
  /// unchanged in both directions.
  String get flagKey => 'feature_${id}_enabled';
}

/// Answers whether a mode may be entered, from live Remote Config.
///
/// DEC-0002 requires a kill switch per mode so a failing one can be disabled
/// without shipping a patch. The three flags were published to Firebase, but
/// nothing read them: the home screen opened all three unconditionally, so the
/// switches existed and did nothing. This is the consumer.
///
/// The flags default to enabled. A mode is turned off deliberately, and a
/// config fetch that fails should not take the game down with it - a player
/// with a flaky connection must still be able to play.
class GameModeAvailability {
  const GameModeAvailability(this._reader);

  final RemoteConfigReader _reader;

  bool isEnabled(GameMode mode) =>
      _reader.readBool(mode.flagKey, fallback: true);

  /// Modes currently open, in menu order.
  List<GameMode> get enabled =>
      GameMode.values.where(isEnabled).toList(growable: false);

  /// Whether every mode is off, which is a configuration mistake rather than a
  /// state the product intends. Callers can use it to show something more
  /// useful than an empty screen.
  bool get allDisabled => enabled.isEmpty;
}
