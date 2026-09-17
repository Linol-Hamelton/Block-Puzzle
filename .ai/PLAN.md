# Development Plan

Status: Approved by owner RuslanFomenko.
Governing decisions: **DEC-0024** (scope; supersedes DEC-0023 - point 5 differs
and the old wording regresses the game) and **DEC-0025** (execution model, set
on the calibration evidence).
Acceptance criteria per step: docs/design/04_DEC0024_ACCEPTANCE_CRITERIA.md
Reviews: docs/design/05_DEC0024_STEP12_REVIEW.md (steps 1-2),
docs/design/06_DEC0024_STEP1BC5_REVIEW.md (steps 1b, 1c, 5)
Review behind the scope: docs/design/03_AV_OVERHAUL_REVIEW_2026-09-16.md

## Objective

Land the DEC-0024 pre-release polish: an AAC-LC soundtrack that can actually
ship, a harmonic sound response, fair piece generation, a predictable drag
grip, and a shockwave - without spending the frame budget that pays for them.

## Where this stands

**Consolidated state, all numbers, all verdicts:
docs/design/13_DEC0024_AUDIT_AND_STATE.md.** Read that before this file; it
replaces reviews 05..12, which stay as history.

- **Accepted:** 1, 1b-1j, 1j(b), 1b.5, 2, 4a, 4b, 5, 6. Audio 577,377 bytes.
- **Open:** 1k (the unexplained floor), 3 and 4c (Claude), one missing unit
  test, and whether DEC-0024 gets committed at all - nothing of it is in Git.
- Classic runs at **26.1 ms raster / 38 fps** on a 120 Hz panel, half-filled.

## Approach

### Now - the frame budget question

**Narrowed, not answered.** Every number is in doc 13; the short version:

- The mechanism found in 1g-1i is real and paid twice. `canvas.drawPicture`
  re-executes a command list every frame; rasterising into an `Image` and
  blitting it removed the board well (+11.35 -> -0.05 ms) and then the occupied
  cells (half-filled board, 38.35 -> 26.14 ms). The look was never the price.
- **But the four named layers explain 4.16 ms of a 17.67 ms gap.** Config F,
  with all of them removed, still costs 22.57 ms against the stand's 7.85.
  Classic's raster p50 has stayed inside 22.6-26.3 ms through every
  configuration tried, while the drawing inside them varied by multiples.
  A number that does not move when the work is removed is not measuring
  that work.
- **1k, pre-registered (doc 13, section 7).** The stand draws its `GameWidget`
  in a 360x360 box; Classic gives it the full screen height and offsets the
  board with viewport insets. Two surfaces of different size were being
  compared all along. Hypothesis: on a tiled GPU the floor is set by the area
  and count of full-screen composited layers, not by draw calls. Falsification
  threshold and exit rule are written down; if it fails, the frame budget
  closes at 26.1 ms / 38 fps and that is the release figure.
- **Instrument resolution: ~0.7 ms across sessions, ~0.3 ms within one.**
  Anything smaller is not a measurement. This is why step 6's raster delta
  reads as "below the noise floor", not as "+0.15 ms".

### In parallel - not blocked by the above

**3. Soundtrack and MusicPlaylistManager (Claude).** Four 2.5-4 minute tracks
in the Parkan register, generated locally (Stable Audio 3 Medium reaches 380s,
so length is not the blocker; arrangement and mastering are their own work).
`MusicPlaylistManager` on two `audioplayers` players - never on
`FlameAudio.bgm`, which is a single instance and cannot cross-fade. One global
playlist that survives navigation; 1.2s equal-power crossfade; audio focus
respected.

### Done

**5. Classic fairness and grip - accepted.** Fair Bag guarantees the first
piece of a dealt triplet is placeable at deal time; the drag anchor centres
horizontally only and `_touchDragLiftPixels = 50` is untouched.

### After the frame budget is understood

**4a, 4b - done and accepted.** Seven pentatonic samples by deterministic
semitone resampling, ladder with a 2.5s reset on an injected clock, and a
two-component placement hit auditioned on speaker and headphones separately.
**4c** - ducking as a multiplier over the crossfade envelope, never a direct
volume set: Claude, with the music layer.

**6. Shockwave and score numbers - delivered, code accepted.** Vector ring from
the centroid, `clipRect` with antialiasing off, no `saveLayer`, no shader, no
blur; the score text lays out once in the constructor; both self-remove after
0.8 s. Wired to real clears at `block_puzzle_game.dart:347` - one ring and one
number per event, not per cell - and the `_pulse` slot is untouched.
**The 2 ms cap holds, as an upper bound from noise rather than a measurement**:
with 8 simultaneous events the raster deltas were +0.15 / +0.12 / -0.67 ms,
all inside the instrument's resolution, and fps went *up*, which no real cost
does. The resolvable cost is on the UI thread: **+0.96 ms build**. Audit: doc 13
section 5.

**7. Composition rule:** one event, one hero effect. A clear now fires flash,
shockwave, score pop and burst, plus a combo pulse on a streak - four or five
on one beat. No frame risk; an eyes-on call for the owner. Scope bounds:
boosters rejected per DEC-0008; Tetris swipe controls deferred to v1.1.

## Who does what

Per DEC-0025:

- **Gemini implements; Claude reviews** against criteria written before the step.
- **Producing and concluding are separate.** The implementer reports raw
  numbers, the method and the measurement window - not a verdict. The reviewer
  draws the conclusion. The first edition of the criteria asked for a
  "baseline in the journal" and that wording invited the interpretation that
  went wrong.
- **A defect class caught twice is fixed in the tool.** Hence the fps readout
  in 1b.3 rather than another line on a reviewer's checklist.
- **Experiments are pre-registered** where a measurement tests a hypothesis.
- **Claude keeps the music layer** - two players, one volume authority, audio
  focus and disposal is the class of bug that passes every test and fails on a
  player's phone.
- **Each review records whether it checked or redid.** Checking is cheap and
  the split pays. Redoing is not. Running tally: step 2 checked, step 1 partly
  redone; 1b, 1c, 5, 1d-A, 1d-B, 1e, 4a, 4b, 1f-A, 1f-B, 1g, 1h, 1i, 1j, 1j(b),
  1b.5 and 6 all checked. One partial redo in twenty steps. The split is paying:
  four conclusions have been corrected by review without a single remeasure.
- **Batch size follows independence, not the last score.** The batch is five
  because it holds two tracks that cannot block each other - frames (1d, 1e)
  and audio (4a, 4b) - not because the previous three went well. Five
  interdependent steps would still be one step at a time.

## Alternatives considered

Recorded in DEC-0024 and DEC-0025: Ogg Vorbis (no native iOS decode), WAV music
(~139 MB, past Play's cap), one implementer without a checkpoint (answers a cost
question by assumption), and carrying on with 4-6 before the frame question
(DEC-0024 put measurement first for exactly this reason).

## Risks

- **76% of Classic's frame is unattributed.** Two attributions have already
  been withdrawn - the chrome, and "the gems are free". The risk is a third.
  Mitigated by measuring inside one scene, by the additivity check, and by 1k
  carrying a falsification threshold that ends the hunt rather than extends it.
- **Nothing of DEC-0024 is in Git.** Two days, ten steps, eight reviews, every
  on-device measurement and 39 receipts live only in the working tree, on a
  branch 28 commits ahead of origin. One `git clean -fd` ends it. It also means
  no step can be isolated by diff, which both recent reviews had to work around.
  Only the owner can authorise the commits that would mitigate this.
- **Effect collision.** Tetris clears (380ms, 680ms for a Tetris) and Match-3
  cascades (300/230ms with falloff) are already staged. Six effects on one beat
  is noise. Mitigated by step 7 and the one-number-per-step rule.
- **Volume with two writers.** Crossfade and ducking both write it; a duck
  landing mid-crossfade can strand a track at a wrong level. Mitigated by
  making ducking a multiplier over the envelope.
- **Reviewer as a single point of judgement.** Claude writes the criteria,
  reviews against them and draws the conclusions. Mitigated by raw numbers
  going to the owner as well, and by conclusions living in documents rather
  than in a head.
- **Third-party audio.** saplesmusic/ holds 39 MB of the Parkan OST (Nikita
  Ltd). Stylistic reference only, gitignored, never shipped, transcoded or
  committed.

## Implementation steps

Per step: change, test, measure on device, screenshot, report raw numbers. No
step starts before its acceptance criteria exist; no step is reported done
without a measurement taken with the corrected instrument.

## Validation

- Every measurement carries its own self-check: `1000 / raster_p50` against the
  observed fps. A gap over 1.5x means the measurement is void.
- Audio assets <= 15 MB; APK/AAB size recorded before and after.
- Fair Bag: a deal against a crowded board never yields a triplet whose first
  piece cannot be placed, across many seeds.
- Drag anchor: the horizontal anchor centres on the bounding box and the
  vertical lift is unchanged.
- Pentatonic ladder: step order and the reset rule.
- `flutter analyze --fatal-infos --fatal-warnings` exit 0; full suite green.

## Review

Proposals were reviewed against the code at d5ae947, not against the playtest
they were written from; roughly half of the gameplay section was already
implemented and is excluded. Steps 1-2 were reviewed against criteria written
before them, which is what made the impossible baseline visible in one pass.

Read the full file before changing architecture or contracts.
