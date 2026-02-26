# UX/Balance AB Wave 001

## 1. Goal
Run the first production-like AB wave for:
1. Gameplay balance pressure.
2. HUD readability and progress clarity.

## 2. Experiment Matrix
1. `difficulty_curve` (`ab.difficulty_variant`)
- `balanced_v1` (control)
- `fairness_bias_v1` (easier opening and lower hard-piece pressure)
- `challenge_bias_v1` (higher hard-piece pressure)

2. `hud_ux` (`ab.ux_variant`)
- `hud_standard_v1` (control)
- `hud_focus_v1` (goal chips + clearer streak and completion layout)

## 3. Required Remote Config Keys
1. `ab.bucket`
2. `ab.difficulty_variant`
3. `ab.ux_variant`
4. `balance.target_moves_per_run`
5. `balance.observed_avg_moves_per_run`
6. `balance.observed_early_gameover_rate`

## 4. Telemetry Requirements
1. `ab_experiment_exposure` must include:
- `experiment_id = difficulty_curve`
- `experiment_id = hud_ux`
2. `session_start`, `game_start`, `game_end` must include:
- `ux_variant`
- `difficulty_variant`

## 5. Success/Guardrail Criteria (Wave #1)
1. Primary: `observed_avg_moves_per_run` reaches target corridor (`target - 1 ... target + 3`).
2. UX: `avg_session_minutes` not lower than control by more than `5%`.
3. Fairness guardrail: `observed_early_gameover_rate <= 0.30`.
4. Quality guardrail: no increase in critical gameplay bugs from QA smoke.

## 6. Rollout Plan
1. Start with 10% traffic on each non-control variant.
2. Run until at least 30 sessions per active variant.
3. Stop early if guardrail is violated.
4. Promote winner to default config and archive losing variant.
