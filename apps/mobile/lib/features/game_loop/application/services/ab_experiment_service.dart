import 'dart:async';

import '../../../../core/config/remote_config_reader.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../data/analytics/analytics_tracker.dart';

/// Tracks A/B experiment variant assignments and exposure events.
///
/// Extracted from [GameLoopController] to keep experiment governance
/// isolated and auditable.
class ABExperimentService {
  ABExperimentService({
    required this.analyticsTracker,
    required this.logger,
  });

  final AnalyticsTracker analyticsTracker;
  final AppLogger logger;

  String _abBucket = 'control';
  String _uxVariant = 'hud_standard_v1';
  String _difficultyVariant = 'balanced_v1';
  Map<String, String> _experimentVariants = <String, String>{};

  String get abBucket => _abBucket;
  String get uxVariant => _uxVariant;
  String get difficultyVariant => _difficultyVariant;
  Map<String, String> get experimentVariants =>
      Map<String, String>.unmodifiable(_experimentVariants);

  /// Resolve all variant assignments from remote config.
  void configure(RemoteConfigReader config) {
    _abBucket = config.readString('ab.bucket', fallback: 'control');
    _uxVariant = config.readString('ab.ux_variant', fallback: 'hud_standard_v1');
    _difficultyVariant =
        config.readString('ab.difficulty_variant', fallback: 'balanced_v1');

    final bool onboardingEnabled =
        config.readBool('onboarding.enabled', fallback: true);

    _experimentVariants = <String, String>{
      'tutorial_onboarding': config.readString(
        'ab.tutorial_variant',
        fallback: onboardingEnabled ? 'guided_v1' : 'off',
      ),
      'offer_strategy': config.readString(
        'ab.offer_strategy_variant',
        fallback: config.readString(
          'iap.rollout_strategy',
          fallback: 'cosmetics_first',
        ),
      ),
      'difficulty_curve': config.readString(
        'ab.difficulty_variant',
        fallback: _difficultyVariant,
      ),
      'hud_ux': config.readString(
        'ab.ux_variant',
        fallback: _uxVariant,
      ),
    };
  }

  /// Fire exposure events for all active experiments.
  Future<void> trackExposures() async {
    for (final MapEntry<String, String> entry in _experimentVariants.entries) {
      await analyticsTracker.track(
        'ab_experiment_exposure',
        params: <String, Object?>{
          'experiment_id': entry.key,
          'variant_id': entry.value,
          'source': 'remote_config',
        },
      );
    }
  }
}
