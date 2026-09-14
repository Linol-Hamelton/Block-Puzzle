import 'bundled_remote_config_defaults.dart';

/// Translates between the app's internal config keys and the names Firebase
/// Remote Config will accept.
///
/// The app has always used dotted keys (`ads.ad_free_mode`,
/// `ops.alerting.enabled`). Firebase parameter names allow letters, digits and
/// underscores only - a dot is rejected - so those keys can never exist
/// remotely. Until this map existed, every remote key silently failed to match
/// a local one, which is invisible until the day someone tries to flip a flag
/// in production and nothing happens.
///
/// The rule is one substitution: `.` becomes `_`. Applied to the 54 bundled
/// keys it produces no collisions, which [RemoteConfigKeyMap.collisions]
/// re-checks so a future key that does collide is caught by a test rather than
/// by a silent overwrite.
///
/// Keys the app does not know about - `feature_tetris_enabled` and the other
/// kill switches from DEC-0002 - pass through untouched in both directions.
class RemoteConfigKeyMap {
  RemoteConfigKeyMap._(this._externalToInternal);

  /// Built from the bundled defaults, which are the authoritative key set.
  factory RemoteConfigKeyMap.fromDefaults([
    Map<String, Object?>? defaults,
  ]) {
    final Map<String, Object?> source = defaults ?? bundledRemoteConfigDefaults;
    final Map<String, String> externalToInternal = <String, String>{};
    for (final String internal in source.keys) {
      externalToInternal[toExternal(internal)] = internal;
    }
    return RemoteConfigKeyMap._(externalToInternal);
  }

  final Map<String, String> _externalToInternal;

  /// Internal (dotted) name to the Firebase parameter name.
  static String toExternal(String internalKey) =>
      internalKey.replaceAll('.', '_');

  /// Firebase parameter name back to the internal (dotted) name.
  ///
  /// Unknown names are returned unchanged: the reverse direction cannot be
  /// computed, because internal keys contain underscores of their own, so it
  /// is a lookup and not a transformation.
  String toInternal(String externalKey) =>
      _externalToInternal[externalKey] ?? externalKey;

  /// Whether this external name maps onto a key the app knows.
  bool isKnown(String externalKey) =>
      _externalToInternal.containsKey(externalKey);

  /// External names that more than one internal key would produce.
  ///
  /// Empty for the current key set. A non-empty result means two internal keys
  /// would fight over one Firebase parameter and one of them would be lost.
  static Map<String, List<String>> collisions([
    Map<String, Object?>? defaults,
  ]) {
    final Map<String, Object?> source = defaults ?? bundledRemoteConfigDefaults;
    final Map<String, List<String>> byExternal = <String, List<String>>{};
    for (final String internal in source.keys) {
      byExternal.putIfAbsent(toExternal(internal), () => <String>[]).add(internal);
    }
    byExternal.removeWhere((_, List<String> internals) => internals.length < 2);
    return byExternal;
  }

  /// Names that Firebase would reject outright.
  static List<String> invalidExternalNames([
    Map<String, Object?>? defaults,
  ]) {
    final Map<String, Object?> source = defaults ?? bundledRemoteConfigDefaults;
    final RegExp allowed = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
    return source.keys
        .map(toExternal)
        .where((String external) => !allowed.hasMatch(external))
        .toList(growable: false);
  }
}
