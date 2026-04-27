import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import 'bundled_remote_config_defaults.dart';
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
  
  // We keep a snapshot cache in memory to fulfill the interface
  RemoteConfigSnapshot? _inMemorySnapshot;

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
      final Map<String, Object?> parsedConfig = {};
      
      for (final entry in allValues.entries) {
        // Assume json string for complex objects, otherwise just the value
        try {
          parsedConfig[entry.key] = jsonDecode(entry.value.asString());
        } catch (_) {
          parsedConfig[entry.key] = entry.value.asString();
        }
      }

      _inMemorySnapshot = RemoteConfigSnapshot(
        version: 'firebase_latest',
        config: parsedConfig.isNotEmpty ? parsedConfig : bundledRemoteConfigDefaults,
        fetchedAtUtc: DateTime.now().toUtc(),
        ttl: _appConfig.remoteConfigTtl,
        source: RemoteConfigSource.remote,
      );
      
      return _inMemorySnapshot!;
    } catch (e) {
      _logger.warn('Failed to fetch from Firebase Remote Config: $e');
      return await getCachedSnapshot();
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
