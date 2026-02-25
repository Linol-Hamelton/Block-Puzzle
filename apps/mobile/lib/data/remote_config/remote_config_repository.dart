abstract interface class RemoteConfigRepository {
  Future<Map<String, Object?>> fetchLatest();

  Future<Map<String, Object?>> getCached();
}
