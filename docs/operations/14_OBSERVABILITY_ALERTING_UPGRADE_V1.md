# Observability and Alerting Upgrade v1 (Sprint 7)

## 1. Goal
Add a first operational guardrail layer on top of gameplay telemetry to detect regressions early and unblock safer sprint-to-sprint rollout.

## 2. New Operational Events
1. `ops_session_snapshot`
- emitted at session end
- payload includes:
  - `session_id`
  - `rounds_played`
  - `rounds_ended`
  - `session_duration_sec`
  - `early_gameover_rate`
  - `move_rejected_rate`
  - `avg_round_duration_sec`
  - `runtime_error_count`
  - optional counters and `alert_count`

2. `ops_alert_triggered`
- emitted once per violated guardrail on session end
- payload includes:
  - `alert_id`
  - `severity`
  - `metric_name`
  - `comparator`
  - `threshold`
  - `observed_value`
  - optional context: `session_id`, variants, message

3. `ops_error`
- emitted on global/runtime error hooks and selected controller recoveries
- payload includes:
  - `source`
  - `error_type`
  - optional `message`

## 3. Runtime Sources
1. `GameLoopController`
- tracks move attempts, rejections, round endings, no-move game-overs
- tracks recoverable runtime failures in gameplay dependencies

2. App bootstrap hooks
- `FlutterError.onError`
- `PlatformDispatcher.instance.onError`

## 4. Guardrail Rules (Default)
1. `early_gameover_rate > ops.alerting.max_early_gameover_rate` (critical)
2. `move_rejected_rate > ops.alerting.max_move_rejection_rate` with sample floor (warning)
3. `avg_round_duration_sec < ops.alerting.min_avg_round_duration_sec` (warning)
4. `runtime_error_count > ops.alerting.max_runtime_error_count` (critical)

## 5. Remote Config Keys
1. `ops.alerting.enabled` (bool)
2. `ops.alerting.max_early_gameover_rate` (double)
3. `ops.alerting.max_move_rejection_rate` (double)
4. `ops.alerting.min_avg_round_duration_sec` (double)
5. `ops.alerting.max_runtime_error_count` (int)

## 6. Operational Playbook v1
1. Monitor daily counts of `ops_alert_triggered` by `alert_id`, `ux_variant`, `difficulty_variant`.
2. If critical alert trend persists for 2 collection windows, freeze experiment traffic increase.
3. If runtime alert spikes, block rollout and run hotfix triage before next build promotion.
4. Keep thresholds in remote config so rollback can be tuned without app patch.
