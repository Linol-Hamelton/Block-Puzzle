# Internal Playtest Run 001 Report

## 1. Run Context
- Run ID: `internal_playtest_run_001`
- Date (UTC): `2026-02-25`
- Data source: automated internal simulation (40 sessions)
- Build artifacts:
  - APK: [block-puzzle-internal-debug.apk](/d:/Block-Puzzle/artifacts/block-puzzle-internal-debug.apk)
  - Web bundle: [block-puzzle-web-build-2026-02-25.zip](/d:/Block-Puzzle/artifacts/block-puzzle-web-build-2026-02-25.zip)

## 2. Checklist Status
1. Build health:
- `flutter analyze` passed
- `flutter test` passed
- `flutter build apk --debug` passed
- `flutter build web --release` passed

2. Gameplay instrumentation:
- `game_start` enabled
- `move_made` enabled
- `line_clear` enabled
- `game_end` enabled
- `move_rejected` enabled

3. Audio/visual readiness:
- Real SFX files loaded through `flame_audio`
- VFX v2 enabled: per-cell line clear burst
- Combo stack UI timings enabled

4. Config pipeline:
- run metrics JSON generated
- iteration #1 tuned config generated

## 3. Collected Metrics (Run 001)
Source file:
[internal_playtest_run_001_metrics.json](/d:/Block-Puzzle/data/dashboards/internal_playtest_run_001_metrics.json)

Values:
- `sample_size_sessions`: `40`
- `observed_early_gameover_rate`: `0.000`
- `observed_avg_moves_per_run`: `49.02`
- `avg_session_minutes`: `3.40`
- `combo_move_rate`: `0.039`
- `line_clear_rate`: `0.236`
- `rewarded_opt_in_rate`: `0.30` (placeholder until real ad flow instrumentation)

## 4. Iteration #1 Tuned Config
Output file:
[internal_playtest_run_001_tuned_config.json](/d:/Block-Puzzle/data/dashboards/internal_playtest_run_001_tuned_config.json)

Tuned values:
- `difficulty.hard_piece_weight`: `0.23`
- `difficulty.max_hard_pieces_per_triplet`: `1`
- `ads.interstitial_cooldown_rounds`: `3`
- `balance.target_moves_per_run`: `14`
- `balance.observed_avg_moves_per_run`: `49.02`
- `balance.observed_early_gameover_rate`: `0`

## 5. Interpretation
- Session length proxy is short (`3.4 min`) while moves per run are high.
- Combo rate is low (`0.039`), indicating we should improve combo opportunities/feedback.
- Early game over is currently low in simulation, but this is not yet human behavior.

## 6. Next Actions for Real Human Cohort
1. Run 30+ human sessions using this build and protocol.
2. Export real metrics JSON with the same schema.
3. Re-run autotune script on human metrics.
4. Approve or rollback config by guardrails.
