# Dashboard MVP Contract (Sprint 5+)

## 1. Goal
Define a stable contract for dashboard blocks and provide repeatable export from compact metrics JSON.

## 2. Source of Truth
- Contract:
  [dashboard_mvp_contract_v1.json](/d:/Block-Puzzle/data/dashboards/dashboard_mvp_contract_v1.json)
- Metrics input (run window):
  [internal_playtest_run_002_metrics.json](/d:/Block-Puzzle/data/dashboards/internal_playtest_run_002_metrics.json)

## 3. Covered Blocks
1. `retention_proxy`
2. `session_quality`
3. `monetization_proxy`
4. `engagement_systems`
5. `experiment_monitoring`
6. `observability_alerting`

## 4. Export Command
```powershell
.\scripts\export_dashboard_mvp_snapshot.ps1 `
  -MetricsPath "data/dashboards/internal_playtest_run_002_metrics.json" `
  -ContractPath "data/dashboards/dashboard_mvp_contract_v1.json" `
  -OutputPath "data/dashboards/dashboard_mvp_snapshot.json"
```

## 5. Output Artifact
`data/dashboards/dashboard_mvp_snapshot.json`

## 6. Validation Rules
1. Required fields exist.
2. Rate fields stay in `0..1` range.
3. Numeric fields are numeric.
4. `target_moves_per_run > 0`.
5. `sample_size_sessions > 0`.

## 7. Scope Boundary
Implemented:
- contract versioning
- deterministic export
- rollout-observability compatible blocks

Pending:
- direct backend aggregation feed for full production BI sources
