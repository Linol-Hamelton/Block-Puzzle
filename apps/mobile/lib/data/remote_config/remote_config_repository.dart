import 'remote_config_snapshot.dart';

abstract interface class RemoteConfigRepository {
  Future<Map<String, Object?>> fetchLatest();

  Future<Map<String, Object?>> getCached();

  Future<RemoteConfigSnapshot> fetchLatestSnapshot();

  Future<RemoteConfigSnapshot> getCachedSnapshot();

  Future<void> applySnapshot(RemoteConfigSnapshot snapshot);

  Future<RemoteConfigSnapshot?> getRollbackSnapshot();
}
