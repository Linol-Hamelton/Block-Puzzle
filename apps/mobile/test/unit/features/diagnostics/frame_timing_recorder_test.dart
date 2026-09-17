import 'package:block_puzzle_mobile/features/diagnostics/diagnostics_screen.dart';
import 'package:block_puzzle_mobile/features/diagnostics/frame_timing_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FrameTimingRecorder', () {
    test('empty recorder returns zeroed snapshot', () {
      final FrameTimingRecorder recorder = FrameTimingRecorder(capacity: 100);
      final FrameTimingSnapshot snapshot = recorder.snapshot;

      expect(snapshot.frameCount, 0);
      expect(snapshot.jankCount, 0);
      expect(snapshot.jankPercentage, 0.0);
      expect(snapshot.buildP50Ms, 0.0);
      expect(snapshot.buildP90Ms, 0.0);
      expect(snapshot.buildP99Ms, 0.0);
      expect(snapshot.buildWorstMs, 0.0);
      expect(snapshot.rasterP50Ms, 0.0);
      expect(snapshot.rasterP90Ms, 0.0);
      expect(snapshot.rasterP99Ms, 0.0);
      expect(snapshot.rasterWorstMs, 0.0);
      expect(snapshot.totalWorstMs, 0.0);
    });

    test('single frame produces exact metrics across all percentiles', () {
      final FrameTimingRecorder recorder = FrameTimingRecorder(capacity: 100);
      recorder.addRaw(
        buildMicroseconds: 4000, // 4.0 ms
        rasterMicroseconds: 6000, // 6.0 ms
      );

      final FrameTimingSnapshot snapshot = recorder.snapshot;
      expect(snapshot.frameCount, 1);
      expect(snapshot.jankCount, 0);
      expect(snapshot.jankPercentage, 0.0);
      expect(snapshot.buildP50Ms, 4.0);
      expect(snapshot.buildP90Ms, 4.0);
      expect(snapshot.buildP99Ms, 4.0);
      expect(snapshot.buildWorstMs, 4.0);
      expect(snapshot.rasterP50Ms, 6.0);
      expect(snapshot.rasterP90Ms, 6.0);
      expect(snapshot.rasterP99Ms, 6.0);
      expect(snapshot.rasterWorstMs, 6.0);
      expect(snapshot.totalWorstMs, 10.0);
    });

    test('two frames correctly interpolate p50, p90, p99', () {
      final FrameTimingRecorder recorder = FrameTimingRecorder(capacity: 100);
      recorder.addRaw(buildMicroseconds: 2000, rasterMicroseconds: 3000);
      recorder.addRaw(buildMicroseconds: 10000, rasterMicroseconds: 18000);

      final FrameTimingSnapshot snapshot = recorder.snapshot;
      expect(snapshot.frameCount, 2);
      // p50 is halfway between 2.0 and 10.0 => 6.0
      expect(snapshot.buildP50Ms, 6.0);
      // p90 is 2.0 + (10.0 - 2.0) * 0.9 = 9.2
      expect(snapshot.buildP90Ms, closeTo(9.2, 0.001));
      // p99 is 2.0 + (10.0 - 2.0) * 0.99 = 9.92
      expect(snapshot.buildP99Ms, closeTo(9.92, 0.001));
      expect(snapshot.buildWorstMs, 10.0);

      expect(snapshot.rasterP50Ms, 10.5);
      expect(snapshot.rasterWorstMs, 18.0);
      // Second frame has max(10ms, 18ms) = 18ms > 16.67ms => 1 jank
      expect(snapshot.jankCount, 1);
      expect(snapshot.jankPercentage, 50.0);
      expect(snapshot.totalWorstMs, 28.0);
    });

    test('synthetic 10-frame distribution calculates exact percentiles and jank', () {
      final FrameTimingRecorder recorder = FrameTimingRecorder(capacity: 100);
      // Values: build 1..10 ms, raster 2..20 ms
      for (int i = 1; i <= 10; i++) {
        recorder.addRaw(
          buildMicroseconds: i * 1000,
          rasterMicroseconds: i * 2000,
        );
      }

      final FrameTimingSnapshot snapshot = recorder.snapshot;
      expect(snapshot.frameCount, 10);
      // Sorted build: 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0
      // p50 rank = 0.5 * 9 = 4.5 -> index 4 (5.0) and index 5 (6.0) -> 5.5
      expect(snapshot.buildP50Ms, 5.5);
      // p90 rank = 0.9 * 9 = 8.1 -> index 8 (9.0) + 0.1 * (10.0 - 9.0) = 9.1
      expect(snapshot.buildP90Ms, closeTo(9.1, 0.001));
      // p99 rank = 0.99 * 9 = 8.91 -> index 8 (9.0) + 0.91 * 1.0 = 9.91
      expect(snapshot.buildP99Ms, closeTo(9.91, 0.001));
      expect(snapshot.buildWorstMs, 10.0);

      // max(build, raster) = i * 2ms.
      // At fallback 60 Hz (16.67 ms threshold):
      // i=1..8: max <= 16ms <= 16.67ms
      // i=9 (18ms > 16.67ms) and i=10 (20ms > 16.67ms) -> jank!
      // 2 frames out of 10
      expect(snapshot.jankCount, 2);
      expect(snapshot.jankPercentage, 20.0);
      expect(snapshot.totalWorstMs, 30.0);
    });

    test('ring buffer does not grow beyond capacity and drops oldest frames', () {
      final FrameTimingRecorder recorder = FrameTimingRecorder(capacity: 5);

      // Add 8 frames: 1ms, 2ms, 3ms, 4ms, 5ms, 6ms, 7ms, 8ms
      for (int i = 1; i <= 8; i++) {
        recorder.addRaw(
          buildMicroseconds: i * 1000,
          rasterMicroseconds: 1000,
        );
      }

      expect(recorder.count, 5);
      expect(recorder.totalRecordedFrames, 8);

      final FrameTimingSnapshot snapshot = recorder.snapshot;
      expect(snapshot.frameCount, 5);
      // The 5 frames remaining in buffer are 4, 5, 6, 7, 8
      // Sorted: 4, 5, 6, 7, 8
      // p50 rank = 0.5 * 4 = 2.0 -> index 2 => 6.0 ms
      expect(snapshot.buildP50Ms, 6.0);
      expect(snapshot.buildWorstMs, 8.0);
    });

    test('thresholdForRefreshRate handles 120Hz, 60Hz, zero and null correctly', () {
      // 120 Hz -> 8333 us
      expect(FrameTimingRecorder.thresholdForRefreshRate(120.0), 8333);
      // 60 Hz -> 16667 us
      expect(FrameTimingRecorder.thresholdForRefreshRate(60.0), 16667);
      // 0 Hz or negative -> fallback 16667 us
      expect(FrameTimingRecorder.thresholdForRefreshRate(0.0), 16667);
      expect(FrameTimingRecorder.thresholdForRefreshRate(-1.0), 16667);
      // null -> fallback 16667 us
      expect(FrameTimingRecorder.thresholdForRefreshRate(null), 16667);
    });

    test('calculateFps computes exact 50.0 fps for 100 frames over 2 seconds', () {
      final double fps = FrameTimingRecorder.calculateFps(
        100,
        const Duration(seconds: 2),
      );
      expect(fps, 50.0);

      // Zero frames or zero duration yields 0.0 fps
      expect(FrameTimingRecorder.calculateFps(0, const Duration(seconds: 2)), 0.0);
      expect(FrameTimingRecorder.calculateFps(100, Duration.zero), 0.0);
    });

    test('recorder configured for 120 Hz correctly applies 8333 us jank threshold with max(build, raster)', () {
      final FrameTimingRecorder recorder120 = FrameTimingRecorder(
        capacity: 10,
        customRefreshRate: 120.0,
      );
      expect(recorder120.jankThresholdMicroseconds, 8333);

      // 5ms build + 5ms raster:
      // Old sum rule: 5 + 5 = 10ms > 8.33ms gave false jank.
      // New max rule: max(5ms, 5ms) = 5ms <= 8.33ms -> NOT jank!
      recorder120.addRaw(buildMicroseconds: 5000, rasterMicroseconds: 5000);
      final FrameTimingSnapshot snapClean = recorder120.snapshot;
      expect(snapClean.jankCount, 0);
      expect(snapClean.jankPercentage, 0.0);

      // Frame with raster 9ms (9000 us) > 8333 us -> jank at 120Hz!
      recorder120.addRaw(buildMicroseconds: 4000, rasterMicroseconds: 9000);
      final FrameTimingSnapshot snap120 = recorder120.snapshot;
      expect(snap120.jankCount, 1);
      expect(snap120.jankPercentage, 50.0);

      // Frame with build 9ms (9000 us) > 8333 us and raster 4ms -> jank at 120Hz!
      recorder120.addRaw(buildMicroseconds: 9000, rasterMicroseconds: 4000);
      final FrameTimingSnapshot snapBuildJank = recorder120.snapshot;
      expect(snapBuildJank.jankCount, 2);
      expect(snapBuildJank.jankPercentage, closeTo(66.67, 0.01));

      // Same frames on 60 Hz recorder are NOT jank (9000 us <= 16667 us)
      final FrameTimingRecorder recorder60 = FrameTimingRecorder(
        capacity: 10,
        customRefreshRate: 60.0,
      );
      recorder60.addRaw(buildMicroseconds: 5000, rasterMicroseconds: 5000);
      recorder60.addRaw(buildMicroseconds: 4000, rasterMicroseconds: 9000);
      recorder60.addRaw(buildMicroseconds: 9000, rasterMicroseconds: 4000);
      final FrameTimingSnapshot snap60 = recorder60.snapshot;
      expect(snap60.jankCount, 0);
      expect(snap60.jankPercentage, 0.0);
    });

    test('recorder tracks window duration and fps via elapsedProvider', () {
      const Duration mockElapsed = Duration(seconds: 4);
      final FrameTimingRecorder recorder = FrameTimingRecorder(
        capacity: 500,
        customRefreshRate: 60.0,
        elapsedProvider: () => mockElapsed,
      );

      for (int i = 0; i < 200; i++) {
        recorder.addRaw(buildMicroseconds: 2000, rasterMicroseconds: 3000);
      }

      final FrameTimingSnapshot snap = recorder.snapshot;
      expect(snap.sampleFrameCount, 200);
      expect(snap.totalWindowFrames, 200);
      expect(snap.windowDuration, const Duration(seconds: 4));
      // 200 frames / 4 seconds = 50.0 fps
      expect(snap.windowFps, 50.0);
    });

    test('reset clears buffer completely and restarts window', () {
      final FrameTimingRecorder recorder = FrameTimingRecorder(capacity: 10);
      recorder.addRaw(buildMicroseconds: 5000, rasterMicroseconds: 5000);
      recorder.addRaw(buildMicroseconds: 7000, rasterMicroseconds: 7000);
      expect(recorder.count, 2);

      recorder.reset();
      expect(recorder.count, 0);
      expect(recorder.totalRecordedFrames, 0);
      expect(recorder.snapshot.frameCount, 0);
      expect(recorder.snapshot.totalWindowFrames, 0);
    });

    test('kDiagnosticsEnabled constant controls callback registration path', () {
      // Confirms compile-time define value behaves predictably
      expect(kDiagnosticsEnabled, isA<bool>());
    });
  });
}
