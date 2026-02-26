import 'package:block_puzzle_mobile/core/observability/guardrail_alert.dart';
import 'package:block_puzzle_mobile/core/observability/guardrail_alert_evaluator.dart';
import 'package:block_puzzle_mobile/core/observability/session_observability_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GuardrailAlertEvaluator', () {
    const GuardrailAlertEvaluator evaluator = GuardrailAlertEvaluator();

    test('returns no alerts when metrics are within thresholds', () {
      const SessionObservabilitySnapshot snapshot =
          SessionObservabilitySnapshot(
        sessionId: 's1',
        roundsPlayed: 5,
        roundsEnded: 5,
        sessionDurationSec: 240,
        totalRoundDurationSec: 180,
        gameOverNoMovesCount: 1,
        moveAttempts: 20,
        moveRejectedCount: 2,
        runtimeErrorCount: 0,
      );

      final List<GuardrailAlert> alerts = evaluator.evaluate(
        snapshot: snapshot,
        remoteConfig: const <String, Object?>{},
      );

      expect(alerts, isEmpty);
    });

    test('triggers critical alert on high early_gameover_rate', () {
      const SessionObservabilitySnapshot snapshot =
          SessionObservabilitySnapshot(
        sessionId: 's2',
        roundsPlayed: 4,
        roundsEnded: 4,
        sessionDurationSec: 200,
        totalRoundDurationSec: 120,
        gameOverNoMovesCount: 3,
        moveAttempts: 25,
        moveRejectedCount: 2,
        runtimeErrorCount: 0,
      );

      final List<GuardrailAlert> alerts = evaluator.evaluate(
        snapshot: snapshot,
        remoteConfig: const <String, Object?>{
          'ops.alerting.max_early_gameover_rate': 0.30,
        },
      );

      expect(
        alerts.any(
          (GuardrailAlert alert) =>
              alert.alertId == 'early_gameover_rate_high' &&
              alert.severity == GuardrailAlertSeverity.critical,
        ),
        isTrue,
      );
    });

    test('does not trigger move rejection alert on low sample', () {
      const SessionObservabilitySnapshot snapshot =
          SessionObservabilitySnapshot(
        sessionId: 's3',
        roundsPlayed: 2,
        roundsEnded: 2,
        sessionDurationSec: 90,
        totalRoundDurationSec: 80,
        gameOverNoMovesCount: 0,
        moveAttempts: 6,
        moveRejectedCount: 4,
        runtimeErrorCount: 0,
      );

      final List<GuardrailAlert> alerts = evaluator.evaluate(
        snapshot: snapshot,
        remoteConfig: const <String, Object?>{
          'ops.alerting.max_move_rejection_rate': 0.10,
        },
      );

      expect(
        alerts.any((GuardrailAlert alert) =>
            alert.alertId == 'move_rejected_rate_high'),
        isFalse,
      );
    });

    test('triggers warning alert on high move rejection rate', () {
      const SessionObservabilitySnapshot snapshot =
          SessionObservabilitySnapshot(
        sessionId: 's4',
        roundsPlayed: 3,
        roundsEnded: 3,
        sessionDurationSec: 140,
        totalRoundDurationSec: 120,
        gameOverNoMovesCount: 1,
        moveAttempts: 20,
        moveRejectedCount: 7,
        runtimeErrorCount: 0,
      );

      final List<GuardrailAlert> alerts = evaluator.evaluate(
        snapshot: snapshot,
        remoteConfig: const <String, Object?>{
          'ops.alerting.max_move_rejection_rate': 0.20,
        },
      );

      expect(
        alerts.any(
          (GuardrailAlert alert) =>
              alert.alertId == 'move_rejected_rate_high' &&
              alert.severity == GuardrailAlertSeverity.warning,
        ),
        isTrue,
      );
    });

    test('triggers runtime error alert', () {
      const SessionObservabilitySnapshot snapshot =
          SessionObservabilitySnapshot(
        sessionId: 's5',
        roundsPlayed: 1,
        roundsEnded: 1,
        sessionDurationSec: 40,
        totalRoundDurationSec: 15,
        gameOverNoMovesCount: 1,
        moveAttempts: 12,
        moveRejectedCount: 1,
        runtimeErrorCount: 2,
      );

      final List<GuardrailAlert> alerts = evaluator.evaluate(
        snapshot: snapshot,
        remoteConfig: const <String, Object?>{
          'ops.alerting.max_runtime_error_count': 0,
        },
      );

      expect(
        alerts.any(
            (GuardrailAlert alert) => alert.alertId == 'runtime_errors_high'),
        isTrue,
      );
    });

    test('returns no alerts when alerting is disabled', () {
      const SessionObservabilitySnapshot snapshot =
          SessionObservabilitySnapshot(
        sessionId: 's6',
        roundsPlayed: 4,
        roundsEnded: 4,
        sessionDurationSec: 180,
        totalRoundDurationSec: 70,
        gameOverNoMovesCount: 4,
        moveAttempts: 20,
        moveRejectedCount: 18,
        runtimeErrorCount: 3,
      );

      final List<GuardrailAlert> alerts = evaluator.evaluate(
        snapshot: snapshot,
        remoteConfig: const <String, Object?>{
          'ops.alerting.enabled': false,
        },
      );

      expect(alerts, isEmpty);
    });
  });
}
