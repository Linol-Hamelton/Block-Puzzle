# Sprint 9: Mode Hub + New Modes Issue-Ready Daily Plan

## 1. Label Convention
- `sprint-9`
- `type:task` / `type:feature` / `type:bug`
- `priority:p0` / `priority:p1`
- `area:mobile` / `area:gameplay` / `area:qa` / `area:data` / `area:product` / `area:design` / `area:ops`

## 2. Scope Reminder
Sprint 9 target:
1. Home `Mode Hub` with new buttons.
2. First playable new mode: `Tetris Rush`.
3. `Match-3` technical scaffold for next sprint (not full implementation yet).

## 3. Daily Issues

### Day 1
Issue `S9-001`  
Title: `Sprint 9 D1: Define Mode Hub architecture and mode registry contract`  
Labels: `sprint-9,type:feature,priority:p0,area:mobile,area:gameplay`  
Acceptance Criteria:
- Mode registry interface is defined.
- Mode metadata contract (`mode_id`, availability, label, icon key) is documented.
- ADR note for mode routing is added.

Issue `S9-002`  
Title: `Sprint 9 D1: Home screen Mode Hub UX with buttons for Classic, Tetris, Match-3`  
Labels: `sprint-9,type:feature,priority:p0,area:design,area:mobile`  
Acceptance Criteria:
- Home has mode buttons with consistent layout.
- `Match-3` button supports `Coming soon` state.
- UX states are approved for implementation.

### Day 2
Issue `S9-003`  
Title: `Sprint 9 D2: Add feature flags and remote config keys for mode availability`  
Labels: `sprint-9,type:task,priority:p0,area:mobile,area:ops`  
Acceptance Criteria:
- Config keys for mode enable/disable are added.
- Safe defaults are defined.
- Runtime fallback behavior is tested.

Issue `S9-004`  
Title: `Sprint 9 D2: Define telemetry schema for mode selection and mode sessions`  
Labels: `sprint-9,type:task,priority:p0,area:data`  
Acceptance Criteria:
- Events `mode_selected`, `mode_start`, `mode_end` are specified.
- Required params include `mode_id` and variant context.
- Schema validation tests pass.

### Day 3
Issue `S9-005`  
Title: `Sprint 9 D3: Implement Tetris domain core (tetromino, collision, rotation, gravity)`  
Labels: `sprint-9,type:feature,priority:p0,area:gameplay`  
Acceptance Criteria:
- Domain module compiles independently of UI.
- Core rules are covered by unit tests.
- Rotation/collision edge cases are validated.

Issue `S9-006`  
Title: `Sprint 9 D3: Integrate mode session orchestration into app controller layer`  
Labels: `sprint-9,type:feature,priority:p0,area:mobile`  
Acceptance Criteria:
- Controller can initialize and dispose mode sessions.
- Mode switching does not break existing classic flow.
- Error handling path is instrumented.

### Day 4
Issue `S9-007`  
Title: `Sprint 9 D4: Implement Tetris rendering and controls (left/right/rotate/drop)`  
Labels: `sprint-9,type:feature,priority:p0,area:mobile,area:gameplay`  
Acceptance Criteria:
- Playable controls work on mobile and desktop input.
- Visual state is stable with no blocking render artifacts.
- Input latency remains within acceptable limits.

Issue `S9-008`  
Title: `Sprint 9 D4: Add automated tests for Tetris line clear and game-over logic`  
Labels: `sprint-9,type:task,priority:p0,area:qa,area:gameplay`  
Acceptance Criteria:
- Unit/integration tests cover critical loop.
- Tests run in CI with stable results.
- Failure messages are actionable.

### Day 5
Issue `S9-009`  
Title: `Sprint 9 D5: Implement Tetris score curve and speed progression v1`  
Labels: `sprint-9,type:feature,priority:p1,area:gameplay,area:product`  
Acceptance Criteria:
- Score and speed progression are configurable.
- Baseline balance profile is documented.
- No unwinnable early-game states in smoke tests.

Issue `S9-010`  
Title: `Sprint 9 D5: Add end-of-round summary and restart flow for Tetris mode`  
Labels: `sprint-9,type:feature,priority:p1,area:mobile,area:design`  
Acceptance Criteria:
- Summary card shows key mode metrics.
- Restart is one-tap and stable.
- UX copy is consistent with brand tone.

### Day 6
Issue `S9-011`  
Title: `Sprint 9 D6: Integrate Mode Hub navigation and route guards`  
Labels: `sprint-9,type:task,priority:p0,area:mobile`  
Acceptance Criteria:
- Mode transitions and back navigation are stable.
- Disabled modes cannot start gameplay session.
- Analytics tracks transitions correctly.

Issue `S9-012`  
Title: `Sprint 9 D6: Create Match-3 scaffold contracts for Sprint 10`  
Labels: `sprint-9,type:task,priority:p1,area:gameplay,area:mobile`  
Acceptance Criteria:
- Match-3 domain interfaces and placeholder module exist.
- Build passes with scaffold enabled.
- No impact on Classic and Tetris runtime behavior.

### Day 7
Issue `S9-013`  
Title: `Sprint 9 D7: Add observability hooks for mode-specific runtime health`  
Labels: `sprint-9,type:task,priority:p0,area:data,area:ops`  
Acceptance Criteria:
- Mode context is included in ops events.
- Runtime errors are attributable by `mode_id`.
- Alert thresholds are reviewable by mode.

Issue `S9-014`  
Title: `Sprint 9 D7: Execute QA mode-switch regression and compatibility checks`  
Labels: `sprint-9,type:task,priority:p0,area:qa`  
Acceptance Criteria:
- Switching between Classic and Tetris passes regression checklist.
- No navigation dead-ends or stuck states.
- Test report is attached.

### Day 8
Issue `S9-015`  
Title: `Sprint 9 D8: Run internal balance window #1 for Tetris mode`  
Labels: `sprint-9,type:task,priority:p1,area:product,area:data`  
Acceptance Criteria:
- Metrics window #1 is collected with required fields.
- Balance pain points are listed and prioritized.
- Proposed tuning values are documented.

Issue `S9-016`  
Title: `Sprint 9 D8: Apply bugfix and UX polish batch from window #1 feedback`  
Labels: `sprint-9,type:bug,priority:p1,area:mobile,area:design`  
Acceptance Criteria:
- Top feedback items are addressed.
- No new P0/P1 introduced.
- Updated build passes smoke checks.

### Day 9
Issue `S9-017`  
Title: `Sprint 9 D9: Build mode release candidate and verify artifacts`  
Labels: `sprint-9,type:task,priority:p0,area:release,area:mobile`  
Acceptance Criteria:
- RC artifacts are generated and installable.
- Version and release notes are aligned.
- Artifact verification report is attached.

Issue `S9-018`  
Title: `Sprint 9 D9: Prepare controlled rollout plan for Mode Hub and Tetris`  
Labels: `sprint-9,type:task,priority:p0,area:ops,area:product`  
Acceptance Criteria:
- Rollout steps and guardrails are defined.
- Rollback path is documented.
- Approval owners are assigned.

### Day 10
Issue `S9-019`  
Title: `Sprint 9 D10: Collect cohort window #2 and publish mode decision memo`  
Labels: `sprint-9,type:task,priority:p0,area:data,area:product`  
Acceptance Criteria:
- Window #2 metrics are collected and validated.
- Decision memo includes `expand`, `iterate`, or `hold`.
- Evidence links are attached.

Issue `S9-020`  
Title: `Sprint 9 D10: Sprint retro and Sprint 10 plan for full Match-3 implementation`  
Labels: `sprint-9,type:task,priority:p1,area:product`  
Acceptance Criteria:
- Retro notes and action items are documented.
- Sprint 10 draft backlog for Match-3 is created.
- Owners and estimates are assigned.
