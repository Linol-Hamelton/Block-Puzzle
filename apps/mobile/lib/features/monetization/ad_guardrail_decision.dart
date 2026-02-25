class AdGuardrailDecision {
  const AdGuardrailDecision({
    required this.allow,
    required this.reason,
  });

  final bool allow;
  final String reason;

  factory AdGuardrailDecision.allow() {
    return const AdGuardrailDecision(
      allow: true,
      reason: 'allowed',
    );
  }

  factory AdGuardrailDecision.deny(String reason) {
    return AdGuardrailDecision(
      allow: false,
      reason: reason,
    );
  }
}
