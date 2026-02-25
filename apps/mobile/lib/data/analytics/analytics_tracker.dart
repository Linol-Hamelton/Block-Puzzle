abstract interface class AnalyticsTracker {
  Future<void> track(
    String eventName, {
    Map<String, Object?> params = const <String, Object?>{},
  });
}
