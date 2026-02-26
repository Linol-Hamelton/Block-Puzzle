# Sprint 9 Backlog: Mode Hub + First New Mode (`Tetris Rush`)

## 1. Sprint Goal
Deliver the first multi-mode step using current engine reuse:
1. add `Mode Hub` on Home with new mode buttons,
2. launch first new playable mode: `Tetris Rush`,
3. prepare technical foundation for next mode: `Match-3` (scaffold only, no full gameplay yet).

## 2. Product Direction Alignment
This sprint follows the strategy:
1. maximum reuse of existing app shell, analytics, remote config, and release pipeline,
2. minimum risk to current classic mode quality,
3. incremental expansion of mode portfolio from one codebase.

## 3. Functional Scope
1. Home screen mode buttons:
   - `Classic` (existing),
   - `Tetris Rush` (new),
   - `Match-3` (`Coming soon` state).
2. Mode registry and routing contracts.
3. `Tetris Rush` core loop v1:
   - falling pieces,
   - left/right movement,
   - rotation,
   - line clear,
   - game over,
   - restart.
4. Mode-specific analytics and rollout flags.
5. Match-3 module scaffold interfaces for Sprint 10+.

## 4. Non-Goals (Sprint 9)
1. Full Match-3 gameplay implementation.
2. Multiplayer/leaderboards.
3. Parallel launch of second new playable mode.

## 5. Day-by-Day Delivery
| Day | Focus | Output |
|---|---|---|
| D1 | Mode Hub contracts + UX layout freeze | `mode_hub_spec_v1` |
| D2 | Mode flags + telemetry schema | `mode_flags_and_events_v1` |
| D3 | Tetris domain core + controller integration | `tetris_domain_v1` |
| D4 | Tetris rendering + controls + tests | `tetris_controls_v1` |
| D5 | Tetris scoring/speed + end-of-round UX | `tetris_round_flow_v1` |
| D6 | Home integration + Match-3 scaffold contracts | `mode_hub_integration_v1` |
| D7 | Observability + mode switching QA | `mode_observability_v1` |
| D8 | Balance window #1 + bugfix polish | `tetris_balance_patch_01` |
| D9 | RC build + rollout step plan | `mode_rc1_rollout_plan` |
| D10 | Cohort window #2 + expand/iterate decision | `sprint9_readout_v1` |

## 6. Hard Gates
1. No open P0/P1 defects in `Tetris Rush`.
2. Mode switch does not break `Classic` behavior.
3. Required mode events validate by schema.
4. Feature flag rollback works without app patch.

## 7. Definition of Done
1. `Mode Hub` is present in production build under config control.
2. `Tetris Rush` is playable end-to-end with tested restart/game-over flow.
3. `Match-3` technical scaffold exists and is ready for Sprint 10 implementation.
4. Mode rollout decision is made from at least 2 cohort windows.
