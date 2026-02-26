# Soft Launch Iteration #2 Loop (Sprint 8)

## 1. Goal
Run a repeatable operational loop for soft launch wave #2 with rollout decisions based on product metrics and new `ops_*` observability signals.

## 2. Input Artifacts
1. Human metrics source:
`data/dashboards/internal_playtest_run_002_metrics.json`
2. Rollout thresholds:
`data/dashboards/rollout_gates_thresholds_v1.json`
3. Dashboard contract:
`data/dashboards/dashboard_mvp_contract_v1.json`

## 3. Iteration Outputs
1. Tuned config:
`data/dashboards/internal_playtest_run_002_tuned_config.json`
2. Dashboard snapshot:
`data/dashboards/dashboard_mvp_snapshot.json`
3. Rollout gates report:
`data/dashboards/rollout_gates_report_iteration_002.json`

## 4. One-Command Loop
```powershell
.\scripts\run_soft_launch_iteration_002.ps1 `
  -MetricsPath "data/dashboards/internal_playtest_run_002_metrics.json" `
  -FailOnHold
```

## 5. Manual Step-by-Step (if needed)
1. Tune config:
```powershell
.\scripts\run_002_tuning.ps1 `
  -MetricsPath "data/dashboards/internal_playtest_run_002_metrics.json" `
  -OutputPath "data/dashboards/internal_playtest_run_002_tuned_config.json"
```

2. Export dashboard snapshot:
```powershell
.\scripts\export_dashboard_mvp_snapshot.ps1 `
  -MetricsPath "data/dashboards/internal_playtest_run_002_metrics.json" `
  -ContractPath "data/dashboards/dashboard_mvp_contract_v1.json" `
  -OutputPath "data/dashboards/dashboard_mvp_snapshot.json"
```

3. Evaluate rollout gates:
```powershell
.\scripts\evaluate_rollout_gates.ps1 `
  -MetricsPath "data/dashboards/internal_playtest_run_002_metrics.json" `
  -ThresholdsPath "data/dashboards/rollout_gates_thresholds_v1.json" `
  -OutputPath "data/dashboards/rollout_gates_report_iteration_002.json"
```

## 6. Decision Mapping
1. `go_rollout_25_percent`
- all hard and soft gates passed
- proceed with 25% rollout step

2. `go_rollout_10_percent_watchlist`
- all hard gates passed, one or more soft gates failed
- continue with 10% rollout and daily watchlist

3. `hold_and_iterate`
- one or more hard gates failed
- freeze rollout increase, iterate config/build and rerun loop

## 7. Cadence
1. Collect fresh human cohort metrics daily during active wave.
2. Re-run loop on each new cohort window.
3. Promote rollout only when decision is stable for at least 2 consecutive windows.
