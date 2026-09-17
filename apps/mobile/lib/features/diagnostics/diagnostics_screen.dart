import 'package:flutter/material.dart';

import '../../app/bootstrap.dart';
import '../../core/config/app_config.dart';
import '../../core/config/app_environment.dart';
import '../../core/di/di_container.dart';
import '../../data/analytics/analytics_tracker.dart';
import '../../infra/monitoring/crash_reporter.dart';

import '../game_loop/presentation/game_loop_screen.dart';
import '../game_modes/game_mode_availability.dart';
import '../game_modes/mode_gate.dart';
import 'benchmark_scene_screen.dart';
import 'frame_timing_recorder.dart';
import 'step1j_decomposition.dart';

/// Whether the diagnostics panel is compiled into this binary.
///
/// Deliberately a compile-time flag rather than [kDebugMode]. The acceptance
/// gate is that a **release** build reaches Crashlytics and Analytics, so the
/// check has to be runnable in a release-configured build; gating on debug mode
/// would only ever prove the debug path. Build the verification binary with
/// `--dart-define=ENABLE_DIAGNOSTICS=true` and the store binary without it, at
/// which point this screen is not compiled in at all.
const bool kDiagnosticsEnabled =
    bool.fromEnvironment('ENABLE_DIAGNOSTICS');

/// Shows what the production data plane is actually doing, and lets a tester
/// force the two events that prove it end to end.
///
/// Reading "Crashlytics is wired" from the source is not the same as seeing a
/// crash arrive in the console; this screen exists to close that gap.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  String? _lastAction;

  void _report(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _lastAction = message);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendTestEvent() async {
    await sl<AnalyticsTracker>().track(
      'ops_diagnostics_ping',
      params: <String, Object?>{
        'source': 'diagnostics_screen',
        'firebase_ready': firebaseReady,
      },
    );
    _report('Analytics event sent. Look for ops_diagnostics_ping in DebugView.');
  }

  Future<void> _recordNonFatal() async {
    await sl<CrashReporter>().recordError(
      StateError('Diagnostics non-fatal check'),
      StackTrace.current,
      reason: 'diagnostics_non_fatal',
    );
    _report('Non-fatal recorded. It appears in Crashlytics within a minute.');
  }

  /// Throws on purpose, outside any try/catch, so the error travels the same
  /// path a real defect would. A synthetic call straight into Crashlytics would
  /// prove less, because it would skip the wiring that has to work.
  ///
  /// This does **not** kill the process, and the button is named accordingly.
  /// `main()` runs the app inside `runZonedGuarded`, so the zone catches this
  /// and hands it to [reportUncaughtError]; it reaches Crashlytics as a
  /// non-fatal. That is the correct behaviour - an app that survives a stray
  /// async error is better than one that dies - but it means this button does
  /// not exercise the fatal path. A genuine fatal needs something the zone
  /// cannot intercept, such as a crash on the platform side.
  void _throwUncaught() {
    _report('Throwing now. Arrives in Crashlytics as a non-fatal.');
    Future<void>.delayed(const Duration(seconds: 1), () {
      throw StateError(
        'Diagnostics uncaught error: this is intentional, not a defect',
      );
    });
  }

  Future<void> _launchStep1j(Step1jConfig config) async {
    Step1jDecomposition.activeConfig.value = config;
    if (sl.isRegistered<FrameTimingRecorder>()) {
      sl<FrameTimingRecorder>().reset();
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ModeGate(
          mode: GameMode.classic,
          child: GameLoopScreen(),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppConfig config = sl<AppConfig>();
    final FrameTimingRecorder? timingRecorder =
        sl.isRegistered<FrameTimingRecorder>()
            ? sl<FrameTimingRecorder>()
            : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
        actions: <Widget>[
          if (timingRecorder != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => setState(() {}),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _StatusCard(
            rows: <(String, String, bool?)>[
              ('Environment', config.environment.wireName, null),
              ('Build flavor', config.buildFlavor.wireName, null),
              ('App version', config.appVersion, null),
              (
                'Debug adapters',
                config.useDebugAdapters ? 'YES - not a production wiring' : 'no',
                !config.useDebugAdapters,
              ),
              (
                'Firebase',
                firebaseReady ? 'initialized' : 'NOT initialized',
                firebaseReady,
              ),
            ],
          ),
          if (timingRecorder != null) ...<Widget>[
            const SizedBox(height: 16),
            _FrameTimingCard(
              recorder: timingRecorder,
              onReset: () {
                timingRecorder.reset();
                _report('Frame timing statistics reset.');
              },
              onRefresh: () => setState(() {}),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Render Pass Bisection (Steps 1g & 1h)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: const Key('btn_benchmark_control'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BenchmarkSceneScreen(
                    initialLayer: BenchmarkLayer.control,
                  ),
                ),
              );
              if (mounted) setState(() {});
            },
            child: const Text('1g: Control Scene (Floor)'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: const Key('btn_benchmark_nebula'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BenchmarkSceneScreen(
                    initialLayer: BenchmarkLayer.withNebula,
                  ),
                ),
              );
              if (mounted) setState(() {});
            },
            child: const Text('1h.2: + NebulaBackground'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: const Key('btn_benchmark_gamewidget'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BenchmarkSceneScreen(
                    initialLayer: BenchmarkLayer.withGameWidget,
                  ),
                ),
              );
              if (mounted) setState(() {});
            },
            child: const Text('1h.3: + Empty GameWidget'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: const Key('btn_benchmark_well'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BenchmarkSceneScreen(
                    initialLayer: BenchmarkLayer.withBoardWell,
                  ),
                ),
              );
              if (mounted) setState(() {});
            },
            child: const Text('1h.4: + Board Well'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: const Key('btn_benchmark_stones'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BenchmarkSceneScreen(
                    initialLayer: BenchmarkLayer.withStones,
                  ),
                ),
              );
              if (mounted) setState(() {});
            },
            child: const Text('1h.5: + Stones (paintGlassFacet)'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          Text(
            'DEC-0024 Step 1j: Classic Decomposition',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: const Key('btn_step1j_a'),
            onPressed: () => _launchStep1j(Step1jConfig.aBaseline),
            child: const Text('1j.A: Baseline (Full Classic)'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: const Key('btn_step1j_b'),
            onPressed: () => _launchStep1j(Step1jConfig.bNoHud),
            child: const Text('1j.B: No HUD / AppBar / Combo'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: const Key('btn_step1j_c'),
            onPressed: () => _launchStep1j(Step1jConfig.cNoClip),
            child: const Text('1j.C: No ClipRRect / DecoratedBox'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: const Key('btn_step1j_d'),
            onPressed: () => _launchStep1j(Step1jConfig.dNoPiecesPic),
            child: const Text('1j.D: No Starfield / Pieces Picture'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: const Key('btn_step1j_e'),
            onPressed: () => _launchStep1j(Step1jConfig.eNoRackPic),
            child: const Text('1j.E: No Rack Pieces Picture'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: const Key('btn_step1j_f'),
            onPressed: () => _launchStep1j(Step1jConfig.fAllRemoved),
            child: const Text('1j.F: All B+C+D+E Removed'),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: _sendTestEvent,
            child: const Text('Send analytics event'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _recordNonFatal,
            child: const Text('Record non-fatal error'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: _throwUncaught,
            child: const Text('Throw an uncaught error'),
          ),
          if (_lastAction != null) ...<Widget>[
            const SizedBox(height: 24),
            Text(_lastAction!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          Text(
            'Reports upload on the next launch, not at the moment of the error, '
            'so reopen the app afterwards. The uncaught error is caught by the '
            'guarded zone and arrives as a non-fatal, not as a crash.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.rows});

  final List<(String, String, bool?)> rows;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final (String label, String value, bool? ok) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 140,
                      child: Text(label, style: theme.textTheme.bodyMedium),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: switch (ok) {
                            true => Colors.green,
                            false => theme.colorScheme.error,
                            null => null,
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FrameTimingCard extends StatelessWidget {
  const _FrameTimingCard({
    required this.recorder,
    required this.onReset,
    required this.onRefresh,
  });

  final FrameTimingRecorder recorder;
  final VoidCallback onReset;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final FrameTimingSnapshot snapshot = recorder.snapshot;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Frame Performance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Refresh',
                      onPressed: onRefresh,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Reset Stats',
                      onPressed: onReset,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            _timingRow(
              'Window elapsed',
              '${(snapshot.windowDuration.inMilliseconds / 1000.0).toStringAsFixed(1)} s',
              theme,
            ),
            _timingRow(
              'Window FPS',
              '${snapshot.windowFps.toStringAsFixed(1)} fps',
              theme,
              highlight: snapshot.windowFps > 0 && snapshot.windowFps < 55.0,
            ),
            _timingRow(
              'Display refresh',
              '${snapshot.refreshRateHz.toStringAsFixed(0)} Hz (budget: ${(snapshot.jankThresholdMicroseconds / 1000.0).toStringAsFixed(1)} ms)',
              theme,
            ),
            _timingRow(
              'Jank frames (>${(snapshot.jankThresholdMicroseconds / 1000.0).toStringAsFixed(1)}ms)',
              '${snapshot.jankPercentage.toStringAsFixed(2)}% (${snapshot.jankCount} / ${snapshot.sampleFrameCount})',
              theme,
              highlight: snapshot.jankCount > 0,
            ),
            const SizedBox(height: 8),
            Text(
              'Percentiles (over last ${snapshot.sampleFrameCount} frames):',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            _timingRow(
              '  p50 / p90 / p99',
              '${snapshot.buildP50Ms.toStringAsFixed(2)} / ${snapshot.buildP90Ms.toStringAsFixed(2)} / ${snapshot.buildP99Ms.toStringAsFixed(2)} ms',
              theme,
            ),
            _timingRow(
              '  Worst build',
              '${snapshot.buildWorstMs.toStringAsFixed(2)} ms',
              theme,
            ),
            const SizedBox(height: 8),
            Text(
              'Raster Duration:',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            _timingRow(
              '  p50 / p90 / p99',
              '${snapshot.rasterP50Ms.toStringAsFixed(2)} / ${snapshot.rasterP90Ms.toStringAsFixed(2)} / ${snapshot.rasterP99Ms.toStringAsFixed(2)} ms',
              theme,
            ),
            _timingRow(
              '  Worst raster',
              '${snapshot.rasterWorstMs.toStringAsFixed(2)} ms',
              theme,
            ),
            const SizedBox(height: 8),
            _timingRow(
              'Total worst frame',
              '${snapshot.totalWorstMs.toStringAsFixed(2)} ms',
              theme,
              highlight: snapshot.totalWorstMs > (snapshot.jankThresholdMicroseconds / 1000.0),
            ),
            const Divider(),
            _timingRow(
              'Total window frames',
              '${snapshot.totalWindowFrames} (capacity ${recorder.capacity})',
              theme,
            ),
            _timingRow(
              'Cumulative frames',
              '${recorder.totalRecordedFrames}',
              theme,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                    label: const Text('Reset Timing Stats'),
                    onPressed: onReset,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timingRow(
    String label,
    String value,
    ThemeData theme, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: highlight ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}
