import 'package:flutter/material.dart';

import '../../app/bootstrap.dart';
import '../../core/config/app_config.dart';
import '../../core/config/app_environment.dart';
import '../../core/di/di_container.dart';
import '../../data/analytics/analytics_tracker.dart';
import '../../infra/monitoring/crash_reporter.dart';

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
  /// path a real defect would: PlatformDispatcher.onError -> CrashReporter.
  /// A synthetic call straight into Crashlytics would prove less, because it
  /// would skip the wiring that actually has to work.
  void _forceCrash() {
    _report('Crashing in 1 second. Reopen the app to let the report upload.');
    Future<void>.delayed(const Duration(seconds: 1), () {
      throw StateError(
        'Diagnostics forced crash: this is intentional, not a defect',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppConfig config = sl<AppConfig>();

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
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
            onPressed: _forceCrash,
            child: const Text('Force a crash'),
          ),
          if (_lastAction != null) ...<Widget>[
            const SizedBox(height: 24),
            Text(_lastAction!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          Text(
            'A crash report uploads on the next launch, not at the moment of '
            'the crash. Reopen the app after forcing one.',
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
