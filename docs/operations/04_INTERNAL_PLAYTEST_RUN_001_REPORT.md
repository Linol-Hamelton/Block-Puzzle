# Internal Playtest Run 001 Report — `simulation_only`

> **Status: `simulation_only`**. This report was generated from 40 automated synthetic sessions, not real human players. It is useful only as a pipeline validation artifact, not as a source of truth for player behavior, balance decisions, or rollout gate evaluation. The first real human cohort window lands in Phase 2 per [../roadmap/01_ROADMAP_AND_SPRINTS.md](../roadmap/01_ROADMAP_AND_SPRINTS.md).

## 1. Run Context
- Run ID: `internal_playtest_run_001`
- Date (UTC): `2026-02-25`
- Data source: automated internal simulation (40 sessions), not real players
- Purpose: pipeline validation only; NOT a substitute for real human cohort windows

Build artifacts used at the time:
- APK (debug): [block-puzzle-internal-debug.apk](/d:/Block-Puzzle/artifacts/block-puzzle-internal-debug.apk)
- Web bundle: [block-puzzle-web-build-2026-02-25.zip](/d:/Block-Puzzle/artifacts/block-puzzle-web-build-2026-02-25.zip)

## 2. Build Checklist (Run 001 Window)
- `flutter analyze` passed
- `flutter test` passed
- `flutter build apk --debug` passed
- `flutter build web --release` passed

## 3. Collected Metrics (Simulation)
Source:
[internal_playtest_run_001_metrics.json](/d:/Block-Puzzle/data/dashboards/internal_playtest_run_001_metrics.json)

Values:
- `sample_size_sessions`: `40`
- `observed_early_gameover_rate`: `0.000`
- `observed_avg_moves_per_run`: `49.02`
- `avg_session_minutes`: `3.40`
- `combo_move_rate`: `0.039`
- `line_clear_rate`: `0.236`
- `rewarded_opt_in_rate`: `0.30` (simulation placeholder)

## 4. Iteration Output
Output config:
[internal_playtest_run_001_tuned_config.json](/d:/Block-Puzzle/data/dashboards/internal_playtest_run_001_tuned_config.json)

## 5. Interpretation
- This run is useful as pipeline validation, not as player truth.
- Real tuning decisions must be made from human cohort data (`run_002` schema).

## 6. Next Step
1. Collect real human sessions (30+).
2. Fill `internal_playtest_run_002_metrics.json`.
3. Run Sprint 8 loop and evaluate rollout gates.
