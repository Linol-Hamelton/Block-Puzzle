import 'package:block_puzzle_mobile/data/remote_config/bundled_remote_config_defaults.dart';
import 'package:block_puzzle_mobile/data/remote_config/remote_config_key_map.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase Remote Config parameter names accept letters, digits and
/// underscores. Every key this app uses internally contains dots, so without a
/// translation layer no remote parameter can ever match a local one and remote
/// config is inert - visibly fine, actually dead.
void main() {
  group('name translation', () {
    test('dots become underscores in both directions', () {
      final RemoteConfigKeyMap map = RemoteConfigKeyMap.fromDefaults();

      expect(RemoteConfigKeyMap.toExternal('ads.ad_free_mode'),
          'ads_ad_free_mode');
      expect(map.toInternal('ads_ad_free_mode'), 'ads.ad_free_mode');
    });

    test('nested keys with two dots survive the round trip', () {
      final RemoteConfigKeyMap map = RemoteConfigKeyMap.fromDefaults();

      expect(RemoteConfigKeyMap.toExternal('ops.alerting.enabled'),
          'ops_alerting_enabled');
      expect(map.toInternal('ops_alerting_enabled'), 'ops.alerting.enabled');
    });

    test('every bundled key round-trips', () {
      final RemoteConfigKeyMap map = RemoteConfigKeyMap.fromDefaults();

      for (final String internal in bundledRemoteConfigDefaults.keys) {
        expect(
          map.toInternal(RemoteConfigKeyMap.toExternal(internal)),
          internal,
          reason: '$internal did not survive the round trip',
        );
      }
    });

    test('unknown remote keys pass through untouched', () {
      final RemoteConfigKeyMap map = RemoteConfigKeyMap.fromDefaults();

      // The per-mode kill switches from DEC-0002 are already Firebase-safe and
      // have no bundled default; they must not be mangled.
      expect(map.toInternal('feature_tetris_enabled'), 'feature_tetris_enabled');
      expect(map.toInternal('feature_match3_enabled'), 'feature_match3_enabled');
      expect(map.isKnown('feature_tetris_enabled'), isFalse);
      expect(map.isKnown('ads_ad_free_mode'), isTrue);
    });
  });

  group('key set health', () {
    test('no two internal keys map onto the same Firebase name', () {
      expect(
        RemoteConfigKeyMap.collisions(),
        isEmpty,
        reason: 'A collision means one of the two keys is silently lost '
            'remotely. Rename one of them before adding it.',
      );
    });

    test('every bundled key produces a name Firebase will accept', () {
      expect(
        RemoteConfigKeyMap.invalidExternalNames(),
        isEmpty,
        reason: 'Firebase parameter names allow only letters, digits and '
            'underscores, and must not start with a digit.',
      );
    });

    test('a colliding key set is reported rather than silently accepted', () {
      final Map<String, Object?> colliding = <String, Object?>{
        'a.b_c': 1,
        'a_b.c': 2,
      };

      final Map<String, List<String>> found =
          RemoteConfigKeyMap.collisions(colliding);

      expect(found.keys, contains('a_b_c'));
      expect(found['a_b_c'], containsAll(<String>['a.b_c', 'a_b.c']));
    });

    test('a key Firebase would reject is reported', () {
      expect(
        RemoteConfigKeyMap.invalidExternalNames(<String, Object?>{
          '9.starts_with_digit': true,
          'has-a-dash': true,
        }),
        containsAll(<String>['9_starts_with_digit', 'has-a-dash']),
      );
    });
  });
}
