# Implementation Status (Actual)

Last updated: 2026-02-26

## Sprint 1
- Status: `done`
- Notes:
  - Flutter+Flame baseline
  - domain contracts and DI foundation
  - app bootstrap and initial telemetry wiring

## Sprint 2
- Status: `done`
- Notes:
  - playable core loop (place/clear/score/game-over/restart)
  - domain use-cases and unit tests

## Sprint 3
- Status: `done`
- Notes:
  - visual feedback baseline + SFX hook points
  - onboarding v1 and remote config fallback
  - first balance controls for piece generation

## Sprint 4
- Status: `partially_done (ad-free strategy)`
- Done:
  - telemetry schemas and validation
  - QA smoke pack baseline
- Deferred by strategy:
  - production ad mediation/integration

## Sprint 5
- Status: `partially_done`
- Done:
  - AB foundation (`ab.bucket`, exposure tracking)
  - dashboard MVP contract + export tooling
- Remaining:
  - backend ingestion integration for non-playtest sources

## Sprint 6
- Status: `done`
- Done:
  - daily goals + streak
  - utility tools economy (hint/undo via credits + entitlement)
  - UX/balance AB wave #1 (`ab.difficulty_variant`, `ab.ux_variant`)

## Sprint 7
- Status: `done`
- Done:
  - segmentation and offer targeting v1
  - end-of-round UX + optional share flow
  - observability and alerting upgrade (`ops_*` events)

## Sprint 8
- Status: `in_progress`
- Done:
  - soft-launch iteration #2 operational loop scripts
  - rollout gate evaluator and thresholds contract
  - rollout checklist based on gameplay + `ops_*` signals
  - Android release workflow and publishing playbooks
- Remaining:
  - execute real cohort run windows and lock winner rollout policy
  - geo expansion packaging and execution

## Post-Sprint UX/Visual Passes (Implemented)
- Branding migration to `Lumina Blocks` (Android/Web/app naming + assets)
- Visual presets via remote config: `visual.blocks_preset = soft|crystal`
- Board/rack visual parity for queued pieces
- Drag UX improvements:
  - minimum touch targets 48dp+
  - mobile drag lift offset 50px above finger
  - drag threshold tuning for touch ergonomics
- Layout stabilization fixes:
  - board scale jitter fix on early moves
  - mobile frame/bounds consistency improvements

## Next Execution Queue
1. Sprint 8.1 stabilization backlog execution:
   [07_SPRINT8_1_STABILIZATION_BACKLOG.md](/d:/Block-Puzzle/docs/roadmap/07_SPRINT8_1_STABILIZATION_BACKLOG.md)
   Issue-ready:
   [09_SPRINT8_1_ISSUE_READY_DAILY.md](/d:/Block-Puzzle/docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md)
2. Sprint 9 first new mode (`Tetris Rush`) + Mode Hub execution:
   [08_SPRINT9_FIRST_NEW_MODE_BACKLOG.md](/d:/Block-Puzzle/docs/roadmap/08_SPRINT9_FIRST_NEW_MODE_BACKLOG.md)
   Issue-ready:
   [10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md](/d:/Block-Puzzle/docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md)
3. Stage-3 prep: additional game modes package (pre-production).
