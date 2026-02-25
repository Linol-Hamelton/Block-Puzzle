import 'remote_config_repository.dart';

class InMemoryRemoteConfigRepository implements RemoteConfigRepository {
  static const Map<String, Object?> _defaultConfig = <String, Object?>{
    'ads.ad_free_mode': true,
    'ads.banner_enabled': false,
    'ads.interstitial_enabled': false,
    'ads.interstitial_skip_first_rounds': 1,
    'difficulty.hard_piece_weight': 0.2,
    'difficulty.max_hard_pieces_per_triplet': 1,
    'ads.interstitial_cooldown_rounds': 2,
    'ads.interstitial_window_minutes': 10,
    'ads.interstitial_max_impressions_in_window': 2,
    'ads.rewarded_revive_enabled': false,
    'ads.rewarded_revive_clear_cells': 6,
    'iap.rollout_strategy': 'cosmetics_first',
    'iap.bundle_enabled': false,
    'ab.bucket': 'control',
    'ab.tutorial_variant': 'guided_v1',
    'ab.offer_strategy_variant': 'cosmetics_first_v1',
    'ab.difficulty_variant': 'balanced_v1',
    'onboarding.enabled': true,
    'onboarding.max_guided_moves': 8,
    'progression.level_score_step': 140,
    'balance.target_moves_per_run': 14,
    'balance.observed_avg_moves_per_run': 12.5,
    'balance.observed_early_gameover_rate': 0.22,
  };

  @override
  Future<Map<String, Object?>> fetchLatest() async {
    return _defaultConfig;
  }

  @override
  Future<Map<String, Object?>> getCached() async {
    return _defaultConfig;
  }
}
