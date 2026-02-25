# Run 002 Input Template (Real Human Metrics)

Use this file as the source template:
[internal_playtest_run_002_metrics_template.json](/d:/Block-Puzzle/data/dashboards/internal_playtest_run_002_metrics_template.json)

Create a real metrics file:
`data/dashboards/internal_playtest_run_002_metrics.json`

## Required fields
1. `target_moves_per_run`
- Integer, recommended: `10..20`.
- Current baseline target: `14`.

2. `observed_early_gameover_rate`
- Float in range `0..1`.
- Formula: runs ending before 8 moves / total runs.

3. `observed_avg_moves_per_run`
- Float in range `0..250`.
- Formula: total moves across runs / number of runs.

4. `avg_session_minutes`
- Float in range `0..180`.
- Formula: total session minutes / number of sessions.

5. `combo_move_rate`
- Float in range `0..1`.
- Formula: moves with combo streak > 1 / total moves.

6. `rewarded_opt_in_rate`
- Float in range `0..1`.
- Formula: rewarded accepts / rewarded offers.

7. `sample_size_sessions`
- Integer, must be `>= 30` for strict tuning.

## Optional fields
- `line_clear_rate` (not used by current tuner, but saved for analysis)
- `collection_window_start_utc`
- `collection_window_end_utc`
- `notes`

## Run tuning for iteration #1 (human data)
```powershell
.\scripts\run_002_tuning.ps1 `
  -MetricsPath "data/dashboards/internal_playtest_run_002_metrics.json" `
  -OutputPath "data/dashboards/internal_playtest_run_002_tuned_config.json"
```

## Validation behavior
- `-Strict` mode is enabled by wrapper script.
- Tuning will fail if any required metric is out of range.
- Tuning will fail if `sample_size_sessions < 30`.
