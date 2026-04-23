/// Utility class for reading typed values from a remote config map.
///
/// Centralizes the type-coercion logic that was previously duplicated
/// in [GameLoopController] and [di_container.dart].
class RemoteConfigReader {
  const RemoteConfigReader(this._config);

  final Map<String, Object?> _config;

  Map<String, Object?> get raw => _config;

  bool readBool(
    String key, {
    required bool fallback,
  }) {
    final Object? rawValue = _config[key];
    if (rawValue is bool) {
      return rawValue;
    }
    if (rawValue is String) {
      final String normalized = rawValue.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    if (rawValue is num) {
      return rawValue > 0;
    }
    return fallback;
  }

  int readInt(
    String key, {
    required int fallback,
  }) {
    final Object? rawValue = _config[key];
    if (rawValue is int) {
      return rawValue;
    }
    if (rawValue is num) {
      return rawValue.toInt();
    }
    if (rawValue is String) {
      return int.tryParse(rawValue) ?? fallback;
    }
    return fallback;
  }

  String readString(
    String key, {
    required String fallback,
  }) {
    final Object? rawValue = _config[key];
    if (rawValue is String && rawValue.trim().isNotEmpty) {
      return rawValue.trim();
    }
    return fallback;
  }
}
