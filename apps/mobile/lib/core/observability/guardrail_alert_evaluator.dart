import 'guardrail_alert.dart';
import 'session_observability_snapshot.dart';

class GuardrailAlertEvaluator {
  const GuardrailAlertEvaluator();

  static const String _enabledKey = 'ops.alerting.enabled';
  static const String _earlyGameOverRateKey =
      'ops.alerting.max_early_gameover_rate';
  static const String _moveRejectedRateKey =
      'ops.alerting.max_move_rejection_rate';
  static const String _avgRoundDurationKey =
      'ops.alerting.min_avg_round_duration_sec';
  static const String _runtimeErrorCountKey =
      'ops.alerting.max_runtime_error_count';

  List<GuardrailAlert> evaluate({
    required SessionObservabilitySnapshot snapshot,
    required Map<String, Object?> remoteConfig,
  }) {
    final bool enabled = _readBool(
      remoteConfig[_enabledKey],
      fallback: true,
    );
    if (!enabled) {
      return <GuardrailAlert>[];
    }

    final List<GuardrailAlert> alerts = <GuardrailAlert>[];
    final double maxEarlyGameOverRate = _readDouble(
      remoteConfig[_earlyGameOverRateKey],
      fallback: 0.30,
    );
    final double maxMoveRejectedRate = _readDouble(
      remoteConfig[_moveRejectedRateKey],
      fallback: 0.18,
    );
    final double minAverageRoundDuration = _readDouble(
      remoteConfig[_avgRoundDurationKey],
      fallback: 20.0,
    );
    final int maxRuntimeErrorCount = _readInt(
      remoteConfig[_runtimeErrorCountKey],
      fallback: 0,
    );

    if (snapshot.roundsEnded > 0 &&
        snapshot.earlyGameOverRate > maxEarlyGameOverRate) {
      alerts.add(
        GuardrailAlert(
          alertId: 'early_gameover_rate_high',
          metricName: 'early_gameover_rate',
          comparator: '>',
          threshold: maxEarlyGameOverRate,
          observedValue: snapshot.earlyGameOverRate,
          severity: GuardrailAlertSeverity.critical,
          message:
              'early_gameover_rate exceeded threshold (${snapshot.gameOverNoMovesCount}/${snapshot.roundsEnded} rounds)',
        ),
      );
    }

    if (snapshot.moveAttempts >= 10 &&
        snapshot.moveRejectedRate > maxMoveRejectedRate) {
      alerts.add(
        GuardrailAlert(
          alertId: 'move_rejected_rate_high',
          metricName: 'move_rejected_rate',
          comparator: '>',
          threshold: maxMoveRejectedRate,
          observedValue: snapshot.moveRejectedRate,
          severity: GuardrailAlertSeverity.warning,
          message:
              'move_rejected_rate exceeded threshold (${snapshot.moveRejectedCount}/${snapshot.moveAttempts} attempts)',
        ),
      );
    }

    if (snapshot.roundsEnded > 0 &&
        snapshot.avgRoundDurationSec < minAverageRoundDuration) {
      alerts.add(
        GuardrailAlert(
          alertId: 'avg_round_duration_low',
          metricName: 'avg_round_duration_sec',
          comparator: '<',
          threshold: minAverageRoundDuration,
          observedValue: snapshot.avgRoundDurationSec,
          severity: GuardrailAlertSeverity.warning,
          message:
              'avg_round_duration_sec is below threshold (${snapshot.avgRoundDurationSec.toStringAsFixed(2)} sec)',
        ),
      );
    }

    if (snapshot.runtimeErrorCount > maxRuntimeErrorCount) {
      alerts.add(
        GuardrailAlert(
          alertId: 'runtime_errors_high',
          metricName: 'runtime_error_count',
          comparator: '>',
          threshold: maxRuntimeErrorCount.toDouble(),
          observedValue: snapshot.runtimeErrorCount.toDouble(),
          severity: GuardrailAlertSeverity.critical,
          message:
              'runtime_error_count exceeded threshold (${snapshot.runtimeErrorCount} > $maxRuntimeErrorCount)',
        ),
      );
    }

    return alerts;
  }

  bool _readBool(
    Object? value, {
    required bool fallback,
  }) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value > 0;
    }
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return fallback;
  }

  int _readInt(
    Object? value, {
    required int fallback,
  }) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final int? parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
    return fallback;
  }

  double _readDouble(
    Object? value, {
    required double fallback,
  }) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final double? parsed = double.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
    return fallback;
  }
}
