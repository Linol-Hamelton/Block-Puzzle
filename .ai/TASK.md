# Current Task

Status: In progress - W1 code + device continuity done (design/15); audible/call, F2, masters pending
Owner: RuslanFomenko
Last update: 2026-09-21

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
- [ ] Step 3: MusicPlaylistManager (Gemini, DEC-0026; prototype reverted per review 14).
- [ ] Step 4c: ducking multiplier over crossfade envelope (Gemini, with music layer).
- [x] Unit test for the occupied-cells image cache (review 12, point 4.1).
- [x] Frame rate held on 2209116AG, measured rather than asserted.

## Current state

**Start here: docs/design/13_DEC0024_AUDIT_AND_STATE.md** (audit) and
**docs/design/14_DEC0024_STEPS_1K_7_3_4C_REVIEW.md** (review 14).
Full repo audits: docs/audit/06 (DeepSeek), 07 (Claude; dissents on the
frame-rate gate, adds D1-D6), 08 (Gemini), 09 (adversarial review; forks F1-F7).
Next stage started: W1 review docs/design/15 (PASS WITH CONDITIONS); plan ed.3, DEC-0026/0027.
Live plan: .ai/PLAN.md. Criteria per step: docs/design/04.
Verified: analyze 0 issues, 392/392 tests, validator OK (review design/15).

## Active agent

- Implementer: Gemini - W1 steps 3/4c implemented; reviewed by DeepSeek (design/15).
- Reviewer: DeepSeek (owner-approved 2026-09-21, DEC-0027) - criteria, code review.
- Reviewer: Claude - audit 13; DeepSeek - review 14 (1k, 7, 3, 4c, status).
- Started: 2026-09-16

## Open questions

1. Stage C frozen by DEC-0026 (ad-free, no monetization for now); DEC-0018
   progress-merge rules; DEC-0004 KPI formulas and sample sizes remain open.
2. `dec-0024/av-polish`: ten commits, **not pushed**; 1k/7/cache committed in triage.
3. Steps 3/4c: code PASS WITH CONDITIONS (docs/design/15); device continuity
   verified; open: owner audible/call check, F2 focus-loss sync, masters.
4. Four soundtrack masters: with Gemini; not delivered yet (W1 open item).
5. Composition: slower effects overlap more, so whether a clear still reads
   as one moment is an eyes-on call on device.
6. Stage C boundaries (audit 06, section 4): Google Sign-In linking (DEC-0018),
   verifyPurchase service account, utility_tools_pass vs DEC-0008, Classic
   game_id, scoped services (DEC-0016), widget tests, localization.

---

Keep this file under 80 lines. It describes the current task only.

