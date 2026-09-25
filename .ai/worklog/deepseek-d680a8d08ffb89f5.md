# Worklog: deepseek-d680a8d08ffb89f5

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-25 - Re-audit of the 6 fixes (7e65d54): REJECT, #3 unresolved, #4 partial

Agent: deepseek-d680a8d08ffb89f5

Action:
1. Read TASK/PLAN, the 7e65d54 diff, the six claimed fixes, the tests, and docs/design/02. Re-ran the full verification from apps/mobile: `flutter analyze --fatal-infos --fatal-warnings` (exit 0, 0 issues), `flutter test --no-pub` (exit 0, 536/536), `validate-protocol.ps1` (exit 0, 0 warnings).
2. Verified fixed: #1 Tetris boardSize is threaded (tetris_game.dart:138) and the shockwave/flash use Rect 10x20 (vfx_director.dart:195-220; test asserts Size(300,600)). #2 drop clock resets per frameSerial (match3_game.dart:399-423, 440) and every step frame carries burst including the terminal one (cascade_playback.dart:97-107), so refills animate; implementation sound. #5 aura enabled on standard+full with one cached FragmentShader (piece_aura_shader.dart:21,29-46), disposed via VfxDirector.clearAll (vfx_director.dart:405) from onRemove. #6 strict ties: score > sessionStartBestScore in both controllers, cards fall back to score > best (match3_screen.dart:377, tetris_screen.dart:630), tie tests added.
3. Temporary probe (deleted; tree clean afterwards) against the real cascade pipeline with seed 42:
   `AUDIT_EVENT type=Match3EventType.match value=3 detail=1 points=0`
   `AUDIT_PROBE score=90 sawRing=true sawScorePop=false`
   Reduced-motion probe: `AUDIT_PROBE_REDUCED_MOTION_ALL_CLEAR rings=1`.
4. Findings:
   - P1-3 NOT FIXED. `Match3Event.points` is never populated (match3_engine.dart:243-247 passes only value/detail); lib has no other writer. The fallback `controller.score - _lastScore` (match3_game.dart:230) is 0 at match-frame time because `_lastScore` is re-synced in update while the opening frame holds. The existing test fabricates `Match3Event(match, 6, 2, 120)` (match3_vfx_test.dart:128-130), so it never exercises the engine.
   - P2-4 RESIDUAL. `_handleAllClear` adds ShockwaveRingComponent unconditionally (vfx_director.dart:346-357); perfectClear/roundComplete still spawn it under reduced motion. Tests cover only lineClear/match. Docs matrix line 145/131 claim full Reduced Motion compliance.
   - P2 TEST GAP. The "drop progress" test asserts only `isHitStopActive == false` (match3_vfx_test.dart:168-183); no test references `_dropProgress`, `yOffset` or fall offsets, so the fix has no real regression coverage.
   - P3. `VfxLevel.fromString` still has no caller: aura is now on by default on standard with no RC/off kill-switch. `loadShader()` completing after `clearAll()` can cache a shader post-dispose (narrow race).
   - P2-6/P2-7 from the first audit were outside the selected six and remain open by scope.

Result:
- Checks: analyze exit 0; test 536/536 exit 0; validate-protocol exit 0 (0 warnings). The suite is green but does not prove the contested claims.
- Verdict: REJECT. 4/6 verified (#1, #2 impl, #5, #6); #3 not fixed; #4 partial; #2 and #3 test coverage does not match the journal claims.
- Probe removed; only this journal is untracked; nothing else changed.

Next step:
- Implementer: populate points from `step.gained` in match3_engine.dart:243-247; add a pipeline-level ScorePop test (real swap, no hand-made event); gate the AllClear shockwave with `reduced`; strengthen the drop-progress assertion.
- Owner: decide scope for P2-6/P2-7/P3, fix docs line 145/131, then request re-audit.

Open:
- P1: Match-3 ScorePop still never fires in production despite TASK checkbox 3.
- P2: AllClear/roundComplete shockwave not gated by reduced motion (TASK checkbox 4 "fully gated" is false).
- P2: drop-progress regression test is vacuous.
- P3: no runtime vfx_level/off path; narrow dispose/loadShader race.
- P2-6/P2-7 (hit-stop model advance, per-frame allocations) remain unfixed outside the six.

Evidence:
- anchor: 7e65d54073f35f4ac6896713083e4dcb2415694a, uncommitted changes present
- digest: sha256:21a6f319e6a2774126969200520473e073c653d50899967db4db4f4715711c72 over 570 tracked and untracked files
- digest format: 4
- recorded: 2026-09-25T03:35:34.493Z by deepseek-d680a8d08ffb89f5
- entry: sha256:13cb6c55b8214649cda662a0fcc009617d13ab64721bcd7551cd4601e445ac9a of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
