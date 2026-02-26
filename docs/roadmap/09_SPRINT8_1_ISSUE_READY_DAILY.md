# Sprint 8.1 Stabilization: Issue-Ready Daily Plan

## 1. Label Convention
- `sprint-8.1`
- `type:task` / `type:bug`
- `priority:p0` / `priority:p1`
- `area:mobile` / `area:qa` / `area:data` / `area:product` / `area:ops` / `area:release`

## 2. Daily Issues

### Day 1
Issue `S81-001`  
Title: `Sprint 8.1 D1: Stabilization scope freeze and P0/P1 triage`  
Labels: `sprint-8.1,type:task,priority:p0,area:product,area:mobile`  
Acceptance Criteria:
- Stabilization scope document is approved.
- All known defects are triaged into P0/P1/P2.
- Owners and due dates are assigned.

Issue `S81-002`  
Title: `Sprint 8.1 D1: QA device matrix and regression checklist freeze`  
Labels: `sprint-8.1,type:task,priority:p0,area:qa`  
Acceptance Criteria:
- Phone/tablet matrix is documented.
- Smoke and regression checklist is finalized.
- Entry/exit criteria for RC validation are published.

### Day 2
Issue `S81-003`  
Title: `Sprint 8.1 D2: Fix all open P0 crash and soft-lock defects`  
Labels: `sprint-8.1,type:bug,priority:p0,area:mobile`  
Acceptance Criteria:
- No open P0 crash/soft-lock tickets remain.
- Fixes are covered by reproducible test steps.
- No new P0 regressions introduced.

Issue `S81-004`  
Title: `Sprint 8.1 D2: Validate baseline gameplay and ops telemetry`  
Labels: `sprint-8.1,type:task,priority:p0,area:data`  
Acceptance Criteria:
- Core gameplay events are present and valid.
- `ops_session_snapshot` and `ops_error` are observable in test runs.
- Validation report is attached.

### Day 3
Issue `S81-005`  
Title: `Sprint 8.1 D3: Fix P1 gameplay and UX blockers`  
Labels: `sprint-8.1,type:bug,priority:p1,area:mobile`  
Acceptance Criteria:
- All agreed P1 blockers are closed or explicitly deferred.
- Drag/hit-area visibility issues are verified fixed.
- QA confirms no blocker remains for RC path.

Issue `S81-006`  
Title: `Sprint 8.1 D3: Run focused regression for drag, placement, and touch targets`  
Labels: `sprint-8.1,type:task,priority:p1,area:qa`  
Acceptance Criteria:
- Regression checklist pass/fail is documented.
- Mobile touch-target and drag offset checks pass on matrix devices.
- Found regressions are linked to tickets.

### Day 4
Issue `S81-007`  
Title: `Sprint 8.1 D4: Performance pass for frame stability and memory spikes`  
Labels: `sprint-8.1,type:task,priority:p1,area:mobile`  
Acceptance Criteria:
- Profiling snapshot is attached.
- Top hotspots have fixes or mitigation notes.
- No new critical perf regressions vs baseline.

Issue `S81-008`  
Title: `Sprint 8.1 D4: QA low-mid Android perf benchmark verification`  
Labels: `sprint-8.1,type:task,priority:p1,area:qa`  
Acceptance Criteria:
- FPS/thermal observations are recorded on target devices.
- Results are compared with previous baseline.
- Go/No-Go perf note is provided.

### Day 5
Issue `S81-009`  
Title: `Sprint 8.1 D5: Telemetry edge-case hardening and schema validation`  
Labels: `sprint-8.1,type:task,priority:p0,area:data,area:mobile`  
Acceptance Criteria:
- Edge cases (session end, runtime error, mode transitions) are validated.
- No schema-breaking payloads in validation run.
- Contract checks are reproducible.

Issue `S81-010`  
Title: `Sprint 8.1 D5: Collect real cohort window #1 metrics`  
Labels: `sprint-8.1,type:task,priority:p0,area:product,area:data`  
Acceptance Criteria:
- Real window metrics JSON is collected and stored.
- Collection window boundaries are documented.
- Sample size meets minimum gate requirements.

### Day 6
Issue `S81-011`  
Title: `Sprint 8.1 D6: Apply tuned config from cohort window #1 with rollback guard`  
Labels: `sprint-8.1,type:task,priority:p0,area:product,area:ops`  
Acceptance Criteria:
- Tuned config is generated and reviewed.
- Rollback config snapshot is saved.
- Change log for applied values is published.

Issue `S81-012`  
Title: `Sprint 8.1 D6: Execute rollout gates evaluation #1`  
Labels: `sprint-8.1,type:task,priority:p0,area:data,area:ops`  
Acceptance Criteria:
- Gates report is generated from real metrics.
- Decision is one of `go_rollout_25_percent`, `go_rollout_10_percent_watchlist`, `hold_and_iterate`.
- Decision rationale is documented.

### Day 7
Issue `S81-013`  
Title: `Sprint 8.1 D7: Build RC1 and fix blockers from first gates cycle`  
Labels: `sprint-8.1,type:task,priority:p0,area:mobile,area:release`  
Acceptance Criteria:
- RC1 build artifacts are produced.
- Blockers from cycle #1 are resolved or documented.
- RC1 is installable on matrix devices.

Issue `S81-014`  
Title: `Sprint 8.1 D7: Smoke pass #2 across mobile DPI classes`  
Labels: `sprint-8.1,type:task,priority:p1,area:qa`  
Acceptance Criteria:
- Smoke pass #2 results are attached.
- Visual and interaction checks pass on selected DPI classes.
- Failures are ticketed and triaged.

### Day 8
Issue `S81-015`  
Title: `Sprint 8.1 D8: Full regression and final QA sign-off draft`  
Labels: `sprint-8.1,type:task,priority:p0,area:qa`  
Acceptance Criteria:
- Full regression is completed on agreed matrix.
- Open defects list contains no P0/P1 blockers.
- QA sign-off draft is published.

Issue `S81-016`  
Title: `Sprint 8.1 D8: Prepare Go/No-Go release decision pack`  
Labels: `sprint-8.1,type:task,priority:p0,area:product,area:release`  
Acceptance Criteria:
- Decision pack includes quality, metrics, and ops sections.
- Risks and mitigations are explicitly listed.
- Stakeholder review meeting is scheduled.

### Day 9
Issue `S81-017`  
Title: `Sprint 8.1 D9: Final release artifact verification (APK/AAB)`  
Labels: `sprint-8.1,type:task,priority:p0,area:release`  
Acceptance Criteria:
- Final APK/AAB pass installation and startup checks.
- Versioning and signing are validated.
- Artifact paths and checksums are documented.

Issue `S81-018`  
Title: `Sprint 8.1 D9: Store submission runbook execution`  
Labels: `sprint-8.1,type:task,priority:p0,area:release,area:ops`  
Acceptance Criteria:
- Submission checklist is completed.
- Console submission status is captured.
- Any moderation blockers are tracked.

### Day 10
Issue `S81-019`  
Title: `Sprint 8.1 D10: 72h post-submission monitoring setup and first review`  
Labels: `sprint-8.1,type:task,priority:p0,area:ops,area:data`  
Acceptance Criteria:
- Monitoring dashboard and alert owners are defined.
- First post-submission review note is published.
- Trigger conditions for hotfix are documented.

Issue `S81-020`  
Title: `Sprint 8.1 D10: Sprint retro and Sprint 9 kickoff decision`  
Labels: `sprint-8.1,type:task,priority:p1,area:product`  
Acceptance Criteria:
- Retro summary is written.
- Action items and owners are assigned.
- Sprint 9 kickoff decision is recorded.
