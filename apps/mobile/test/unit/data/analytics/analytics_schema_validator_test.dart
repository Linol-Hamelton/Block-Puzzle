import 'package:block_puzzle_mobile/data/analytics/analytics_schema_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsSchemaValidator', () {
    const AnalyticsSchemaValidator validator = AnalyticsSchemaValidator();

    test('validates game_start payload with required fields', () {
      final AnalyticsValidationResult result = validator.validate(
        'game_start',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'round_id': 4,
          'mode': 'classic',
          'config_version': 'cfg-01',
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('accepts game_start payload with UX and balance variants', () {
      final AnalyticsValidationResult result = validator.validate(
        'game_start',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'round_id': 5,
          'mode': 'classic',
          'config_version': 'cfg-02',
          'ux_variant': 'hud_focus_v1',
          'difficulty_variant': 'challenge_bias_v1',
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('accepts share_score_tapped payload', () {
      final AnalyticsValidationResult result = validator.validate(
        'share_score_tapped',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'round_id': 7,
          'channel': 'clipboard',
          'score_total': 540,
          'best_score': 820,
          'level': 4,
          'moves_played': 31,
          'daily_goals_completed': 2,
          'daily_goals_total': 3,
          'ux_variant': 'hud_focus_v1',
          'difficulty_variant': 'balanced_v1',
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('accepts share_score_result payload', () {
      final AnalyticsValidationResult result = validator.validate(
        'share_score_result',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'round_id': 7,
          'channel': 'clipboard',
          'success': true,
          'score_total': 540,
          'best_score': 820,
          'level': 4,
          'moves_played': 31,
          'daily_goals_completed': 2,
          'daily_goals_total': 3,
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('returns invalid when required fields are missing', () {
      final AnalyticsValidationResult result = validator.validate(
        'ad_impression',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'placement': 'game_over_interstitial',
        },
      );

      expect(result.isValid, isFalse);
      expect(result.missingRequired, contains('ad_type'));
      expect(result.missingRequired, contains('network'));
    });

    test('marks unknown params as warnings without failing', () {
      final AnalyticsValidationResult result = validator.validate(
        'move_rejected',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'reason': 'invalid_move',
          'unexpected_param': 123,
        },
      );

      expect(result.isValid, isTrue);
      expect(result.unknownParams, contains('unexpected_param'));
      expect(result.warnings, isNotEmpty);
    });

    test('requires schema_version for any event', () {
      final AnalyticsValidationResult result = validator.validate(
        'game_loop_initialized',
        params: const <String, Object?>{},
      );

      expect(result.isValid, isFalse);
      expect(result.missingRequired, contains('schema_version'));
    });

    test('accepts tutorial_step with optional dropoff_reason', () {
      final AnalyticsValidationResult result = validator.validate(
        'tutorial_step',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'step_id': 'goal_clear_line',
          'status': 'skipped',
          'dropoff_reason': 'max_guided_moves_reached',
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('accepts ab_experiment_exposure payload', () {
      final AnalyticsValidationResult result = validator.validate(
        'ab_experiment_exposure',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'experiment_id': 'offer_strategy',
          'variant_id': 'cosmetics_first_v1',
          'source': 'remote_config',
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('accepts store_open payload with targeting fields', () {
      final AnalyticsValidationResult result = validator.validate(
        'store_open',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'items_count': 4,
          'owned_count': 1,
          'strategy': 'cosmetics_first',
          'offer_strategy_variant': 'cosmetics_first_v2',
          'user_segment': 'engaged_user',
          'recommended_sku': 'utility_tools_pass',
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('accepts offer_targeting_exposure payload', () {
      final AnalyticsValidationResult result = validator.validate(
        'offer_targeting_exposure',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'segment': 'new_user',
          'strategy_variant': 'cosmetics_first_v2',
          'recommended_sku': 'skin_pack_neon',
          'targeted_skus': 'skin_pack_neon,skin_pack_mono,utility_tools_pass',
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('accepts daily_goal_progress payload', () {
      final AnalyticsValidationResult result = validator.validate(
        'daily_goal_progress',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'goal_id': 'daily_moves',
          'progress': 18,
          'target': 18,
          'is_completed': true,
          'completed_goals': 1,
          'total_goals': 3,
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('accepts streak_updated payload', () {
      final AnalyticsValidationResult result = validator.validate(
        'streak_updated',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'current_streak': 4,
          'best_streak': 7,
          'reason': 'continued',
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('accepts rewarded_hint_used payload', () {
      final AnalyticsValidationResult result = validator.validate(
        'rewarded_hint_used',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'round_id': 3,
          'cost': 1,
          'source': 'earned_credits',
          'credits_after': 2,
          'piece_id': 'line4',
          'anchor_x': 2,
          'anchor_y': 4,
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('accepts rewarded_undo_used payload', () {
      final AnalyticsValidationResult result = validator.validate(
        'rewarded_undo_used',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'round_id': 3,
          'cost': 1,
          'source': 'iap_unlimited',
          'credits_after': 2,
          'moves_after': 4,
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('accepts rewarded_tools_credits_earned payload', () {
      final AnalyticsValidationResult result = validator.validate(
        'rewarded_tools_credits_earned',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'source': 'daily_goals',
          'goals_completed_now': 2,
          'credits_earned': 2,
          'credits_balance': 5,
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('accepts ops_session_snapshot payload', () {
      final AnalyticsValidationResult result = validator.validate(
        'ops_session_snapshot',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'session_id': 'session_1',
          'rounds_played': 4,
          'rounds_ended': 4,
          'session_duration_sec': 220,
          'early_gameover_rate': 0.25,
          'move_rejected_rate': 0.08,
          'avg_round_duration_sec': 34.2,
          'runtime_error_count': 0,
          'move_attempts': 25,
          'move_rejected_count': 2,
          'no_valid_moves_game_over_count': 1,
          'alert_count': 0,
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('accepts ops_alert_triggered payload', () {
      final AnalyticsValidationResult result = validator.validate(
        'ops_alert_triggered',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'alert_id': 'early_gameover_rate_high',
          'severity': 'critical',
          'metric_name': 'early_gameover_rate',
          'comparator': '>',
          'threshold': 0.30,
          'observed_value': 0.5,
          'session_id': 'session_1',
          'rounds_played': 3,
          'ux_variant': 'hud_standard_v1',
          'difficulty_variant': 'balanced_v1',
          'message': 'rate exceeded threshold',
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });

    test('accepts ops_error payload', () {
      final AnalyticsValidationResult result = validator.validate(
        'ops_error',
        params: <String, Object?>{
          'schema_version': '1.0.0',
          'source': 'flutter_error',
          'error_type': 'StateError',
          'message': 'Bad state',
        },
      );

      expect(result.isValid, isTrue);
      expect(result.missingRequired, isEmpty);
      expect(result.unknownParams, isEmpty);
    });
  });
}
