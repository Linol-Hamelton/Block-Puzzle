class RewardedReviveResult {
  const RewardedReviveResult({
    required this.isSuccess,
    this.failureReason,
  });

  final bool isSuccess;
  final String? failureReason;

  factory RewardedReviveResult.success() {
    return const RewardedReviveResult(isSuccess: true);
  }

  factory RewardedReviveResult.failure(String reason) {
    return RewardedReviveResult(
      isSuccess: false,
      failureReason: reason,
    );
  }
}
