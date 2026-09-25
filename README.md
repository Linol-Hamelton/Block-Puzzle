# Lumina Blocks

Flutter + Flame block puzzle client with supporting docs, store assets, release checklists, and backend service contracts. Android-first (Google Play and RuStore), ad-free-first monetization, targeting the TOP-1 tier of the block puzzle genre.

## Current Status
- Product maturity: `pre-release / external testing ready`
- Playable modes: `Classic`, `Tetris`, `Match-3`, `Daily Challenge` — all fully wired and playable
- Quality & test coverage: **540 tests passing** (`flutter test --no-pub`), 0 analyzer issues (`flutter analyze --no-pub`)
- Active milestone: Stage W3 (First External Test Readiness) complete; Stage W4 (Documentation Hygiene) in progress per [docs/roadmap/15_POST_DEC0024_PLAN_2026-09-21.md](docs/roadmap/15_POST_DEC0024_PLAN_2026-09-21.md)
- Distribution: direct release-signed APK for initial external testing cohort (DEC-0012/DEC-0026)

## Monetization Model (Fixed Decision)
- Fully ad-free. No banner, no interstitial, no rewarded video.
- In v1.0 initial release, commercial store surfaces are gated and hidden (DEC-0026 / DEC-0028).
- Future monetization (Stage C, frozen) is limited strictly to non-consumable cosmetic items (skins, themes, VFX).
- Reference: [docs/operations/08_AD_FREE_MODE_STRATEGY.md](docs/operations/08_AD_FREE_MODE_STRATEGY.md)

## Backend Choice (Fixed Decision)
Firebase-first for production data plane:
- Firebase Crashlytics — crash reporting
- Firebase Analytics + BigQuery export — event ingestion, cohort analysis
- Firebase Remote Config — feature flags, mode kill-switches, live config
- Firebase Cloud Messaging — push notifications (re-engagement, max 1/day)
- Firebase Auth (Anonymous) — UID binding for entitlement sync
- Cloud Functions — receipt validation (`verifyPurchase`), alert routing

The `services/config-api` and `services/analytics-pipeline` contracts are deferred in favor of Firebase.

## What Is Implemented
> Full reconciled status with code evidence: [docs/roadmap/05_IMPLEMENTATION_STATUS.md](docs/roadmap/05_IMPLEMENTATION_STATUS.md).
- **Three Playable Game Modes**:
  - Classic: Fair Bag deal guarantee (DEC-0024/0028), anti-chunking deal generator, combo ladder, score popups, shockwave VFX.
  - Tetris: 7-bag, SRS rotation/kicks, ghost piece, hold/next preview, T-spin, combo, dedicated snapshot persistence.
  - Match-3: 8x8 gem grid, cascade resolver, move limits, shuffle, dedicated session store.
  - Daily Challenge: deterministic seed milestone run.
- **Flame VFX Juice Architecture (DEC-0024 / DEC-0028)**:
  - Decoupled `VfxDirector` event bus powering particles, shockwaves, score pops, and combo banners across all modes.
  - Hardware-accelerated `GlassTileAtlas` procedural baking for smooth batch rendering.
  - Calibrated tactile haptics, landing squashes, camera shakes, and hit-stop physics.
  - GLSL fragment shader `PieceAuraShader` blooming for active/ghost pieces and charged gems.
  - Procedural `CelebrationDirector` victory and high-score badge overlays.
  - Comprehensive `Reduced Motion` accessibility gating (suppression of shockwaves/shakes and flash attenuation).
- **Audio Overhaul (DEC-0024 / DEC-0026 / DEC-0028)**:
  - 4 mastered AAC-LC CBR 144k stereo tracks (`music_menu`, `music_classic`, `music_tetris`, `music_match3`).
  - Seamless equal-power crossfading (`MusicPlaylistManager`) across screens with audio focus and ducking.
  - Dedicated unstealable SFX channels for line clears and game over.
- **Screen Wake Management**: `FLAG_KEEP_SCREEN_ON` platform channel (`ScreenWakeManager`) keeps screen on during active games.
- **Persistence & Progress**: Hive-backed persistence (`HivePlayerProgressRepository` + `HiveGameSessionRepository`), daily goals, streak, best score.
- **Telemetry**: Analytics events (`game_session_start`, `game_start`, `line_clear`, `game_end`, `ops_*`) with strict schema validation and explicit `game_id` across all modes.
- **Test Infrastructure & E2E**: Test DI helper (`apps/mobile/test/helpers/test_di.dart`) and 8 end-to-end integration widget tests in `apps/mobile/test/widget_test.dart`.
- **Security & CI**: Release signing fail-fast without debug fallback in Gradle & CI workflow.
- **Localization**: Russian localization for store controller strings (`StoreStrings`).

## What Is Simulated Or Scaffolded
- `services/config-api` and `services/analytics-pipeline` contracts exist, deferred — Firebase replaces them.
- Store monetization UI: gated and hidden in v1.0 builds per DEC-0026 / DEC-0028. `utility_tools_pass` excluded from catalog.
- Billing client (`GooglePlayBillingService`) and Cloud Function exist; sandbox deployment deferred to Stage C.

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
