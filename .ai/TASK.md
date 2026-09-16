# Current Task

Status: In progress - DEC-0022 items 1-3 done plus a visual pass; item 4 open

Owner: RuslanFomenko
Last update: 2026-09-16

---

## Objective

Execute DEC-0022: home screen order, Tetris control ergonomics, Match-3 depth,
then media. Stage A release proof stays open behind it.

## Problem

Match-3 had no bonus gems, no rounds and a flat move limit; the audit's stage A
gaps (release DI, native fatal, purchases) are still unproven.

## Constraints

DEC-0015 authorizes stages 0 and A; DEC-0022 authorizes the gameplay round and
supersedes DEC-0005/0006. Decisions DEC-0001..DEC-0022 outrank any plan. No
commits, pushes or deployments unless the owner asks. Reviewers write in their
own journal, never another session's.

## Acceptance criteria

- [x] Audit findings F1-F7 closed with tests; plans 12/13 superseded.
- [x] DEC-0022 items 1-3: home order, Tetris controls, Match-3 depth.
- [x] Visual pass: one material and one field across all three games.
- [ ] DEC-0022 item 4: media acceptance set per DEC-0019.
- [ ] Release build proves DI resolves production adapters (DEC-0007).
- [ ] Real client progress passes Firestore rules in a live run.

## Current state

Live plan: docs/roadmap/14_EXECUTION_PLAN_2026-09-14.md; plans 12/13 are history.
Codex audit: docs/audit/05_CLAUDE_EXECUTION_AUDIT_2026-09-15.md, cutoff eb47a89.
Match-3 spawns bonus gems, resolves special-on-special swaps through one
detonation chain, and runs on rounds that pay out moves; 20 opening moves.
Classic's two crashes are fixed: Firebase-reserved event names threw out of
initialization, and a lazy iterable passed to removeAll threw on piece
placement. Event names are now validated against the reserved list.
All three games share one material (lib/ui/effects/glass_board.dart) and one
recessed field; the ambient background is dimmed and vignetted so the board is
the brightest thing on screen. Tetris line clears run 380ms (680ms for a Tetris)
in three staged beats; Match-3 cascades play out step by step, with grid for the
rules and displayGrid for the eye.
Strict analyze clean, 322 Flutter tests pass, up from 236.
Uncommitted: all of the above. Device-verified on a Redmi at each stage.
Frame timing is unmeasured - gfxinfo reports no frames for this renderer.
Not done: Tetris Next-queue art, HUD styling and the vertical space it eats,
Classic rack legibility.
Release DI, native fatal/ANR and any purchase remain unproven. Blaze still
blocks A5. README/status/PLAN still need reconciliation with code.

## Active agent

- Agent: Claude implementation; Codex independent audit (DEC-0017)
- Started: 2026-09-15

## Open questions

Not decisions - actions and external dependencies:

1. Google Play Console access for whoever runs stage C, and a Blaze billing
   account before Cloud Functions can deploy.
2. Progress-merge rules when linking an anonymous account to Google Sign-In:
   what wins when local and cloud state disagree.
3. Formulas, denominators and minimum sample size for the KPI sets in DEC-0004.
4. Provenance for the model weights: checksums and a manifest for the
   acceptance set required by DEC-0019.
5. Round tuning is a guess until it is played: 20 opening moves, +6 a round,
   targets 1200 then +400 a round. Needs a device session to confirm.

---

Keep this file under 80 lines. It describes the current task only, never the
project history.
