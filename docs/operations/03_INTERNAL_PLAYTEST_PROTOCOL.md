# Internal Playtest Protocol (v1)

## 1. Goal
Validate gameplay feel, early retention proxies, and monetization pressure before broader rollout.

## 2. Scope
- Build: latest internal `debug` or `profile` build from `apps/mobile`.
- Cohort: 15-30 internal testers.
- Window: 2-4 days.
- Sessions per tester: at least 3 sessions, total 30+ sessions minimum.

## 3. Pre-Playtest Checklist
1. Build is green:
`flutter analyze`, `flutter test`, `flutter build apk --debug`.
2. Analytics events are enabled:
`game_start`, `move_made`, `line_clear`, `game_end`, `move_rejected`.
3. SFX and VFX enabled in build.
4. Config snapshot saved (current remote config values).

## 4. Test Scenario
1. Session A:
- Fresh launch.
- Play until first game over.
- Restart once and play 3+ minutes.
2. Session B:
- Focus on combo attempts and rack management.
- Record subjective fairness from 1 to 5.
3. Session C:
- Long run attempt (score optimization).
- Record frustration moments.

## 5. Metrics to Collect
Primary:
- `observed_early_gameover_rate` (share of runs ending before 8 moves).
- `observed_avg_moves_per_run`.
- `avg_session_minutes`.

Secondary:
- `combo_move_rate` (moves with combo / total moves).
- `rewarded_opt_in_rate`.
- `line_clear_rate` (line_clear events / move_made events).

Quality:
- crash count
- input bugs
- visual clarity issues
- perceived fairness score (1-5)

## 6. Data Export Format (JSON)
Use a compact JSON (example in [internal_playtest_metrics_sample.json](/d:/Block-Puzzle/data/dashboards/internal_playtest_metrics_sample.json)).

Required fields:
- `target_moves_per_run`
- `observed_early_gameover_rate`
- `observed_avg_moves_per_run`
- `avg_session_minutes`
- `combo_move_rate`
- `rewarded_opt_in_rate`

## 7. Auto-Tuning Workflow
1. Prepare metrics JSON.
2. Run autotune script:
```powershell
.\scripts\autotune_playtest_config.ps1 `
  -MetricsPath "data/dashboards/internal_playtest_metrics_sample.json" `
  -OutputPath "data/dashboards/internal_playtest_autotuned_config.json"
```
3. Review tuned values and apply to remote config.
4. Build next internal version and repeat playtest cycle.

## 8. Guardrails
- Never increase difficulty if `observed_early_gameover_rate > 0.35`.
- If `avg_session_minutes < 6`, reduce pressure (difficulty + ads cooldown).
- Rollback config if D1 proxy or session quality drops noticeably (>2 pp proxy threshold).

## 9. Release Decision Gate
Go to next phase only if:
1. `observed_avg_moves_per_run` >= target-1
2. early game over rate <= 0.30
3. no critical gameplay bugs
4. fairness score median >= 4/5
