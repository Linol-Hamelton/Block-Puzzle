enum IapPurchaseStatus {
  success,
  cancelled,
  failed,
}

class IapPurchaseResult {
  const IapPurchaseResult({
    required this.status,
    this.errorCode,
    this.message,
  });

  final IapPurchaseStatus status;
  final String? errorCode;
  final String? message;

  bool get isSuccess => status == IapPurchaseStatus.success;

  factory IapPurchaseResult.success() {
    return const IapPurchaseResult(status: IapPurchaseStatus.success);
  }

  factory IapPurchaseResult.cancelled([String? message]) {
    return IapPurchaseResult(
      status: IapPurchaseStatus.cancelled,
      message: message,
    );
  }

  factory IapPurchaseResult.failed({
    String? errorCode,
    String? message,
  }) {
    return IapPurchaseResult(
      status: IapPurchaseStatus.failed,
      errorCode: errorCode,
      message: message,
    );
  }
}
