import '../../core/config/app_config.dart';
import 'bundled_remote_config_defaults.dart';
import 'remote_config_repository.dart';
import 'remote_config_snapshot.dart';

class InMemoryRemoteConfigRepository implements RemoteConfigRepository {
  InMemoryRemoteConfigRepository({
    AppConfig? appConfig,
    Map<String, Object?>? initialConfig,
  })  : _appConfig = appConfig ?? AppConfig.fromEnvironment(),
        _activeSnapshot = RemoteConfigSnapshot(
          version: (appConfig ?? AppConfig.fromEnvironment())
              .bundledRemoteConfigVersion,
          config: Map<String, Object?>.from(
            initialConfig ?? bundledRemoteConfigDefaults,
          ),
          fetchedAtUtc: DateTime.now().toUtc(),
          ttl: (appConfig ?? AppConfig.fromEnvironment()).remoteConfigTtl,
          source: RemoteConfigSource.bundled,
        );

  final AppConfig _appConfig;
  RemoteConfigSnapshot _activeSnapshot;
  RemoteConfigSnapshot? _rollbackSnapshot;

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
    return _activeSnapshot;
  }

  @override
  Future<RemoteConfigSnapshot> getCachedSnapshot() async {
    return _activeSnapshot;
  }

  @override
  Future<void> applySnapshot(RemoteConfigSnapshot snapshot) async {
    _rollbackSnapshot = _activeSnapshot.copyWith(
      source: RemoteConfigSource.rollback,
    );
    _activeSnapshot = snapshot.copyWith(
      ttl: snapshot.ttl <= Duration.zero ? _appConfig.remoteConfigTtl : null,
      source: RemoteConfigSource.applied,
    );
  }

  @override
  Future<RemoteConfigSnapshot?> getRollbackSnapshot() async {
    return _rollbackSnapshot;
  }
}
