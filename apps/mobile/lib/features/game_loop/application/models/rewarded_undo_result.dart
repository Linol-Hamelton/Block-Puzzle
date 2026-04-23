class RewardedUndoResult {
  const RewardedUndoResult({
    required this.isSuccess,
    this.failureReason,
  });

  final bool isSuccess;
  final String? failureReason;

  factory RewardedUndoResult.success() {
    return const RewardedUndoResult(isSuccess: true);
  }

  factory RewardedUndoResult.failure(String reason) {
    return RewardedUndoResult(
      isSuccess: false,
      failureReason: reason,
    );
  }
}
