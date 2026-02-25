# Dashboard MVP Contract (Sprint 5)

## 1. Goal
Define a stable contract for first dashboard blocks and provide a repeatable export step from playtest metrics JSON.

## 2. Source of Truth
- Contract file:
  [dashboard_mvp_contract_v1.json](/d:/Block-Puzzle/data/dashboards/dashboard_mvp_contract_v1.json)
- Primary compact source (playtest):
  [internal_playtest_run_002_metrics.json](/d:/Block-Puzzle/data/dashboards/internal_playtest_run_002_metrics.json)

## 3. Covered Blocks
1. `retention_proxy`
2. `session_quality`
3. `monetization_proxy`
4. `engagement_systems` (source-ready placeholder)
5. `experiment_monitoring` (source-ready placeholder)

## 4. Export Command
```powershell
.\scripts\export_dashboard_mvp_snapshot.ps1 `
  -MetricsPath "data/dashboards/internal_playtest_run_002_metrics.json" `
  -ContractPath "data/dashboards/dashboard_mvp_contract_v1.json" `
  -OutputPath "data/dashboards/dashboard_mvp_snapshot.json"
```

## 5. Output
- Export artifact:
  `data/dashboards/dashboard_mvp_snapshot.json`
- The export validates required fields and metric ranges, then writes normalized block-level payload for BI/bootstrap usage.

## 6. Validation Rules
1. Required fields must exist (from contract).
2. Rates must be within `0..1`.
3. `target_moves_per_run > 0`.
4. `sample_size_sessions > 0`.
5. Numeric fields must contain numeric values (not strings/null).

## 7. Sprint 5 Scope Boundary
- Included now:
  - contract versioning
  - source mapping
  - deterministic export payload
- Deferred:
  - direct pipeline aggregation wiring (daily goals/streak and experiment split placeholders become real after backend/data ingestion integration)
