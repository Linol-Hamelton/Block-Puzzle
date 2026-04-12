import 'dart:convert';

enum RemoteConfigSource {
  bundled,
  cache,
  remote,
  applied,
  rollback;

  static RemoteConfigSource fromWire(String rawValue) {
    switch (rawValue.trim().toLowerCase()) {
      case 'cache':
        return RemoteConfigSource.cache;
      case 'remote':
        return RemoteConfigSource.remote;
      case 'applied':
        return RemoteConfigSource.applied;
      case 'rollback':
        return RemoteConfigSource.rollback;
      case 'bundled':
      default:
        return RemoteConfigSource.bundled;
    }
  }
}

class RemoteConfigSnapshot {
  const RemoteConfigSnapshot({
    required this.version,
    required this.config,
    required this.fetchedAtUtc,
    required this.ttl,
    required this.source,
  });

  final String version;
  final Map<String, Object?> config;
  final DateTime fetchedAtUtc;
  final Duration ttl;
  final RemoteConfigSource source;

  bool isFreshAt(DateTime nowUtc) {
    if (ttl <= Duration.zero) {
      return false;
    }
    return fetchedAtUtc.add(ttl).isAfter(nowUtc);
  }

  RemoteConfigSnapshot copyWith({
    String? version,
    Map<String, Object?>? config,
    DateTime? fetchedAtUtc,
    Duration? ttl,
    RemoteConfigSource? source,
  }) {
    return RemoteConfigSnapshot(
      version: version ?? this.version,
      config: config ?? this.config,
      fetchedAtUtc: fetchedAtUtc ?? this.fetchedAtUtc,
      ttl: ttl ?? this.ttl,
      source: source ?? this.source,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'version': version,
      'config': config,
      'fetched_at_utc': fetchedAtUtc.toIso8601String(),
      'ttl_seconds': ttl.inSeconds,
      'source': source.name,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory RemoteConfigSnapshot.fromJson(Map<String, Object?> json) {
    final Object? rawConfig = json['config'];
    final Map<String, Object?> castConfig;
    if (rawConfig is Map<String, Object?>) {
      castConfig = rawConfig;
    } else if (rawConfig is Map) {
      castConfig = rawConfig.cast<String, Object?>();
    } else {
      castConfig = const <String, Object?>{};
    }

    return RemoteConfigSnapshot(
      version: (json['version'] as String?)?.trim().isNotEmpty == true
          ? (json['version'] as String).trim()
          : 'bundled_config_v1',
      config: castConfig,
      fetchedAtUtc: _readDateTime(
        json['fetched_at_utc'],
        fallback: DateTime.utc(1970, 1, 1),
      ),
      ttl: Duration(
        seconds: _readInt(json['ttl_seconds'], fallback: 0).clamp(0, 86400),
      ),
      source: RemoteConfigSource.fromWire(
        (json['source'] as String?) ?? 'bundled',
      ),
    );
  }

  factory RemoteConfigSnapshot.fromJsonString(String rawJson) {
    final Object? decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('Remote config snapshot must be an object.');
    }
    return RemoteConfigSnapshot.fromJson(
      decoded.cast<String, Object?>(),
    );
  }

  static int _readInt(
    Object? rawValue, {
    required int fallback,
  }) {
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

  static DateTime _readDateTime(
    Object? rawValue, {
    required DateTime fallback,
  }) {
    if (rawValue is String) {
      return DateTime.tryParse(rawValue)?.toUtc() ?? fallback;
    }
    return fallback;
  }
}
