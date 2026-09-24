import 'dart:math' as math;
import 'dart:ui';

/// Immutable snapshot of frame timing performance metrics over a recorded window.
class FrameTimingSnapshot {
  const FrameTimingSnapshot({
    required this.sampleFrameCount,
    required this.totalWindowFrames,
    required this.windowDuration,
    required this.windowFps,
    required this.refreshRateHz,
    required this.jankThresholdMicroseconds,
    required this.jankCount,
    required this.jankPercentage,
    required this.buildP50Ms,
    required this.buildP90Ms,
    required this.buildP99Ms,
    this.buildP95Ms = 0.0,
    required this.buildWorstMs,
    required this.rasterP50Ms,
    required this.rasterP90Ms,
    this.rasterP95Ms = 0.0,
    required this.rasterP99Ms,
    required this.rasterWorstMs,
    required this.totalWorstMs,
  });

  const FrameTimingSnapshot.empty({
    this.refreshRateHz = 60.0,
    this.jankThresholdMicroseconds = FrameTimingRecorder.fallbackThresholdMicroseconds,
  })  : sampleFrameCount = 0,
        totalWindowFrames = 0,
        windowDuration = Duration.zero,
        windowFps = 0.0,
        jankCount = 0,
        jankPercentage = 0.0,
        buildP50Ms = 0.0,
        buildP90Ms = 0.0,
        buildP95Ms = 0.0,
        buildP99Ms = 0.0,
        buildWorstMs = 0.0,
        rasterP50Ms = 0.0,
        rasterP90Ms = 0.0,
        rasterP95Ms = 0.0,
        rasterP99Ms = 0.0,
        rasterWorstMs = 0.0,
        totalWorstMs = 0.0;

  final int sampleFrameCount;
  final int totalWindowFrames;
  final Duration windowDuration;
  final double windowFps;
  final double refreshRateHz;
  final int jankThresholdMicroseconds;

  /// Alias for backward compatibility.
  int get frameCount => sampleFrameCount;

  final int jankCount;
  final double jankPercentage;

  final double buildP50Ms;
  final double buildP90Ms;
  final double buildP95Ms;
  final double buildP99Ms;
  final double buildWorstMs;

  final double rasterP50Ms;
  final double rasterP90Ms;
  final double rasterP95Ms;
  final double rasterP99Ms;
  final double rasterWorstMs;

  final double totalWorstMs;

  @override
  String toString() {
    return 'FrameTimingSnapshot(sampleFrames: $sampleFrameCount, totalFrames: $totalWindowFrames, '
        'window: ${(windowDuration.inMilliseconds / 1000.0).toStringAsFixed(1)}s, fps: ${windowFps.toStringAsFixed(1)}, '
        'jank: ${jankPercentage.toStringAsFixed(1)}% ($jankCount), threshold: ${(jankThresholdMicroseconds / 1000.0).toStringAsFixed(1)}ms, '
        'build[p50: ${buildP50Ms.toStringAsFixed(2)}ms, p90: ${buildP90Ms.toStringAsFixed(2)}ms, p95: ${buildP95Ms.toStringAsFixed(2)}ms, p99: ${buildP99Ms.toStringAsFixed(2)}ms, worst: ${buildWorstMs.toStringAsFixed(2)}ms], '
        'raster[p50: ${rasterP50Ms.toStringAsFixed(2)}ms, p90: ${rasterP90Ms.toStringAsFixed(2)}ms, p95: ${rasterP95Ms.toStringAsFixed(2)}ms, p99: ${rasterP99Ms.toStringAsFixed(2)}ms, worst: ${rasterWorstMs.toStringAsFixed(2)}ms], '
        'totalWorst: ${totalWorstMs.toStringAsFixed(2)}ms)';
  }
}

/// Statistics for a 1-minute bucket used in the 20-minute jank log.
class JankMinuteRecord {
  const JankMinuteRecord({
    required this.minuteIndex,
    required this.totalFrames,
    required this.jankFrames,
    required this.jankPercentage,
    required this.rasterP50Ms,
    required this.rasterP95Ms,
    required this.rasterWorstMs,
  });

  final int minuteIndex;
  final int totalFrames;
  final int jankFrames;
  final double jankPercentage;
  final double rasterP50Ms;
  final double rasterP95Ms;
  final double rasterWorstMs;

  @override
  String toString() =>
      'Min $minuteIndex: frames=$totalFrames, jank=$jankFrames (${jankPercentage.toStringAsFixed(1)}%), '
      'raster[p50: ${rasterP50Ms.toStringAsFixed(1)}ms, p95: ${rasterP95Ms.toStringAsFixed(1)}ms, worst: ${rasterWorstMs.toStringAsFixed(1)}ms]';
}

/// Fixed-capacity ring buffer recorder for frame timings.
///
/// Accumulating all frames over a session causes a memory leak that grows
/// linearly with gameplay time. This recorder bounds memory to a fixed [capacity]
/// (default 1200 frames ≈ 20 seconds at 60 fps).
class FrameTimingRecorder {
  FrameTimingRecorder({
    this.capacity = 1200,
    this.platformDispatcher,
    double? customRefreshRate,
    int? customJankThresholdMicroseconds,
    Duration Function()? elapsedProvider,
  })  : assert(capacity > 0, 'capacity must be greater than 0'),
        _customRefreshRate = customRefreshRate,
        _customJankThresholdMicroseconds = customJankThresholdMicroseconds,
        _elapsedProvider = elapsedProvider,
        _buildMicroseconds = List<int>.filled(capacity, 0),
        _rasterMicroseconds = List<int>.filled(capacity, 0) {
    _stopwatch.start();
  }

  static const int fallbackRefreshRateHz = 60;
  static const int fallbackThresholdMicroseconds = 16667; // 16.67 ms (60 Hz target)

  final int capacity;
  final PlatformDispatcher? platformDispatcher;
  final double? _customRefreshRate;
  final int? _customJankThresholdMicroseconds;
  final Duration Function()? _elapsedProvider;

  final List<int> _buildMicroseconds;
  final List<int> _rasterMicroseconds;
  final Stopwatch _stopwatch = Stopwatch();

  int _head = 0;
  int _count = 0;
  int _totalRecordedFrames = 0;

  final List<JankMinuteRecord> _completedMinutes = <JankMinuteRecord>[];
  int _currentMinuteFrameCount = 0;
  int _currentMinuteJankCount = 0;
  final List<int> _currentMinuteRastersUs = <int>[];
  int _lastRecordedMinute = 0;

  /// Returns completed 1-minute jank log records for long-running benchmarks (e.g. 20-min run).
  List<JankMinuteRecord> get jankLog =>
      List<JankMinuteRecord>.unmodifiable(_completedMinutes);

  void _finalizeMinute(int minuteIndex) {
    if (_currentMinuteFrameCount == 0) {
      _completedMinutes.add(
        JankMinuteRecord(
          minuteIndex: minuteIndex,
          totalFrames: 0,
          jankFrames: 0,
          jankPercentage: 0.0,
          rasterP50Ms: 0.0,
          rasterP95Ms: 0.0,
          rasterWorstMs: 0.0,
        ),
      );
      return;
    }

    final List<double> rasters = _currentMinuteRastersUs
        .map((int us) => us / 1000.0)
        .toList()
      ..sort();

    final double worst = rasters.isEmpty ? 0.0 : rasters.last;
    final double p50 = calculatePercentile(rasters, 0.50);
    final double p95 = calculatePercentile(rasters, 0.95);
    final double jankPct =
        (_currentMinuteJankCount / _currentMinuteFrameCount) * 100.0;

    _completedMinutes.add(
      JankMinuteRecord(
        minuteIndex: minuteIndex,
        totalFrames: _currentMinuteFrameCount,
        jankFrames: _currentMinuteJankCount,
        jankPercentage: jankPct,
        rasterP50Ms: p50,
        rasterP95Ms: p95,
        rasterWorstMs: worst,
      ),
    );

    _currentMinuteFrameCount = 0;
    _currentMinuteJankCount = 0;
    _currentMinuteRastersUs.clear();
  }

  /// Resolves the current display refresh rate in Hz from [PlatformDispatcher].
  static double resolveRefreshRate({PlatformDispatcher? dispatcher}) {
    final PlatformDispatcher d = dispatcher ?? PlatformDispatcher.instance;
    if (d.views.isNotEmpty) {
      final double rate = d.views.first.display.refreshRate;
      if (rate > 0.0) {
        return rate;
      }
    }
    return fallbackRefreshRateHz.toDouble();
  }

  /// Calculates jank threshold in microseconds from refresh rate.
  ///
  /// For 120 Hz: 8333 us (8.33 ms).
  /// For 60 Hz: 16667 us (16.67 ms).
  /// If refreshRate is <= 0 or null, falls back to [fallbackThresholdMicroseconds] (16667 us).
  static int thresholdForRefreshRate(double? refreshRate) {
    if (refreshRate == null || refreshRate <= 0.0) {
      return fallbackThresholdMicroseconds;
    }
    return (1000000.0 / refreshRate).round();
  }

  /// Computes FPS over a duration window.
  static double calculateFps(int frames, Duration duration) {
    final double seconds = duration.inMicroseconds / 1000000.0;
    if (seconds <= 0.0 || frames <= 0) {
      return 0.0;
    }
    return frames / seconds;
  }

  /// Current display refresh rate in Hz.
  double get currentRefreshRate =>
      _customRefreshRate ?? resolveRefreshRate(dispatcher: platformDispatcher);

  /// Current jank threshold in microseconds based on the display refresh rate.
  int get jankThresholdMicroseconds =>
      _customJankThresholdMicroseconds ??
      thresholdForRefreshRate(currentRefreshRate);

  Duration get windowDuration {
    final Duration Function()? provider = _elapsedProvider;
    return provider != null ? provider() : _stopwatch.elapsed;
  }

  /// Current number of frames stored in the ring buffer.
  int get count => _count;

  /// Total frames processed since creation or last [reset].
  int get totalRecordedFrames => _totalRecordedFrames;

  /// Records a batch of frame timings delivered by Flutter's scheduler callback.
  void addTimings(List<FrameTiming> timings) {
    for (final FrameTiming timing in timings) {
      addRaw(
        buildMicroseconds: timing.buildDuration.inMicroseconds,
        rasterMicroseconds: timing.rasterDuration.inMicroseconds,
      );
    }
  }

  /// Records an individual frame with raw microsecond values (convenient for testing).
  void addRaw({
    required int buildMicroseconds,
    required int rasterMicroseconds,
  }) {
    final int minute = windowDuration.inMinutes;
    while (_lastRecordedMinute < minute) {
      _finalizeMinute(_lastRecordedMinute + 1);
      _lastRecordedMinute++;
    }

    _buildMicroseconds[_head] = buildMicroseconds;
    _rasterMicroseconds[_head] = rasterMicroseconds;
    _head = (_head + 1) % capacity;
    if (_count < capacity) {
      _count++;
    }
    _totalRecordedFrames++;

    _currentMinuteFrameCount++;
    if (math.max(buildMicroseconds, rasterMicroseconds) > jankThresholdMicroseconds) {
      _currentMinuteJankCount++;
    }
    if (_currentMinuteRastersUs.length < 300) {
      _currentMinuteRastersUs.add(rasterMicroseconds);
    }
  }

  /// Clears the ring buffer and restarts the measurement window timer.
  void reset() {
    _head = 0;
    _count = 0;
    _totalRecordedFrames = 0;
    _completedMinutes.clear();
    _currentMinuteFrameCount = 0;
    _currentMinuteJankCount = 0;
    _currentMinuteRastersUs.clear();
    _lastRecordedMinute = 0;
    _stopwatch.reset();
    _stopwatch.start();
  }

  /// Computes a statistical snapshot over the frames currently in the buffer.
  FrameTimingSnapshot get snapshot {
    final double refreshRate = currentRefreshRate;
    final int threshold = jankThresholdMicroseconds;
    final Duration duration = windowDuration;
    final double fps = calculateFps(_totalRecordedFrames, duration);

    if (_count == 0) {
      return FrameTimingSnapshot.empty(
        refreshRateHz: refreshRate,
        jankThresholdMicroseconds: threshold,
      );
    }

    final List<double> builds = <double>[];
    final List<double> rasters = <double>[];
    int jankCount = 0;
    double totalWorst = 0.0;
    double buildWorst = 0.0;
    double rasterWorst = 0.0;

    for (int i = 0; i < _count; i++) {
      final double bMs = _buildMicroseconds[i] / 1000.0;
      final double rMs = _rasterMicroseconds[i] / 1000.0;
      final double totalMs = bMs + rMs;

      builds.add(bMs);
      rasters.add(rMs);

      if (math.max(_buildMicroseconds[i], _rasterMicroseconds[i]) > threshold) {
        jankCount++;
      }

      if (totalMs > totalWorst) {
        totalWorst = totalMs;
      }
      if (bMs > buildWorst) {
        buildWorst = bMs;
      }
      if (rMs > rasterWorst) {
        rasterWorst = rMs;
      }
    }

    builds.sort();
    rasters.sort();

    return FrameTimingSnapshot(
      sampleFrameCount: _count,
      totalWindowFrames: _totalRecordedFrames,
      windowDuration: duration,
      windowFps: fps,
      refreshRateHz: refreshRate,
      jankThresholdMicroseconds: threshold,
      jankCount: jankCount,
      jankPercentage: (jankCount / _count) * 100.0,
      buildP50Ms: calculatePercentile(builds, 0.50),
      buildP90Ms: calculatePercentile(builds, 0.90),
      buildP95Ms: calculatePercentile(builds, 0.95),
      buildP99Ms: calculatePercentile(builds, 0.99),
      buildWorstMs: buildWorst,
      rasterP50Ms: calculatePercentile(rasters, 0.50),
      rasterP90Ms: calculatePercentile(rasters, 0.90),
      rasterP95Ms: calculatePercentile(rasters, 0.95),
      rasterP99Ms: calculatePercentile(rasters, 0.99),
      rasterWorstMs: rasterWorst,
      totalWorstMs: totalWorst,
    );
  }

  /// Linear interpolation percentile on a pre-sorted list of doubles.
  static double calculatePercentile(List<double> sorted, double percentile) {
    if (sorted.isEmpty) {
      return 0.0;
    }
    if (sorted.length == 1) {
      return sorted.first;
    }
    final double rank = percentile.clamp(0.0, 1.0) * (sorted.length - 1);
    final int lowerIndex = rank.floor();
    final int upperIndex = rank.ceil();
    final double weight = rank - lowerIndex;
    return sorted[lowerIndex] +
        (sorted[upperIndex] - sorted[lowerIndex]) * weight;
  }
}
