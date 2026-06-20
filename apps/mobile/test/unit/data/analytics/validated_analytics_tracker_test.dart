import 'package:block_puzzle_mobile/core/logging/app_logger.dart';
import 'package:block_puzzle_mobile/data/analytics/analytics_tracker.dart';
import 'package:block_puzzle_mobile/data/analytics/validated_analytics_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingTracker implements AnalyticsTracker {
  final List<({String name, Map<String, Object?> params})> tracked =
      <({String name, Map<String, Object?> params})>[];
  int flushCount = 0;
  int closeCount = 0;

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {
    tracked.add((name: eventName, params: params));
  }

  @override
  Future<void> flush({bool force = false}) async {
    flushCount += 1;
  }

  @override
  Future<void> close() async {
    closeCount += 1;
  }
}

void main() {
  group('ValidatedAnalyticsTracker', () {
    late _RecordingTracker inner;
    late ValidatedAnalyticsTracker tracker;

    setUp(() {
      inner = _RecordingTracker();
      tracker = ValidatedAnalyticsTracker(
        inner: inner,
        logger: AppLogger(),
        nowUtcProvider: () => DateTime.utc(2026, 6, 19, 12),
      );
    });

    test('forwards a valid event and enriches it with schema + timestamp',
        () async {
      await tracker.track(
        'game_start',
        params: <String, Object?>{
          'round_id': 7,
          'mode': 'classic',
          'config_version': 'cfg-01',
        },
      );

      expect(inner.tracked, hasLength(1));
      final Map<String, Object?> sent = inner.tracked.single.params;
      expect(inner.tracked.single.name, 'game_start');
      expect(sent['schema_version'], isNotNull);
      expect(sent['event_ts_utc'], '2026-06-19T12:00:00.000Z');
      // Original params are preserved.
      expect(sent['round_id'], 7);
      expect(sent['mode'], 'classic');
    });

    test('quarantines an event missing required params (never forwarded)',
        () async {
      await tracker.track(
        'game_start',
        params: <String, Object?>{
          // round_id / mode / config_version are required and absent.
        },
      );

      expect(inner.tracked, isEmpty);
    });

    test('forwards unknown events (partial validation, warning only)', () async {
      await tracker.track(
        'totally_new_event',
        params: <String, Object?>{'x': 1},
      );

      expect(inner.tracked, hasLength(1));
      expect(inner.tracked.single.params['schema_version'], isNotNull);
    });

    test('does not mutate the caller-provided params map', () async {
      final Map<String, Object?> original = <String, Object?>{
        'round_id': 1,
        'mode': 'classic',
        'config_version': 'cfg',
      };
      await tracker.track('game_start', params: original);

      expect(original.containsKey('schema_version'), isFalse);
      expect(original.containsKey('event_ts_utc'), isFalse);
    });

    test('delegates flush and close to the inner transport', () async {
      await tracker.flush(force: true);
      await tracker.close();

      expect(inner.flushCount, 1);
      expect(inner.closeCount, 1);
    });
  });
}
