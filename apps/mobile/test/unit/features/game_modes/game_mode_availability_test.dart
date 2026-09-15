import 'package:block_puzzle_mobile/core/config/remote_config_reader.dart';
import 'package:block_puzzle_mobile/data/remote_config/remote_config_key_map.dart';
import 'package:block_puzzle_mobile/features/game_modes/game_mode_availability.dart';
import 'package:flutter_test/flutter_test.dart';

/// DEC-0002 requires a kill switch per mode. The flags were published to
/// Firebase and read by nothing for a while, so these tests pin the consumer:
/// the names the client looks for, the default when config is missing, and the
/// fact that a published `false` actually closes the mode.
void main() {
  GameModeAvailability availabilityFrom(Map<String, Object?> config) =>
      GameModeAvailability(RemoteConfigReader(config));

  group('flag keys', () {
    test('match the parameter names published to Firebase', () {
      expect(GameMode.classic.flagKey, 'feature_classic_enabled');
      expect(GameMode.tetris.flagKey, 'feature_tetris_enabled');
      expect(GameMode.match3.flagKey, 'feature_match3_enabled');
    });

    test('survive the Remote Config key translation untouched', () {
      // They contain no dots, so the translator must pass them through in both
      // directions. If that ever changes, the client would look up a name the
      // server does not publish and every mode would silently fall back to
      // enabled.
      final RemoteConfigKeyMap map = RemoteConfigKeyMap.fromDefaults();
      for (final GameMode mode in GameMode.values) {
        expect(RemoteConfigKeyMap.toExternal(mode.flagKey), mode.flagKey);
        expect(map.toInternal(mode.flagKey), mode.flagKey);
      }
    });

    test('the mode id matches the analytics game_id', () {
      expect(GameMode.classic.id, 'classic');
      expect(GameMode.tetris.id, 'tetris');
      expect(GameMode.match3.id, 'match3');
    });
  });

  group('availability', () {
    test('defaults to enabled when the flag is absent', () {
      // A failed config fetch must not take the game down. Switching a mode off
      // is a deliberate act; missing config is not.
      final GameModeAvailability modes = availabilityFrom(<String, Object?>{});

      for (final GameMode mode in GameMode.values) {
        expect(modes.isEnabled(mode), isTrue, reason: mode.id);
      }
      expect(modes.allDisabled, isFalse);
    });

    test('a published false closes that mode and no other', () {
      final GameModeAvailability modes = availabilityFrom(<String, Object?>{
        'feature_tetris_enabled': false,
      });

      expect(modes.isEnabled(GameMode.tetris), isFalse);
      expect(modes.isEnabled(GameMode.classic), isTrue);
      expect(modes.isEnabled(GameMode.match3), isTrue);
      expect(modes.enabled, <GameMode>[GameMode.classic, GameMode.match3]);
    });

    test('accepts the string form Remote Config can deliver', () {
      // Firebase parameters travel as strings; a flag arriving as "false" must
      // not be read as truthy.
      final GameModeAvailability modes = availabilityFrom(<String, Object?>{
        'feature_match3_enabled': 'false',
      });

      expect(modes.isEnabled(GameMode.match3), isFalse);
    });

    test('reports when every mode is off', () {
      final GameModeAvailability modes = availabilityFrom(<String, Object?>{
        'feature_classic_enabled': false,
        'feature_tetris_enabled': false,
        'feature_match3_enabled': false,
      });

      expect(modes.enabled, isEmpty);
      expect(modes.allDisabled, isTrue);
    });

    test('enabled preserves menu order', () {
      final GameModeAvailability modes = availabilityFrom(<String, Object?>{});

      expect(
        modes.enabled,
        <GameMode>[GameMode.classic, GameMode.tetris, GameMode.match3],
      );
    });
  });
}
