# Dashboard MVP Contract (Firebase Analytics → BigQuery → Looker Studio)

Last updated: 2026-04-12. Supersedes the earlier local-export contract. Aligned with [../roadmap/01_ROADMAP_AND_SPRINTS.md](../roadmap/01_ROADMAP_AND_SPRINTS.md) Phase 2 Week 6.

## 1. Goal
Define a stable contract for live-ops dashboards that feed rollout-gate decisions. The source of truth is Firebase Analytics streamed to BigQuery; Looker Studio materializes the gate-ready cohort view.

## 2. Data Pipeline
```
Client (Flutter)
  → Firebase Analytics SDK
  → Firebase Analytics ingest
  → BigQuery Export (dataset: lumina_blocks_analytics)
  → Scheduled queries (aggregation views)
  → Looker Studio dashboard
  → Product / Data team
```

- BigQuery export is enabled in Firebase Console → Project Settings → Integrations → BigQuery (daily + streaming).
- The raw export lands in `events_YYYYMMDD` and `events_intraday_YYYYMMDD` tables.
- Scheduled queries in `analytics_aggregates.*` build per-gate materializations on a 1-hour cadence.

## 3. Dashboard Blocks
1. **Retention proxy** — D1 / D7 / D30 retention cohort plot by install date and build version.
2. **Session quality** — DAU, average session length, sessions per DAU, average moves per run.
3. **Monetization proxy** — ARPDAU, paying DAU %, top SKUs by revenue, pass conversion rate.
4. **Engagement systems** — mission completion rate, wheel engagement, revive usage, cosmetic preview rate, achievement unlock rate.
5. **Experiment monitoring** — Firebase A/B Testing variant exposure, metric delta vs control, significance.
6. **Observability & alerting** — crash-free sessions %, ANR rate, `ops_alert_triggered` counts by severity, `ops_error` counts by source.
7. **Rollout gates** — per-window hard/soft gate pass state (green/yellow/red) with direct link to the acceptance checklist.

## 4. Source Data Expectations
- Every production release emits `session_start`, `session_end`, `game_start`, `game_end`, and `ops_session_snapshot` within 10 minutes of install.
- Every gameplay round emits exactly one `game_end` with session_id, score, lines_cleared, rounds, early_gameover flag.
- Analytics events are Firebase Analytics snake_case with `schema_version`, `app_version`, `build_flavor`, `config_version`, and `ab_*` variant parameters.
- BigQuery export includes the `user_pseudo_id` for cohort joining.

## 5. Aggregation Rules
- Rate fields stay in `0..1`; any out-of-range value is excluded from the aggregate and logged to `analytics_quarantine`.
- `sample_size_sessions > 0` is required for any cohort block to be considered valid.
- Windows are 72 hours by default; the dashboard offers 24h / 72h / 7d toggles.
- AB variants are split only when `sample_size_per_variant ≥ 100`.

## 6. Rollout Gate Evaluation
Gate thresholds come from [16_ROLLOUT_GATES_CHECKLIST_OPS_SIGNALS.md](16_ROLLOUT_GATES_CHECKLIST_OPS_SIGNALS.md). The dashboard does not gate decisions on its own; it surfaces gate state and a "snapshot as JSON" link for a human review meeting.

## 7. Access & Permissions
- Firebase project: `lumina-blocks-prod` (and `lumina-blocks-stage`).
- BigQuery: `analyst` IAM role for the product/data team; `editor` only for CI-managed scheduled queries.
- Looker Studio: view-only link for the leadership group; edit access limited to the data owner.

## 8. Artifact Naming
- Scheduled queries: `aggregates_retention_d1_d7_d30`, `aggregates_monetization_daily`, `aggregates_engagement_daily`, `aggregates_ops_alerts_hourly`, `aggregates_rollout_gate_window`.
- Looker Studio report: `Lumina Blocks — Rollout & LiveOps`.
- Weekly export for executive review: `lumina_blocks_weekly_<YYYY-Www>.pdf` generated via Looker Studio scheduled email.

## 9. Deferred / Out of Scope
- The local PowerShell export path and `data/dashboards/dashboard_mvp_contract_v1.json` artifact are retained only for Phase 0 internal-playtest replay. They do not reflect production data.
- A custom `services/analytics-pipeline` ingestion backend is deferred ([../../services/analytics-pipeline/README.md](../../services/analytics-pipeline/README.md)).
- Server-side funnels beyond Firebase/BigQuery views are Phase 5+, only if Looker Studio becomes insufficient.
