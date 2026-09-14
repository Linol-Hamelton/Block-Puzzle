import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import 'bundled_remote_config_defaults.dart';
import 'remote_config_key_map.dart';
import 'remote_config_repository.dart';
import 'remote_config_snapshot.dart';

class FirebaseRemoteConfigRepository implements RemoteConfigRepository {
  FirebaseRemoteConfigRepository({
    required AppConfig appConfig,
    required AppLogger logger,
  })  : _appConfig = appConfig,
        _logger = logger;

  final AppConfig _appConfig;
  final AppLogger _logger;
  final RemoteConfigKeyMap _keyMap = RemoteConfigKeyMap.fromDefaults();

  // We keep a snapshot cache in memory to fulfill the interface
  RemoteConfigSnapshot? _inMemorySnapshot;

  /// Overlays whatever the remote returned on top of the bundled defaults.
  ///
  /// The previous version substituted one for the other: any non-empty remote
  /// response replaced the defaults wholesale. Since no remote key could ever
  /// match a dotted local key, the first successful fetch would have dropped
  /// all 54 settings at once and left the app running on whatever handful of
  /// parameters happened to be published. Defaults are the floor; the remote
  /// only overrides individual keys.
  Map<String, Object?> _mergeOverDefaults(Map<String, Object?> remoteValues) {
    return <String, Object?>{
      ...bundledRemoteConfigDefaults,
      ...remoteValues,
    };
  }

  /// Rejects a remote value whose type does not match the bundled default.
  ///
  /// A flag published as the string `"false"` is truthy if taken at face value,
  /// and a kill switch that cannot be trusted to be a bool is worse than no
  /// kill switch. Unknown keys - the DEC-0002 mode flags, for instance - have
  /// no default to compare against and are accepted as parsed.
  Object? _coerceToDefaultType(String internalKey, Object? parsed, String raw) {
    final Object? fallback = bundledRemoteConfigDefaults[internalKey];
    if (fallback == null) {
      return parsed;
    }
    if (fallback is bool) {
      if (parsed is bool) {
        return parsed;
      }
      final String normalized = raw.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
      _logger.warn(
        'Remote config "$internalKey" expected bool, got "$raw"; keeping default',
      );
      return null;
    }
    if (fallback is num) {
      if (parsed is num) {
        return parsed;
      }
      final num? asNumber = num.tryParse(raw.trim());
      if (asNumber != null) {
        return asNumber;
      }
      _logger.warn(
        'Remote config "$internalKey" expected num, got "$raw"; keeping default',
      );
      return null;
    }
    if (fallback is String) {
      return parsed is String ? parsed : raw;
    }
    return parsed;
  }

  @override
  Future<Map<String, Object?>> fetchLatest() async {
    return (await fetchLatestSnapshot()).config;
  }

  @override
  Future<Map<String, Object?>> getCached() async {
    return (await getCachedSnapshot()).config;
  }

  @override
  Future<RemoteConfigSnapshot> fetchLatestSnapshot() async {
    try {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: _appConfig.remoteConfigTtl,
      ));
      
      await remoteConfig.fetchAndActivate();
      
      final Map<String, RemoteConfigValue> allValues = remoteConfig.getAll();
      final Map<String, Object?> remoteValues = <String, Object?>{};

      for (final MapEntry<String, RemoteConfigValue> entry
          in allValues.entries) {
        final String internalKey = _keyMap.toInternal(entry.key);
        final String raw = entry.value.asString();
        // Complex values arrive as JSON strings; scalars arrive as text.
        Object? parsed;
        try {
          parsed = jsonDecode(raw);
        } catch (_) {
          parsed = raw;
        }
        final Object? accepted = _coerceToDefaultType(internalKey, parsed, raw);
        if (accepted != null) {
          remoteValues[internalKey] = accepted;
        }
      }

      _inMemorySnapshot = RemoteConfigSnapshot(
        version: 'firebase_latest',
        config: _mergeOverDefaults(remoteValues),
        fetchedAtUtc: DateTime.now().toUtc(),
        ttl: _appConfig.remoteConfigTtl,
        source: RemoteConfigSource.remote,
      );

      return _inMemorySnapshot!;
    } catch (e) {
      _logger.warn('Failed to fetch from Firebase Remote Config: $e');
      return getCachedSnapshot();
    }
  }

  @override
  Future<RemoteConfigSnapshot> getCachedSnapshot() async {
    if (_inMemorySnapshot != null) {
      return _inMemorySnapshot!;
    }
    
    // Fallback to bundled
    return RemoteConfigSnapshot(
      version: _appConfig.bundledRemoteConfigVersion,
      config: Map<String, Object?>.from(bundledRemoteConfigDefaults),
      fetchedAtUtc: DateTime.now().toUtc(),
      ttl: _appConfig.remoteConfigTtl,
      source: RemoteConfigSource.bundled,
    );
  }

  @override
  Future<void> applySnapshot(RemoteConfigSnapshot snapshot) async {
    _inMemorySnapshot = snapshot;
  }

  @override
  Future<RemoteConfigSnapshot?> getRollbackSnapshot() async {
    // Rollback logic is managed by Firebase natively, so we just return null
    return null;
  }
}
