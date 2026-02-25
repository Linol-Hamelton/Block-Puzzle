import 'ad_guardrail_decision.dart';
import 'ad_guardrail_policy.dart';

class BasicAdGuardrailPolicy implements AdGuardrailPolicy {
  const BasicAdGuardrailPolicy();

  bool _isAdFreeMode(Map<String, Object?> remoteConfig) {
    return _readBool(
      remoteConfig['ads.ad_free_mode'],
      fallback: false,
    );
  }

  @override
  bool isBannerEnabled(Map<String, Object?> remoteConfig) {
    if (_isAdFreeMode(remoteConfig)) {
      return false;
    }
    return _readBool(
      remoteConfig['ads.banner_enabled'],
      fallback: true,
    );
  }

  @override
  bool isRewardedReviveEnabled(Map<String, Object?> remoteConfig) {
    if (_isAdFreeMode(remoteConfig)) {
      return false;
    }
    return _readBool(
      remoteConfig['ads.rewarded_revive_enabled'],
      fallback: true,
    );
  }

  @override
  int rewardedReviveClearCells(Map<String, Object?> remoteConfig) {
    return _readInt(
      remoteConfig['ads.rewarded_revive_clear_cells'],
      fallback: 6,
    ).clamp(2, 20);
  }

  @override
  AdGuardrailDecision evaluateInterstitial({
    required Map<String, Object?> remoteConfig,
    required int roundsPlayed,
    required int? lastInterstitialRound,
    required DateTime nowUtc,
    required List<DateTime> interstitialHistoryUtc,
  }) {
    if (_isAdFreeMode(remoteConfig)) {
      return AdGuardrailDecision.deny('ad_free_mode');
    }

    final bool enabled = _readBool(
      remoteConfig['ads.interstitial_enabled'],
      fallback: true,
    );
    if (!enabled) {
      return AdGuardrailDecision.deny('disabled');
    }

    final int skipFirstRounds = _readInt(
      remoteConfig['ads.interstitial_skip_first_rounds'],
      fallback: 1,
    ).clamp(0, 99);
    if (roundsPlayed <= skipFirstRounds) {
      return AdGuardrailDecision.deny('new_user_protection');
    }

    final int cooldownRounds = _readInt(
      remoteConfig['ads.interstitial_cooldown_rounds'],
      fallback: 2,
    ).clamp(1, 20);
    if (lastInterstitialRound != null) {
      final int roundsSinceLast = roundsPlayed - lastInterstitialRound;
      if (roundsSinceLast < cooldownRounds) {
        return AdGuardrailDecision.deny('cooldown_rounds');
      }
    }

    final int windowMinutes = _readInt(
      remoteConfig['ads.interstitial_window_minutes'],
      fallback: 10,
    ).clamp(1, 120);
    final int maxInWindow = _readInt(
      remoteConfig['ads.interstitial_max_impressions_in_window'],
      fallback: 2,
    ).clamp(1, 20);

    final DateTime windowStart = nowUtc.subtract(
      Duration(minutes: windowMinutes),
    );
    final int impressionsInWindow = interstitialHistoryUtc
        .where((DateTime ts) => ts.isAfter(windowStart))
        .length;
    if (impressionsInWindow >= maxInWindow) {
      return AdGuardrailDecision.deny('window_cap');
    }

    return AdGuardrailDecision.allow();
  }

  bool _readBool(
    Object? value, {
    required bool fallback,
  }) {
    if (value is bool) {
      return value;
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
    return fallback;
  }
}
