enum GuardrailAlertSeverity {
  warning,
  critical,
}

class GuardrailAlert {
  const GuardrailAlert({
    required this.alertId,
    required this.metricName,
    required this.comparator,
    required this.threshold,
    required this.observedValue,
    required this.severity,
    required this.message,
  });

  final String alertId;
  final String metricName;
  final String comparator;
  final double threshold;
  final double observedValue;
  final GuardrailAlertSeverity severity;
  final String message;

  String get severityWireName {
    switch (severity) {
      case GuardrailAlertSeverity.warning:
        return 'warning';
      case GuardrailAlertSeverity.critical:
        return 'critical';
    }
  }
}
