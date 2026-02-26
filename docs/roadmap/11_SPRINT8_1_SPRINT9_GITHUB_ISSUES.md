# Sprint 8.1 + Sprint 9 GitHub Issue Pack

Format: direct copy into GitHub issue editor (`Title / Labels / Body`).

Autocreate script:
```powershell
.\scripts\create_sprint8_1_sprint9_issues.ps1 -Repo "<owner>/<repo>" -Sprint all
```

## Sprint 8.1

### Day 1

Issue `S81-001`
Title: `Sprint 8.1 D1: Stabilization scope freeze and P0/P1 triage`
Labels: `sprint-8.1,type:task,priority:p0,area:product,area:mobile`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 1 (`S81-001`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Stabilization scope document is approved.
- [ ] All known defects are triaged into P0/P1/P2.
- [ ] Owners and due dates are assigned.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

Issue `S81-002`
Title: `Sprint 8.1 D1: QA device matrix and regression checklist freeze`
Labels: `sprint-8.1,type:task,priority:p0,area:qa`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 1 (`S81-002`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Phone/tablet matrix is documented.
- [ ] Smoke and regression checklist is finalized.
- [ ] Entry/exit criteria for RC validation are published.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

### Day 2

Issue `S81-003`
Title: `Sprint 8.1 D2: Fix all open P0 crash and soft-lock defects`
Labels: `sprint-8.1,type:bug,priority:p0,area:mobile`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 2 (`S81-003`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] No open P0 crash/soft-lock tickets remain.
- [ ] Fixes are covered by reproducible test steps.
- [ ] No new P0 regressions introduced.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

Issue `S81-004`
Title: `Sprint 8.1 D2: Validate baseline gameplay and ops telemetry`
Labels: `sprint-8.1,type:task,priority:p0,area:data`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 2 (`S81-004`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Core gameplay events are present and valid.
- [ ] `ops_session_snapshot` and `ops_error` are observable in test runs.
- [ ] Validation report is attached.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

### Day 3

Issue `S81-005`
Title: `Sprint 8.1 D3: Fix P1 gameplay and UX blockers`
Labels: `sprint-8.1,type:bug,priority:p1,area:mobile`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 3 (`S81-005`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] All agreed P1 blockers are closed or explicitly deferred.
- [ ] Drag/hit-area visibility issues are verified fixed.
- [ ] QA confirms no blocker remains for RC path.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

Issue `S81-006`
Title: `Sprint 8.1 D3: Run focused regression for drag, placement, and touch targets`
Labels: `sprint-8.1,type:task,priority:p1,area:qa`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 3 (`S81-006`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Regression checklist pass/fail is documented.
- [ ] Mobile touch-target and drag offset checks pass on matrix devices.
- [ ] Found regressions are linked to tickets.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

### Day 4

Issue `S81-007`
Title: `Sprint 8.1 D4: Performance pass for frame stability and memory spikes`
Labels: `sprint-8.1,type:task,priority:p1,area:mobile`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 4 (`S81-007`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Profiling snapshot is attached.
- [ ] Top hotspots have fixes or mitigation notes.
- [ ] No new critical perf regressions vs baseline.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

Issue `S81-008`
Title: `Sprint 8.1 D4: QA low-mid Android perf benchmark verification`
Labels: `sprint-8.1,type:task,priority:p1,area:qa`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 4 (`S81-008`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] FPS/thermal observations are recorded on target devices.
- [ ] Results are compared with previous baseline.
- [ ] Go/No-Go perf note is provided.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

### Day 5

Issue `S81-009`
Title: `Sprint 8.1 D5: Telemetry edge-case hardening and schema validation`
Labels: `sprint-8.1,type:task,priority:p0,area:data,area:mobile`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 5 (`S81-009`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Edge cases (session end, runtime error, mode transitions) are validated.
- [ ] No schema-breaking payloads in validation run.
- [ ] Contract checks are reproducible.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

Issue `S81-010`
Title: `Sprint 8.1 D5: Collect real cohort window #1 metrics`
Labels: `sprint-8.1,type:task,priority:p0,area:product,area:data`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 5 (`S81-010`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Real window metrics JSON is collected and stored.
- [ ] Collection window boundaries are documented.
- [ ] Sample size meets minimum gate requirements.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

### Day 6

Issue `S81-011`
Title: `Sprint 8.1 D6: Apply tuned config from cohort window #1 with rollback guard`
Labels: `sprint-8.1,type:task,priority:p0,area:product,area:ops`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 6 (`S81-011`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Tuned config is generated and reviewed.
- [ ] Rollback config snapshot is saved.
- [ ] Change log for applied values is published.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

Issue `S81-012`
Title: `Sprint 8.1 D6: Execute rollout gates evaluation #1`
Labels: `sprint-8.1,type:task,priority:p0,area:data,area:ops`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 6 (`S81-012`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Gates report is generated from real metrics.
- [ ] Decision is one of `go_rollout_25_percent`, `go_rollout_10_percent_watchlist`, `hold_and_iterate`.
- [ ] Decision rationale is documented.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

### Day 7

Issue `S81-013`
Title: `Sprint 8.1 D7: Build RC1 and fix blockers from first gates cycle`
Labels: `sprint-8.1,type:task,priority:p0,area:mobile,area:release`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 7 (`S81-013`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] RC1 build artifacts are produced.
- [ ] Blockers from cycle #1 are resolved or documented.
- [ ] RC1 is installable on matrix devices.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

Issue `S81-014`
Title: `Sprint 8.1 D7: Smoke pass #2 across mobile DPI classes`
Labels: `sprint-8.1,type:task,priority:p1,area:qa`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 7 (`S81-014`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Smoke pass #2 results are attached.
- [ ] Visual and interaction checks pass on selected DPI classes.
- [ ] Failures are ticketed and triaged.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

### Day 8

Issue `S81-015`
Title: `Sprint 8.1 D8: Full regression and final QA sign-off draft`
Labels: `sprint-8.1,type:task,priority:p0,area:qa`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 8 (`S81-015`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Full regression is completed on agreed matrix.
- [ ] Open defects list contains no P0/P1 blockers.
- [ ] QA sign-off draft is published.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

Issue `S81-016`
Title: `Sprint 8.1 D8: Prepare Go/No-Go release decision pack`
Labels: `sprint-8.1,type:task,priority:p0,area:product,area:release`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 8 (`S81-016`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Decision pack includes quality, metrics, and ops sections.
- [ ] Risks and mitigations are explicitly listed.
- [ ] Stakeholder review meeting is scheduled.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

### Day 9

Issue `S81-017`
Title: `Sprint 8.1 D9: Final release artifact verification (APK/AAB)`
Labels: `sprint-8.1,type:task,priority:p0,area:release`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 9 (`S81-017`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Final APK/AAB pass installation and startup checks.
- [ ] Versioning and signing are validated.
- [ ] Artifact paths and checksums are documented.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

Issue `S81-018`
Title: `Sprint 8.1 D9: Store submission runbook execution`
Labels: `sprint-8.1,type:task,priority:p0,area:release,area:ops`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 9 (`S81-018`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Submission checklist is completed.
- [ ] Console submission status is captured.
- [ ] Any moderation blockers are tracked.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

### Day 10

Issue `S81-019`
Title: `Sprint 8.1 D10: 72h post-submission monitoring setup and first review`
Labels: `sprint-8.1,type:task,priority:p0,area:ops,area:data`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 10 (`S81-019`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Monitoring dashboard and alert owners are defined.
- [ ] First post-submission review note is published.
- [ ] Trigger conditions for hotfix are documented.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

Issue `S81-020`
Title: `Sprint 8.1 D10: Sprint retro and Sprint 9 kickoff decision`
Labels: `sprint-8.1,type:task,priority:p1,area:product`
Body:
```md
## Context
Roadmap execution item from Sprint 8.1, Day 10 (`S81-020`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Retro summary is written.
- [ ] Action items and owners are assigned.
- [ ] Sprint 9 kickoff decision is recorded.

## Source
- `docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md`
```

## Sprint 9

### Day 1

Issue `S9-001`
Title: `Sprint 9 D1: Define Mode Hub architecture and mode registry contract`
Labels: `sprint-9,type:feature,priority:p0,area:mobile,area:gameplay`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 1 (`S9-001`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Mode registry interface is defined.
- [ ] Mode metadata contract (`mode_id`, availability, label, icon key) is documented.
- [ ] ADR note for mode routing is added.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

Issue `S9-002`
Title: `Sprint 9 D1: Home screen Mode Hub UX with buttons for Classic, Tetris, Match-3`
Labels: `sprint-9,type:feature,priority:p0,area:design,area:mobile`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 1 (`S9-002`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Home has mode buttons with consistent layout.
- [ ] `Match-3` button supports `Coming soon` state.
- [ ] UX states are approved for implementation.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

### Day 2

Issue `S9-003`
Title: `Sprint 9 D2: Add feature flags and remote config keys for mode availability`
Labels: `sprint-9,type:task,priority:p0,area:mobile,area:ops`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 2 (`S9-003`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Config keys for mode enable/disable are added.
- [ ] Safe defaults are defined.
- [ ] Runtime fallback behavior is tested.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

Issue `S9-004`
Title: `Sprint 9 D2: Define telemetry schema for mode selection and mode sessions`
Labels: `sprint-9,type:task,priority:p0,area:data`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 2 (`S9-004`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Events `mode_selected`, `mode_start`, `mode_end` are specified.
- [ ] Required params include `mode_id` and variant context.
- [ ] Schema validation tests pass.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

### Day 3

Issue `S9-005`
Title: `Sprint 9 D3: Implement Tetris domain core (tetromino, collision, rotation, gravity)`
Labels: `sprint-9,type:feature,priority:p0,area:gameplay`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 3 (`S9-005`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Domain module compiles independently of UI.
- [ ] Core rules are covered by unit tests.
- [ ] Rotation/collision edge cases are validated.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

Issue `S9-006`
Title: `Sprint 9 D3: Integrate mode session orchestration into app controller layer`
Labels: `sprint-9,type:feature,priority:p0,area:mobile`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 3 (`S9-006`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Controller can initialize and dispose mode sessions.
- [ ] Mode switching does not break existing classic flow.
- [ ] Error handling path is instrumented.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

### Day 4

Issue `S9-007`
Title: `Sprint 9 D4: Implement Tetris rendering and controls (left/right/rotate/drop)`
Labels: `sprint-9,type:feature,priority:p0,area:mobile,area:gameplay`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 4 (`S9-007`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Playable controls work on mobile and desktop input.
- [ ] Visual state is stable with no blocking render artifacts.
- [ ] Input latency remains within acceptable limits.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

Issue `S9-008`
Title: `Sprint 9 D4: Add automated tests for Tetris line clear and game-over logic`
Labels: `sprint-9,type:task,priority:p0,area:qa,area:gameplay`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 4 (`S9-008`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Unit/integration tests cover critical loop.
- [ ] Tests run in CI with stable results.
- [ ] Failure messages are actionable.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

### Day 5

Issue `S9-009`
Title: `Sprint 9 D5: Implement Tetris score curve and speed progression v1`
Labels: `sprint-9,type:feature,priority:p1,area:gameplay,area:product`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 5 (`S9-009`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Score and speed progression are configurable.
- [ ] Baseline balance profile is documented.
- [ ] No unwinnable early-game states in smoke tests.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

Issue `S9-010`
Title: `Sprint 9 D5: Add end-of-round summary and restart flow for Tetris mode`
Labels: `sprint-9,type:feature,priority:p1,area:mobile,area:design`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 5 (`S9-010`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Summary card shows key mode metrics.
- [ ] Restart is one-tap and stable.
- [ ] UX copy is consistent with brand tone.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

### Day 6

Issue `S9-011`
Title: `Sprint 9 D6: Integrate Mode Hub navigation and route guards`
Labels: `sprint-9,type:task,priority:p0,area:mobile`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 6 (`S9-011`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Mode transitions and back navigation are stable.
- [ ] Disabled modes cannot start gameplay session.
- [ ] Analytics tracks transitions correctly.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

Issue `S9-012`
Title: `Sprint 9 D6: Create Match-3 scaffold contracts for Sprint 10`
Labels: `sprint-9,type:task,priority:p1,area:gameplay,area:mobile`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 6 (`S9-012`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Match-3 domain interfaces and placeholder module exist.
- [ ] Build passes with scaffold enabled.
- [ ] No impact on Classic and Tetris runtime behavior.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

### Day 7

Issue `S9-013`
Title: `Sprint 9 D7: Add observability hooks for mode-specific runtime health`
Labels: `sprint-9,type:task,priority:p0,area:data,area:ops`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 7 (`S9-013`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Mode context is included in ops events.
- [ ] Runtime errors are attributable by `mode_id`.
- [ ] Alert thresholds are reviewable by mode.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

Issue `S9-014`
Title: `Sprint 9 D7: Execute QA mode-switch regression and compatibility checks`
Labels: `sprint-9,type:task,priority:p0,area:qa`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 7 (`S9-014`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Switching between Classic and Tetris passes regression checklist.
- [ ] No navigation dead-ends or stuck states.
- [ ] Test report is attached.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

### Day 8

Issue `S9-015`
Title: `Sprint 9 D8: Run internal balance window #1 for Tetris mode`
Labels: `sprint-9,type:task,priority:p1,area:product,area:data`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 8 (`S9-015`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Metrics window #1 is collected with required fields.
- [ ] Balance pain points are listed and prioritized.
- [ ] Proposed tuning values are documented.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

Issue `S9-016`
Title: `Sprint 9 D8: Apply bugfix and UX polish batch from window #1 feedback`
Labels: `sprint-9,type:bug,priority:p1,area:mobile,area:design`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 8 (`S9-016`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Top feedback items are addressed.
- [ ] No new P0/P1 introduced.
- [ ] Updated build passes smoke checks.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

### Day 9

Issue `S9-017`
Title: `Sprint 9 D9: Build mode release candidate and verify artifacts`
Labels: `sprint-9,type:task,priority:p0,area:release,area:mobile`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 9 (`S9-017`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] RC artifacts are generated and installable.
- [ ] Version and release notes are aligned.
- [ ] Artifact verification report is attached.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

Issue `S9-018`
Title: `Sprint 9 D9: Prepare controlled rollout plan for Mode Hub and Tetris`
Labels: `sprint-9,type:task,priority:p0,area:ops,area:product`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 9 (`S9-018`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Rollout steps and guardrails are defined.
- [ ] Rollback path is documented.
- [ ] Approval owners are assigned.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

### Day 10

Issue `S9-019`
Title: `Sprint 9 D10: Collect cohort window #2 and publish mode decision memo`
Labels: `sprint-9,type:task,priority:p0,area:data,area:product`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 10 (`S9-019`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Window #2 metrics are collected and validated.
- [ ] Decision memo includes `expand`, `iterate`, or `hold`.
- [ ] Evidence links are attached.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

Issue `S9-020`
Title: `Sprint 9 D10: Sprint retro and Sprint 10 plan for full Match-3 implementation`
Labels: `sprint-9,type:task,priority:p1,area:product`
Body:
```md
## Context
Roadmap execution item from Sprint 9, Day 10 (`S9-020`).

## Scope
- Execute the task described in the title.
- Keep implementation aligned with current roadmap and implementation status docs.
- Add/update tests and docs for behavior changes.

## Acceptance Criteria
- [ ] Retro notes and action items are documented.
- [ ] Sprint 10 draft backlog for Match-3 is created.
- [ ] Owners and estimates are assigned.

## Source
- `docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md`
```

