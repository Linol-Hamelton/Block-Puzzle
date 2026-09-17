# Current Task

Status: In progress - DEC-0024 on branch dec-0024/av-polish; 1k and 7 open
Owner: RuslanFomenko
Last update: 2026-09-17

---

## Objective

Execute DEC-0024: the pre-release audio/visual polish. Stage A is closed and
proven on device; this is the last pass before Stage C.

## Problem

Classic sits at 26.1 ms raster / 38 fps on a 120 Hz panel. Four named layers
explain 4.16 ms of a 17.67 ms gap against the benchmark stand; **76% of the
frame is still unattributed** and config F, with every candidate removed, is
still 14.7 ms above the stand. Full picture: docs/design/13_DEC0024_AUDIT_AND_STATE.md

## Constraints

**Read DEC-0024, not DEC-0023** - point 5 differs and the old wording regresses
the game. DEC-0001..DEC-0025 outrank any plan. No commits/pushes unless the
owner asks. Reviewers write only in their own journal. Boosters rejected per
DEC-0008; Tetris swipes deferred to v1.1. saplesmusic/ is reference only,
gitignored, never shipped or committed.

## Acceptance criteria

- [x] Steps 1, 1b-1j, 2, 4a, 4b, 5: accepted. Reviews 05..12.
- [x] Step 1i: well to an Image; layer-4 delta 11.35 -> -0.05 ms.
- [x] Step 1j: decomposed inside one scene; third exit branch, nothing fixed.
- [x] Step 1j(b): occupied cells rasterised; half-filled 38.35 -> 26.14 ms.
- [x] Step 1b.5: jank = max(build, raster); A/D pair on half board +0.34 ms.
- [x] Step 6: shockwave + score pops; code accepted, effect under the 2 ms cap.
- [ ] Step 1k: is the floor set by the Flame surface area? Pre-registered.
- [ ] Step 7: reproduce the Match-3 crash with a logcat before judging it.
- [x] Effects run 3.5x slower on a scaled clock; owner asked for 3-5x.
- [x] Disposed-surface crash class closed across all five render caches.
- [ ] Step 3: MusicPlaylistManager on two audioplayers, 1.2s crossfade, focus.
- [ ] Step 4c: ducking as a multiplier over the crossfade envelope (Claude).
- [ ] Unit test for the occupied-cells image cache (review 12, point 4.1).
- [ ] Frame rate held on 2209116AG, measured rather than asserted.

## Current state

**Start here: docs/design/13_DEC0024_AUDIT_AND_STATE.md** - every measurement,
every verdict and every open item in one file. It replaces reading reviews
05..12, which stay as history.
Live plan: .ai/PLAN.md. Criteria per step: docs/design/04.
Verified 2026-09-17 by Claude: analyze 0 issues, 369/369 tests, both exit 0.
Instrument resolution: ~0.7 ms between sessions, ~0.3 ms inside one. Deltas
smaller than that are not measurements.

## Active agent

- Implementer: Gemini - 1b.5 and 6 delivered; 1k pre-registered in doc 13 s.7.
- Reviewer: Claude - audited 1b.5 and 6 (checked, not redone). DeepSeek stood
  in for reviews 11 and 12 by owner instruction.
- Started: 2026-09-16

## Open questions

1. Play Console access and Blaze billing (Stage C); DEC-0018 progress-merge
   rules; DEC-0004 KPI formulas and sample sizes. All external, all unchanged.
2. DEC-0024 is committed on `dec-0024/av-polish`, eight commits, **not pushed**.
   Split by area, not by step: step isolation was no longer recoverable.
3. Do the 39 PNG receipts (~18 MB) belong in Git history, or elsewhere? They
   are in the branch; nothing is pushed, so this is still reversible.
4. Four soundtrack masters: assigned to Claude with step 3.
5. Composition: the owner called the effects 3-5x too fast; they now run at
   3.5x on a scaled clock (`kEffectTimeScale`). Slower effects overlap more,
   so whether a clear still reads as one moment is an eyes-on call on device.
6. The Match-3 crash is **not diagnosed**, only defended against. Step 7 asks
   for a logcat before anyone judges it fixed.

---

Keep this file under 80 lines. It describes the current task only.
