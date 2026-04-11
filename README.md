# Lumina Blocks

Flutter + Flame block puzzle client with supporting docs, store assets, release checklists, and backend service contracts. Android-first (Google Play and RuStore), ad-free-first monetization, targeting the TOP-1 tier of the block puzzle genre.

## Current Status
- Product maturity: `pre-production`
- Core mode: `Classic` is playable and instrumented, but not yet publish-ready
- Active priority: foundation gates — Firebase Crashlytics, real Google Play Billing v7, lifecycle-safe persistence, Firebase Remote Config, release discipline
- Frozen until foundation gates are green: `Mode Hub`, `Time Rush`, `Puzzle Pack`, `Daily Challenge`, `Leaderboards`

## Monetization Model (Fixed Decision)
- Fully ad-free. No banner, no interstitial, no rewarded video.
- Revenue comes from IAP only: cosmetics (block skins, board backgrounds, line-clear VFX, SFX packs), Premium Pass, soft-currency packs.
- Second chance, daily wheel, and utility tools are backed by soft currency and the Premium Pass, never by ads.
- Reference: [docs/operations/08_AD_FREE_MODE_STRATEGY.md](docs/operations/08_AD_FREE_MODE_STRATEGY.md)

## Backend Choice (Fixed Decision)
Firebase-first for production data plane:
- Firebase Crashlytics — crash / ANR reporting
- Firebase Analytics + BigQuery export — event ingestion, cohort analysis via Looker Studio
- Firebase Remote Config — feature flags, kill switches, AB assignments, live config
- Firebase Cloud Messaging — push notifications (re-engagement, max 1/day)
- Firebase Auth (Anonymous) — UID binding for entitlement sync
- Cloud Functions — receipt validation (`verifyPurchase`), alert routing, mission rolling

The `services/config-api` and `services/analytics-pipeline` contracts are deferred; they remain in the repo for historical context and as potential future replacement paths if Firebase becomes insufficient for control or compliance reasons.

## What Is Implemented
- Classic gameplay loop: scoring, line clear, combo, game over, restart
- FTUE/onboarding flow with persisted completion state
- Best score, streak, daily goals, rewarded credits, owned premium items persistence (on SharedPreferences, Phase 1 migrates this to Hive)
- Remote config client contract with bundled defaults, cached snapshots, versioning, rollback slot (Phase 1 adds Firebase Remote Config implementation)
- Local queued analytics with schema validation and release-safe transport hooks (Phase 1 adds Firebase Analytics bridge)
- Premium store UI surface, offer targeting logic, entitlement-aware utility tools access (Phase 1 wires real Google Play Billing)
- Ops instrumentation (`session_*`, `game_*`, `ops_*`) and client-side alert evaluation

## What Is Simulated Or Scaffolded
- `services/config-api` contract exists, deferred — Firebase Remote Config replaces it
- `services/analytics-pipeline` contract exists, deferred — Firebase Analytics + BigQuery replace it
- Premium flow persists local entitlements, not store billing (Phase 1 replaces with `in_app_purchase` + Cloud Functions receipt validation)
- Store screenshots and checklist assets are restored from current branded exports

## Debug-Only (restricted to `APP_ENV=dev` + `APP_FLAVOR=debug`)
- `DebugAnalyticsTracker`
- `DebugAdService` (no-op; ad-free strategy makes this dev-only forever)
- `DebugIapStoreService`
- `InMemoryRemoteConfigRepository`
- `LocalCatalogIapStoreService` (kept as fallback for Google-Play-less dev builds)

## Planned Before Any Scale-Up (Phase 1 and Phase 2)
- Firebase Crashlytics + ANR reporting with release dashboards
- Real Google Play Billing v7 + RuStore billing adapter + server-side receipt validation
- Firebase Remote Config with kill switches and rollout controls
- Firebase Analytics ingestion + BigQuery export + Looker Studio dashboards
- Device-matrix QA, offline/lifecycle hardening, store submission validation
- Persisted progress surviving cold kill and corrupted cache recovery (Hive migration)

## Roadmap (See docs/roadmap/01_ROADMAP_AND_SPRINTS.md)
- **Phase 0** — Gardening & Alignment (3 days)
- **Phase 1** — Foundation & Stability Gates (20 days) — replaces and extends Sprint 8.1
- **Phase 2** — Soft Launch & Cohort Loop (15 days)
- **Phase 3** — Engagement Expansion (25 days) — meta-progression, cosmetics, missions, juice, localization
- **Phase 4** — Mode Hub & New Modes (30 days) — Mode Hub, Time Rush, Puzzle Pack, Daily Challenge, Leaderboards; unfreezes Sprint 9 scope
- **Phase 5** — TOP-1 Tuning & Live Ops (continuous)

## Repo Areas
- `apps/mobile` — Flutter client
- `docs` — active product, architecture, operations, release, roadmap docs
- `docs/archive` — historical docs removed from the active decision loop
- `brand_pack` — branded source exports and brand-specific docs
- `distribution/metadata` — canonical store metadata
- `distribution/assets/checklist` — store submission asset bundle
- `services/config-api` — remote config service contract (deferred in favor of Firebase Remote Config)
- `services/analytics-pipeline` — analytics ingestion service contract (deferred in favor of Firebase Analytics + BigQuery)
- `infra/cloud_functions` — Firebase Cloud Functions (created in Phase 1)

## Source Of Truth
If documents conflict, use this order:
1. `docs/roadmap/05_IMPLEMENTATION_STATUS.md`
2. `apps/mobile` runtime code
3. `distribution/metadata/...` for store text
4. `brand_pack/docs/...` for brand asset guidance
5. `docs/archive/...` for historical context only

## Build Notes
From `apps/mobile`:

```bash
flutter pub get
flutter analyze
flutter test
```

Run the asset restoration pipeline from repo root:

```bash
python generate_assets_from_source.py
```

`flutter` and `dart` are not vendored in this repository. They must be available in the local environment.

## Target KPIs (TOP-1 benchmarks)
- Crash-free sessions ≥ 99.7%
- ANR rate ≤ 0.20%
- D1 ≥ 45%, D7 ≥ 18%, D30 ≥ 8%
- Average session length ≥ 9 minutes
- ARPDAU (IAP only) ≥ $0.08
- Early game-over rate ≤ 0.25
- Cold start p90 ≤ 2.5s on low-mid Android
