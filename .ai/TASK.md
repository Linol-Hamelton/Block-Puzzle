# Current Task

Status: Completed - VFX Calibration (Timings, SFX, Haptics) & Multi-Game Tech Debt Formalization
Owner: RuslanFomenko
Last update: 2026-09-25

---

## Objective

1. Formalize multi-game VFX adoption technical debt in `docs/design/02_VFX_JUICE_RESEARCH_PLAN.md` and `.ai/PLAN.md` (roadmap for Tetris and Match-3 adopting `VfxDirector`, camera shake, squash & shaders).
2. Calibrate animation timings, SFX trigger synchronization, and haptic feedback levels across piece drops, combo ladders, line clears, and celebratory milestones in Classic.
3. Verify test suite (515+ tests green) and strict static analysis (0 issues).

## Problem & Acceptance

- [x] Document technical debt matrix for Tetris and Match-3 in `docs/design/02_VFX_JUICE_RESEARCH_PLAN.md`
- [x] Update `.ai/PLAN.md` with multi-game scaling phase and acceptance criteria
- [x] Calibrate and synchronize audio/haptic/visual feedback in `BlockPuzzleGame` and `VfxDirector`
- [x] Add unit test verifying calibrated feedback dispatch
- [x] Verify `flutter analyze`, `flutter test`, and `validate-protocol.ps1` pass cleanly

## Current state

- All stages (0-6) completed for Classic, procedural tile atlas baked for Tetris/Match-3.
- Feedback calibration (timings, SFX, tiered haptics) complete with zero regressions.
- Multi-game adoption tech debt formalized and ready for owner review.

## Roles

- implementer: antigravity
- owner: RuslanFomenko

## Open questions

None.

---

Keep this file under 80 lines. It describes the current task only.
