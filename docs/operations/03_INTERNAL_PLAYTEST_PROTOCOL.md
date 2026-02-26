# Internal Playtest Protocol (v2)

## 1. Goal
Validate gameplay feel, control ergonomics, stability, and early retention proxies before rollout promotion.

## 2. Scope
- Build: latest internal `debug`, `profile`, or store-mode `release` build from `apps/mobile`.
- Cohort: 15-30 internal testers.
- Window: 2-4 days.
- Sessions per tester: at least 3 sessions.

## 3. Pre-Playtest Checklist
1. Build quality is green:
`flutter analyze`, `flutter test`, and at least one installable Android build (`debug` or `release`).
2. Analytics events are enabled:
`game_start`, `move_made`, `line_clear`, `game_end`, `move_rejected`.
3. Observability events are enabled:
`ops_session_snapshot`, `ops_alert_triggered` (when thresholds fail), `ops_error`.
4. Config snapshot is saved (current remote config values).

## 4. Test Scenario
1. Session A:
- Fresh launch
- Play until first game over
- Restart and continue 3+ minutes
2. Session B:
- Focus on combos and rack planning
- Rate fairness (1..5)
3. Session C:
- Long-run optimization attempt
- Mark frustration moments and visibility problems

## 5. Metrics to Collect
Primary:
- `observed_early_gameover_rate`
- `observed_avg_moves_per_run`
- `avg_session_minutes`

Secondary:
- `combo_move_rate`
- `rewarded_opt_in_rate` (utility tools opt-in path: credits/IAP context)
- `line_clear_rate`

Operational:
- `ops_alert_count`
- `ops_alert_critical_count`
- `ops_runtime_error_sessions`
- `ops_early_gameover_alert_rate`

## 6. Data Export Format
Use compact JSON schema from:
[internal_playtest_run_002_metrics_template.json](/d:/Block-Puzzle/data/dashboards/internal_playtest_run_002_metrics_template.json)

Output file:
`data/dashboards/internal_playtest_run_002_metrics.json`

## 7. Auto-Tuning Workflow
```powershell
.\scripts\run_002_tuning.ps1 `
  -MetricsPath "data/dashboards/internal_playtest_run_002_metrics.json" `
  -OutputPath "data/dashboards/internal_playtest_run_002_tuned_config.json"
```

Then run full iteration loop:
```powershell
.\scripts\run_soft_launch_iteration_002.ps1 `
  -MetricsPath "data/dashboards/internal_playtest_run_002_metrics.json"
```

## 8. Guardrails
- Never increase difficulty when `observed_early_gameover_rate > 0.35`.
- If `avg_session_minutes < 6`, reduce pressure (difficulty/UX).
- Freeze rollout increase on any hard gate fail from rollout evaluator.

## 9. Gate to Next Phase
Proceed only if:
1. `observed_avg_moves_per_run` is in target corridor.
2. `observed_early_gameover_rate <= 0.30`.
3. No critical stability issues.
4. Median fairness score >= 4/5.
