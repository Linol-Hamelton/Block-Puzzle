# Technical Requirements Specification

Last updated: 2026-04-12. Aligned with the Firebase-first decision, ad-free monetization, and the 5-phase roadmap in [../roadmap/01_ROADMAP_AND_SPRINTS.md](../roadmap/01_ROADMAP_AND_SPRINTS.md).

## 1. Scope
Functional and non-functional requirements for Lumina Blocks — Flutter + Flame 1.18 client, Android-only (Google Play + RuStore), ad-free monetization, Firebase-first backend.

## 2. Phase Scope (5-Phase Roadmap)
1. **Phase 0 — Gardening & Alignment (3 days):** docs sync, skeleton modules, analyzer baseline.
2. **Phase 1 — Foundation & Stability (20 days):** Firebase wiring, Crashlytics + ANR, Hive persistence, lifecycle state machine, real billing, release pipeline.
3. **Phase 2 — Soft Launch & Cohort Loop (15 days):** closed test, BigQuery/Looker Studio dashboards, 2 cohort windows, Go/No-Go.
4. **Phase 3 — Engagement Expansion (25 days):** meta-progression, soft currency, missions, wheel, cosmetics + Season Pass, achievements, events, juice pack, l10n, accessibility, FCM.
5. **Phase 4 — Mode Hub & New Modes (30 days):** Mode Hub, Time Rush, Puzzle Pack, Daily Challenge, Firestore-backed leaderboards.
6. **Phase 5 — TOP-1 Tuning (continuous):** Firebase A/B experiments, weekly rollout reviews, seasonal content, ASO, community.

## 3. Functional Requirements

### FR-CORE (Phase 0 — shipped)
- 8x8 board, rack of 3 pieces, valid full-placement rule, auto-clear full lines, score/combo, game-over on no valid placements, one-tap restart.

### FR-LIFECYCLE (Phase 1 W1)
- Explicit `GameLoopPhase { idle, playing, paused, gameOver }` state machine.
- `WidgetsBindingObserver` subscription saves a full snapshot on `paused`/`inactive`.
- Cold-kill of the process mid-round restores the snapshot on next launch.
- PausedOverlay with Resume / Restart / Quit.

### FR-UX
- Minimal-friction session entry, clear placement preview, stable drag threshold, drag-lift offset on touch devices, 48dp+ touch targets, persistent HUD (score/best/level/combo/moves).
- Phase 1 W1 adds a full-screen ErrorBoundary fallback.
- Phase 3 3E adds interactive onboarding, locales, accessibility (text scaling, color-blind palettes, haptics toggle).

### FR-PROGRESSION (Phase 3 3A)
- Hive-backed `PlayerProgressState` with schema versioning and self-heal.
- Best score, daily goals, streak (current).
- Phase 3 adds player level, XP, soft currency wallet (Shards, Crystals), Mastery points, cosmetic selection.

### FR-MONETIZATION (Ad-Free)
- Runtime is ad-free. No rewarded/interstitial/banner placements.
- Utility tools (hint/undo), revive, and wheel spins are funded by soft currency, Premium Pass, or IAP only.
- Phase 1 W3 ships a real `in_app_purchase` Google Play Billing v7 integration with server-side receipt validation via Cloud Functions.
- Phase 3 3C ships the cosmetics shop (skins, backgrounds, VFX, SFX packs) and the Season Pass.
- Rationale: [../operations/08_AD_FREE_MODE_STRATEGY.md](../operations/08_AD_FREE_MODE_STRATEGY.md).

### FR-DATA
- Typed analytics contracts with `schema_version`, local queue, retry, and schema validation client-side.
- Phase 1 W3 wires `FirebaseAnalyticsTracker` as production transport; BigQuery export feeds Looker Studio dashboards.
- Observability events: `ops_session_snapshot`, `ops_alert_triggered`, `ops_error`, plus Phase 1 additions `ops_storage_recovered`, `ops_rack_fallback`, `ops_audio_degraded`, `ops_config_invalid`, `ops_error_boundary`.

### FR-OPS
- Phase 1 W3 wires `FirebaseRemoteConfigRepository` as production config source.
- Kill switches: `feature_missions_enabled`, `feature_events_enabled`, `feature_leaderboard_enabled`, `feature_juice_enabled`, `force_update_min_version`.
- Versioned config with bounded TTL (12h prod / 30s stage) and strict schema validation.
- Phase 1 W4 adds a device-matrix smoke pack and release pipeline dry-run through Internal Testing.

### FR-BACKEND (Firebase)
- Firebase Core, Crashlytics (+ NDK symbols), Analytics (+ BigQuery export), Remote Config, Authentication (Anonymous Auth for UID binding), Cloud Messaging (max 1 push/day), Performance Monitoring, Cloud Functions (`verifyPurchase`, `alert_router`, `mission_roll`), Firestore (`entitlements/{uid}`, leaderboards).
- Deferred: `services/config-api` ([../../services/config-api/README.md](../../services/config-api/README.md)) and `services/analytics-pipeline` ([../../services/analytics-pipeline/README.md](../../services/analytics-pipeline/README.md)) are retained as historical contracts only.

## 4. Non-Functional Requirements (TOP-1 Targets)

### Performance
- 60 FPS target; p95 ≥ 50 FPS on mid-range Android (Redmi 9/10, Samsung A23/A35, Honor X6).
- Cold-start p90 ≤ 2.5s on low-mid Android.
- Memory: rss growth ≤ 40MB over a 60-minute stability session on mid device.
- Input latency: drag-to-place visible feedback under 32ms.

### Reliability
- Crash-free sessions ≥ 99.7% from Phase 2 onwards.
- ANR rate ≤ 0.20%.
- Core gameplay is fully offline-capable.
- Persisted board snapshot survives `SIGKILL` of the process.

### Security
- No secrets in the repository.
- Minimal personal data footprint; anonymous UID via Firebase Auth.
- Signed release pipeline (Google Play App Signing + upload key).
- Hive encryption key stored in `flutter_secure_storage`.
- IAP receipts validated server-side via Cloud Functions (`verifyPurchase`) against Google Play Developer API.

### Maintainability
- Domain layer is SDK-independent (no Flutter/Firebase imports).
- Contracts stay stable across Firebase vs in-memory implementations (`AnalyticsTracker`, `RemoteConfigRepository`, `IapStoreService`, `CrashReporter`).
- Unit tests for core rules (`MoveValidator`, `LineClearService`, `ScoreService`, `PieceGenerationService`).
- `flutter analyze` escalates to `--fatal-infos --fatal-warnings` in Phase 1 W2 after the unawaited-futures sweep.

## 5. Acceptance Criteria

### Phase 1 Exit Gates
1. Crashlytics receives real events from a release build within 10 minutes of install.
2. `flutter analyze --fatal-infos --fatal-warnings` green.
3. `flutter test` green, including `cold_kill_recovery_test`.
4. Real billing sandbox: purchase `skin_aurora` + restore after reinstall both succeed.
5. Persisted board snapshot survives process kill-9 during gameplay.
6. `ops_alert_critical_count == 0` over a 24-hour internal testing window.

### Phase 2 Exit Gates (per [../operations/16_ROLLOUT_GATES_CHECKLIST_OPS_SIGNALS.md](../operations/16_ROLLOUT_GATES_CHECKLIST_OPS_SIGNALS.md))
1. Two consecutive 72h cohort windows with accepted rollout decisions.
2. Crash-free sessions ≥ 99.5% on real users.
3. Early game-over rate ≤ 0.30.
4. Runtime error session rate ≤ 0.02.
5. Zero open P0/P1 bugs.

### Phase 3 Exit Gates
1. Remote Config kill switches for missions/events/leaderboard/juice verified end-to-end.
2. All launch locales (ru, en, tr, id, pt-br, es, de, fr) pass a smoke screen.
3. Accessibility pass on TalkBack.
4. Post-release cohort windows show session length ≥ 7 minutes and D1 ≥ 45%.

### TOP-1 KPI Targets (Phase 5 continuous)
- Crash-free sessions ≥ 99.7%.
- ANR rate ≤ 0.20%.
- D1 ≥ 48%, D7 ≥ 20%, D30 ≥ 10%.
- Average session ≥ 9 minutes.
- ARPDAU (IAP only) ≥ $0.08 (interim) → $0.10 (target).
- Early game-over rate ≤ 0.25.
- Store rating ≥ 4.6 with ≥ 1000 reviews.

## 6. Out of Scope
- iOS client (Android-only product decision).
- Rewarded/interstitial/banner ads (ad-free, permanent).
- PvP/multiplayer.
- Full narrative campaign.
- UGC level editor.
- Custom `services/config-api` and `services/analytics-pipeline` (deferred in favor of Firebase).
