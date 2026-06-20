# Tetris — Implementation Plan & Status

Date started: 2026-06-19
Strategy: per [ADR-002](../adr/002-multi-game-engine-strategy.md) and the [Multi-Game Engine Plan](04_MULTI_GAME_ENGINE_PLAN.md), Tetris is built as a **separate, pure domain module** (`lib/domain/tetris/`) that does **not** touch Classic's `BoardState`/`GameLoopController`. The model layer was implemented first because it is the highest-correctness-risk, fully toolchain-independent part. Presentation (Flame) and input UI wire onto it next.

> **Verification (2026-06-19):** `flutter analyze` reports no issues and all 153 tests pass (Flutter 3.44.2 / Dart 3.12.2), including the Tetris domain suites — so the SRS kick tables, board collapse, 7-bag, scoring, and engine behave as specified. What remains is **on-device play-testing** (input feel, gravity cadence) and the wiring items below.

## Done (domain core + tests)

| File | Responsibility |
|---|---|
| `lib/domain/tetris/tetromino.dart` | 7 tetrominoes, 4 SRS rotation states each, bounding-box geometry (`TCell`, `Tetromino`, `TetrominoType`). |
| `lib/domain/tetris/srs_rotation.dart` | SRS wall-kick tables (JLSTZ + I), canonical y-up, converted to board y-down at one point (`kicksFor`). |
| `lib/domain/tetris/falling_piece.dart` | Immutable active-piece state (type, rotation, origin) + absolute-cell projection + JSON. |
| `lib/domain/tetris/tetris_board.dart` | W×H typed grid, collision, lock, full-row clear **with gravity collapse**, drop distance (ghost), JSON. |
| `lib/domain/tetris/seven_bag_randomizer.dart` | Seedable 7-bag (deterministic for daily challenge), `peek` for the next-queue. |
| `lib/domain/tetris/tetris_scoring.dart` | Guideline scoring (single/double/triple/Tetris), soft/hard drop, combo, back-to-back, level + gravity curve. |
| `lib/domain/tetris/tetris_engine.dart` | Rules engine: spawn, `applyInput` (move/rotate/soft/hard/hold), `tick` (gravity + lock-delay with reset cap), top/block-out, next-queue, ghost, drainable events. |

Tests (the safety net — run on a real toolchain):
- `test/unit/domain/tetris/srs_rotation_test.dart` — kick-table sign conversion + transition coverage.
- `test/unit/domain/tetris/tetris_board_test.dart` — collision, single/multi clear, gravity collapse, drop distance, JSON.
- `test/unit/domain/tetris/seven_bag_randomizer_test.dart` — bag fairness, determinism, peek.
- `test/unit/domain/tetris/tetris_scoring_test.dart` — scores, level/gravity curve.
- `test/unit/domain/tetris/tetris_engine_test.dart` — spawn/move/rotate/hard-drop/ghost/tick smoke.

## Done (presentation + input, 2026-06-19)

| File | Responsibility |
|---|---|
| `lib/features/tetris/application/tetris_controller.dart` | `ChangeNotifier` owning the engine; drives `tick`, routes `TetrisEvent`s to SFX (`GameSfxPlayer`) + haptics (`HapticsController`), exposes HUD state, `restart()`. Notifies only on HUD-relevant change (not per gravity frame). |
| `lib/features/tetris/presentation/tetris_game.dart` | Flame view: renders board/locked cells/ghost/active in screen space, per-`TetrominoType` neon palette; forwards each frame's `dt` to `controller.tick`. |
| `lib/features/tetris/presentation/tetris_screen.dart` | Screen: `GameWidget` in a 10:20 box, HUD (score/lines/level + hold + next-3 previews via a mini painter), on-screen controls (rotate L/R, hold, move L/R + soft drop with **press-and-hold auto-repeat**, hard drop), lifecycle pause/resume, game-over overlay with restart. |
| `lib/ui/screens/home_screen.dart` | "Play Tetris" button routes to `TetrisScreen`. |

## Done (completion, 2026-06-20)

- **T-spin detection + scoring**: 3-corner rule with front/back full-vs-mini classification (`_detectTSpin`); `TetrisScoring.actionScore` covers T-spin / Tetris / back-to-back / combo.
- **Persistence**: engine `toSnapshot`/`restore` + `TetrisSessionStore` (SharedPreferences) for best score and resume-after-kill — saved on app pause, restored on launch, cleared on game over; registered in DI.
- **Analytics**: `game_start` / `game_end` / `line_clear` emitted with `game_id: 'tetris'`, mode, level, lines, duration; new optional fields registered in `AnalyticsSchemaValidator` so `ValidatedAnalyticsTracker` does not quarantine them.
- **HUD**: best score shown live and on the game-over card.
- Verified: `flutter analyze` clean, 158 tests pass (incl. T-spin scoring + snapshot round-trip).

## Remaining work (ordered)

1. **On-device play-test**: input feel, gravity cadence, rendering, and the resume flow on a real device/emulator.
2. **Mode Hub seam**: fold the Tetris controller/engine into the `GameId`/`GameRegistry` abstraction (Multi-Game plan Phase 0/1); migrate the SharedPreferences snapshot into the unified per-game envelope.
3. **Feel / parity tuning**: DAS/ARR repeat timing, lock-delay reset feel, spawn buffer; the wall-kick mini→full T-spin upgrade nuance.
4. **Daily-challenge**: wire the deterministic seed (engine + 7-bag already accept one) to the daily pattern; Tetris daily leaderboard later.
5. **Polish**: line-clear / lock flash VFX, next-queue depth, perf validation (60fps at high gravity on low-end Android).

## Notes / open decisions
- Spawn currently places pieces at `originY = 0` (top of the visible field). If top-out feels too eager, add a 1–2 row hidden spawn buffer.
- Lock-delay reset is capped at 15 (guideline "infinity with cap"); gravity-induced landings currently consume a reset — fine for now, revisit during feel tuning.
- 180° rotation uses no wall kick (plain SRS). Add a 180° kick table only if play-testing calls for it.
