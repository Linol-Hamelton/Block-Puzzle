# Worklog: deepseek-b9f959e0e6c4a677

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-25 - Hostile audit: Track A / B.1 / B.2 Flame VFX (758e63e, e10e829, 5cf08b5)

Agent: deepseek-b9f959e0e6c4a677

Action:
1. Read TASK/PLAN/DECISIONS (28 blocks), docs/design/02, the six effects modules, Tetris/Match-3 game and screen integrations, and the three new test suites.
2. Verified Flame 1.18 lifecycle in the pub cache: GameWidget.dispose -> disposeCurrentGame -> finalizeRemoval -> game.dart:106 onRemove(), so onRemove/dropCachedSurfaces do run.
3. Ran, from apps/mobile: `flutter analyze --fatal-infos --fatal-warnings` (exit 0, 0 issues) and `flutter test --no-pub` (530/530, exit 0). Ran `validate-protocol.ps1` (exit 0, 0 warnings, 28 decisions).
4. Verdict: REJECT. Findings below, each with file:line.

Result:
- P1-1 Tetris line-clear geometry is hardcoded 8x8: vfx_director.dart:199 (`Vector2.all(cellSize * 8)`) and :209-214 (clip Rect `cellSize * 8`). Tetris board is 10x20 (tetris_board.dart:21-22), event carries the true origin (tetris_game.dart:136) but no size. Flash lands in the top-left 8x8; the shockwave is centred on cleared rows and clipped to that rect, so with maxRadius 140 it never intersects and is invisible. Test asserts presence only: tetris_vfx_test.dart:103-131.
- P1-2 Match-3 cascadeDropCurve is not applied in the common case: `_chargeElapsed` is reset only inside `_frameCharge()`, which render calls only when `igniting` is non-empty (match3_game.dart:342-353, 459-460). The terminal frame (and every single-step move) has `igniting: const {}` (cascade_playback.dart:97-107), while `_dropProgress()` (match3_game.dart:397-420) reuses the same stale clock: t = elapsed/hold = 300/180 = 1.67 -> clamped to 1, so refill gems snap/teleport. No test covers `_dropProgress`, `isDropping` or yOffset; only the pure `computeFallDistances` math (match3_vfx_test.dart:87-119).
- P1-3 Match-3 score popups never fire: scoreDelta = `controller.score - _lastScore` (match3_game.dart:228-237), but the engine settles the whole cascade synchronously before playback (match3_controller.dart:159-190), and `_lastScore` is re-synced every game update (match3_game.dart:435), so the delta at visual-event time is 0. The test named "with Shockwave and ScorePop" asserts only ShockwaveRingComponent and ComboPulseComponent (match3_vfx_test.dart:121-139).
- P1-4 Reduced motion is only half-honoured: the games' own `_shake` canvas translate and `_flash` overlay are ungated (match3_game.dart:470-471, 592-601; tetris_game.dart:333-336, 499-509; no `reducedMotion` reference in either game file), and `_handleLineCleared` always adds a ShockwaveRingComponent (vfx_director.dart:205-217). Director-internal gating (shake/zoom/hit-stop alpha) works; integration tests do not cover reduced motion.
- P2-5 PieceAuraShader creates a new native FragmentShader per createPaint call and never disposes it (piece_aura_shader.dart:51; callers match3_game.dart:544, tetris_game.dart:396 and :434; no dispose in the file). Flutter documents the program's shader as reusable and Shader.dispose exists. Feature is latent: `VfxLevel.full` is set nowhere in lib (no VfxLevel.fromString caller, no `vfx_level` key in Remote Config defaults), so Stage 4 and its RC kill-switch are not plugged in.
- P2-6 Hit-stop is inconsistent: Tetris gates `controller.tick` (tetris_game.dart:290-295), while Match-3's controller keeps its own `Timer(frame.hold, _advanceFrame)` (match3_controller.dart:189) so the model advances while the view is frozen; after the freeze the next drop uses a larger elapsed gap.
- P2-7 Per-frame render allocations remain: colorBomb wheel list + Paint per colour (match3_game.dart:892-908), hint paints with MaskFilter (match3_game.dart:954-970), one Paint per particle per frame in BurstField.render (burst_field.dart:114-117).
- P2-8 docs/design/02_VFX_JUICE_RESEARCH_PLAN.md:141-147 still marks Tetris and Match-3 stages 1-5 as tech debt (⏳) while TASK claims B.1/B.2 "fully implemented".
- P3: tie scores show "New Record!" (match3_screen.dart:378, tetris_screen.dart:631, because bestScore = max(stored, score)); TextPainter never disposed in ScorePop/ComboPulse; `_canReuseGemsPicture` (match3_game.dart:661-697) omits atlas identity, so a pixel-ratio-only rebake can reuse a picture recorded from the disposed atlas (danger not proven, no repro).

Verified OK (so the next agent does not redo it): dispose-before-null ordering at the three call sites; onRemove reachable; resume drops surfaces and background pauses (match3_screen.dart:65-87, tetris_screen.dart:61-81); portrait lock (bootstrap.dart:43-46) makes rotation moot; aura bounds skip y<0 cells (tetris_game.dart:385-405, 423-443); easeOutQuad cannot overshoot and dynamic gems are clipped (match3_game.dart:504-509); `computeFallDistances` and `_updateStaticGemsPicture` run per frame serial / per settle, not per frame; all effect timers self-remove; triggerHitStop clamps 0.02..0.08 and is gated by reduced motion and VfxLevel.off (vfx_director.dart:74-79).

Next step:
- Implementer decides fixes 1-4 (blocking) and 5-6; owner either accepts the fixes or records an explicit descope of Stage 4/`vfx_level` and the reduced-motion scope. Then a re-audit of the same three commits.

Open:
- Session-start role parser reported "not among the roles" although .ai/TASK.md names `reviewer: deepseek (hostile audit after Track B completion)`; the audit was performed on the owner's explicit instruction. Owner should confirm the role text is machine-readable for the next session.

Evidence:
- anchor: 5cf08b5fa512966215a04d0418a176ab98d44e34, uncommitted changes present
- digest: sha256:f9c30a3e01fdf90c0a5ce862be6ca2cd7af7366752e3912389c1711a398f489b over 570 tracked and untracked files
- digest format: 4
- recorded: 2026-09-25T03:06:58.236Z by deepseek-b9f959e0e6c4a677
- entry: sha256:d9cf9a3b87fe42ada466cb02e8e4dc54937f31a73dd72b76acffcf393505ee5f of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
