import '../game_loop_view_state.dart';

class RewardedHintResult {
  const RewardedHintResult({
    required this.isSuccess,
    this.hintSuggestion,
    this.failureReason,
  });

  final bool isSuccess;
  final HintSuggestion? hintSuggestion;
  final String? failureReason;

  factory RewardedHintResult.success(HintSuggestion hintSuggestion) {
    return RewardedHintResult(
      isSuccess: true,
      hintSuggestion: hintSuggestion,
    );
  }

  factory RewardedHintResult.failure(String reason) {
    return RewardedHintResult(
      isSuccess: false,
      failureReason: reason,
    );
  }
}
