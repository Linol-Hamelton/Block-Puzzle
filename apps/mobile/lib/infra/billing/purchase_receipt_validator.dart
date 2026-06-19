/// Outcome of a server-side purchase/receipt validation.
class ReceiptValidationResult {
  const ReceiptValidationResult({
    required this.isValid,
    this.errorCode,
    this.message,
    this.entitlements = const <String>{},
  });

  /// Whether the server confirmed the purchase as genuine and active.
  final bool isValid;

  /// Stable machine code on failure (e.g. `receipt_invalid`, `network_error`).
  final String? errorCode;

  /// Human-readable diagnostic; not shown to end users verbatim.
  final String? message;

  /// Authoritative set of product ids the server reports as owned after this
  /// validation, when available (used to reconcile local entitlement cache).
  final Set<String> entitlements;

  factory ReceiptValidationResult.valid({
    Set<String> entitlements = const <String>{},
  }) {
    return ReceiptValidationResult(isValid: true, entitlements: entitlements);
  }

  factory ReceiptValidationResult.invalid({
    required String errorCode,
    String? message,
  }) {
    return ReceiptValidationResult(
      isValid: false,
      errorCode: errorCode,
      message: message,
    );
  }
}

/// Validates a store purchase against an authoritative server (the
/// `verifyPurchase` Cloud Function, which calls the Google Play Developer API
/// and writes `entitlements/{uid}` in Firestore). The client never trusts a
/// purchase until this returns [ReceiptValidationResult.isValid].
abstract interface class PurchaseReceiptValidator {
  Future<ReceiptValidationResult> validate({
    required String productId,
    required String purchaseToken,
    required String source, // 'purchase' | 'restore'
  });
}
