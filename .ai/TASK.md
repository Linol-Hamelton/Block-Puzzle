# Current Task

Status: Completed - VFX Flame Juice Research: Stage 0 audit and Stage 1 easing presets spike
Owner: RuslanFomenko
Last update: 2026-09-25

---

## Objective

Formalize the Flame VFX research plan into docs/design/02_VFX_JUICE_RESEARCH_PLAN.md
and .ai/PLAN.md. Complete Stage 0 animation points audit, and implement Stage 1
spikes (EasingPresets class, ScorePopComponent overshoot and layout optimization).

## Problem & Acceptance

- [x] Save research plan to docs/design/02_VFX_JUICE_RESEARCH_PLAN.md
- [x] Update .ai/PLAN.md with VFX roadmap (under 200 lines limit)
- [x] S0.1: Document animation points map across Classic, Tetris, Match-3
- [x] S1.1-S1.2: Implement EasingPresets in apps/mobile/lib/ui/effects/easing_presets.dart
- [x] S1.3: Refactor ScorePopComponent in block_puzzle_game.dart (cached TextPainter + easeOutBack/overshoot)
- [x] Add unit tests for EasingPresets and ScorePopComponent
- [x] validate-protocol.ps1, flutter analyze, and flutter test pass cleanly
- [x] Record and verify protocol handoff evidence

## Current state

- Stage 0 and Stage 1 spikes complete: EasingPresets implemented, ScorePopComponent optimized with zero per-frame allocations and easeOutBack pop.
- flutter analyze 0 issues, flutter test 465/465 PASS (+8 new tests), validate-protocol 0 warnings.

## Roles

- implementer: antigravity
- owner: RuslanFomenko

## Open questions

None.

---

Keep this file under 80 lines. It describes the current task only.
