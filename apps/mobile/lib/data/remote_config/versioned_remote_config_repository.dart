import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import 'bundled_remote_config_defaults.dart';
import 'remote_config_repository.dart';
import 'remote_config_snapshot.dart';

class VersionedRemoteConfigRepository implements RemoteConfigRepository {
  VersionedRemoteConfigRepository({
    required AppConfig appConfig,
    required AppLogger logger,
    http.Client? httpClient,
    DateTime Function()? nowUtcProvider,
  })  : _appConfig = appConfig,
        _logger = logger,
        _httpClient = httpClient ?? http.Client(),
        _nowUtc = nowUtcProvider ?? (() => DateTime.now().toUtc());

  static const String _activeSnapshotKey = 'remote_config_snapshot_active_v1';
  static const String _rollbackSnapshotKey =
      'remote_config_snapshot_rollback_v1';

  final AppConfig _appConfig;
  final AppLogger _logger;
  final http.Client _httpClient;
  final DateTime Function() _nowUtc;

  SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async {
    final SharedPreferences? cached = _preferences;
    if (cached != null) {
      return cached;
    }
    final SharedPreferences created = await SharedPreferences.getInstance();
    _preferences = created;
    return created;
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
    final RemoteConfigSnapshot cachedSnapshot = await getCachedSnapshot();
    if (!_appConfig.hasConfigApi) {
      return cachedSnapshot;
    }

    final Uri uri = Uri.parse(
      '${_appConfig.configApiBaseUrl}/v1/config/latest',
    );

    try {
      final http.Response response = await _httpClient.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _logger.warn(
          'Remote config fetch failed with ${response.statusCode}. '
          'Using cached snapshot ${cachedSnapshot.version}.',
        );
        return cachedSnapshot;
      }

      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        _logger.warn('Remote config response is not an object.');
        return cachedSnapshot;
      }

      final Map<String, Object?> payload = decoded.cast<String, Object?>();
      final Map<String, Object?> nextConfig =
          _readConfigMap(payload['config']) ?? bundledRemoteConfigDefaults;
      final String version =
          (payload['version'] as String?)?.trim().isNotEmpty == true
              ? (payload['version'] as String).trim()
              : _appConfig.bundledRemoteConfigVersion;
      final int ttlSeconds = _readInt(
        payload['ttl_seconds'],
        fallback: _appConfig.remoteConfigTtl.inSeconds,
      );
      final RemoteConfigSnapshot fetchedSnapshot = RemoteConfigSnapshot(
        version: version,
        config: nextConfig,
        fetchedAtUtc: _nowUtc(),
        ttl: Duration(seconds: ttlSeconds.clamp(30, 86400)),
        source: RemoteConfigSource.remote,
      );
      await applySnapshot(fetchedSnapshot);
      return fetchedSnapshot;
    } catch (error) {
      _logger.warn(
        'Remote config fetch threw $error. Using cached snapshot '
        '${cachedSnapshot.version}.',
      );
      return cachedSnapshot;
    }
  }

  @override
  Future<RemoteConfigSnapshot> getCachedSnapshot() async {
    final SharedPreferences preferences = await _prefs();
    final String? rawJson = preferences.getString(_activeSnapshotKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return _bundledSnapshot();
    }

    try {
      final RemoteConfigSnapshot snapshot =
          RemoteConfigSnapshot.fromJsonString(rawJson);
      if (snapshot.isFreshAt(_nowUtc())) {
        return snapshot.copyWith(source: RemoteConfigSource.cache);
      }
      return snapshot.copyWith(source: RemoteConfigSource.cache);
    } catch (error) {
      _logger.warn('Remote config cache decode failed: $error');
      await preferences.remove(_activeSnapshotKey);
      return _bundledSnapshot();
    }
  }

  @override
  Future<void> applySnapshot(RemoteConfigSnapshot snapshot) async {
    final SharedPreferences preferences = await _prefs();
    final String? previousRawJson = preferences.getString(_activeSnapshotKey);
    if (previousRawJson != null && previousRawJson.trim().isNotEmpty) {
      await preferences.setString(_rollbackSnapshotKey, previousRawJson);
    }
    await preferences.setString(
      _activeSnapshotKey,
      snapshot.copyWith(source: RemoteConfigSource.applied).toJsonString(),
    );
  }

  @override
  Future<RemoteConfigSnapshot?> getRollbackSnapshot() async {
    final SharedPreferences preferences = await _prefs();
    final String? rawJson = preferences.getString(_rollbackSnapshotKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return null;
    }
    try {
      return RemoteConfigSnapshot.fromJsonString(rawJson).copyWith(
        source: RemoteConfigSource.rollback,
      );
    } catch (error) {
      _logger.warn('Remote config rollback decode failed: $error');
      await preferences.remove(_rollbackSnapshotKey);
      return null;
    }
  }

  RemoteConfigSnapshot _bundledSnapshot() {
    return RemoteConfigSnapshot(
      version: _appConfig.bundledRemoteConfigVersion,
      config: Map<String, Object?>.from(bundledRemoteConfigDefaults),
      fetchedAtUtc: _nowUtc(),
      ttl: _appConfig.remoteConfigTtl,
      source: RemoteConfigSource.bundled,
    );
  }

  Map<String, Object?>? _readConfigMap(Object? rawValue) {
    if (rawValue is Map<String, Object?>) {
      return rawValue;
    }
    if (rawValue is Map) {
      return rawValue.cast<String, Object?>();
    }
    return null;
  }

  int _readInt(
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
}
