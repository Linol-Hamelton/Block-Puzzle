# Multi-Game Engine Plan — Tetris & Match-3 on the Lumina Blocks foundation

Date: 2026-06-19
Status: proposal / feasibility study (not yet committed). Companion to the full audit: [../audit/01_FULL_PROJECT_AUDIT_2026-06-19.md](../audit/01_FULL_PROJECT_AUDIT_2026-06-19.md).
Decision needed: adopt this as ADR-002 before any new-mode work (see [../adr/](../adr/)).

---

## 0. The honest framing

The main menu should become a **Mode Hub** offering **Classic**, **Tetris**, and **Match-3** on one Flutter + Flame foundation. The grounding constraint, verified against the source:

> The shared foundation is the **meta-layer** (DI, analytics, remote config, persistence, monetization, theme, audio/haptics, the Flame harness shell), **not the gameplay primitives.** `BoardState`, `BoardCell`, `Piece`, `Move`, `MoveValidator`, `LineClearService`, and `ScoreService` are shaped exclusively around *drag-a-polyomino-onto-a-square-grid-and-clear-full-lines*. Tetris and Match-3 need fundamentally different runtime semantics those types cannot express.

So Tetris and Match-3 are **two new games that share Classic's plumbing and shell**, not configurations of it. The abstraction's job is to let them *plug in* without forking the meta-layer.

### Why the current engine cannot host them (verified)

| Concern | Current type | Blocks |
|---|---|---|
| Board geometry | `BoardState.size` (single int); `isInBounds` uses `x<size && y<size` (`board_state.dart:7,29-31`) | Square only. Tetris = 10×20; Match-3 = arbitrary W×H. |
| Cell | `BoardCell{x,y}`, occupancy = `Set<BoardCell>` membership (`board_state.dart:59-89`) | No color/kind; no value grid. **Match-3 is impossible to model.** |
| Piece | `Piece{id, List<PieceCellOffset>}` (`piece.dart`) | No orientation/rotation. |
| Move | `Move{piece, anchorX, anchorY}` (`move.dart`) | Anchor-only; no swap, no directional input. |
| Rules | inlined in `GameLoopController.processMove` (`game_loop_controller.dart:362-576`) | No engine seam; only "mode" is the string `'mode':'classic'` (`:335`) + `isDailyChallenge` (reseeds RNG only). |
| Clear | `LineClearService` → `clearedRows/clearedColumns` (`basic_line_clear_service.dart:11-32`) | Row/column-full only; no gravity collapse, no connected-group cascade. |
| Score | `ScoreInput{clearedLines}` (`score_service.dart:3-9`) | No match size / drop height / spin / cascade depth. |
| Loop | `FlameGame.update(dt)` lerps a palette only (`block_puzzle_game.dart:220-231`) | No tick/gravity/lock-delay anywhere. |
| Input | `RackPieceComponent` + `DragCallbacks` (`block_puzzle_game.dart:1206-1458`) | Drag-rack only; no tap/swap/directional. |
| Renderer | layout/anchor math hardcodes `/8` and `*8` (`block_puzzle_game.dart:440,578-579,649`) | Non-8 / non-square boards mis-anchor (BoardComponent.render itself correctly divides by `_boardState.size` at `:1016`, so the renderer is *inconsistent*, which is worse than uniformly hardcoded). |

The **one real asset** is the meta-layer plus the fact that `MoveValidator`/`LineClearService`/`ScoreService`/`PieceGenerationService`/`DifficultyTuner` are already DI-registered interfaces. Their *shapes* become per-engine strategy slots.

---

## 1. Two strategies (pick one as ADR-002)

| | **A. Unified `GameEngine` seam** (recommended if building both) | **B. Parallel per-game controllers** |
|---|---|---|
| Idea | One `GameSessionController` delegates the rules step to a `GameEngine<TState>`; generalize the board once. | A `Match3Controller` and `TetrisController` sit beside `GameLoopController`, each with its own board type; Classic untouched. |
| Pro | No meta-layer duplication; new genres reuse everything; cleanest long-term. | Lower blast radius; Classic's `BoardState` never touched; fastest path to *one* extra game. |
| Con | Highest upfront cost (the board generalization touches every domain consumer). | Infrastructure (snapshot envelope, mode router, analytics keying) gets duplicated; diverges over time. |
| Cost | **~9–13 eng-weeks for Mode Hub + both games** (phased). | **~7–10 (Tetris) + ~8–12 (Match-3)** independently. |

**Recommendation:** if the goal is *both* games, choose **A** — the per-game costs amortize against a shared Phase 0+1. If the goal is to validate *one* game fast, choose **B** for that game, then refactor toward A. Either way, **do Phase 0 (Mode Hub + `GameId`) first** — it is cheap, low-risk, and unblocks the home-screen UX independently.

---

## 2. Target architecture (Strategy A)

```
                         ┌──────────────────────────┐
  Mode Hub (home)  ────► │  GameRegistry (DI)        │  Map<GameId, GameDefinition + factory>
                         └────────────┬─────────────┘
                                      │ resolve(GameId)
                                      ▼
        ┌───────────────────────────────────────────────────────────┐
        │            GameSessionController  (was GameLoopController)  │  shared lifecycle:
        │  init · snapshot · analytics · ads · revive/undo/hint hooks │  session_start/_end,
        │            delegates the RULES STEP to ──────────┐          │  ad guardrails, IAP
        └──────────────────────────────────────────────────┼─────────┘
                                                            ▼
                             ┌──────────────── GameEngine<TState> ────────────────┐
                             │  start(seed) · applyInput(intent) · tick(dt)?       │
                             │  serialize/deserialize · isTerminal · events stream │
                             └───────┬──────────────┬───────────────┬─────────────┘
                                     ▼              ▼               ▼
                              ClassicEngine    Match3Engine     TetrisEngine
                              (8×8, line clear, (W×H typed tiles, (10×20, OrientedPiece
                               drag-rack)        swap+cascade)    +SRS, gravity clock)
                                     │              │               │
                                     ▼              ▼               ▼
                              per-game Flame GameRenderer (reads RectBoardState + GridCell kind/color)
                                     └────────── shared chrome: NebulaBackground, LuminaPalette, HUD
```

### Core new abstractions
- **`GameId { classic, tetris, match3 }`** — replaces the hardcoded `'mode':'classic'` string and the overloaded `isDailyChallenge` bool.
- **`GameDefinition`** — static descriptor (id, displayName, blurb, icon, `GameInputModel`, `GameClockSpec`, board geometry, `supportsDailyChallenge`) consumed by the Mode Hub + registry.
- **`GameRegistry`** — DI-resolved `Map<GameId, GameDefinition + factory>`; the only place that knows concrete engine/renderer types. Replaces `sl.registerFactory<BlockPuzzleGame>` + the manual `new BlockPuzzleGame(...)` in `game_loop_screen.dart`.
- **`GameEngine<TState>`** — `start` / `applyInput` / `tick` / `isTerminal` / `serialize`+`deserialize` / `events` stream. The `processMove` body becomes `ClassicEngine.applyInput`.
- **`GameInputModel { dragRack, tapCell, swapAdjacent, directionalControls }`** + a sealed `GameInput` (PlacePiece / SwapCells / Directional / HardDrop).
- **`GameClockSpec { none, gravity(baseInterval, lockDelay) }`** — `GameSessionController` runs a deterministic fixed-timestep accumulator calling `engine.tick(state, dt)` for time-driven games; Classic & Match-3 declare `none` (no-op), preserving today's event-driven behavior exactly.
- **`RectBoardState{width,height, List<GridCell?> grid}`** + **`GridCell{x,y,kind,colorId}`** — rectangular geometry + per-cell typed value. Classic is the `width==height==8, colorId==0` special case. Keep `size`/`isOccupied`/`occupiedCells` shims during migration so Classic code compiles unchanged.
- **`ScoreContext`** (generalized `ScoreInput`) — carries `clearedLines, matchSize, cascadeDepth, dropRows, spinType, comboChain`; `BasicScoreService` ignores the new fields, so Classic scoring is byte-identical.
- **`MultiGameSnapshot` envelope** — `{gameId, schemaVersion, engineState}` keyed per game so a paused Tetris and a paused Classic coexist; legacy `active_game_snapshot` reads as `gameId=classic`.

### Reused verbatim (the meta-layer)
DI container, analytics pipeline (+ a `game_id` param), remote config (per-game key prefixes), progression/economy/cosmetics persistence (cosmetics + high scores generalized to `Map<GameId,…>`; economy stays global), monetization (ad guardrail + IAP), haptics + audio, theme/`NebulaBackground`/`GameLayoutProfile`, observability/crash reporting, the Flame harness shell and its juice components (`CellBurst`/`LineClearFlash`/`ComboPulse`/camera shake), and the glass-cell primitive `_drawGlassBlockCell(canvas, rect, tint, preset, opacity)` (already takes a tint → colored gems are a data change, not a renderer rewrite).

---

## 3. Phased migration (Classic never breaks)

| Phase | Scope | Effort | Risk |
|---|---|---:|---|
| **0 — Scaffold & Mode Hub** | `GameId`/`GameDefinition`/`GameRegistry` (Classic-only); convert `home_screen.dart` to a hub driven by `registry.all`; route through the registry; add `game_id` to analytics + per-game snapshot key with legacy fallback. **No gameplay touched.** | ~1.5–2 wk | Low |
| **1 — Engine seam + board generalization** | `GameEngine`, `RectBoardState` (+ shims), typed `GridCell`, `ScoreContext`, `EngineEvent`; extract `processMove` + revive/hint into `ClassicEngine`; de-hardcode the renderer `8`s. **Acceptance gate: Classic plays byte-for-byte identically.** | ~3–4 wk | **Highest** — touches every domain consumer; mitigated by shims + a strict "Classic identical" gate |
| **2 — Match-3** | Reuses `RectBoardState`, typed `GridCell.colorId`, `swapAdjacent` input, `GameClockSpec.none`. New: `Match3Engine`, match/cascade resolver, Match-3 score service, tap/swap renderer. Registering its `GameDefinition` makes it appear in the hub. | ~2.5–3 wk | Medium |
| **3 — Tetris** | Reuses `RectBoardState` (10×20). New: `OrientedPiece`+`RotationSystem` (SRS/wall-kicks), `GameClockSpec.gravity` driving `tick` (gravity + lock-delay, pause/resume-safe), `directionalControls` with DAS/ARR, full-row-clear-then-collapse, Tetris score service. The clock is the only net-new runtime subsystem. | ~2.5–3.5 wk | Medium-high |

---

## 4. Tetris Mode — feasibility & design

**Feasible, medium, ~7–10 eng-weeks standalone (or ~2.5–3.5 wk as Phase 3 on the shared seam).** Recommended seam: a `TetrisBoard` (W×H value grid) — **do not widen the square `BoardState`** (~21 `size`/`occupiedCells` reads in `GameLoopController`; 40 across 6 files) if going Strategy B.

### Required new mechanics

| Mechanic | New work |
|---|---|
| 10×20 board (+hidden spawn rows) | `TetrisBoard` width/height + per-cell value grid (`Uint8List`) storing mino type/color |
| Gravity tick, frame-independent | accumulator in `update(dt)`; gravity interval = f(level); 20G handling; **no per-frame allocations** (mutable active-phase grid, don't rebuild the immutable board each tick) |
| SRS rotation + wall kicks | per-tetromino orientation tables + JLSTZ/I kick tables; rotate-with-kick op |
| Lock delay | lock timer with move/rotate reset + reset cap; lock-out detection |
| Soft / hard drop | soft = faster gravity; hard = drop-to-ghost + immediate lock + points |
| 7-bag randomizer | `SevenBagRandomizer`, seeded via the existing `setSeed` for daily determinism |
| Ghost piece | project active piece to landing row; render reduced alpha |
| Hold queue + next-queue | one-slot hold (once per drop) + render next N |
| Row-only clears + collapse | new `LineClearService` variant: detect full rows, collapse rows above downward |
| Level/speed curve + T-spin | lines-based level + gravity curve; 3-corner T-spin (mini/full) at lock; B2B + combo |

### Reusable as-is
`Piece`/`PieceCellOffset` (one `Piece` per (type, rotation)), DI, analytics pipeline, persistence plumbing, haptics (light→move, selection→rotate, medium→lock, heavy→tetris/hard-drop), audio (extend with rotate/drop/lock cues), theme/palette/visual-preset/nebula + the Flame harness shell + the screen host's lifecycle pause/resume, remote config + monetization guardrails (feature flag + rewarded "continue").

### Top risks
1. **SRS / wall-kick correctness** — transcribe kick tables from spec; unit-test every (piece, from→to) kick; T-spin depends on it.
2. **Phone input feel** — no existing tap/repeat path; build an on-screen button cluster (most reliable) + optional gesture layer; DAS/ARR + hard-drop ergonomics need real-device iteration. **Top product risk.**
3. **Tick-loop perf & frame independence** — accumulator-driven gravity; mutable active-phase grid; smooth at 20G on low-end Android.
4. **Architectural blast radius** — keep Tetris behind the seam; do not widen the square `BoardState` (Strategy B).
5. **Renderer de-hardcoding** — parameterize the literal 8-column math for a 10×20 portrait board; add ghost/next/hold chrome.
6. **Daily-challenge determinism** — the 7-bag must consume the existing daily seed deterministically for leaderboard parity.

---

## 5. Match-3 Mode ("Три в ряд") — feasibility & design

**Feasible, medium, ~8–12 eng-weeks standalone (10 central), or ~2.5–3 wk as Phase 2 on the shared seam.** Match-3 shares almost none of the block-puzzle's *rules* but reuses most of its *infrastructure*. The single largest blocker is that `BoardCell` has **no color/type field** — Match-3 cannot be modeled on binary occupancy.

### Required new mechanics

| Mechanic | Why the current engine can't express it |
|---|---|
| Fully-filled grid of typed/colored tiles | `BoardCell` is pure x/y binary occupancy, no color (`board_state.dart:59-89`). **Largest blocker.** |
| Swap two adjacent cells, revert on no-match | Only input is rack drag-and-drop; no tap/swap path. |
| Match-detect 3+ H/V | `BasicLineClearService` detects full rows/columns only (`basic_line_clear_service.dart:11-32`). |
| Cascade: gravity collapse + refill from top | No tick/gravity loop anywhere; `update(dt)` only lerps a palette. |
| Special tiles (line-blast/bomb from 4, color-bomb from 5) | No representation; needs spawn-rule + detonation-resolution with chained side effects. |
| Move-limited / score-target objectives + shuffle-on-no-moves | Classic loop only knows "no valid move ⇒ game over"; no objective abstraction, no shuffle. |

### New domain contracts
```dart
class TileGrid { final int width, height; final List<Tile?> cells; /* value grid, not a Set */ }
class Tile { final TileColor color; final SpecialKind kind; } // kind: none|lineH|lineV|bomb|colorBomb

abstract interface class SwapValidator    { /* adjacency + must create >=1 match */ }
abstract interface class MatchDetector    { /* connected runs of 3+ H/V; flags 4/5 special spawns */ }
abstract interface class CascadeResolver  { /* clear -> collapse -> refill -> re-detect; tracks cascade depth */ }
abstract interface class TileSpawner      { /* weighted spawn; no pre-existing match; guaranteed solvable; seeded */ }
abstract interface class SpecialTileResolver { /* 4->line, 5->colorBomb spawn + special×special / special×swap matrix */ }
abstract interface class Match3Objective  { /* move-limited / score-target + NoMovesDetector + shuffle */ }
```
`ScoreInput` must widen (today `clearedLines` only) to carry match size, cascade depth, and special-tile bonuses.

### Reusable as-is
DI, analytics (the `'mode':'classic'` string becomes a real enum value), persistence (`GameSnapshot` gains an additive typed-grid payload), haptics + audio (`playLineClear`/`playCombo` map onto match/cascade), theme + juice components, and the **glass-cell primitive** (already takes a tint → colored gems with no signature change). Caveat: generalize the layout literals to W×H (`block_puzzle_game.dart:440,578-579,649`).

### Top risks
1. **Match/cascade correctness** — collapse + refill + chained re-detection is a from-scratch deterministic state machine; table-driven unit tests before any animation work.
2. **Special-tile combinatorics** — the special×special / special×swap detonation matrix is an O(n²) surface with chained effects; classic source of match-3 clone bugs (double-clears, missed propagation, score desync).
3. **Randomness fairness / solvable boards** — initial fill has no pre-existing match yet always offers a legal move; shuffle must terminate; deterministic seeding for daily.
4. **Monetization fit (ad-free)** — move-limited Match-3 maps to rewarded "extra moves" + boosters, but the level-map progression that usually drives match-3 retention/revenue does not exist here and is out of scope at this estimate; endless-only risks a weak monetization surface.
5. **BoardState refactor blast radius** — 6 files read `.size`/`.occupiedCells`; keep Classic on a frozen legacy board (or shim) while Match-3 uses `TileGrid`, then converge.
6. **Input/animation gating** — swap-revert, pops, and falls must lock input mid-resolution; the discrete `processMove` model has no "animating, input-locked" phase — a new presentation state machine is required (common race-condition source).

---

## 6. Cross-cutting prerequisites (apply to both games)

- **Fix the engine-extensibility blockers from the audit first** (or in Phase 1): generalize `BoardState`→`RectBoardState` and `BoardCell`→typed `GridCell`; add a model-level tick capability; de-hardcode the renderer `8`s. These are the verified hard blockers (audit dimension 8, score 22/100).
- **Snapshot envelope + per-game keys** so paused games coexist; migrate the legacy key as `classic`.
- **Analytics:** add `game_id` to every event; coordinate genre-specific fields (`match_size`, `cascade_depth`, `drop_rows`, `t_spin`) with `analytics_schema_validator.dart` or events get dropped.
- **Daily-challenge determinism** for both new games via the existing `setSeed`.
- **Do not** leave any code path that hard-constructs `BlockPuzzleGame` — it bypasses the registry and silently locks the app back to Classic.

---

## 7. Bottom line

Adding Tetris and Match-3 is a sound product direction and the clean meta-layer makes it *worth* doing on this foundation rather than a new project. But it must be scoped honestly: **the shared engine saves the meta-layer, not the genre logic.** Budget the full program (Mode Hub + board generalization + both games) at **~9–13 engineer-weeks**, sequence it so Classic never regresses, and gate Phase 1 on "Classic plays byte-for-byte identically." Adopt this plan as ADR-002 before starting.
