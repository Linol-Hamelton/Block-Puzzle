# Run 002 Input Template (Real Human Metrics)

Use this template:
[internal_playtest_run_002_metrics_template.json](/d:/Block-Puzzle/data/dashboards/internal_playtest_run_002_metrics_template.json)

Create metrics file:
`data/dashboards/internal_playtest_run_002_metrics.json`

## Required fields
1. `target_moves_per_run`
2. `observed_early_gameover_rate`
3. `observed_avg_moves_per_run`
4. `avg_session_minutes`
5. `combo_move_rate`
6. `rewarded_opt_in_rate`
7. `sample_size_sessions`

Field notes:
- `rewarded_opt_in_rate` in current ad-free strategy means utility tools opt-in path (credits/IAP context), not ad reward traffic.

## Optional fields
- `line_clear_rate`
- `ops_alert_count`
- `ops_alert_critical_count`
- `ops_runtime_error_sessions`
- `ops_early_gameover_alert_rate`
- `collection_window_start_utc`
- `collection_window_end_utc`
- `notes`

For Sprint 8 rollout-gate evaluation, all `ops_*` fields above are required.

## Run tuning
```powershell
.\scripts\run_002_tuning.ps1 `
  -MetricsPath "data/dashboards/internal_playtest_run_002_metrics.json" `
  -OutputPath "data/dashboards/internal_playtest_run_002_tuned_config.json"
```

## Validation behavior
- Strict mode rejects out-of-range required values.
- Strict mode fails if `sample_size_sessions < 30`.
