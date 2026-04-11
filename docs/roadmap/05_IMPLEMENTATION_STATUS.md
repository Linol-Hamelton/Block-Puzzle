# Implementation Status (Source Of Truth)

Last updated: 2026-04-12

## Overall
- Product maturity: `pre-production`
- Playable scope: `Classic`
- Release readiness: `not ready for market publication`
- Active phase: `Phase 0 — Gardening & Alignment` (per [01_ROADMAP_AND_SPRINTS.md](01_ROADMAP_AND_SPRINTS.md))
- Strategy: finish reliability/data/commerce foundations before launching new modes or engagement features
- Monetization model: ad-free (IAP cosmetics + Premium Pass + soft-currency packs); no ads of any kind
- Production data plane: Firebase-first (Crashlytics, Analytics + BigQuery, Remote Config, Cloud Messaging, Auth, Cloud Functions)
- `services/config-api` and `services/analytics-pipeline` — deferred; superseded by Firebase for now
- Phase 4 (Mode Hub, Time Rush, Puzzle Pack, Daily Challenge, Leaderboards) status: `frozen` until Phase 1 and Phase 2 gates are green

## Implemented In Code
- Classic gameplay loop with scoring, combos, game over, restart
- FTUE/onboarding overlay logic with persisted completion status
- Daily goals, streak progression, rewarded tool credits, best score persistence
- Premium store surface, offer targeting, owned entitlement sync into player progress
- Session/game/ops analytics events and schema validation hooks
- Remote config client with:
  - bundled defaults
  - cached snapshots
  - version field
  - rollback snapshot slot
  - TTL-based freshness model
- Release-safe local analytics queue with batched HTTP transport hook
- Environment-aware DI with `AppEnvironment` + `BuildFlavor`

## Simulated / Scaffolded
- `services/config-api` API boundary is documented but deferred — Firebase Remote Config will replace it in Phase 1
- `services/analytics-pipeline` ingestion boundary is documented but deferred — Firebase Analytics + BigQuery export will replace it in Phase 1
- Stage/prod premium flow persists local entitlements and does not perform real store billing (Phase 1 wires `in_app_purchase` + Cloud Functions `verifyPurchase`)
- Rollout/AB logic exists on the client side, but not yet under a live remote control plane (Phase 1 moves this to Firebase Remote Config + Firebase A/B Testing)
- Internal playtests and dashboards exist as simulations, but production telemetry aggregation is not active (Phase 2 stands up Looker Studio + BigQuery)

## Debug-Only
- `DebugAnalyticsTracker`
- `DebugAdService`
- `DebugIapStoreService`
- `InMemoryRemoteConfigRepository`

These are allowed only for `dev/debug` builds.

## Not Implemented Yet
- Firebase Crashlytics + ANR bridge (Phase 1 Week 1)
- Google Play Billing v7 + RuStore billing with server-side receipt validation via Cloud Functions (Phase 1 Week 3)
- Firebase Remote Config adapter with kill switches and typed schema (Phase 1 Week 3)
- Firebase Analytics adapter + BigQuery export + Looker Studio dashboards (Phase 1 Week 3, Phase 2 Week 6)
- Hive-backed persistence for player progress, game snapshot, entitlements, config cache (Phase 1 Week 2)
- Explicit lifecycle state machine with cold-kill recovery (Phase 1 Week 1)
- Device-matrix QA smoke pack on Redmi/Samsung/Honor/Xiaomi (Phase 1 Week 4)
- Meta-progression, soft currency, revive, missions, cosmetics shop, Season Pass, achievements, events, juice pack, localization, accessibility, FCM push (Phase 3)
- Mode Hub, Time Rush, Puzzle Pack, Daily Challenge, Leaderboards (Phase 4)

## Current Execution Order
1. **Phase 0** — Gardening & Alignment (docs under Firebase-first, skeletons, strict analyzer)
2. **Phase 1** — Foundation & Stability Gates (20 days) — Firebase core, Crashlytics, Remote Config, Analytics, real Billing, Hive, lifecycle, device matrix
3. **Phase 2** — Soft Launch & Cohort Loop (15 days) — store submission, dashboards, 2 cohort windows, Go/No-Go
4. **Phase 3** — Engagement Expansion (25 days) — meta-progression, soft currency, revive, missions, cosmetics, Pass, achievements, events, juice, localization
5. **Phase 4** — Mode Hub & New Modes (30 days) — unfreezes Sprint 9 scope on a hardened foundation
6. **Phase 5** — TOP-1 Tuning & Live Ops (continuous) — A/B experiments, seasonal content, ASO, community

## Acceptance Gates Before Any Publish Decision
- Persisted progress survives cold restart and corrupted cache recovery (Phase 1 Week 2)
- Release builds send `session_start`, `game_start`, `game_end`, and `ops_*` via Firebase Analytics (Phase 1 Week 3)
- Crashlytics receives real crash/ANR events from release builds (Phase 1 Week 1)
- Real Google Play billing sandbox passes purchase + restore + reinstall for at least one cosmetic SKU (Phase 1 Week 3)
- Store metadata and screenshots match shipped functionality (Phase 2 Week 5)
- Crash-free sessions ≥ 99.5% measured from real release traffic across two consecutive cohort windows (Phase 2 Week 7-8)
- `flutter analyze --fatal-infos --fatal-warnings` green and `flutter test` green including `cold_kill_recovery_test`
- Early game-over rate ≤ 0.30, runtime error session rate ≤ 0.02, `ops_alert_critical_count == 0` in the decision window
- No open P0/P1 bugs
