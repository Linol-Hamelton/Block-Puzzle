class AnalyticsEventSchema {
  const AnalyticsEventSchema({
    required this.requiredParams,
    this.optionalParams = const <String>{},
  });

  final Set<String> requiredParams;
  final Set<String> optionalParams;

  Set<String> get allKnownParams => <String>{
        ...requiredParams,
        ...optionalParams,
      };
}

class AnalyticsValidationResult {
  const AnalyticsValidationResult({
    required this.isValid,
    required this.missingRequired,
    required this.unknownParams,
    required this.warnings,
  });

  final bool isValid;
  final List<String> missingRequired;
  final List<String> unknownParams;
  final List<String> warnings;
}

class AnalyticsSchemaValidator {
  const AnalyticsSchemaValidator({
    this.schemaVersion = '1.1.0',
    Map<String, AnalyticsEventSchema>? schemas,
  }) : _schemas = schemas ?? _defaultSchemas;

  static const Set<String> _globalKnownParams = <String>{
    'schema_version',
    'event_ts_utc',
  };

  final String schemaVersion;
  final Map<String, AnalyticsEventSchema> _schemas;

  AnalyticsValidationResult validate(
    String eventName, {
    required Map<String, Object?> params,
  }) {
    final List<String> missingRequired = <String>[];
    final List<String> unknownParams = <String>[];
    final List<String> warnings = <String>[];

    if (!_hasNonEmptyValue(params['schema_version'])) {
      missingRequired.add('schema_version');
    }

    final AnalyticsEventSchema? schema = _schemas[eventName];
    if (schema == null) {
      warnings.add('Unknown event "$eventName": validation is partial.');
      return AnalyticsValidationResult(
        isValid: missingRequired.isEmpty,
        missingRequired: missingRequired,
        unknownParams: unknownParams,
        warnings: warnings,
      );
    }

    for (final String key in schema.requiredParams) {
      if (!_hasNonEmptyValue(params[key])) {
        missingRequired.add(key);
      }
    }

    final Set<String> known = <String>{
      ...schema.allKnownParams,
      ..._globalKnownParams,
    };
    for (final String key in params.keys) {
      if (!known.contains(key)) {
        unknownParams.add(key);
      }
    }

    if (unknownParams.isNotEmpty) {
      warnings.add('Unknown params: ${unknownParams.join(', ')}');
    }

    return AnalyticsValidationResult(
      isValid: missingRequired.isEmpty,
      missingRequired: missingRequired,
      unknownParams: unknownParams,
      warnings: warnings,
    );
  }

  static bool _hasNonEmptyValue(Object? value) {
    if (value == null) {
      return false;
    }
    if (value is String) {
      return value.trim().isNotEmpty;
    }
    return true;
  }

  static const Map<String, AnalyticsEventSchema> _defaultSchemas =
      <String, AnalyticsEventSchema>{
    'session_start': AnalyticsEventSchema(
      requiredParams: <String>{
        'session_id',
        'app_version',
        'platform',
        'ab_bucket',
      },
      optionalParams: <String>{
        'ux_variant',
        'difficulty_variant',
      },
    ),
    'session_end': AnalyticsEventSchema(
      requiredParams: <String>{
        'session_id',
        'duration_sec',
        'rounds_played',
      },
    ),
    'store_open': AnalyticsEventSchema(
      requiredParams: <String>{
        'items_count',
        'owned_count',
      },
      optionalParams: <String>{
        'strategy',
        'offer_strategy_variant',
        'user_segment',
        'recommended_sku',
      },
    ),
    'offer_targeting_exposure': AnalyticsEventSchema(
      requiredParams: <String>{
        'segment',
        'strategy_variant',
        'recommended_sku',
      },
      optionalParams: <String>{
        'targeted_skus',
      },
    ),
    'game_loop_initialized': AnalyticsEventSchema(
      requiredParams: <String>{},
    ),
    'game_start': AnalyticsEventSchema(
      requiredParams: <String>{
        'round_id',
        'mode',
        'config_version',
      },
      optionalParams: <String>{
        'board_size',
        'rack_size',
        'ux_variant',
        'difficulty_variant',
      },
    ),
    'move_made': AnalyticsEventSchema(
      requiredParams: <String>{
        'round_id',
        'piece_type',
        'lines_cleared',
        'combo_index',
        'board_fill_pct',
      },
      optionalParams: <String>{
        'piece_id',
        'anchor_x',
        'anchor_y',
        'cleared_lines',
        'combo_streak',
        'score_total',
        'moves_played',
      },
    ),
    'move_rejected': AnalyticsEventSchema(
      requiredParams: <String>{
        'reason',
      },
      optionalParams: <String>{
        'piece_id',
        'anchor_x',
        'anchor_y',
      },
    ),
    'line_clear': AnalyticsEventSchema(
      requiredParams: <String>{
        'count',
      },
      optionalParams: <String>{
        'round_id',
        'score_total',
      },
    ),
    'game_end': AnalyticsEventSchema(
      requiredParams: <String>{
        'round_id',
        'end_reason',
        'score',
        'duration_sec',
      },
      optionalParams: <String>{
        'ux_variant',
        'difficulty_variant',
      },
    ),
    'share_score_tapped': AnalyticsEventSchema(
      requiredParams: <String>{
        'round_id',
        'channel',
        'score_total',
        'best_score',
        'level',
        'moves_played',
      },
      optionalParams: <String>{
        'daily_goals_completed',
        'daily_goals_total',
        'ux_variant',
        'difficulty_variant',
      },
    ),
    'share_score_result': AnalyticsEventSchema(
      requiredParams: <String>{
        'round_id',
        'channel',
        'success',
      },
      optionalParams: <String>{
        'failure_reason',
        'score_total',
        'best_score',
        'level',
        'moves_played',
        'daily_goals_completed',
        'daily_goals_total',
        'ux_variant',
        'difficulty_variant',
      },
    ),
    'tutorial_step': AnalyticsEventSchema(
      requiredParams: <String>{
        'step_id',
        'status',
      },
      optionalParams: <String>{
        'dropoff_reason',
      },
    ),
    'ab_experiment_exposure': AnalyticsEventSchema(
      requiredParams: <String>{
        'experiment_id',
        'variant_id',
      },
      optionalParams: <String>{
        'source',
      },
    ),
    'daily_goal_progress': AnalyticsEventSchema(
      requiredParams: <String>{
        'goal_id',
        'progress',
        'target',
        'is_completed',
      },
      optionalParams: <String>{
        'completed_goals',
        'total_goals',
      },
    ),
    'streak_updated': AnalyticsEventSchema(
      requiredParams: <String>{
        'current_streak',
        'best_streak',
        'reason',
      },
    ),
    'rewarded_hint_used': AnalyticsEventSchema(
      requiredParams: <String>{
        'round_id',
        'cost',
        'source',
        'credits_after',
      },
      optionalParams: <String>{
        'piece_id',
        'anchor_x',
        'anchor_y',
      },
    ),
    'rewarded_undo_used': AnalyticsEventSchema(
      requiredParams: <String>{
        'round_id',
        'cost',
        'source',
        'credits_after',
      },
      optionalParams: <String>{
        'moves_after',
      },
    ),
    'rewarded_tools_credits_earned': AnalyticsEventSchema(
      requiredParams: <String>{
        'source',
        'goals_completed_now',
        'credits_earned',
        'credits_balance',
      },
    ),
    'ad_impression': AnalyticsEventSchema(
      requiredParams: <String>{
        'placement',
        'ad_type',
        'network',
      },
      optionalParams: <String>{
        'ecpm_usd',
      },
    ),
    'ad_rewarded': AnalyticsEventSchema(
      requiredParams: <String>{
        'reward_type',
        'reward_value',
      },
    ),
    'iap_purchase_attempt': AnalyticsEventSchema(
      requiredParams: <String>{
        'sku',
        'price',
        'currency',
      },
      optionalParams: <String>{
        'user_segment',
        'offer_strategy_variant',
        'is_recommended_offer',
        'position_index',
      },
    ),
    'iap_purchase': AnalyticsEventSchema(
      requiredParams: <String>{
        'sku',
        'price',
        'currency',
        'country',
      },
      optionalParams: <String>{
        'user_segment',
        'offer_strategy_variant',
        'is_recommended_offer',
        'position_index',
      },
    ),
    'iap_restore': AnalyticsEventSchema(
      requiredParams: <String>{
        'restored_count',
      },
    ),
    'revive_applied': AnalyticsEventSchema(
      requiredParams: <String>{
        'round_id',
        'method',
      },
      optionalParams: <String>{
        'score_total',
        'moves_played',
      },
    ),
    'level_up': AnalyticsEventSchema(
      requiredParams: <String>{
        'round_id',
        'from_level',
        'to_level',
        'score_total',
      },
    ),
    'ops_session_snapshot': AnalyticsEventSchema(
      requiredParams: <String>{
        'session_id',
        'rounds_played',
        'rounds_ended',
        'session_duration_sec',
        'early_gameover_rate',
        'move_rejected_rate',
        'avg_round_duration_sec',
        'runtime_error_count',
      },
      optionalParams: <String>{
        'move_attempts',
        'move_rejected_count',
        'no_valid_moves_game_over_count',
        'alert_count',
      },
    ),
    'ops_alert_triggered': AnalyticsEventSchema(
      requiredParams: <String>{
        'alert_id',
        'severity',
        'metric_name',
        'comparator',
        'threshold',
        'observed_value',
      },
      optionalParams: <String>{
        'session_id',
        'rounds_played',
        'ux_variant',
        'difficulty_variant',
        'message',
      },
    ),
    'ops_error': AnalyticsEventSchema(
      requiredParams: <String>{
        'source',
        'error_type',
      },
      optionalParams: <String>{
        'message',
      },
    ),
  };
}
