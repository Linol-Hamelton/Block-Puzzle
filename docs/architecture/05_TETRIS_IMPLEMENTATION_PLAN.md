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

## Done (presentation + input, 2026-06-19)

| File | Responsibility |
|---|---|
| `lib/features/tetris/application/tetris_controller.dart` | `ChangeNotifier` owning the engine; drives `tick`, routes `TetrisEvent`s to SFX (`GameSfxPlayer`) + haptics (`HapticsController`), exposes HUD state, `restart()`. Notifies only on HUD-relevant change (not per gravity frame). |
| `lib/features/tetris/presentation/tetris_game.dart` | Flame view: renders board/locked cells/ghost/active in screen space, per-`TetrominoType` neon palette; forwards each frame's `dt` to `controller.tick`. |
| `lib/features/tetris/presentation/tetris_screen.dart` | Screen: `GameWidget` in a 10:20 box, HUD (score/lines/level + hold + next-3 previews via a mini painter), on-screen controls (rotate L/R, hold, move L/R + soft drop with **press-and-hold auto-repeat**, hard drop), lifecycle pause/resume, game-over overlay with restart. |
| `lib/ui/screens/home_screen.dart` | "Play Tetris" button routes to `TetrisScreen`. |

## Remaining work (ordered)

1. **Verify on a real toolchain**: `flutter pub get` / `analyze` / `test`, then run the app and play-test feel on a device (the renderer/input were authored without a compiler).
2. **Persistence**: a `TetrisGameSnapshot` (engine serialize/deserialize) behind the existing `GameSessionRepository` pattern, per-game Hive key so a paused Tetris and Classic coexist (Multi-Game plan §8).
3. **Analytics**: emit `game_start`/`game_end`/etc. with `game_id: 'tetris'` + Tetris params (level, lines, tetris/t-spin counts); register new fields in `AnalyticsSchemaValidator` or `ValidatedAnalyticsTracker` will quarantine them.
4. **DI / Mode Hub**: register the Tetris graph in `di_container.dart` (currently the screen builds its own controller from `sl<GameSfxPlayer>()`/`sl<HapticsController>()`); fold into the `GameId`/`GameRegistry` seam when Phase 0 of the Multi-Game plan lands.
5. **Feel / parity tuning**: DAS/ARR repeat timing, lock-delay reset feel, spawn buffer, level-curve, and **T-spin detection + scoring**.
6. **Daily-challenge**: wire the deterministic seed (the engine + 7-bag already accept one) to the existing daily pattern; add a Tetris daily leaderboard later.
7. **Polish**: line-clear flash / lock flash VFX, next-queue depth, perf validation (60fps at high gravity on Redmi 9/10).

## Notes / open decisions
- Spawn currently places pieces at `originY = 0` (top of the visible field). If top-out feels too eager, add a 1–2 row hidden spawn buffer.
- Lock-delay reset is capped at 15 (guideline "infinity with cap"); gravity-induced landings currently consume a reset — fine for now, revisit during feel tuning.
- 180° rotation uses no wall kick (plain SRS). Add a 180° kick table only if play-testing calls for it.
