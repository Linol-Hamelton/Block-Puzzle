class ValidationResult {
  const ValidationResult._({
    required this.isValid,
    this.reason,
  });

  const ValidationResult.valid() : this._(isValid: true);

  const ValidationResult.invalid(String reason)
      : this._(
          isValid: false,
          reason: reason,
        );

  final bool isValid;
  final String? reason;
}
