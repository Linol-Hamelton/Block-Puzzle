# Development Plan

Status: Approved in substance; stage 0 in progress.
Task: Converge documents and branches, then close production wiring.
Authors: Codex (plan 13) and Claude (plan 12), merged into one plan.
Date: 2026-09-14

A plan is a proposal. It becomes binding only as an approved `DEC-nnnn` block
in `.ai/DECISIONS.md`. Everything below is subordinate to DEC-0001..DEC-0021.

---

## Objective

Turn the existing Classic, Tetris and Match-3 work into a verifiable Android
release, then prioritize retention and cosmetic monetization on real cohort
evidence.

## Proposed approach

The live plan is
[14_EXECUTION_PLAN_2026-09-14.md](../docs/roadmap/14_EXECUTION_PLAN_2026-09-14.md).
It merges plan 12 (Claude) and plan 13 (Codex) per item 17 of DEC-0015; both
originals carry a superseded banner and remain as history. Findings R1-R12 from
[the Codex review](../docs/audit/04_CLAUDE_CHANGES_REVIEW_2026-09-14.md) are
folded in: R4 was closed by measurement, the rest were applied to the operations
documents and the publish checklist.

Stages: 0 consolidation, A production wiring, B reliability of the three modes,
C one commercial scenario end to end, D device QA and cohorts, with media as a
bounded parallel task under the DEC-0019 timebox.

## Alternatives considered

### Alternative 1

A universal GameEngine with one generalized board. Rejected by DEC-0001: two
engines already have working boards, so the migration costs the most and buys
nothing a release needs. The seam stays external - id, registry, snapshots.

### Alternative 2

Adding modes or the Pass/wheel/currency systems now. Deferred by DEC-0006 and
DEC-0008 until the reliability, data and commerce gates are green and content
capacity exists.

## Risks

- Branch convergence crosses `tetris_engine.dart`, edited on both lines.
- The first live Firebase will reveal a crash rate nobody has measured.
- Play sandbox usually exposes SKU and permission mismatches.
- Low-end performance is unmeasured; the gate is weakened by DEC-0014 and must
  be labelled as weakened wherever it is reported.
- Tooling expands to fill available time; DEC-0019 sets the media timebox.

## Implementation steps

1. Stage 0: one plan, R1-R11 applied, batch 2 converged, CI strictness, status
   docs reconciled, protocol files aligned.
2. Stage A: dart-defines and DI proof, package contract, guarded bootstrap with
   an independent logger, Remote Config key mapping and defaults merge, Firebase
   project, function runtime principal, Firestore rules, ANR, mode flags.
3. Stage B: RNG in snapshots, GameId registry without a shared board, scoped
   lifetimes, three process-death scenarios, real widget and integration tests,
   RU/EN localization.
4. Stage C: account linking, one non-consumable SKU, entitlement, preview and
   equip, restore after reinstall.
5. Stage D: device QA on one Redmi plus emulators, BigQuery export before the
   first window, two cohort windows with the KPI sets kept separate.

## Validation

On the current product tree:
- `flutter analyze --fatal-infos --fatal-warnings`: exit 0.
- `flutter test`: exit 0, 196 tests (195 when the simulation test is excluded).
- `validate-protocol.ps1`: exit 0, 21 decision blocks, 0 warnings.

Media environment verified by generation, not by import: SDXL produced a
1024x1024 image in 26.4s; Stable Audio 3 Medium produced 20s of music in 5.8s
and a 3s effect in 1.4s, peak 5.06 GB VRAM.

Device behaviour, store transactions, cloud deployment and live cohorts are not
verified and are not certified by any of the above.

## Review

- [x] Drafted
- [x] Reviewed by GPT/Codex
- [x] Reviewed by Claude
- [x] Disagreements resolved into DEC-0016..DEC-0021
- [x] Approved by owner
- [ ] Implemented
- [ ] Validated

Approved by: RuslanFomenko
Date: 2026-09-14
