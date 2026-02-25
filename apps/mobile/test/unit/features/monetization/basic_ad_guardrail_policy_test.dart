import 'package:block_puzzle_mobile/features/monetization/basic_ad_guardrail_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BasicAdGuardrailPolicy', () {
    const BasicAdGuardrailPolicy policy = BasicAdGuardrailPolicy();

    test('blocks interstitial for protected first rounds', () {
      final decision = policy.evaluateInterstitial(
        remoteConfig: <String, Object?>{
          'ads.interstitial_skip_first_rounds': 2,
        },
        roundsPlayed: 2,
        lastInterstitialRound: null,
        nowUtc: DateTime.utc(2026, 2, 25, 10),
        interstitialHistoryUtc: const <DateTime>[],
      );

      expect(decision.allow, isFalse);
      expect(decision.reason, 'new_user_protection');
    });

    test('blocks interstitial when cooldown is not passed', () {
      final decision = policy.evaluateInterstitial(
        remoteConfig: <String, Object?>{
          'ads.interstitial_skip_first_rounds': 0,
          'ads.interstitial_cooldown_rounds': 3,
        },
        roundsPlayed: 5,
        lastInterstitialRound: 3,
        nowUtc: DateTime.utc(2026, 2, 25, 10),
        interstitialHistoryUtc: const <DateTime>[],
      );

      expect(decision.allow, isFalse);
      expect(decision.reason, 'cooldown_rounds');
    });

    test('blocks interstitial when cap in window is reached', () {
      final DateTime now = DateTime.utc(2026, 2, 25, 10);
      final decision = policy.evaluateInterstitial(
        remoteConfig: <String, Object?>{
          'ads.interstitial_skip_first_rounds': 0,
          'ads.interstitial_cooldown_rounds': 1,
          'ads.interstitial_window_minutes': 10,
          'ads.interstitial_max_impressions_in_window': 2,
        },
        roundsPlayed: 8,
        lastInterstitialRound: 6,
        nowUtc: now,
        interstitialHistoryUtc: <DateTime>[
          now.subtract(const Duration(minutes: 4)),
          now.subtract(const Duration(minutes: 2)),
        ],
      );

      expect(decision.allow, isFalse);
      expect(decision.reason, 'window_cap');
    });

    test('allows interstitial when all guardrails are satisfied', () {
      final DateTime now = DateTime.utc(2026, 2, 25, 10);
      final decision = policy.evaluateInterstitial(
        remoteConfig: <String, Object?>{
          'ads.interstitial_skip_first_rounds': 0,
          'ads.interstitial_cooldown_rounds': 2,
          'ads.interstitial_window_minutes': 10,
          'ads.interstitial_max_impressions_in_window': 3,
        },
        roundsPlayed: 7,
        lastInterstitialRound: 4,
        nowUtc: now,
        interstitialHistoryUtc: <DateTime>[
          now.subtract(const Duration(minutes: 7)),
          now.subtract(const Duration(minutes: 1)),
        ],
      );

      expect(decision.allow, isTrue);
      expect(decision.reason, 'allowed');
    });
  });
}
