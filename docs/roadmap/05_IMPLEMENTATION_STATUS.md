# Implementation Status (Source Of Truth)

Last updated: 2026-09-25 (reconciled against codebase after DEC-0024, DEC-0026, DEC-0028, Sprint G1 and Stage W3 completion)

> Reconciliation note (2026-09-25): Product status updated following the multi-game merge (Classic, Tetris, Match-3), audio overhaul (4 AAC-LC masters, unstealable SFX channels), Stage W3 readiness (C5 `game_id: 'classic'`, D1 signing fail-fast, C6 factory-scoped services, F4 RU l10n, C7 test DI & 8 integration widget tests), and Sprint G1 gameplay integration (Fair Bag deal fairness, anti-chunking deal generator, ScreenWakeManager). The false claim regarding an automated `cold_kill_recovery_test` has been corrected: cold recovery is verified manually on device, automated unit tests for it remain pending.

## Overall
- Product maturity: `pre-release / external testing ready`
- Playable scope: `Classic`, `Tetris`, `Match-3`, `Daily Challenge`
- Release readiness: `ready for Stage W3 external APK testing`
- Active phase: `Stage W3 code & build wiring complete (W3.1-W3.5); W3.6-W3.8 (APK tester cohort distribution and telemetry gathering) will be executed during external testing. Stage W4 (Documentation Hygiene) in progress` (per [02_HISTORICAL_PLANS_SUMMARY.md](02_HISTORICAL_PLANS_SUMMARY.md) and [docs/archive/roadmap/15_POST_DEC0024_PLAN_2026-09-21.md](../archive/roadmap/15_POST_DEC0024_PLAN_2026-09-21.md))
- Strategy: finish reliability/data/quality foundations before open public distribution
- Monetization model: fully ad-free; in v1.0 monetization surfaces are completely gated / hidden per DEC-0026 / DEC-0028
- Production data plane: Firebase-first (Crashlytics, Analytics + BigQuery, Remote Config, Cloud Messaging, Auth, Cloud Functions)
- `services/config-api` and `services/analytics-pipeline` — deferred; superseded by Firebase
- Quality status: `flutter analyze --no-pub` reports 0 issues; `flutter test --no-pub` passes **465/465 tests**

## Implemented In Code
- **Multi-Game Core**:
  - Classic loop with Fair Bag deal fairness (DEC-0024/DEC-0028), anti-chunking deal generator, combo ladder, score popups, shockwave VFX.
  - Tetris loop with 7-bag, SRS rotation/kicks, ghost piece, hold/next preview, T-spin, combo, and dedicated session snapshot persistence.
  - Match-3 loop with 8x8 gem grid, cascade resolver, move limits, shuffle, and session store.
  - Daily Challenge mode (deterministic seed milestone run).
- **Audio System (DEC-0024 / DEC-0026 / DEC-0028)**:
  - 4 mastered AAC-LC CBR 144k stereo music tracks (`music_menu`, `music_classic`, `music_tetris`, `music_match3`).
  - Seamless equal-power crossfading (`MusicPlaylistManager`) across screen navigation with audio focus and ducking.
  - Dedicated unstealable audio channels for line clears and game over in `FlameGameSfxPlayer` and `DebugGameSfxPlayer`.
- **Display & Device**:
  - Native screen wake management (`FLAG_KEEP_SCREEN_ON` via `ScreenWakeManager` platform channel) during active gameplay.
  - Haptics integration with device feedback throttling.
- **Progression & Persistence**:
  - Daily goals, streak progression, best score persistence via Hive (`HivePlayerProgressRepository` + `HiveGameSessionRepository`).
  - FTUE/onboarding flow with persisted completion state.
- **Telemetry & Observability**:
  - Analytics events (`game_session_start`, `game_start`, `line_clear`, `game_end`, `ops_*`) with strict schema validation and explicit `game_id` across all modes.
  - Firebase Crashlytics reporting via `FirebaseCrashReporter`.
- **Configuration & Architecture**:
  - Remote config client with bundled defaults, cached snapshots, rollback slot, and feature flag kill-switches (`GameModeAvailability`).
  - DI container (`di_container.dart`) with environment switching, factory-scoped services (`ABExperimentService`, `OnboardingFlowController`, `ProgressionSyncService` per DEC-0016), and release debug adapter guard (DEC-0007).
  - Test DI infrastructure (`apps/mobile/test/helpers/test_di.dart`) and 8 end-to-end integration widget tests in `apps/mobile/test/widget_test.dart` (C7).
- **Release & Security**:
  - Release signing fail-fast without debug fallback in `build.gradle` and CI workflow `android-release.yml` (D1).
  - RU-only localization for store controller strings via `StoreStrings` (F4).

## Simulated / Scaffolded
- `services/config-api` and `services/analytics-pipeline` contracts exist, deferred in favor of Firebase.
- Store monetization UI: gated and hidden in v1.0 builds per DEC-0026 / DEC-0028. `utility_tools_pass` excluded from catalog.

## Debug-Only
- `DebugAnalyticsTracker`
- `DebugAdService` (no-op; ad-free strategy makes this dev-only)
- `DebugIapStoreService`
- `InMemoryRemoteConfigRepository`
- `DebugGameSfxPlayer`

These are allowed only for `dev/debug` builds and rejected in release mode via `di_container.dart` (DEC-0007).

## Not Implemented Yet
- Dedicated ANR bridge + native symbol upload for Crashlytics.
- Google Play Billing v7 real sandbox activation and deployment (deferred to Stage C per DEC-0026).
- RuStore billing adapter (deferred per DEC-0012).
- Automated unit test suite for process cold-kill recovery (`cold_kill_recovery_test` is not written; cold restart is verified via physical device acceptance).
- Broad device-matrix QA (limited to owner Redmi device per DEC-0014).

## Acceptance Gates Before Any Publish Decision
- Persisted progress survives cold restart and corrupted cache recovery.
- Release builds send `game_session_start`, `game_start`, `game_end`, and `ops_*` via Firebase Analytics with correct `game_id`.
- Crashlytics receives real crash events from release builds.
- Store metadata matches shipped functionality.
- `flutter analyze --fatal-infos --fatal-warnings` green (0 issues) and `flutter test` green (all 465 tests passing).
- Early game-over rate <= 0.30 for Classic, runtime error session rate <= 0.02, `ops_alert_critical_count == 0`.
- No open P0/P1 bugs.

