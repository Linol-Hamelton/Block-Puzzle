# Current Task

Status: In progress - stage A0-A3 done; A4 needs the owner in the console

Owner: RuslanFomenko
Last update: 2026-09-14

---

## Objective

Execute the approved plan: converge documents and branches, then close the
production-wiring gaps so a release build behaves as a release build.

## Problem

Stale roadmaps, sibling-branch fixes and release/media readiness need evidence.

## Constraints

Stages 0 and A are authorized by DEC-0015. Decisions DEC-0001..DEC-0021 are
binding and outrank any plan. No commits, pushes or deployments unless the owner
asks. Reviewers write in their own journal, never another session's.

## Acceptance criteria

- [x] Plans 12 and 13 merged into one live plan; both marked superseded.
- [x] Review items R1, R5-R11 applied to docs 17/18/19 and the checklist.
- [x] Batch 2 (db8d05e) converged with the Match-3 line and merged to main.
- [x] Release build proves DI resolves production adapters (DEC-0007).
- [x] Remote Config keys map and merge with defaults instead of replacing them.

## Current state

Live plan: docs/roadmap/14_EXECUTION_PLAN_2026-09-14.md. Plans 12 and 13 carry a
superseded banner and stay as history. All planning forks are closed by
DEC-0001..DEC-0021; the owner ruled on the last of them on 2026-09-14 - scoped
lifetime, package string, Google Sign-In, minSdk 24, asset toolchain, large
screens, plus corrections superseding DEC-0009 and DEC-0013.
Codex review R1-R12 processed: R4 closed by measurement, the rest applied to
docs 17/18/19 and the publish checklist. A local-only launcher run_local.py
replaces the upstream Gradio one, which hardcodes share=True.
Media environment verified by generation: SDXL 1024x1024 in 26.4s; Stable Audio
3 Medium 20s of music in 5.8s at 5.06 GB peak VRAM. Run them one at a time -
together they exhaust system RAM, not VRAM.
No product code changed yet. Device, store and cloud gates remain open.

## Active agent

- Agent: Claude preparing media; Codex review completed (roles: DEC-0013)
- Started: 2026-09-14

## Open questions

Not decisions - actions and external dependencies:

1. Google Play Console access for whoever runs stage C, and a Blaze billing
   account before Cloud Functions can deploy.
2. Progress-merge rules when linking an anonymous account to Google Sign-In:
   what wins when local and cloud state disagree.
3. Formulas, denominators and minimum sample size for the KPI sets in DEC-0004.
4. Provenance for the model weights: checksums and a manifest for the
   acceptance set required by DEC-0019.

---

Keep this file under 80 lines. It describes the current task only, never the
project history.
