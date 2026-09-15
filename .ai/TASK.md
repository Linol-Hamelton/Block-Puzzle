# Current Task

Status: In progress - stage A integration gaps reopened by independent audit

Owner: RuslanFomenko
Last update: 2026-09-15

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
- [ ] Release build proves DI resolves production adapters (DEC-0007).
- [x] Remote Config keys map and merge with defaults instead of replacing them.
- [ ] Real client progress passes Firestore rules; CI supplies Firebase config.
- [ ] Remote Config survives restart/offline and mode flags block navigation.

## Current state

Live plan: docs/roadmap/14_EXECUTION_PLAN_2026-09-14.md; plans 12/13 are history.
Production code for defines, bootstrap, package, RC mapping and Firebase is in
main. Live Remote Config has 57 parameters matching the tracked template.
Claude's eb47a89 records a Redmi profile run with production defines and
telemetry uploads; release DI, native fatal/ANR and purchases remain unproven.
Codex audit: docs/audit/05_CLAUDE_EXECUTION_AUDIT_2026-09-15.md, cutoff eb47a89.
Emulator reproduces rejection of the real progress envelope; existing rules
tests use a different schema. CI does not provision google-services.json.
Mode flags have no consumers; RC restart/offline and deterministic game restore
remain open. AOT loses optional environment overrides. See audit F1-F7.
Strict analyze and 214 Flutter tests pass; these do not certify device/store
acceptance. Media tools run, but the full DEC-0019 acceptance set is incomplete.
README/status/PLAN still need reconciliation with code and approved decisions.

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
5. Audit disagreement: Claude's journal closes A6, but the actual Dart payload
   is denied by repo rules. Keep A6 open until the client/rules contract passes.

---

Keep this file under 80 lines. It describes the current task only, never the
project history.
