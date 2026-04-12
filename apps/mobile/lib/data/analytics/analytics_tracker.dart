abstract interface class AnalyticsTracker {
  Future<void> track(
    String eventName, {
    Map<String, Object?> params = const <String, Object?>{},
  });

  Future<void> flush({
    bool force = false,
  });

  Future<void> close();
}
