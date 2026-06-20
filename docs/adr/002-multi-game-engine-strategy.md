# ADR-002 — Multi-game engine abstraction strategy (Tetris / Match-3)

Status: Proposed (2026-06-19)
Related: [architecture/04_MULTI_GAME_ENGINE_PLAN.md](../architecture/04_MULTI_GAME_ENGINE_PLAN.md), [audit §10](../audit/01_FULL_PROJECT_AUDIT_2026-06-19.md)

## Context
The Mode Hub roadmap promises Classic, Tetris, and Match-3. The engine has no multi-game abstraction (no `GameId`/`GameEngine`/`GameRegistry`), a square-only `BoardState`, a binary `BoardCell` (no color/kind — Match-3 cannot be modeled), and no model-level tick loop or rotation (Tetris core absent). The shared foundation is the meta-layer (DI, analytics, persistence, monetization, theme, audio, Flame shell), not the gameplay primitives.

## Decision (to ratify)
Adopt **Strategy A — a unified `GameEngine` seam** if building both games: introduce `GameId`/`GameDefinition`/`GameRegistry` + a Mode Hub (Phase 0), then extract a `GameEngine` interface and generalize `BoardState`→`RectBoardState` and `BoardCell`→typed `GridCell` (Phase 1), gating Phase 1 on "Classic plays byte-for-byte identically". Add Match-3 (Phase 2) and Tetris (Phase 3) as engines. Choose **Strategy B — parallel per-game controllers** only to validate a single game fast, accepting infra duplication.

## Consequences
- Program cost ~9–13 engineer-weeks (Strategy A, both games) vs ~7–10 + ~8–12 independently (Strategy B).
- Phase 1 is the highest-risk step (touches every domain consumer); mitigated by compatibility shims (`size`/`isOccupied`/`occupiedCells`) and the identical-Classic gate.
- No code path may hard-construct `BlockPuzzleGame` after Phase 0, or it bypasses the registry.

## Implementation note (2026-06-19)
Tetris work has started **Strategy-B style for the domain**: a self-contained
`lib/domain/tetris/` module (board, SRS rotation, 7-bag, scoring, engine) that
does not touch Classic's `BoardState`/`GameLoopController` — this de-risks the
genre logic independently of the shared-seam refactor. The domain core +
unit tests are in; presentation/input/wiring remain. See
[05_TETRIS_IMPLEMENTATION_PLAN.md](../architecture/05_TETRIS_IMPLEMENTATION_PLAN.md).
If/when Match-3 is also greenlit, fold both engines under the Strategy-A
`GameRegistry`/`GameEngine` seam rather than maintaining two parallel stacks.
