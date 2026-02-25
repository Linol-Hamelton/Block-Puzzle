import 'ad_guardrail_decision.dart';

abstract interface class AdGuardrailPolicy {
  bool isBannerEnabled(Map<String, Object?> remoteConfig);

  bool isRewardedReviveEnabled(Map<String, Object?> remoteConfig);

  int rewardedReviveClearCells(Map<String, Object?> remoteConfig);

  AdGuardrailDecision evaluateInterstitial({
    required Map<String, Object?> remoteConfig,
    required int roundsPlayed,
    required int? lastInterstitialRound,
    required DateTime nowUtc,
    required List<DateTime> interstitialHistoryUtc,
  });
}
