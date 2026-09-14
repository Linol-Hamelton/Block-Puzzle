# Worklog Archive

Cold storage for worklog entries moved out of `.ai/worklog/`. Never trimmed,
never summarized away.

Entries keep the exact text they had when they were current. Add the agent name
and the date they were archived; change nothing else.

Information needed to understand an accepted decision belongs in
`.ai/DECISIONS.md`, not here. This file is history, not authority.

---

## Archive

No archived entries yet.

---

## Archiving procedure

Two different limits, two different operations.

A journal passed its 150-line limit:

1. Cut its oldest entries.
2. Paste them below, under a heading naming the journal and the archive date.
3. Leave the newest entries in place, enough to explain the current state.

`.ai/worklog/` passed 30 files:

1. Pick the oldest journals whose sessions have ended. A journal is closed when
   no lock names it and its newest entry carries evidence or a Next step that
   the following session already acted on.
2. Move each closed journal here whole, heading and all, then delete the file.
   Moving entries out of a journal never reduces the file count; only this does.
3. Ownership does not block this. The rule against writing to another session's
   journal protects a live session; a closed journal is archived by whoever
   holds the shared-document lock.

Never rewrite an entry while moving it.

## Archived 2026-09-14 from .ai/worklog/claude-bd0bce05de513f55.md

Moved to keep that journal under its 150-line limit. Text unchanged.

## 2026-09-14 - Development plan, then review of the Codex plan

Agent: Claude / claude-bd0bce05de513f55.

Action: Read TASK/PLAN/DECISIONS, both journals, and the roadmap, audit, ADR,
architecture and operations docs; verified state against code and Git instead of
docs. Ran flutter analyze and flutter test on the product tree. Wrote
docs/roadmap/12_DEVELOPMENT_PLAN_2026-09-14.md. The shared lock was held by
codex-d56f1c2c371b35a6 at the time, so .ai/PLAN.md and .ai/TASK.md were left
untouched until that session released it. Then cross-checked the Codex
deliverable (plan 13) against code and recorded the review in plan 12 section 9,
TASK.md open questions 7-11, and .ai/PLAN.md.

Result: analyze exit 0; flutter test exit 0, 196 tests passed, on 357300c.
Validator passed with 2 warnings before edits. Verified: origin/main is at
50e008a (PR #42/#43 merged), so plan 12's first-draft claim that main had not
moved since April was wrong and is corrected; db8d05e (review batch 2) is still
not an ancestor of HEAD. Confirmed four findings of plan 13 that plan 12 and the
June audit both missed - neither workflow passes --dart-define, so
AppConfig defaults to APP_ENV=dev/APP_FLAVOR=debug and a released build would
resolve DebugIapStoreService, DebugAnalyticsTracker, InMemoryRemoteConfigRepository
and NoopCrashReporter; applicationId com.blockpuzzle.game vs server default
com.luminablocks.app; TetrisEngine.toSnapshot omits the 7-bag; no firestore.rules
in the repo. Also confirmed Match3Engine.moveLimit defaults to 30, so plan 12's
endless framing of DEC-0005 was wrong and is fixed. Product code unchanged; no
commits, no pushes.

Next step: owner consolidates plans 12 and 13 into one document and records
DEC-0001..DEC-0005; then start with the release-adapter fix and branch
convergence before any new feature work.

Open: the line-ending-only diff this session's test run left in
data/dashboards/internal_playtest_run_001_metrics.json was restored by the owner
after the permission classifier blocked git checkout here. Nothing verified on
device, in Play Console or in the cloud; both plans remain static plus unit-test
evidence only. DECISIONS.md is still empty.

Evidence:
- anchor: 357300ccddff7f7c62bda8639dc966419442453a, uncommitted changes present
- digest: sha256:3fdb222bd3e8d33198beef1c76d8b12595b48dd552fb487e26c4a6214c5a61f9 over 431 tracked and untracked files
- digest format: 4
- recorded: 2026-09-14T13:34:33.959Z by claude-bd0bce05de513f55
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-14 from .ai/worklog/claude-bd0bce05de513f55.md (2)

Moved to keep that journal under its 150-line limit. Text unchanged.

## 2026-09-14 - Owner decisions recorded; executor recommendation

Agent: Claude / claude-bd0bce05de513f55.

Action: Presented every open question from both plans to the owner, split into
self-contained proposals and genuine forks. The owner ruled on all ten forks.
Took the shared lock and wrote the rulings into .ai/DECISIONS.md as DEC-0001 to
DEC-0008, each with context, reasoning, rejected alternatives and consequences.
Updated .ai/TASK.md: resolved questions moved out, six left open. Added a note
to section 6 of plan 12 that the draft DEC numbering there is superseded by the
decision log.

Result: validate-protocol.ps1 passes with 0 warnings and reports 8 decision
blocks; the earlier "no numbered decisions recorded yet" warning is gone.
TASK.md is 70 lines, DECISIONS.md 303, both LF and BOM-free. Two forks were not
ruled on and stay open: closed-test composition, and the early-gameover
definition for move-limited Match-3. The first-store question was deferred by
the owner, with Google Play kept as the estimation baseline. The 17
self-contained proposals are still unapproved. No product code changed.

Next step: owner approves or amends the self-contained block, then merges plans
12 and 13 into one document with stages A and B as the spine. First code work
is DEC-0007 (release adapters) together with the branch convergence.

Open: Executor assignment. The owner asked which of the two agents has more
capability for the work. Honest answer: neither of us can see the other quota,
model or cost, so the owner is better placed to weigh that; what is observable
from this session is the split below.
- Codex read cross-file runtime contracts better. It found the missing
  --dart-define chain across workflow, AppConfig and di_container, the
  client/server package mismatch, the unserialized 7-bag and the absent
  Firestore rules. That is exactly the skill stage A needs: release wiring,
  billing, config.
- Claude ran the toolchain directly with no sandbox escalation (analyze, 196
  tests, validator), and caught the A6/B1 dependency cycle and the premature
  Completed task status. That suits the seam and registry work, test writing,
  and document reconciliation.
- Recommendation: Codex executes stage A, Claude executes stage S0 convergence,
  the registry/flag seam and the test and document work; each reviews the other
  before handoff. Both mistakes found this session were found by the reviewer,
  not the author, so a single-executor arrangement loses the mechanism that
  caught them.

Evidence:
- anchor: 357300ccddff7f7c62bda8639dc966419442453a, uncommitted changes present
- digest: sha256:1c834d8f09d19ee5c95e379f1753148c6d21c3728cf85d0bc3717b6b52af95b0 over 431 tracked and untracked files
- digest format: 4
- recorded: 2026-09-14T13:53:53.915Z by claude-bd0bce05de513f55
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
