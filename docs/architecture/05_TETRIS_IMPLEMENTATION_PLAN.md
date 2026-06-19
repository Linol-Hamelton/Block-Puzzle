# Tetris — Implementation Plan & Status

Date started: 2026-06-19
Strategy: per [ADR-002](../adr/002-multi-game-engine-strategy.md) and the [Multi-Game Engine Plan](04_MULTI_GAME_ENGINE_PLAN.md), Tetris is built as a **separate, pure domain module** (`lib/domain/tetris/`) that does **not** touch Classic's `BoardState`/`GameLoopController`. The model layer was implemented first because it is the highest-correctness-risk, fully toolchain-independent part. Presentation (Flame) and input UI wire onto it next.

> **Verification caveat:** authored without a Flutter/Dart toolchain available. The code is written to compile and the unit tests encode the correctness contracts, but **`flutter pub get` / `flutter analyze` / `flutter test` must be run on a real machine** to confirm. The SRS kick tables in particular are transcribed from spec and validated by `srs_rotation_test.dart` — run that first.

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

## Remaining work (ordered)

1. **Flame renderer** (`features/tetris/presentation/tetris_game.dart`): render the W×H board (portrait, taller-than-wide — do NOT reuse Classic's hardcoded `/8` layout math), the active piece, the **ghost**, the **next-queue** and **hold** panels, line-clear flash + lock flash. The glass-cell primitive `_drawGlassBlockCell` (currently private in `block_puzzle_game.dart`) should be extracted to a shared renderer util and tinted per `TetrominoType` color.
2. **Input UX** (top product risk): on-screen control cluster (left/right with DAS/ARR, soft drop, hard drop, rotate CW/CCW, hold) + optional gesture layer. Requires real-device tuning of repeat timing and thumb reach.
3. **Tick driver**: drive `engine.tick(dt)` from `FlameGame.update(dt)` with a frame-independent accumulator; pause/resume on the app-lifecycle path already used by `game_loop_screen.dart`. Avoid per-frame allocations (the board is copy-on-write; consider a mutable active-phase fast path if profiling demands).
4. **Controller + screen** (`features/tetris/application/tetris_controller.dart`, `presentation/tetris_screen.dart`): a `ChangeNotifier`/listenable that owns the engine, drains `TetrisEvent`s to SFX (`GameSfxPlayer`), haptics (`HapticsController`), and analytics, and exposes view state. Mirror `GameLoopScreen`'s lifecycle wiring.
5. **Persistence**: a `TetrisGameSnapshot` (engine state serialize/deserialize) behind the existing `GameSessionRepository` pattern, with a per-game Hive key so a paused Tetris and a paused Classic coexist (see Multi-Game plan §8).
6. **Analytics**: emit `game_start`/`game_end`/`move_made`-equivalent events with `game_id: 'tetris'` and Tetris-specific params (level, lines, tetris/t-spin counts); register the new fields in `AnalyticsSchemaValidator` or they will be quarantined by `ValidatedAnalyticsTracker`.
7. **Mode Hub entry**: add a "Tetris" card to the home screen routing to `TetrisScreen` (Phase 0 of the Multi-Game plan introduces `GameId`/`GameRegistry`; until then, a direct route mirroring the Classic/Daily buttons is acceptable).
8. **Polish / parity**: T-spin detection + scoring, DAS/ARR tuning, level-curve tuning, daily-challenge seed wiring (reuse the existing `setSeed` daily pattern), and device-matrix perf validation (60fps at high gravity on Redmi 9/10).

## Notes / open decisions
- Spawn currently places pieces at `originY = 0` (top of the visible field). If top-out feels too eager, add a 1–2 row hidden spawn buffer.
- Lock-delay reset is capped at 15 (guideline "infinity with cap"); gravity-induced landings currently consume a reset — fine for now, revisit during feel tuning.
- 180° rotation uses no wall kick (plain SRS). Add a 180° kick table only if play-testing calls for it.
