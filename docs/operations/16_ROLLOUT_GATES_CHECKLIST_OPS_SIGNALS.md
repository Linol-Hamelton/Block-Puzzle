# Rollout Gates Checklist (ops_* Signals, v1)

## 1. Scope
Checklist for rollout readiness in Sprint 8 using gameplay + observability signals.

## 2. Pre-Check (must be true before metrics review)
1. Build health:
- `flutter analyze` passed
- `flutter test` passed
2. Data contract:
- `session_start`, `game_start`, `game_end` events are valid
- `ops_session_snapshot` events are present
- `ops_alert_triggered` events are present when violations happen
- `ops_error` events are present for runtime failures
3. Cohort quality:
- human sessions only
- stable session window defined (`collection_window_start_utc`, `collection_window_end_utc`)

## 3. Hard Gates (block rollout increase if failed)
1. `sample_size_sessions >= 30`
2. `observed_early_gameover_rate <= 0.30`
3. `ops_alert_critical_count <= 0`
4. `ops_runtime_error_session_rate <= 0.02`
5. `ops_early_gameover_alert_rate <= 0.10`

## 4. Soft Gates (watchlist; do not block 10% rollout step)
1. `avg_session_minutes >= 6.0`
2. `combo_move_rate >= 0.20`
3. `target_attainment_pct` within `92..123`
4. `ops_alert_rate <= 0.25`

## 5. Decision Policy
1. All hard + all soft pass:
- decision: `go_rollout_25_percent`

2. Hard pass, soft fail:
- decision: `go_rollout_10_percent_watchlist`

3. Any hard fail:
- decision: `hold_and_iterate`

## 6. Incident Follow-up
1. `ops_alert_critical_count` fail:
- freeze rollout increase immediately
- run rollback review for remote config diffs

2. `ops_runtime_error_session_rate` fail:
- open hotfix triage
- block promotion until new build verification

3. `ops_early_gameover_alert_rate` fail:
- lower difficulty pressure and rerun cohort window

## 7. Command
```powershell
.\scripts\evaluate_rollout_gates.ps1 `
  -MetricsPath "data/dashboards/internal_playtest_run_002_metrics.json" `
  -ThresholdsPath "data/dashboards/rollout_gates_thresholds_v1.json" `
  -OutputPath "data/dashboards/rollout_gates_report_iteration_002.json"
```
