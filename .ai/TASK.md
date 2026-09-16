# Current Task

Status: In progress - DEC-0022 closed (items 1-4); Stage A release DI verified

Owner: RuslanFomenko
Last update: 2026-09-16

---

## Objective

Execute DEC-0022: home order, Tetris controls, Match-3 depth, and media set.
Stage A release proof verified on device. Next: live Firestore sync & Stage C.

## Problem

Match-3 lacked bonus gems/rounds; release DI & media set were unverified.

## Constraints

DEC-0015 authorizes stages 0/A; DEC-0022 authorizes gameplay round and
supersedes DEC-0005/0006. Decisions DEC-0001..DEC-0022 outrank any plan. No
commits/pushes unless owner asks. Reviewers write only in their own journal.

## Acceptance criteria

- [x] Audit findings F1-F7 closed with tests; plans 12/13 superseded.
- [x] DEC-0022 items 1-3: home order, Tetris controls, Match-3 depth.
- [x] Visual pass: one material and one field across all three games.
- [x] Release build proves DI resolves production adapters (DEC-0007).
- [x] DEC-0022 item 4: media acceptance set per DEC-0019.
- [ ] Real client progress passes Firestore rules in a live run.

## Current state

Live plan: docs/roadmap/14_EXECUTION_PLAN_2026-09-14.md; plans 12/13 are history.
DEC-0022 items 1-4 complete. Media acceptance set (SDXL neon cosmetic set,
Stable Audio 3 Medium music loop, 3 SFX, machine manifest & docs) integrated.
StoreScreen renders live preview of skin_pack_neon asset.
DI adapter resolution proven by unit tests (di_container_test.dart) and verified
live on physical device (2209116AG / Android 13); 324 Flutter tests pass.
Next: Real client progress passes live Firestore rules & Stage C prep.

## Active agent

- Agent: Gemini (Stage A release DI proof, gameplay polish & media set)
- Started: 2026-09-16

## Open questions

1. Google Play Console access for stage C, and Blaze billing for Cloud Functions.
2. Progress-merge rules when linking anonymous account to Google Sign-In (DEC-0018).
3. Formulas, denominators and minimum sample size for KPI sets in DEC-0004.
4. Round tuning confirmation on physical device: 20 moves, +6/round, 1200/+400.

---

Keep this file under 80 lines. It describes the current task only.

