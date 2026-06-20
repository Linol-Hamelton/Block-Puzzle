# Documentation Changelog

Append one dated line per status-changing documentation merge. The canonical status of the product is [roadmap/05_IMPLEMENTATION_STATUS.md](roadmap/05_IMPLEMENTATION_STATUS.md); this log records *when and why* it (and other load-bearing docs) changed. Supersedes the archived `archive/root/DOCS_CHANGELOG_2026-02-26.md`.

## 2026-06-20 (Game-feel follow-ups — shared particles in Classic + Settings)
- **Classic adopts `BurstField`:** line-clear particles in Classic now use the shared `ui/effects/BurstField` (a `_BurstLayer` Flame component); the old `CellBurstComponent` was removed. Both games now share one particle system.
- **Settings screen:** new `features/settings/presentation/settings_screen.dart` with Music / Sound effects / Haptics toggles (music via `MusicController`; sound/haptics persisted to `PlayerSettings` and applied to the live singletons). Reachable from a gear icon on the home screen. The in-game AppBar music toggle was removed in favor of Settings.
- `flutter analyze` clean; 162 tests pass.

## 2026-06-20 (Game-feel P3 — music & shared juice)
- **Background music:** `MusicController` (looping via `FlameAudio.bgm`) with a persisted enable flag; a placeholder seamless ambient loop (`assets/audio/music_loop.wav`, project-generated). Wired into Classic and Tetris screens with lifecycle pause/resume and an AppBar music on/off toggle. (Settings-screen integration is a follow-up; final music is a content debt.)
- **Shared juice module:** extracted the Tetris particle system into a reusable `lib/ui/effects/burst_field.dart` (`BurstField`); Tetris now uses it. Classic adoption is a follow-up toward the unified engine.
- Remaining content debt: final sound design (replace placeholder SFX/music) — needs real audio assets.
- `flutter analyze` clean; 162 tests pass.

## 2026-06-20 (Game-feel P2 — depth & tension)
- **Perfect Clear (All-Clear):** Tetris emits a `perfectClear` bonus event (1000×level) with a "PERFECT CLEAR!" fanfare; Classic adds a +100 all-clear bonus (`ScoreInput.allClear` → `BasicScoreService`) and a board-flash + shake + "PERFECT!" fanfare via `MoveProcessingResult.isAllClear`.
- **Tetris danger signal:** a pulsing red glow at the top of the board when the stack nears the ceiling; **lock-flash** briefly whitens just-locked cells.
- **Tetris continue/revive:** once per run, a "Continue" button on the game-over card clears the top rows and resumes (`reviveClearTop`), with a `revive_applied` analytics event.
- `flutter analyze` clean; 162 tests pass (+3: perfect clear, revive, all-clear bonus).

## 2026-06-20 (Game-feel P1 — clear action)
- **Tetris clear action:** engine now runs a delayed clearing phase (highlight → dissolve → collapse, ~120 ms) exposed via `isClearing`/`clearingRows`/`clearProgress`; the Flame view spawns a colored particle burst on the cleared cells and brightens them as they dissolve.
- **Tetris combo:** engine emits `combo` events; controller plays the combo SFX and shows a "COMBO xN" pulse.
- **Input SFX:** added generated `rotate.wav` / `hold.wav` / `hard_drop.wav` and `playRotate`/`playHold`/`playHardDrop` on `GameSfxPlayer`; Tetris rotate/hold/hard-drop are now audible.
- **Floating "+N" score popups** on clears in both games (Tetris via `lineClear.detail`; Classic via a `ScorePopComponent` at the cleared-cell centroid).
- `flutter analyze` clean; 159 tests pass (+1 clearing-phase test). Engine also gained `combo`/`perfectClear` events + `board.fullRows()`/`isEmpty` for P2.

## 2026-06-20 (Tetris — polish)
- Visual juice in the Flame view: line-clear board flash (intensity by lines), screen shake on Tetris/T-spin/hard-drop, and text pulses ("TETRIS!", "T-SPIN SINGLE/DOUBLE/TRIPLE", "LEVEL n") via a new `controller.onVisualEvent` hook and a `TetrisEventType.tSpin` engine event. HUD now shows 5 next pieces and dims Hold while it is locked for the drop. Snappier DAS/ARR (130/45 ms). `flutter analyze` clean; 158 tests pass.

## 2026-06-20 (Tetris — completion)
- Finished Tetris feature work: **T-spin** detection + scoring (`actionScore`, 3-corner rule), **resume persistence + best score** via `TetrisSessionStore` (engine `toSnapshot`/`restore`, saved on pause / restored on launch / cleared on game over, DI-registered), and **analytics** (`game_start`/`game_end`/`line_clear` with `game_id:'tetris'`; schema extended). HUD shows best score. `flutter analyze` clean; **158 tests pass** (+5). Remaining: on-device feel tuning, Mode Hub seam, daily seed, VFX/perf — see [architecture/05_TETRIS_IMPLEMENTATION_PLAN.md](architecture/05_TETRIS_IMPLEMENTATION_PLAN.md).

## 2026-06-19 (Verification)
- Toolchain installed (Flutter 3.44.2 / Dart 3.12.2). `flutter analyze` → **No issues found**; `flutter test` → **all 153 tests passed** (including the Tetris domain suites and the analytics-decorator test). Resolved 4 analyzer lints (3 from this work + 1 pre-existing unnecessary import in `block_puzzle_game.dart`). Still pending: billing deploy + Play sandbox before transacting; Tetris DI/persistence/analytics wiring + on-device feel tuning.

## 2026-06-19 (Tetris — presentation + input)
- Added `features/tetris/`: `TetrisController` (ChangeNotifier + SFX/haptics event routing), `TetrisFlameGame` (board/ghost/active render + frame clock), and `TetrisScreen` (HUD with hold/next previews, on-screen controls with auto-repeat, lifecycle, game-over overlay). Added a "Play Tetris" button to the home screen. Plan doc updated. Still unverified (no toolchain); DI/persistence/analytics wiring + feel tuning remain.

## 2026-06-19 (Tetris — domain core started)
- New pure-domain module `apps/mobile/lib/domain/tetris/` (tetromino + SRS rotation/kicks, W×H board with gravity collapse, falling piece, 7-bag, scoring, engine) + 5 unit-test files. Plan + remaining work: [architecture/05_TETRIS_IMPLEMENTATION_PLAN.md](architecture/05_TETRIS_IMPLEMENTATION_PLAN.md). ADR-002 updated with the implementation note. Presentation/input/wiring still to come; SRS tables to be confirmed by running the tests on a real toolchain.

## 2026-06-19 (P0 remediation)
- **P0-3 fixed:** `BlockPuzzleGame` DI factory now passes the required `haptics` arg (`di_container.dart`).
- **P0-2 fixed:** added `ValidatedAnalyticsTracker` decorator; production now validates the analytics schema before sending to Firebase ([adr/001](adr/001-analytics-tracker-choice.md)). Added unit test.
- **P0-1 implemented (pending deploy/verify):** real Google Play billing — `GooglePlayBillingService` + `CloudFunctionsReceiptValidator` + `verifyPurchase` Cloud Function; added `in_app_purchase`/`cloud_functions` deps; wired production billing in DI ([adr/003](adr/003-billing-receipt-validation.md)).
- ADR-001 → Accepted/implemented; ADR-003 → Accepted/implemented (pending deploy + Play sandbox). `05_IMPLEMENTATION_STATUS.md`, `README.md`, and `lib/infra/billing/README.md` updated to match.
- Caveat: flutter/dart not available in the authoring environment — all P0 code changes are unverified by `analyze`/`test` and must be re-checked on a real toolchain.

## 2026-06-19
- Full project audit published: [audit/01_FULL_PROJECT_AUDIT_2026-06-19.md](audit/01_FULL_PROJECT_AUDIT_2026-06-19.md). Release readiness assessed at ~38% (NO-GO). Method: static analysis only (flutter/dart toolchain not available).
- Multi-game engine plan + Tetris & Match-3 feasibility published: [architecture/04_MULTI_GAME_ENGINE_PLAN.md](architecture/04_MULTI_GAME_ENGINE_PLAN.md).
- `05_IMPLEMENTATION_STATUS.md` reconciled with code: Hive persistence and Firebase Crashlytics moved to **Implemented In Code**; "release-safe analytics queue" reworded as orphaned; billing clarified as scaffold-only; Daily Challenge (Classic variant) recorded as shipped and distinguished from the standalone Phase 4 mode.
- `README.md` "What Is Implemented / Simulated" synced to the above.
- Added explicit "STATUS" banners to `apps/mobile/lib/infra/billing/README.md` and `apps/mobile/lib/l10n/README.md` so specs are not mistaken for shipped code.
- Introduced documentation governance: this changelog + the ADR register under [adr/](adr/).
