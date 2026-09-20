# Current Task

Status: In progress - 1k/7/cache triaged & committed; 3/4c reverted for Claude (review 14)
Owner: RuslanFomenko
Last update: 2026-09-20

---

## Objective

Execute DEC-0024: the pre-release audio/visual polish. Stage A is closed and
proven on device; this is the last pass before Stage C.

## Problem

Classic sits at 26.1 ms raster / 38 fps on a 120 Hz panel. Step 1k proved stand
floor was low due to 360x360 canvas (expanded stand reached 31.55 ms). Frame
budget closed on release baseline numbers (26.1 ms / 38 fps).

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
- [x] Step 1k: stand floor 7.85 -> 31.55 ms on Classic canvas; 1k.2 regressed; closed at 26.1/38.
- [x] Step 7: bounded sfx ring; live 11-combo pass. crash.txt and 20-min protocol not attached.
- [x] Effects run 3.5x slower on a scaled clock; owner asked for 3-5x.
- [x] Disposed-surface crash class closed across all five render caches.
- [ ] Step 3: MusicPlaylistManager (Claude, DEC-0024 p.8; prototype reverted per review 14).
- [ ] Step 4c: ducking multiplier over crossfade envelope (Claude, with music layer).
- [x] Unit test for the occupied-cells image cache (review 12, point 4.1).
- [x] Frame rate held on 2209116AG, measured rather than asserted.

## Current state

**Start here: docs/design/13_DEC0024_AUDIT_AND_STATE.md** (audit) and
**docs/design/14_DEC0024_STEPS_1K_7_3_4C_REVIEW.md** (review 14).
Live plan: .ai/PLAN.md. Criteria per step: docs/design/04.
Triage verified: analyze 0 issues, 380/380 tests, validator OK.

## Active agent

- Implementer: Gemini - 1b.5, 6, 1k, 7; triage session 2026-09-20.
- Reviewer: Claude - audit 13; DeepSeek - review 14 (1k, 7, 3, 4c, status).
- Started: 2026-09-16

## Open questions

1. Play Console access and Blaze billing (Stage C); DEC-0018 progress-merge
   rules; DEC-0004 KPI formulas and sample sizes. All external, all unchanged.
2. `dec-0024/av-polish`: ten commits, **not pushed**; 1k/7/cache committed in triage.
3. Steps 3 and 4c (music layer compliance & ducking) assigned to Claude (DEC-0024 p.8).
4. Four soundtrack masters: assigned to Claude with step 3.
5. Composition: slower effects overlap more, so whether a clear still reads
   as one moment is an eyes-on call on device.

---

Keep this file under 80 lines. It describes the current task only.

