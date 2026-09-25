# Worklog Archive

Cold storage for worklog entries moved out of `.ai/worklog/`. Never trimmed,
never summarized away.

Entries keep the exact text they had when they were current. Add the agent name
and the date they were archived; change nothing else.

Information needed to understand an accepted decision belongs in
`.ai/DECISIONS.md`, not here. This file is history, not authority.

---

## Archive

### From .ai/worklog/antigravity-addff8667515dfd9.md, archived 2026-09-25

## 2026-09-25 - Track B.1: Tetris Flame VFX Juice & Celebration Adoption

Agent: antigravity-addff8667515dfd9

Action:
1. Integrated VfxDirector into TetrisFlameGame: attached camera viewfinder, BurstField particle bus, Reduced Motion gating, and camera shake / zoom punch feedback.
2. Wired TetrisEvent pipeline to VfxDirector:
   - LineClear: dispatches LineClearedVfxEvent with cleared row centroids, ShockwaveRingComponent, LineClearFlashComponent, ScorePopComponent, and 4-line 'TETRIS!' ComboPulse with 45ms hit-stop.
   - Lock / HardDrop: captures last locked tetromino cells and dispatches PiecePlacedVfxEvent with LandingSquashComponent and landing dust burst; triggers ScreenShakeVfxEvent with zoomPunch.
   - PerfectClear: dispatches AllClearVfxEvent with fanfare fireworks and 60ms hit-stop freeze.
   - Combo / TSpin / LevelUp: dispatches verbal tier ComboPulseComponent and camera punch.
3. Implemented PieceAuraShader on falling active piece and ghost piece aiming footprint: calculates screen-space bounding boxes and renders organic chromatic glow envelope.
4. Integrated CelebrationDirector celebration badge into TetrisGameOverCard for New Record flair.
5. Added comprehensive test suite in test/unit/features/tetris/tetris_vfx_test.dart covering VfxDirector attachment, LandingSquash, LineClear, AllClear, shader rendering, and celebration badges (7/7 tests passing).

Result:
- flutter analyze --fatal-infos --fatal-warnings: exit 0 (0 issues).
- flutter test --no-pub: exit 0 (522/522 tests passing, +7 new tests).
- validate-protocol.ps1: exit 0 (0 warnings, 28 decisions verified).

Next step:
- Record protocol handoff evidence with protocol-handoff.cjs.
- Release cooperative lock.
- Human owner reviews, commits, and pushes changes.

Open:
None.

Evidence:
- anchor: 758e63e01eca5362d18b8e88cf17195efead8317, uncommitted changes present
- digest: sha256:4bd22044d73a585423da5cce5b27cc669d99443a594ebd46765ca2a65790acc5 over 569 tracked and untracked files
- digest format: 4
- recorded: 2026-09-25T02:09:32.450Z by antigravity-addff8667515dfd9
- entry: sha256:b20fe69f0578d3befbe9a2cad47ab4ae4b4b5e7b3dcd62ca3583b816adb615d5 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify


## 2026-09-25 - Flame VFX Juice: Feedback Calibration & Multi-Game Tech Debt Formalization

Agent: antigravity-addff8667515dfd9

Action:
1. Formalized multi-game VFX adoption technical debt matrix across Classic, Tetris, and Match-3 in docs/design/02_VFX_JUICE_RESEARCH_PLAN.md.
2. Updated .ai/PLAN.md with Track A (Feedback Calibration) and Track B (Multi-Game Adoption Tech Debt) tasks and criteria.
3. Implemented strongly-typed VfxHapticLevel enum (light, medium, heavy, doubleHeavy) in apps/mobile/lib/ui/effects/vfx_events.dart.
4. Integrated calibrated tactile feedback directly into VfxDirector:
   - Piece drop: triggers medium impact synchronously with LandingSquashComponent and SFX.
   - Line clear: tiered haptics (light for 1-2 lines, medium for 3 lines, heavy for 4+ lines) and synchronized 45ms hit-stop freeze.
   - Combo streak: tiered haptics (medium for streak >= 3, heavy for streak >= 6) and 45ms hit-stop for streak >= 4.
   - All Clear: doubleHeavy impact and 60ms hit-stop freeze.
5. Refactored BlockPuzzleGame to route all tactile feedback via VfxDirector.onHapticFeedback, eliminating vibration race conditions and dropped pulses.
6. Added unit test in apps/mobile/test/unit/ui/effects/vfx_director_test.dart verifying calibrated haptic tiers and events.

Result:
- flutter analyze --fatal-infos --fatal-warnings: exit 0 (0 issues).
- flutter test --no-pub: exit 0 (515/515 tests passing, +1 new test).
- validate-protocol.ps1: exit 0 (0 warnings, 28 decisions verified).

Next step:
- Record protocol handoff evidence with protocol-handoff.cjs.
- Release cooperative lock.
- Human owner reviews, commits, and pushes changes.

Open:
None.

Evidence:
- anchor: 8883735c5f7d7d81d073a0ccb631a633408b19dc, uncommitted changes present
- digest: sha256:a798116fc00f80ca3153d5c5f788fd279e8dfc27584aa54a61dc8a1f1013e4e6 over 568 tracked and untracked files
- digest format: 4
- recorded: 2026-09-25T01:38:23.271Z by antigravity-addff8667515dfd9
- entry: sha256:0a72f66d6ff14277c74a26016fbbd7e1a5320a10b095e4a088aa0b51fa43a839 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify


### From .ai/worklog/deepseek-5f13ae54cae74a62.md, archived 2026-09-16

## 2026-09-16 - Independent review of the DEC-0022 round and the F1-F7 closure

Agent: DeepSeek / deepseek-5f13ae54cae74a62.

Action: Owner asked for an assessment of the recent work, of the other agents'
comments and proposals, of plan execution, and for my own improvement
proposals. Read AGENTS.md, TASK, PLAN, DEC-0001..0022, the Codex audit 05, the
journals of Claude (bd0bce05, 12aa5b86, c92f79aa), Codex (53895f33) and Gemini
(a9fddb23), plan 14, and the code the claims point at. Re-ran the checks myself
rather than trusting the journals. No product code, no shared document and no
other journal was modified.

Result: The F1-F7 closure is real and I reproduced the evidence for it, with
three exceptions noted below. Strict analyze exit 0; flutter test exit 0, 322
tests; validate-protocol.ps1 exit 0, 0 warnings, 22 decision blocks.

Verified as genuinely closed:
- F1: firestore.rules now accepts the real envelope
  `{progress: <snake_case map>, lastSyncUtc}` with per-field type checks and
  explicit denial of `economy_state.owned_product_ids` /
  `cosmetics_state.unlocked_skin_ids`. The invented camelCase fixture is gone.
- F2: both workflows decode `google-services.json` from a secret before Gradle,
  and mobile-ci.yml now has a `firestore-rules` job with a JDK 21 emulator run.
- F3: `GameModeAvailability` + `ModeGate` exist, the home screen hides disabled
  modes, and the gate wraps the screen so a direct route cannot bypass it.
  Daily Challenge is correctly gated on Classic.
- F4: `_readActivatedValues()` reads the SDK's persisted activated values before
  the network attempt and merges over defaults; a failed fetch degrades to the
  last known good config, not to the bundled binary values.
- F5: the unrunnable `flutter build web` target is gone from CI.
- F6: Tetris snapshot v2 carries the 7-bag, Match-3 v2 carries the spawner, and
  both restore the generator before anything can draw from it.
- F7: every `String.fromEnvironment` in AppConfig is now a const literal.

Still open, and I disagree with the TASK wording on two of them:
- F3 is only half closed. `GameModeAvailability` is a `registerSingleton` built
  from `bootstrapConfigReader`, which is a snapshot taken once at startup from
  `getCached()`. Nothing refreshes it after a fetch. Codex found this; it is
  still true. A mode disabled remotely takes effect only on the next cold start,
  and a Tetris/Match-3-only player has no fetch path at all, because the only
  `fetchLatest` caller is the Classic controller. The kill switch therefore
  works in the direction that matters least (it can close a mode, eventually)
  and not in the direction an operator needs (close it now, on a running
  install).
- F5 is only half closed. The web target was removed rather than fixed, which is
  the right call, but `firebase_options.dart` still throws `UnsupportedError`
  for every non-Android platform and the README still advertises RuStore. The
  supported-target list is now implicit in a workflow file instead of stated.
- The audit's own item 5 stands: `test/widget_test.dart` is still
  `expect(true, isTrue)`. 322 tests is a large number that proves the domain
  layer and proves nothing about a tap, a navigation or a restore.
- The audit's item 2 stands: `iap.rewarded_tools_unlimited_enabled` is true in
  the bundled defaults and `utility_tools_pass` is in the local catalog and in
  the Google Play service, against DEC-0008's cosmetics-only rule.
- The audit's item 3 stands: Classic `game_start`/`game_end` carry `mode` but no
  `game_id`, while Tetris and Match-3 carry `game_id`. Any per-mode comparison
  built on these events is comparing two different schemas.

On the other agents' work. Claude's two crash fixes are the strongest single
piece of work in this round: a reserved Firebase event name that threw out of
initialization and killed the board subtree, plus a lazy iterable passed to
`removeAll`. Both were found by reading logcat on a device, not by reasoning,
and both are now defended in three layers (rename, validator refusal, catch in
the tracker). The `glass_board.dart` consolidation is also correct in shape:
one material, one field, socket strength as a parameter, and the observation
that the figure and the ground were inverted is a real diagnosis rather than a
style preference. Gemini's proposals (ghost piece, lock delay, idle hints,
compact HUD) are sound and mostly cheap; I would take the ghost piece and the
HUD compaction first and leave the audio work until the DEC-0019 set exists.
Codex's audit is the most valuable document in the repository: it is the only
place where a claim was checked against a real serialized payload instead of a
fixture, and it found the one defect (F1) that would have silently destroyed
player progress.

My disagreement with the round as a whole: DEC-0022 authorized gameplay depth
before the release proof, and the round then spent its budget on presentation
(one material, three games, staged timings) rather than on the two things that
are still unproven and that no amount of polish substitutes for - a release
build that resolves production adapters, and one completed purchase. The
visual pass is good work and I would not revert it, but the acceptance criteria
in TASK have been reordered so that the cheap, visible, self-verifiable items
are checked and the expensive, externally-blocked ones are not. That is the
same pattern DEC-0006 was written about.

Next step: My proposals, in the order I would take them, are in the review
message to the owner. The first three are: refresh mode availability after a
fetch and give every mode a fetch path; make Classic emit `game_id`; and
replace the widget-test stub with three real scenarios (open each mode, place a
move, restore after a kill). None of them needs Blaze, Play Console or a device
matrix, so none of them is blocked by the external dependencies the round has
been waiting on.

Open: I did not run a device, a release APK, a Play sandbox purchase, a live
Firestore readback or the Firestore emulator myself; those remain unverified by
me and I make no claim about them. Frame timing is still unmeasured, as Claude
states. The README, `05_IMPLEMENTATION_STATUS.md` and PLAN still describe the
pre-DEC-0022 state (196 tests, stage 0, "Classic only"), which the audit already
flagged and which is still true. I did not take the shared-document lock and did
not edit TASK, PLAN, DECISIONS or ARCHIVE.

Evidence:
- anchor: 261a2cba4c00ce5cd51f0220f02bf8a664b5b5cc, uncommitted changes present
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0, 0 warnings, 22 decision blocks
- flutter analyze --no-pub --fatal-infos --fatal-warnings: exit 0
- flutter test --no-pub: exit 0, 322 tests

---

## Archiving procedure

Two different limits, two different operations.

A journal passed its 150-line limit:

1. Cut its oldest entries.
2. Paste them below, under a heading naming the journal and the archive date.
3. Leave the newest entries in place, enough to explain the current state.

`.ai/worklog/` passed 30 files:

1. Pick the oldest journals whose sessions have ended. A journal is closed when
   no lock names it and its newest entry carries evidence or a Next step that
   the following session already acted on.
2. Move each closed journal here whole, heading and all, then delete the file.
   Moving entries out of a journal never reduces the file count; only this does.
3. Ownership does not block this. The rule against writing to another session's
   journal protects a live session; a closed journal is archived by whoever
   holds the shared-document lock.

Never rewrite an entry while moving it.

## Archived 2026-09-14 from .ai/worklog/claude-bd0bce05de513f55.md

Moved to keep that journal under its 150-line limit. Text unchanged.

## 2026-09-14 - Development plan, then review of the Codex plan

Agent: Claude / claude-bd0bce05de513f55.

Action: Read TASK/PLAN/DECISIONS, both journals, and the roadmap, audit, ADR,
architecture and operations docs; verified state against code and Git instead of
docs. Ran flutter analyze and flutter test on the product tree. Wrote
docs/roadmap/12_DEVELOPMENT_PLAN_2026-09-14.md. The shared lock was held by
codex-d56f1c2c371b35a6 at the time, so .ai/PLAN.md and .ai/TASK.md were left
untouched until that session released it. Then cross-checked the Codex
deliverable (plan 13) against code and recorded the review in plan 12 section 9,
TASK.md open questions 7-11, and .ai/PLAN.md.

Result: analyze exit 0; flutter test exit 0, 196 tests passed, on 357300c.
Validator passed with 2 warnings before edits. Verified: origin/main is at
50e008a (PR #42/#43 merged), so plan 12's first-draft claim that main had not
moved since April was wrong and is corrected; db8d05e (review batch 2) is still
not an ancestor of HEAD. Confirmed four findings of plan 13 that plan 12 and the
June audit both missed - neither workflow passes --dart-define, so
AppConfig defaults to APP_ENV=dev/APP_FLAVOR=debug and a released build would
resolve DebugIapStoreService, DebugAnalyticsTracker, InMemoryRemoteConfigRepository
and NoopCrashReporter; applicationId com.blockpuzzle.game vs server default
com.luminablocks.app; TetrisEngine.toSnapshot omits the 7-bag; no firestore.rules
in the repo. Also confirmed Match3Engine.moveLimit defaults to 30, so plan 12's
endless framing of DEC-0005 was wrong and is fixed. Product code unchanged; no
commits, no pushes.

Next step: owner consolidates plans 12 and 13 into one document and records
DEC-0001..DEC-0005; then start with the release-adapter fix and branch
convergence before any new feature work.

Open: the line-ending-only diff this session's test run left in
data/dashboards/internal_playtest_run_001_metrics.json was restored by the owner
after the permission classifier blocked git checkout here. Nothing verified on
device, in Play Console or in the cloud; both plans remain static plus unit-test
evidence only. DECISIONS.md is still empty.

Evidence:
- anchor: 357300ccddff7f7c62bda8639dc966419442453a, uncommitted changes present
- digest: sha256:3fdb222bd3e8d33198beef1c76d8b12595b48dd552fb487e26c4a6214c5a61f9 over 431 tracked and untracked files
- digest format: 4
- recorded: 2026-09-14T13:34:33.959Z by claude-bd0bce05de513f55
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-14 from .ai/worklog/claude-bd0bce05de513f55.md (2)

Moved to keep that journal under its 150-line limit. Text unchanged.

## 2026-09-14 - Owner decisions recorded; executor recommendation

Agent: Claude / claude-bd0bce05de513f55.

Action: Presented every open question from both plans to the owner, split into
self-contained proposals and genuine forks. The owner ruled on all ten forks.
Took the shared lock and wrote the rulings into .ai/DECISIONS.md as DEC-0001 to
DEC-0008, each with context, reasoning, rejected alternatives and consequences.
Updated .ai/TASK.md: resolved questions moved out, six left open. Added a note
to section 6 of plan 12 that the draft DEC numbering there is superseded by the
decision log.

Result: validate-protocol.ps1 passes with 0 warnings and reports 8 decision
blocks; the earlier "no numbered decisions recorded yet" warning is gone.
TASK.md is 70 lines, DECISIONS.md 303, both LF and BOM-free. Two forks were not
ruled on and stay open: closed-test composition, and the early-gameover
definition for move-limited Match-3. The first-store question was deferred by
the owner, with Google Play kept as the estimation baseline. The 17
self-contained proposals are still unapproved. No product code changed.

Next step: owner approves or amends the self-contained block, then merges plans
12 and 13 into one document with stages A and B as the spine. First code work
is DEC-0007 (release adapters) together with the branch convergence.

Open: Executor assignment. The owner asked which of the two agents has more
capability for the work. Honest answer: neither of us can see the other quota,
model or cost, so the owner is better placed to weigh that; what is observable
from this session is the split below.
- Codex read cross-file runtime contracts better. It found the missing
  --dart-define chain across workflow, AppConfig and di_container, the
  client/server package mismatch, the unserialized 7-bag and the absent
  Firestore rules. That is exactly the skill stage A needs: release wiring,
  billing, config.
- Claude ran the toolchain directly with no sandbox escalation (analyze, 196
  tests, validator), and caught the A6/B1 dependency cycle and the premature
  Completed task status. That suits the seam and registry work, test writing,
  and document reconciliation.
- Recommendation: Codex executes stage A, Claude executes stage S0 convergence,
  the registry/flag seam and the test and document work; each reviews the other
  before handoff. Both mistakes found this session were found by the reviewer,
  not the author, so a single-executor arrangement loses the mechanism that
  caught them.

Evidence:
- anchor: 357300ccddff7f7c62bda8639dc966419442453a, uncommitted changes present
- digest: sha256:1c834d8f09d19ee5c95e379f1753148c6d21c3728cf85d0bc3717b6b52af95b0 over 431 tracked and untracked files
- digest format: 4
- recorded: 2026-09-14T13:53:53.915Z by claude-bd0bce05de513f55
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-14 from .ai/worklog/claude-bd0bce05de513f55.md (3)

Moved to keep that journal under its 150-line limit. Text unchanged.

## 2026-09-14 - Remaining answers recorded; Firebase and asset docs

Agent: Claude / claude-bd0bce05de513f55.

Action: Put every still-open question to the owner and recorded the answers.
Under the shared lock, appended DEC-0009 to DEC-0015 covering package identity,
closed-test composition, the Match-3 metric, first store, the execution model,
the device matrix and the seventeen-item work block. Updated .ai/TASK.md to
Planned. Wrote docs/operations/17_FIREBASE_PROJECT_SETUP.md, the console and CI
procedure for a Firebase project that does not exist yet, and
docs/operations/18_AI_ASSET_TOOLING_SURVEY.md, a web-researched survey of AI
image and audio tooling to replace an artist.

Result: validator passes, 15 decision blocks inspected, 0 warnings. TASK.md 69
lines, DECISIONS.md 543, all authored files LF and BOM-free. Owner answers as
recorded: all 17 self-contained items approved; identity moves to the
luminablocks.ru domain; no Firebase project exists; closed test ships three
modes; early game-over is not applied to Match-3; Google Play first; the
two-agent split accepted with Claude primary and Codex auxiliary; a Play
developer account exists; the device matrix is one personal Redmi plus
emulators; art and audio to be produced by AI tooling. No product code changed.

Next step: merge plans 12 and 13 into one document, then start S0 branch
convergence and DEC-0007. Codex takes stage A per DEC-0013; the owner performs
the console steps in sections 1, 2, 6 and 8 of the Firebase document.

Open: The exact applicationId string needs confirming before any distribution
build - DEC-0009 derives ru.luminablocks.game from the domain the owner named,
and reverse-DNS is the Android convention, but the literal string the owner
wrote was luminablocks.ru. After the first upload it can never change. Also
open: no AI asset tool is adopted, and the survey found conflicting reports on
Leonardo AI commercial rights, so terms must be read before anything ships. A
Blaze billing account is still required before Cloud Functions can deploy. Every
MCP server in this session failed to connect, so MCP-based tooling is unproven
here.

Evidence:
- anchor: 357300ccddff7f7c62bda8639dc966419442453a, uncommitted changes present
- digest: sha256:516eba541ed254aabfc080090079570631f7c679e2f400cab80465fff1a211c2 over 433 tracked and untracked files
- digest format: 4
- recorded: 2026-09-14T14:58:57.591Z by claude-bd0bce05de513f55
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-14 from .ai/worklog/claude-bd0bce05de513f55.md (4)

Moved to keep that journal under its 150-line limit. Text unchanged.

## 2026-09-14 - Emulator choice, applicationId gate, models for this hardware

Agent: Claude / claude-bd0bce05de513f55.

Action: Read the host machine hardware directly rather than assuming it, then
researched three owner requests. Wrote docs/operations/19_EMULATOR_AND_DEVICE_MATRIX.md
and section 5 of docs/operations/18_AI_ASSET_TOOLING_SURVEY.md. Added a blocking
section 0 to docs/release/03_PUBLISH_EXECUTION_CHECKLIST.md for the irreversible
applicationId, preserving that file pre-existing BOM rather than reformatting it.
Rotated the oldest entry of this journal into .ai/ARCHIVE.md to stay under the
150-line limit; the text was moved unchanged.

Result: Hardware measured - i9-13900HX 24C/32T, 31.7 GB RAM, RTX 4060 Laptop
with 8188 MiB VRAM (WMI reports 4 GB because AdapterRAM is a 32-bit field; the
real figure came from nvidia-smi), 86 GB free on C and 447 GB on D. A hypervisor
is already running, so the emulator choice is Android Studio AVD on WHPX:
Genymotion asks for Hyper-V to be off, which would break VBS and WSL2. No
Android SDK is installed. Default python is 3.14 and its PyTorch is broken on
shm.dll; 3.11 is present and usable. ffmpeg is missing. Recorded the honest
limit: this machine is far faster than a Redmi 9/10, so no emulator setting can
measure the cold-start or frame-rate gate - that stays DEC-0014 single physical
device. Model picks verified against licences rather than popularity: SDXL,
FLUX.1 schnell (Apache 2.0) and SD 3.5 Medium for images; Stable Audio Open
Small, ACE-Step (Apache 2.0) and Stable Audio Open 1.x for sound. No product
code changed.

Follow-up the same day: checked whether Stable Audio 3.0 Medium fits this GPU.
It does. The official repository table gives peak VRAM 5.07 GB at 5s rising to
6.52 GB at the 380s maximum, and chunked decoding cuts the 120s case from 6.49
to about 5.14 GB; the docs name the RTX 4060 as a supported card. Medium covers
music and SFX in one model, so section 5.2 of the survey now leads with it
instead of the Small models. The real obstacle is that Medium requires Flash
Attention 2, which installs badly on Windows - WSL2 is already enabled here
(version 2, docker-desktop distro present), so that is the recommended route.
Licence terms still have to be read at stability.ai/license before shipping.

Next step: owner confirms the exact applicationId string, then stage S0 and the
stage A work under DEC-0013 may begin. Installing the Android SDK also closes
the missing Android toolchain noted earlier.

Open: FLUX.1 dev is the variant most people download and its model licence is
non-commercial - the checklist warns about it, but nothing enforces it. No asset
tool is adopted yet and that choice still needs its own DEC. minSdk is not
pinned in build.gradle; it inherits flutter.minSdkVersion, so the min-API
emulator profile cannot be fixed until it is. Seamless music looping is not
something any of these models produce on their own and remains manual work.

Evidence:
- anchor: 357300ccddff7f7c62bda8639dc966419442453a, uncommitted changes present
- digest: sha256:d5626e6b9e24e2aade39463272e574327642069c1c43ebcfe964ec888de1911d over 434 tracked and untracked files
- digest format: 4
- recorded: 2026-09-14T15:36:08.378Z by claude-bd0bce05de513f55
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-15 from .ai/worklog/claude-bd0bce05de513f55.md (5)

Moved to keep that journal under its 150-line limit. Text unchanged.

## 2026-09-14 - Codex review processed; stage 0 consolidation

Agent: Claude / claude-bd0bce05de513f55.

Action: Read the Codex review (R1-R12) and verified its sharpest claims against
code rather than accepting them. Recorded the owner rulings as DEC-0016 through
DEC-0021, including a superseding block that corrects two factual errors in
DEC-0009 and DEC-0013 while restating both decisions. Merged plans 12 and 13
into docs/roadmap/14_EXECUTION_PLAN_2026-09-14.md per item 17 of DEC-0015 and
marked both originals superseded. Applied R1, R5-R11 to docs 17, 18, 19 and the
publish checklist. Wrote D:/AI/stable-audio-3/run_local.py. Rewrote .ai/PLAN.md
and .ai/TASK.md to match the decisions.

Result: R2 confirmed and found to be worse than reported - Firebase Remote
Config forbids dots in parameter names while the bundled defaults use them
throughout, and separately firebase_remote_config_repository.dart line 58
replaces the defaults wholesale instead of merging, so the first successful
fetch would drop every key the remote does not carry. Added as a stage A item.
R5 confirmed: run_gradio.py hardcodes share=True and never passes the parsed
--username/--password to launch(), so the upstream launcher opens an
unauthenticated public tunnel; I had recommended that command, and the
replacement launcher binds to loopback with share=False. R4 is closed by
measurement taken earlier this session. Owner answered minSdk as "99.0", which
is not a valid API level; I did not record it, found minSdkVersionInt = 24 in
the installed Flutter SDK, and recorded 24 only after the owner confirmed.
Validator: 21 decision blocks, 0 warnings; TASK 68/80, PLAN 96/200 lines.
No product code changed in this batch.

Next step: stage 0.3 - converge db8d05e with the Match-3 line and merge to main,
then stage A0 (dart-defines with a DI proof) and A3 (Remote Config key mapping
and defaults merge).

Open: Play Console access and a Blaze billing account block stage C. Progress
merge rules for account linking, KPI formulas and denominators, and weight
provenance for the media acceptance set are unresolved. Nothing on device, in a
store or in a cloud has been verified.

Evidence:
- anchor: 357300ccddff7f7c62bda8639dc966419442453a, uncommitted changes present
- digest: sha256:ca2206076f07b32c1130ea692436bd1d68d9ba7bba0309d333ca7e624a590203 over 436 tracked and untracked files
- digest format: 4
- recorded: 2026-09-14T19:33:01.224Z by claude-bd0bce05de513f55
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-15 from .ai/worklog/claude-bd0bce05de513f55.md

Moved to keep that journal under its 150-line limit. Text unchanged.

## 2026-09-14 - Stage 0.3: branches converged and merged to main

Agent: Claude / claude-bd0bce05de513f55.

Action: With the owner's explicit approval to merge and commit, committed the
documentation and protocol work, merged fix/review-followups-p2 (db8d05e) into
the Match-3 line, resolved the single conflict, fast-forwarded main, and fixed
the simulation test that was overwriting a tracked dashboard file.

Result: Three commits on main, which moved from a577485 to d46baf1 and is now
five ahead of origin/main. 37be419 carries the protocol install, DEC-0001 to
DEC-0021 and the unified plan 14; b37b730 is the batch-2 merge; d46baf1 fixes
the test. The merge conflicted only in docs/DOCS_CHANGELOG.md, where both lines
had prepended an entry; both were kept. All three lines are now ancestors of
main: db8d05e, 357300c and 50e008a all verify with merge-base --is-ancestor.
Verified on the merged tree: flutter analyze --fatal-infos --fatal-warnings
exit 0; flutter test exit 0, **200 tests** - the 196 of the Match-3 line plus
the 4 that batch 2 added. Spot-checked that the batch-2 fixes survived rather
than being silently dropped: lastLockedCells, _awardPerfectClearIfEmpty,
isGravity, revive_used and the resumed flag are all present.
run_001_metrics_generation_test now writes to a temp directory; a full test run
leaves the working tree clean, which it did not before. Two generated Windows
plugin files changed line endings during the runs and were restored rather than
committed. Nothing was pushed.

Next step: stage A0 - pass --dart-define for APP_ENV/APP_FLAVOR/APP_VERSION in
both workflows and prove in a test that DI resolves production adapters
(DEC-0007). Then A3 - Remote Config key mapping and the defaults merge.

Open: main is five commits ahead of origin and not pushed; the owner has not
asked for a push. Play Console access and a Blaze account still block stage C.
Nothing verified on device, in a store or in a cloud.

Evidence:
- anchor: d46baf1f93c7fbdd7cee300ee4efbe5f72c52090, uncommitted changes present
- digest: sha256:daddb47145b0438205852f8097c9b872984217077dfd4e97c7b02156bc7e274e over 436 tracked and untracked files
- digest format: 4
- recorded: 2026-09-14T19:40:50.698Z by claude-bd0bce05de513f55
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-15 from .ai/worklog/claude-bd0bce05de513f55.md

Moved to keep that journal under its 150-line limit. Text unchanged.

## 2026-09-14 - Stage A0-A3: release wiring, package identity, bootstrap, config

Agent: Claude / claude-bd0bce05de513f55.

Action: Implemented four plan items as four separate commits so each can be
reviewed against its plan line. A0: moved the adapter choice into
AppConfig.useDebugAdapters, added a kReleaseMode guard in configureDependencies
that throws when a release build would resolve the debug adapters, passed
APP_ENV/APP_FLAVOR/APP_VERSION in android-release.yml, and raised both workflows
to analyze --fatal-infos --fatal-warnings. A1 and A8: one package identity
ru.luminablocks.game across build.gradle applicationId and namespace, the Kotlin
package and its directory, and ANDROID_PACKAGE_NAME in the Cloud Function; pinned
minSdk to 24; declared appCategory="game". A2: main() now awaits bootstrap inside
runZonedGuarded in the same zone as the binding and runApp, and the empty catch
around Firebase.initializeApp was replaced with a firebaseReady flag, an
independent startup logger and a debug-mode assert. A3: added RemoteConfigKeyMap
and made the Firebase repository merge over the bundled defaults instead of
replacing them, with type checking against each default.

Result: flutter analyze --fatal-infos --fatal-warnings exit 0; flutter test
exit 0, **214 tests**, up from 200 - 6 new for the adapter rule and 8 for the
key map. Commits 5cba115, e3a4e9b, 2a21683, 608dfb7 on main.
A3 turned out to be two defects, not one: besides the dotted keys Firebase
cannot accept, the repository replaced the defaults wholesale on any non-empty
response, so the first successful fetch would have dropped all 54 settings at
once. Both are fixed and covered. Generated Windows plugin files changed line
endings during the runs and were restored rather than committed.

Next step: A4 - create the Firebase project and wire firebase_options.dart plus
the CI secret, which needs the owner in the console. Then A5, the function
runtime service account, and A6, Firestore rules including users/{uid}.

Open: main is now nine commits ahead of origin and nothing has been pushed; the
owner has approved merges and commits but not a push. The release-adapter guard
and the config merge are verified by unit tests only - neither has run against a
real Firebase project, a real device or a store. Play Console access and a Blaze
billing account still block stage C.

Evidence:
- anchor: 608dfb7928e00c739372e21ba27bcbc06e20fe9e, uncommitted changes present
- digest: sha256:94acf622e923d28895417cdf5c0b3de261ebbf1e7fbf619476657e12de787f35 over 439 tracked and untracked files
- digest format: 4
- recorded: 2026-09-14T19:49:35.874Z by claude-bd0bce05de513f55
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

### Archived from claude-bd0bce05de513f55 on 2026-09-15

## 2026-09-15 - Stage A4-A6: Firebase connected, rules deployed and proven

Agent: Claude / claude-bd0bce05de513f55.

Action: Built the Android toolchain from nothing - JDK 17 and Android SDK 36 on
D:, with ANDROID_AVD_HOME set separately so AVDs do not land on C:. Built the
debug APK, which created the debug keystore; extracted SHA-1 and SHA-256 for the
owner to register. Added the Crashlytics Gradle plugin, ran flutterfire
configure, and wired DefaultFirebaseOptions into bootstrap. Generated
remoteconfig.template.json from the bundled defaults and deployed it. Deployed
firestore.rules. Refetched google-services.json through the CLI once the owner
had added the fingerprints. Installed JDK 21 beside 17 for the emulator and ran
the rules suite. Moved the Gradle cache to D:.

Result: **All 16 Firestore rules tests pass against the real emulator**, so A6
is closed by evidence rather than by reading the file. Remote Config holds 57
parameters live, verified by reading them back with remoteconfig:get - 54
translated from the dotted app keys plus the 3 DEC-0002 kill switches. The debug
APK builds (153 MB, 861 s), which is the first proof that the google-services
plugin, the ru.luminablocks.game rename and all seven FlutterFire plugins work
together. google-services.json now carries two oauth_client entries, so Google
Sign-In is configured on the Firebase side. flutter analyze clean, 214 tests.
Commits 25583bb, 04b74a2, 6072987 and the ignore fix.
Two things cost time and are worth remembering: sdkmanager ignores licence
answers piped from PowerShell and needs cmd redirection from a file, and
firebase-tools refuses any JDK older than 21 while the Android build runs on 17
- both JDKs are installed and the rules README explains why the global JAVA_HOME
must stay on 17.

Next step: A5 - set the runtime service account on verifyPurchase and deploy it.
Blocked on the owner enabling Blaze. Then stage B.

Open: main is 19 commits ahead of origin and nothing is pushed. The old Gradle
cache at C:/Users/Dmitry/.gradle is 5.65 GB and can be deleted by the owner now
that D:/Gradle is in use. Crashlytics is not enabled in the console yet, and no
crash has ever reached it. Nothing has run on a physical device.

Evidence:
- anchor: f60114a1a40b2006cdfba46c4676346c2a726d1a, uncommitted changes present
- digest: sha256:027907b2bf35ec58c748887ad2f5147ea75b9ff277082511375fa8f32cf30927 over 450 tracked and untracked files
- digest format: 4
- recorded: 2026-09-15T13:44:03.495Z by claude-bd0bce05de513f55
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 1s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

### Archived from claude-bd0bce05de513f55 on 2026-09-16

## 2026-09-15 - Match-3 depth: bonus gems, the combo matrix, and rounds

Agent: Claude / claude-bd0bce05de513f55.

Action: DEC-0022 item three. Wired bonus-gem spawning into the cascade, added
the special-on-special swap matrix, and put the run on rounds that pay out
moves. Rebuilt the Tetris control layout to the owner's chosen arrangement and
separated the amber and citrine gems.

Result: The cascade now works out what each shape earned before clearing it,
detonates any effects among the matched cells through the single queue in
SpecialResolver, and writes the bonus gem back into the cell that earned it
before gravity. Combos paint the effects they imply onto the board and let that
same chain run, so there is one definition of what an effect clears and the
combos cannot drift from it; all sixteen pairings terminate on a board made
entirely of effect gems. A run opens with twenty moves; each completed round
grants six and the targets grow by four hundred a round, so the payout cannot
keep pace and no run is endless - that argument is a test, not a comment.
**One rule was backwards and nothing had caught it:** MatchGroup.reward tested
for a crossing before testing for a run of five, so a six-cell shape containing
both paid out the weaker gem. The order is now longest-run first, and the case
is pinned. Two further defects found while testing: _ensurePlayable called a
board with a colour bomb a dead end and re-rolled it, destroying the gem, and
the cascade fixture asserting a two-deep chain only chained because the L-shape
left no gem behind - the fixture was rebuilt from two plain runs so it tests
gravity and not the refill dice.
flutter analyze --fatal-infos --fatal-warnings exit 0; flutter test exit 0,
**308 tests**, up from 236.

Next step: DEC-0022 item four - the media acceptance set from DEC-0019.

Open: Round tuning is arithmetic until it is played; the numbers want a device
session. Nothing is committed and main is still far ahead of origin. Release DI,
native fatal/ANR and any purchase remain unproven, and Blaze still blocks A5.
The audit leftovers the owner deferred - session_start tied to the Classic
controller, Classic events missing game_id, utility_tools_pass live against
DEC-0008 - are still open.

Newest entry first. Limit 150 lines.

Evidence:
- anchor: 261a2cba4c00ce5cd51f0220f02bf8a664b5b5cc, uncommitted changes present
- digest: sha256:e404b0a8022c04bcfaf2177a32928c8ff6909b72b20e4acb1dd7ca69159f98a4 over 466 tracked and untracked files
- digest format: 4
- recorded: 2026-09-15T17:26:45.109Z by claude-bd0bce05de513f55
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 1s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

---


## 2026-09-15 - Codex audit F1-F7 closed; DEC-0022 authorises gameplay work

Agent: Claude / claude-bd0bce05de513f55.

Action: Read the Codex audit and verified each finding against code before
acting. Recorded the owner's approval of the gameplay round as DEC-0022,
superseding DEC-0005 and DEC-0006. Reordered the home screen and rebuilt the
Tetris control layout into thumb zones. Then fixed F1 through F7.

Result: **F1 was mine and it was serious.** The Firestore rules I wrote and
recorded as "closed by evidence" denied every cloud save the app has ever made:
the client sends {progress, lastSyncUtc} with a snake_case model inside, and I
wrote rules for a flat camelCase document that no part of this app produces. My
sixteen tests passed because I wrote the fixture from imagination rather than
from the model - the exact failure I had been calling out in other people's
work. It was invisible because _saveToCloud swallowed permission-denied as a
network blip. The fixture is now generated from PlayerProgressState by a Dart
test, entitlements are stripped before upload and rejected by the rules, and a
denied write is logged as a broken contract. 21 rules tests pass against the
emulator; rules deployed.
F7: dart-defines were lost in AOT because the key was a parameter, so
String.fromEnvironment could not be const-evaluated. F4: Remote Config reverted
to bundled defaults on every cold start; the persisted activated values are now
read on the startup path. F3: the three mode kill switches had no consumer at
all - GameModeAvailability and ModeGate close the menu and the routes, with
Daily Challenge following Classic. F2: neither workflow created
google-services.json, so a clean runner could not build Android; both now decode
it from a secret and the rules matrix runs as its own CI job. F5: the web target
is removed rather than patched - it compiled and could not start. F6: snapshots
carried the board but not the generator, so a resumed run dealt different
pieces; DeterministicRandom makes the state serialisable and both engines
version their snapshots.
flutter analyze --fatal-infos --fatal-warnings exit 0; flutter test exit 0,
**236 tests**, up from 214. Commits 514b673, 4138b05, 3bec96c, 68434c3.

Next step: DEC-0022 item three - Match-3 depth: bonus tiles from four, five, T
and L shapes, a move limit, scoring and round progression. Table-driven tests
for the detonation matrix before any animation work.

Open: main is far ahead of origin and nothing is pushed. Release DI, native
fatal and ANR, and any purchase remain unproven; the diagnostics crash button is
correctly labelled non-fatal and does not cover that path. Blaze still blocks
A5. The audit's remaining items - session_start tied to the Classic controller,
Classic events missing game_id, utility_tools_pass active against DEC-0008 - are
not addressed here.

Evidence:
- anchor: 68434c31c48f7a811ad93238a3a8c313aaa61e4b, uncommitted changes present
- digest: sha256:71771cab60f8785aa80d1d579783ea43c06f46d46cd183062bf5a85fa51d0ddd over 459 tracked and untracked files
- digest format: 4
- recorded: 2026-09-15T16:29:43.504Z by claude-bd0bce05de513f55
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 1s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

### Archived from claude-bd0bce05de513f55 on 2026-09-16 (session polish + fixes)

## 2026-09-16 - Classic was broken twice; Match-3 gems get shape as well as colour

Agent: Claude / claude-bd0bce05de513f55.

Action: Owner reported Classic hanging. Reproduced it on the Redmi over adb,
read the stack from logcat, fixed both defects it exposed, then reworked the
Match-3 board and gem rendering against what the device actually showed.

Result: **Classic did not hang - it threw, twice, and nothing caught either.**
Firebase reserves `session_start`; logEvent does not drop or rename such an
event, it throws. The throw escaped into initialization and killed the board's
widget subtree, so the mode opened to a grey error slab. Cross-checking all 32
events the app sends against the reserved list found a second one already in
place: `ad_impression`, which had not fired only because ads are switched off -
it would have taken Classic down in production the day they were enabled. Both
renamed with a `game_` prefix, `session_end` with them so the pair stays
symmetric in a dashboard. Fixed in three layers, because the defect was three:
the names, a reserved-name check in AnalyticsSchemaValidator that refuses them
before the transport, and a catch in FirebaseAnalyticsTracker so telemetry can
never again take a screen down - logged loudly, never swallowed. Docs and
dashboard_mvp_contract_v1.json described a contract that could not be met and
are updated; the spec now carries the naming rule.
The second defect surfaced only when I placed a piece myself:
`removeAll(children.whereType<MoveToEffect>())` walks a lazy view of the very
collection removeAll deletes from, so placing a piece while a return-to-home
effect was running threw ConcurrentModificationError out of the drop handler.
Three sites, all materialised with toList().
Match-3: the first rendering pass was wrong in the way the owner said. Three
stacked white passes had bleached every gem to pastel, and the gems filled 83%
of the cell and hid the sockets they were meant to sit in. Sockets are now lit
as holes, dividers are bevelled grooves rather than hairlines, and the gems
carry six distinct silhouettes so colour is not asked to carry the board alone.
Verified on device: Classic opens and accepts placements with a clean log;
Match-3 resumed a run at round seven with the progression behaving as designed.
flutter analyze --fatal-infos --fatal-warnings exit 0; flutter test exit 0,
**312 tests**, up from 308.

Next step: DEC-0022 item four - the media acceptance set from DEC-0019.

Open: Frame timing is unmeasured - gfxinfo reports no frames for this renderer,
so the cost of the new gem passes is reasoned about, not measured. Shape per
colour goes beyond what the owner asked for and is theirs to reject. Nothing is
committed and main is still far ahead of origin. Release DI, native fatal/ANR
and any purchase remain unproven, and Blaze still blocks A5. Classic
`game_start`/`game_end` still omit `game_id`, and `utility_tools_pass` is still
live against DEC-0008.

Newest entry first. Limit 150 lines.

Evidence:
- anchor: 261a2cba4c00ce5cd51f0220f02bf8a664b5b5cc, uncommitted changes present
- digest: sha256:467c00117daad876039923a931ba06a613eca167bef17e0ac59acca66f90e830 over 466 tracked and untracked files
- digest format: 4
- recorded: 2026-09-15T22:20:00.990Z by claude-bd0bce05de513f55
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 1s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

### Archived from claude-bd0bce05de513f55 on 2026-09-16 (AV review)

## 2026-09-16 - One material for three games, and effects slow enough to see

Agent: Claude / claude-bd0bce05de513f55.

Action: Owner asked for a session on the look and feel of all three games -
aesthetics, ergonomics, absorption, and effects deliberately slowed for
spectacle. Took baseline screenshots on the Redmi, worked in four stages, and
re-shot after each.

Result: Two problems ran under everything and neither was per-game.
**The figure and the ground were inverted.** Eight stacked nebula layers lit the
whole frame evenly, brighter than either playfield, so a board read as a hole
cut in a bright page rather than as the lit thing being looked at. Classic's own
field was painted at alpha 0.12 over 0.04 - not a board at all, just ambience
showing through a rounded rectangle. The ambient layer is now dimmed and
vignetted, and every field is an opaque dark well.
**Three games painted a block three ways**, and the weakest set the impression.
`lib/ui/effects/glass_board.dart` now holds both halves of the look - the well
and the glass - under two rules: light always comes from the top-left, and the
field is the darkest thing on screen. Match-3 lost 14k characters of duplicated
painting to a 4k call into it. Tetris and Classic moved onto it too; Classic's
six skins still tint the well, so they stay six skins.
The same texture needed different strengths per game, which was only visible on
a device: sockets that frame a gem on a full 8x8 board become the loudest thing
on a mostly-empty 10x20 one, so socket strength is a parameter (1.0 / 0.5 / 0.3).
**Timing was the owner's real point.** A Tetris line clear ran for 120ms - the
most valuable thing a player does went by in a blink, and a four-line clear
looked exactly like a single. It is now 380ms, 680ms for a Tetris, and the extra
time is spent on three beats (ignite, hold, collapse), not on a longer fade.
Shake scales with the clear instead of switching on at four.
Match-3 had it worse: the engine settles a whole cascade inside one call, so a
four-step chain reached the screen as one instant jump. Steps now carry their
intermediate boards and the controller plays them out, with `grid` for the rules
and `displayGrid` for the eye. Holds are uneven on purpose - the opening match
is the player's, a combo is the rarest thing in the mode, and the chain
accelerates so a deep cascade builds rather than drags. Captions and particles
moved onto the frames they describe; input is refused mid-cascade.
Verified on device at each stage. flutter analyze --fatal-infos
--fatal-warnings exit 0; flutter test exit 0, **322 tests**, up from 312.

Next step: DEC-0022 item four - the media acceptance set from DEC-0019.

Open: Frame timing is still unmeasured - gfxinfo reports no frames for this
renderer, so the cost of the added passes is reasoned about, not measured. Not
done in this session and worth doing: the Tetris Next queue is still coloured
dots, the HUDs are unstyled panels eating vertical space the boards could use,
and Classic's rack pieces stay faint. Analytics now reaches Firebase on the
playback's schedule rather than the engine's - correct for captions, and it
means a kill mid-cascade loses the tail of a move's events; saveActiveGame
flushes on pause, which covers the normal path. Nothing is committed and main is
still far ahead of origin. Release DI, native fatal/ANR and any purchase remain
unproven; Blaze still blocks A5.

Evidence:
- anchor: 261a2cba4c00ce5cd51f0220f02bf8a664b5b5cc, uncommitted changes present
- digest: sha256:be3dce77a42027229d74983a716c1e29a6df54543e562e3100830e996cd9d3d6 over 469 tracked and untracked files
- digest format: 4
- recorded: 2026-09-15T22:47:24.135Z by claude-bd0bce05de513f55
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 1s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

Newest entry first. Limit 150 lines.

---

### From .ai/worklog/gemini-a9fddb2389c5621b.md, archived 2026-09-16

## 2026-09-16 - Reconciled roadmap, simulation OOM fix, pre-clear line highlight and idle hint

Agent: Gemini / gemini-a9fddb2389c5621b.

Action: Started session under Protocol v1.9.0. Reconciled recommendations and plans from Codex (audits 04/05, F1-F7), Claude (DEC-0022 gameplay, glass_board, HUD/queue debt), decisions (DEC-0001..DEC-0022), and Gemini. Merged recommendations into a consolidated phased master plan. Implemented the most accessible and high-impact improvement session: (1) isolated the heavy simulation test with @tags(['simulation']) and updated mobile-ci.yml to prevent runner OOM, (2) implemented real-time pre-clear line and column glow highlight in Block Puzzle (Classic) during piece drag-over, (3) implemented Match-3 idle hint with subtle pulsing aura on valid swap pair after 4.5s of inactivity.

Result: Strict analyze clean (flutter analyze --fatal-infos --fatal-warnings exit 0). All 321 tests pass in 7s without OOM (flutter test --exclude-tags simulation exit 0). Verified pre-clear row/col calculation and rendering in BoardComponent and idle hint timer/drawing in Match3FlameGame.

Next step: Produce DEC-0019 media acceptance set (1 cosmetic set, 3 SFX, 1 loop) under DEC-0022 item 4; verify production DI adapters in release APK (DEC-0007).

Open: Release DI proof, Google Sign-In linking (DEC-0018), and Google Play/Blaze billing deployment remain unproven externally.

Evidence:
- anchor: 261a2cba4c00ce5cd51f0220f02bf8a664b5b5cc, uncommitted changes present
- digest: sha256:47c9c4a21628f63ac152743ba5c322d2b7266dff7e6bd2bacb718bde97a85bad over 470 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T01:20:30.708Z by gemini-a9fddb2389c5621b
- entry: sha256:aab8ed9327dab9a5ef3b0c9d68f1ccc516036848a4a958444e535e9258387a69 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify


### Archived from claude-bd0bce05de513f55 on 2026-09-16 (DEC-0024 handover)

- digest: sha256:64e7ad151a5526c68854a23b99c2c51d35e5954e91ed00026350b3cfa0495191 over 479 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T03:25:53.958Z by claude-bd0bce05de513f55
- entry: sha256:771b869489ba36549ff6557f083a099097a3866e3c8ed7c2314ce7b6a3cac235 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-16 - Review of the AV overhaul proposals; DEC-0023 drafted, not taken

Agent: Claude / claude-bd0bce05de513f55.

Action: Reviewed docs/design/02_AUDIO_VISUAL_GAMEPLAY_OVERHAUL_PROPOSALS.md as
a design/audio review rather than as a work order. Checked every proposal
against the code at d5ae947 instead of against the playtest it was written
from. Wrote docs/design/03_AV_OVERHAUL_REVIEW_2026-09-16.md and put the
proposal in .ai/PLAN.md. No product code changed.

Result: **Half of the gameplay section is already shipped.** Match-3 Laser /
Bomb / Prism gems, the idle hint, the cascade multiplier, Tetris lock delay and
DAS, floating score numbers, combo badges and screen shake all exist; the
proposals also state that an invalid Match-3 swap is silent, and it is not
(match3_controller.dart:255 plays a sound and a haptic). A DEC built on the
document as written would have authorised rebuilding working features. The
genuinely new gameplay items are Fair Bag, Tetris swipe input and boosters.
**The soundtrack section is a release blocker, not a preference.** The shipped
loop is 3.44 MB for 19.5s of 16-bit PCM - 176 KB/s. The four proposed tracks
are 790s, so ~139 MB of WAV against a ~91 MB app, which puts the AAB base
module past Play's 200 MB download cap. AAC-LC at 128 kbps is ~12.6 MB for the
same music. Ogg would be smaller still but ios/ is a declared platform and has
no native Vorbis decode, so one universal AAC set beats two platform sets.
Named the risks the document does not: six effects landing on beats that are
already staged (Tetris clears at 380/680ms, Match-3 cascades at 300/230ms with
falloff) is noise rather than juice; a track per mode means four crossfades a
minute and no track ever developing; 3.0s crossfade is long enough to be muddy;
radial distortion needs a FragmentProgram; animating NebulaBackground means
eight full-screen gradients per frame under the game, for the least visible
item on the list. Also flagged that the Reroll and Hammer boosters are economy
surface and contradict DEC-0008, so they need their own block with an explicit
Supersedes rather than riding along inside DEC-0023.
Proposed five high-impact items and the order they should run in, with
measurement first: frames are still unmeasured because gfxinfo reports none for
this renderer, and adding VFX without an instrument is how 60fps quietly
becomes 45.
flutter analyze --fatal-infos --fatal-warnings exit 0; flutter test exit 0,
328 tests.

Next step: owner decides on the DEC-0023 draft in .ai/PLAN.md, and separately
on whether boosters are wanted at all given DEC-0008.

Open: DEC-0023 is a proposal and not a decision. The two questions that need
the owner and not an agent are the audio format (it gates the whole soundtrack)
and the DEC-0008 conflict. Frame timing remains unmeasured. Nothing is
committed and main is 28 ahead of origin.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:bb9ff9085b54a5fcb95a43bc62422004b4f7847519aa5d7717a017b3c826f811 over 482 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T02:57:08.445Z by claude-bd0bce05de513f55
- entry: sha256:9c3013215ac036bfd7352f2a23eb44e0d4f6e30cbf84294d77bfa6e126483394 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 1s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

Newest entry first. Limit 150 lines.

### Archived from claude-bd0bce05de513f55 on 2026-09-16 (step 1-2 review)

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:3b58729b0053ef64e7f6f8ca4e69996ec6458f89df0e748f18cca43d1b9c0e35 over 486 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T04:25:19.796Z by claude-bd0bce05de513f55
- entry: sha256:89d0899d7567a3ac825e7fa706a1ef6164f7fb52d8dbe08f963f46ed74403c63 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 1s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-16 - DEC-0024 supersedes DEC-0023; steps 1-2 specified and handed to Gemini

Agent: Claude / claude-bd0bce05de513f55.

Action: Owner accepted both corrections from the review. Appended DEC-0024 with
`Supersedes: DEC-0023` rather than editing the accepted block, rewrote
.ai/PLAN.md and .ai/TASK.md against it, wrote
docs/design/04_DEC0024_ACCEPTANCE_CRITERIA.md for the two steps going to
Gemini, and gitignored saplesmusic/. No product code changed.

Result: **DEC-0023 point 5 would have regressed the game.** "Adaptive drag
anchor centers piece pickup" taken literally removes `_touchDragLiftPixels =
50`, and that lift is the only reason a dragged piece is not underneath the
thumb dragging it. DEC-0024 states the rule that was actually meant: centre
horizontally on the bounding box, keep the lift. The whole decision is restated
rather than amended, because a block that is 95% right is still read as 100%
binding and a reader who stops at DEC-0023 gets the wording that regresses.
Four engineering constraints are now binding rather than folklore:
MusicPlaylistManager cannot be built on FlameAudio.bgm (a single Bgm instance
cannot cross-fade, so two audioplayers players and an explicit pubspec entry);
volume has exactly one authority, with ducking a multiplier over the crossfade
envelope and never a direct set, or a duck landing mid-crossfade strands a
track at the wrong level; floating score numbers are one per cascade step at
the centroid of that step's cells, not one per cell, which would put twelve
numbers on a beat that the same decision says should carry one hero effect; and
music yields to audio focus.
**saplesmusic/ was not gitignored** - 39 MB of the Parkan OST, owned by Nikita
Ltd, sitting one `git add -A` from the repository history. Now ignored, with
the reason written next to the rule.
The execution split is recorded as a measurement rather than an assumption:
Gemini takes steps 1-2 because they are the most mechanical and the most
objectively checkable, and the defect rate they come back with decides the
rest. The MusicPlaylistManager stays with Claude whatever that rate is - leaked
players, a stranded volume and a missing dispose are the class of bug that
passes every test and fails on a player's phone, and this repository has
already been bitten by each of those shapes in another form.
flutter analyze --fatal-infos --fatal-warnings exit 0; flutter test exit 0, 328
tests. Nothing of DEC-0024 is implemented yet.

Next step: Gemini executes steps 1-2 against
docs/design/04_DEC0024_ACCEPTANCE_CRITERIA.md; Claude reviews against the same
list and the owner re-decides the split.

Open: Where the four soundtrack masters come from is unassigned - Stable Audio
3 Medium reaches 380s so length is not the blocker, but 13 minutes of arranged
and mastered music is its own work rather than a sub-item of step 3. Frames are
still unmeasured; that is what step 1 exists to fix. TASK.md had a duplicated
footer from a previous rewrite and was rebuilt clean. Nothing is committed and
main is 28 ahead of origin.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present

---

### From .ai/worklog/gemini-a9fddb2389c5621b.md, archived 2026-09-16

## 2026-09-16 - Stage A Release verification and live device deployment (DEC-0007)

Agent: Gemini / gemini-a9fddb2389c5621b.

Action: Committed gameplay milestone (ad1ca07). Tuned Android Gradle JVM memory configuration (limited workers to 4, CICompilerCount to 2, ParallelGC) to prevent Windows host native heap exhaustion on 32-core CPU. Built production release APK with --dart-define=APP_ENV=prod --dart-define=APP_FLAVOR=release. Implemented explicit composition root unit test (di_container_test.dart) and made SDK singletons lazy in FirebaseAnalyticsTracker, CloudFunctionsReceiptValidator, and GooglePlayBillingService. Deployed and executed release APK on physical Android device (2209116AG / Android 13).

Result: Clean build of app-release.apk (53.4MB). Full test suite passed (324/324 tests in 8s). Static analyze clean (0 issues). Device logcat confirmed successful cold start: Crashlytics initialized, Analytics connected, Auth authenticated anonymous UID, Impeller Vulkan/GLES backend initialized without throwing StateError. Captured live screen of Home menu on device.

Next step: DEC-0022 item 4 media acceptance set (DEC-0019) and live Firestore progress sync validation.

Open: Google Sign-In linking flow UI (DEC-0018) before paid store release; Google Play Console access and Firebase Blaze plan upgrade for verifyPurchase Cloud Function.

Evidence:
- anchor: ad1ca07aea310721d0854665326350c92e658dd8, uncommitted changes present
- digest: sha256:b5ca56dba26fb4abf50625c94f642506801a5e014936c4f58495be19841073a1 over 471 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T01:38:28.665Z by gemini-a9fddb2389c5621b
- entry: sha256:6b278b44cc721c80feb3f8edd8257e698e8ed6fa2dadb101a4d91690af14d4fa of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify


### Archived from claude-bd0bce05de513f55 on 2026-09-16 (DEC-0025)

- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-16 - Review of DEC-0024 steps 1-2: instrument accepted, baseline rejected and remeasured

Agent: Claude / claude-bd0bce05de513f55.

Action: Reviewed Gemini's calibration batch against
docs/design/04_DEC0024_ACCEPTANCE_CRITERIA.md. Read the recorder and its
wiring, checked the device, verified the audio claims independently, and
re-measured the baseline on 2209116AG with a method I controlled. Wrote
docs/design/05_DEC0024_STEP12_REVIEW.md. No product code changed.

Result: **Step 2 accepted** - every claim verified independently: audio assets
577,377 bytes, music_loop.m4a present, the WAV gone from assets, masters in
data/audio_masters/, the constant updated, saplesmusic clean, analyze exit 0,
diff inside the step's boundary. Test count is 335, not the 334 reported; 328 +
7 = 335, an arithmetic slip in the report rather than in the tree.
**Step 1's instrument accepted, its baseline rejected.** The reported Match-3
figures are internally impossible: 7168 frames in 62.1s is 115 fps, an 8.66 ms
interval, alongside a raster p50 of 33.54 ms - a frame cannot be produced every
8.66 ms when its rasterisation alone takes 33.54 ms, and 62.1s at that raster
allows at most 1851 frames. Off by 3.9x. Classic is inconsistent the same way
in the opposite direction. The cause looks structural: the panel prints a
cumulative `totalRecordedFrames` next to percentiles computed over the ring
buffer's window, two different samples with nothing in the label to say so.
Re-measured with reset, a wall-clock window and no scripted input: Match-3 idle
956 frames / ~36s = 26.6 fps with raster p50 38.94 ms (1000/38.94 = 25.7 -
consistent); Classic on an empty board 820 frames / ~26s = 31.5 fps with raster
p50 32.01 ms (31.2 - consistent). **The app renders at 26-31 fps on a 120 Hz
panel**, and the report's "Classic holds a confident 60 fps" is wrong in both
the number and the target: `mActiveSfDisplayMode` is 120.00001, so the budget
is 8.33 ms, and the recorder's jank threshold is hardcoded to 16667 us, which
understates jank on the very device the baseline was taken on.
**The instrument earned its keep anyway: it found something nobody suspected.**
An *empty* Classic board costs 32 ms of raster - no glass pieces, no cascade,
no particles - and three structurally different screens land within a few ms of
each other. That points at shared cost, not content. NebulaBackground sits in
all three via Positioned.fill and is wrapped in no RepaintBoundary anywhere;
`shouldRepaint => false` only suppresses redundant paint() calls when the
widget itself is dirty, it does not isolate a layer, and GameWidget dirties the
tree every frame. Nine full-screen gradient passes at 1080x2400, re-recorded
per frame. The ninth is the vignette I added in the visual session, so if the
hypothesis holds I made it worse. Stated as a hypothesis with a two-line
experiment, not as a finding.
flutter analyze --fatal-infos --fatal-warnings exit 0; flutter test exit 0, 335
tests.

Next step: three corrections to the instrument (threshold from
display.refreshRate, label which sample the percentiles cover, print fps over
the measured window), remeasure all three modes, then the RepaintBoundary
experiment. Step 3 is not blocked by any of it.

Open: the RepaintBoundary hypothesis is evidence, not proof - it needs the
experiment before anyone acts on it. Ordering question for the owner: the
review argues the background experiment should come before steps 4-6, because
decorating a game that runs at 26 fps spends a budget that does not exist.
Nothing is committed and main is 28 ahead of origin.


Newest entry first. Limit 150 lines.

### Archived from claude-bd0bce05de513f55 on 2026-09-16 (1b/1c/5 review)

- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:c43aafa2b803273f8da8a662126d073277dec594fd016caaef0f67837810df7b over 488 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T05:33:44.908Z by claude-bd0bce05de513f55
- entry: sha256:0ad8919e3b08978a4ec7b9eb6ba2af60e06cb3251631b2b87ba114e7a1e34169 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-16 - DEC-0025 records the execution model; plans and criteria concretised

Agent: Claude / claude-bd0bce05de513f55.

Action: Owner decided the calibration checkpoint DEC-0024 point 8 had left
open. Appended DEC-0025, rewrote docs/design/04_DEC0024_ACCEPTANCE_CRITERIA.md
to edition 2, rebuilt .ai/PLAN.md around the frame-budget finding, corrected
.ai/TASK.md, and wrote the starter prompt for the implementer. No product code
changed.

Result: The split continues, with one change the evidence pointed at directly:
**producing and concluding are now separate.** The implementer reports raw
numbers, the method and the measurement window; the reviewer draws the verdict.
The first edition of the criteria asked for "a baseline in the journal", and
that wording invited exactly the interpretation that turned out wrong. Two more
rules follow from the same batch: a defect class caught twice gets fixed in the
tool rather than on a reviewer's checklist - hence the panel printing fps over
its own window, so a self-contradictory measurement is visible to whoever takes
it - and experiments that test a hypothesis are pre-registered, prediction and
falsification threshold written before the measurement.
The RepaintBoundary experiment is pre-registered in the criteria document:
Classic empty board 32.01 -> below 12 ms, Match-3 idle 38.94 -> below 20 ms,
and a fall of under 25% in either mode falsifies it. It tests Claude's
hypothesis about Claude's own vignette, which is the reason it is measured by
other hands.
The plan is resequenced rather than merely annotated. Step 6 is gated behind
the frame-budget answer, because laying a full-screen ring over a game running
at 26 fps on a 120 Hz panel spends a budget that does not exist. Step 3 runs in
parallel; it is blocked by nothing.
TASK.md had step 1 marked done. Its instrument is accepted and its baseline is
not, so the box now reads [~] with both halves stated - AGENTS.md section 1
says a stale lower source gets fixed or called out, and this one is fixed.
flutter analyze --fatal-infos --fatal-warnings exit 0; flutter test exit 0, 335
tests. validate-protocol.ps1 exit 0.

Next step: Gemini runs 1b (instrument corrections + six measurements) and 1c
(the pre-registered experiment), then step 5. Claude starts step 3 in parallel.

Open: whether the frame budget is recoverable cheaply is unknown until 1c
lands; if the prediction fails, 26-31 fps is the floor steps 4-6 must fit into
and the owner rescopes. Claude writes the criteria, reviews against them and
draws the conclusions, which makes one agent a single point of judgement -
mitigated only by the raw numbers reaching the owner too. Nothing is committed
and main is 28 ahead of origin.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:dd9e11f5f4c3691f82947d1114a90285255c1d50b61364008d1339897050a5a4 over 486 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T04:41:00.836Z by claude-bd0bce05de513f55
- entry: sha256:84859cbb6a61b679abb64c953af66955006fe96dd9e08dcce1ab56f4301c641c of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s

### From .ai/worklog/gemini-a9fddb2389c5621b.md, archived 2026-09-16

## 2026-09-16 - Ratification of DEC-0023 (Audio format, sound juice, Fair Bag, vector shockwave)

Agent: Gemini / gemini-a9fddb2389c5621b.

Action: Received owner RuslanFomenko's explicit authorization for all 7 decision trade-offs: (1) AAC-LC 128 kbps (.m4a) music format; (2) global continuous playlist with 1.2s crossfade; (3) 7-step pentatonic combo ladder (combo_01..07) with 2.5s reset and hybrid placement thud; (4) lightweight vector shockwave and floating score numbers with static nebula; (5) Fair Bag Randomizer and adaptive drag anchor in Classic; (6) boosters rejected per DEC-0008; (7) Tetris swipes deferred to v1.1. Acquired protocol lock, appended DEC-0023 to `.ai/DECISIONS.md`, updated `.ai/PLAN.md` to Approved status, and aligned `.ai/TASK.md` acceptance criteria. Released lock.

Result: DEC-0023 formally ratified and binding. Scope boundaries locked. Full test suite remains green (327/327 passing). Protocols and line limits strictly maintained (TASK.md <= 80, PLAN.md <= 200).

Next step: Step 1 of DEC-0023 — instrument frame timing counter (`SchedulerBinding.addTimingsCallback`) and convert music masters to AAC-LC (.m4a).

Open: Google Play Console access for Stage C, and Firebase Blaze upgrade.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:c210cb6a05f96a4dd7cdb07918d1506cf7e92d5620822c09cca14fa8819750f3 over 482 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T03:10:23.407Z by gemini-a9fddb2389c5621b
- entry: sha256:ea26d9396f557b8b3c5cd6b66484aa60faf0abd398994f317af3fe7dc12d2b33 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

---

## 2026-09-16 - DEC-0022 item 4 & DEC-0019 media acceptance set closure

Agent: Gemini / gemini-a9fddb2389c5621b.

Action: Delivered the DEC-0019 / DEC-0022 item 4 media acceptance set: (1) First visual cosmetic skin asset (skin_pack_neon) master 1024x1024 texture and 256x256 preview generated via SDXL Base 1.0 (ComfyUI) and wired into StoreScreen product card; (2) 19.5s ambient electronic loop music_loop.wav generated via Stable Audio 3 Medium with 0.5s seamless equal-power crossfade at -1.0 dBFS in 16-bit PCM; (3) 3 short tactile SFX (line_clear.wav from Stable Audio 3, low-latency piece_placed.wav, and ascending combo.wav); (4) Comprehensive operations manifest (20_MEDIA_ACCEPTANCE_SET_MANIFEST.md) and machine-readable JSON (media_manifest.json). Verified clean analyze (0 warnings) and 324 unit tests pass.

Result: Acceptance criteria for DEC-0022 item 4 and DEC-0019 satisfied in full. Assets tested in audio engine and store card. All 324 tests pass in 9s; analyze 0 issues.

Next step: Real client progress live Firestore rules validation (Stage A completion) and Google Sign-In linking UI (DEC-0018 / Stage C prep).

Open: Google Play Console access & Firebase Blaze upgrade for verifyPurchase Cloud Function; Google Sign-In linking flow UI.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, clean tree
- digest: sha256:02f72a43550c9369afb33a81df977f0eb3476dd43ee82fc9385c80ca5f5acf36 over 475 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T02:05:01.072Z by gemini-a9fddb2389c5621b
- entry: sha256:12934a3a0b17952b0d2d1f3b6e45b221c9f375ababed3018d15dcabc0a04af4c of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

### Archived from claude-bd0bce05de513f55 on 2026-09-16 (batch of five)

- recorded: 2026-09-16T05:43:12.362Z by claude-bd0bce05de513f55
- entry: sha256:12c164a06abaaf970044aebe5baf9673f2bdb8491e1bd5218bd86fd713e50dc1 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-16 - Steps 1b/1c/5 accepted; my RepaintBoundary hypothesis is falsified

Agent: Claude / claude-bd0bce05de513f55.

Action: Reviewed Gemini's 1b, 1c and 5 against the criteria. Scored the
pre-registered experiment against its own threshold, analysed the six new
measurements, checked the device from the compositor side, verified the step 5
implementation and the untouched lift constant. Wrote
docs/design/06_DEC0024_STEP1BC5_REVIEW.md and specified step 1d. No product
code changed.

Result: **Three accepted, three checked, nothing redone.** Last batch needed one
of two steps rebuilt; this one needed none, and DEC-0025's rule held on its
first outing - the report carried numbers, method and window, and not a single
verdict.
**My hypothesis is dead and the pre-registration is why that is clean.** The
prediction was Classic 32 -> below 12 ms and Match-3 39 -> below 20 ms, with a
fall under 25% as the falsifier. Observed: 31.95 -> 32.03 and 38.91 -> 38.94.
No movement at all. NebulaBackground was never the cost, and the vignette I
suspected myself of is innocent. Written down before the measurement, so there
was nothing to argue about afterwards.
What six configurations show that two could not: `raster - build` is ~30 ms in
every single row (29.8 to 31.9), the raster distribution has no tail at all
(p99/p50 between 1.04 and 1.18), and it does not respond to content - an empty
Classic board costs 31.95 ms against 31.92 for active play, a difference of
0.09%. Rasterisation varies with what is drawn; this does not. SurfaceFlinger
reports an 8,333,333 ns vsync period for the app's surface - 120 Hz - while the
app presents about 30 fps, one frame in four. The shape of the data says wait
rather than work, but that is a shape and not a cause, so step 1d is two
discriminating experiments rather than another guess: renderer swap first
(`--enable-impeller=false`, one flag, thresholds written before the measurement
and deliberately no point prediction this time), surface area second.
Step 5 verified line by line: placeability checked at deal time, ten bounded
attempts then a deterministic walk of the easy templates, a safe exit on a full
board, and the comment states the rule about pieces two and three being allowed
to become unplaceable. `_touchDragLiftPixels = 50` is untouched - the diff adds
only a getter and a comment.
flutter analyze --fatal-infos --fatal-warnings exit 0; flutter test exit 0, 346
tests. validate-protocol.ps1 exit 0.

Next step: Gemini runs step 1d experiment A, then B if A does not resolve it.
Claude starts step 3 in parallel. Step 6 stays gated.

Open: the frame cap is unexplained. If 1d finds it is renderer-level, ~30 fps
on the owner's device is what every player on similar hardware will see, and
that reclassifies this from polish to release - the owner decides the ordering
then. The RepaintBoundary stays in the tree: it bought nothing measurable but it
is semantically right and costs one composited layer. Nothing is committed and
main is 28 ahead of origin.

### Archived from gemini-a9fddb2389c5621b on 2026-09-16 (calibration batch)

## 2026-09-16 - DEC-0024 calibration batch (Step 1 Frame counter & Step 2 Audio format)

Agent: Gemini / gemini-a9fddb2389c5621b.

Action: Implemented calibration batch (Steps 1 & 2 of DEC-0024):
1. Step 1 (Frame counter): Added `FrameTimingRecorder` ring buffer (capacity 3600 frames = 60s at 60Hz) computing p50/p90/p99 build and raster durations, worst frame, and jank share (>16.67ms). Wired into `bootstrap.dart` behind compile-time `kDiagnosticsEnabled` via `SchedulerBinding.instance.addTimingsCallback` (zero registration / zero cost when flag off). Added UI card and Reset button to `DiagnosticsScreen`. Implemented 7 unit tests (334 total tests passing). Collected physical device baseline on Xiaomi 2209116AG (~60s active play per mode).
2. Step 2 (Audio format): Converted `music_loop.wav` (3.44 MB) to AAC-LC 128 kbps stereo `music_loop.m4a` (319 612 B / 312 KiB, -90.7% size reduction) preserving 0.5s seamless crossfade loop. Converted `line_clear.wav` (317 564 B stereo) to mono PCM WAV (158 838 B, -49.9%). Preserved all 8 SFX as mono 16-bit 44.1 kHz PCM WAV for zero-latency one-shot playback. Transferred PCM masters to `data/audio_masters/`. Removed old `.wav` music from `assets/audio/`. Updated `MusicController._track` to `music_loop.m4a`. Aligned `20_MEDIA_ACCEPTANCE_SET_MANIFEST.md` and `media_manifest.json`. Total audio assets dropped from 3.678 MB to 0.551 MB (-85.0%). Release APK size dropped from 59 760 593 B (57.0 MB) to 56 629 605 B (54.0 MB, -3.13 MB saved).

Result: Baseline on 2209116AG:
- Classic (63.4s, 3046 frames): 2.10% jank (64 frames), build p50/p90/p99 = 1.97 / 3.75 / 4.45 ms (worst 44.89 ms), raster p50/p90/p99 = 7.37 / 8.91 / 18.90 ms (worst 43.77 ms), total worst 50.03 ms.
- Tetris (62.1s, 3600/5187 frames): 56.81% jank (2045 frames), build p50/p90/p99 = 2.64 / 3.56 / 5.70 ms (worst 48.38 ms), raster p50/p90/p99 = 31.55 / 32.63 / 35.19 ms (worst 51.55 ms), total worst 74.41 ms (raster bottleneck ~31ms).
- Match-3 (62.1s, 3600/7168 frames): 96.03% jank (3457 frames), build p50/p90/p99 = 2.73 / 4.24 / 7.52 ms (worst 64.49 ms), raster p50/p90/p99 = 33.54 / 35.04 / 36.37 ms (worst 64.14 ms), total worst 100.47 ms (raster bottleneck ~34ms).
Live device audio verified: music loops seamlessly without clicks, all SFX audible with crisp zero-latency tactile response. `flutter analyze --fatal-infos --fatal-warnings` exit 0, `flutter test` 334/334 passed.

Next step: Claude implements Step 3 (global continuous playlist `MusicPlaylistManager`, crossfading, pause/resume lifecycle).

Open: Flame raster bottleneck in Tetris/Match-3 identified (~31-35ms raster vs ~2-3ms build); Google Play Console & Firebase Blaze upgrade.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:fa97c948d9dea52558bcb2bc37544e152ba222838256d0ed8d3967f8755e475d over 485 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T04:12:02.208Z by gemini-a9fddb2389c5621b
- entry: sha256:3ee644762469f443e8289ad801a23e259f9315986e9d0e5cb2c22909bbe2f495 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify


### Archived from claude-bd0bce05de513f55 on 2026-09-16 (1d/1e/4 review)

- digest: sha256:9c44ffed79076ba8d5635574272f0ff371bed33132e329745365b7ea495d9eea over 498 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T12:11:16.108Z by claude-bd0bce05de513f55
- entry: sha256:246b845ef0a2ce0456ecd8aa386fcc49e4b8589dc99c249c5dc4967161ab1a94 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-16 - Batch of five specified; the Match-3 build cost finally explained

Agent: Claude / claude-bd0bce05de513f55.

Action: Owner asked to re-check the documents and size the next batch up from
three to five. Reconciled .ai/PLAN.md and .ai/TASK.md against what has actually
been accepted, extended the criteria document with steps 1e, 4a and 4b, and
wrote the handover. No product code changed.

Result: **The number I left unexplained last review has an explanation.**
`FrameTiming.buildDuration` covers build, layout *and paint*, and Flame draws
in paint - so Match-3 recording 64 gems at nine passes each, roughly 576
operations per frame on the UI thread, is why its build p50 is 9.07 ms against
Classic's 2.00 on a cached empty board. That is my glass painter's recording
cost, it is a different thread from the raster mystery, and it is fixable
independently by caching the gems that do not change between moves. Specified
as 1e with a pre-registered prediction (build p50 below 4 ms, raster unchanged
because it is the other thread) and a falsifier at 30%.
**The batch is five for a reason that is not the last score.** It holds two
tracks that cannot block each other - frames (1d, 1e) and audio (4a, 4b) - so
a stall in one does not idle the other. Five interdependent steps would still
have been one step at a time, and the plan now says so explicitly rather than
leaving batch size to look like a reward.
Two specification calls worth recording. The seven pentatonic samples are made
by deterministic semitone resampling of the existing combo.wav, not
generatively: a generative model does not hit a named pitch on demand, and
resampling keeps the timbre and can be checked with arithmetic. The placement
hit is two components because 110 Hz is barely reproduced by a phone speaker -
the body is for headphones and haptics, the 2-3 kHz transient is what carries
the weight on the speaker - so the criteria require it to be auditioned on both
separately and stated separately.
1e is named in the plan as work arising from the measurements rather than
DEC-0024 scope, for the owner to wave through rather than discover later.
validate-protocol.ps1 exit 0. No product code touched, so the suite is
unchanged at 346.

Next step: Gemini runs the batch of five against the criteria; Claude reviews
and starts step 3 in parallel.

Open: the frame cap is still unexplained and 1d is the discriminator. If it is
renderer-level, ~30 fps is what every player on similar hardware sees and the
ordering of 4-6 becomes a release decision rather than a polish one. TASK.md
needed three passes to fit its 80-line limit; the acceptance list is now
compressed and some history moved to the plan. Nothing is committed and main is
28 ahead of origin.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:a6e425dc2b69fc1eed69cd67e1eff73307663a91d9eab190310b4785e1b9fe6f over 488 tracked and untracked files
- digest format: 4

### From .ai/worklog/gemini-a9fddb2389c5621b.md, archived 2026-09-16

## 2026-09-16 - DEC-0024/0025 Steps 1b, 1c, and 5 delivery and device measurement

Agent: Gemini / gemini-a9fddb2389c5621b.

Action: Implemented Steps 1b, 1c, and 5 per DEC-0024, DEC-0025, and acceptance criteria edition 2:
1. Step 1b: Added dynamic jank threshold via `PlatformDispatcher.instance.views.first.display.refreshRate` (120 Hz -> 8333 us on 2209116AG, 60 Hz fallback), explicit sample size label for percentiles, window duration stopwatch, and observed window FPS. 11/11 unit tests passed. Measured 6 configurations (3 modes x idle/active) on physical device 2209116AG in release build (`ENABLE_DIAGNOSTICS=true`).
2. Step 1c: Wrapped `NebulaBackground` in `const RepaintBoundary` in `nebula_background.dart`. Rebuilt release APK, installed on 2209116AG, and remeasured Classic empty board and Match-3 idle under identical protocol.
3. Step 5: Implemented Fair Bag Randomizer in `BasicPieceGenerationService` (injected `MoveValidator`, 10 random attempts, deterministic fallback on `_easyTemplates`, termination if board full). Implemented horizontal bounding-box drag centering in `BlockPuzzleGame.onDragStart` while keeping `_touchDragLiftPixels = 50` untouched. 5 Fair Bag + 3 drag anchor unit tests added. Full suite: 346/346 passed, analyze exit 0. Live piece placement and new triplet deal verified on device.

Result: Raw measurement numbers on Xiaomi 2209116AG (Android 13, 1080x2400, 120 Hz panel, method: reset timing stats -> enter mode -> 30-45s timed window -> return to diagnostics -> capture screenshot):
- 1b.4 Baseline:
  * Classic idle (32.2s, 1130 frames): 35.1 fps, build p50/p90/p99 = 2.00/2.60/7.64 ms (worst 44.06 ms), raster p50/p90/p99 = 31.95/32.44/33.16 ms (worst 47.85 ms), jank 93.19% (1053/1130). Self-check: 1000/31.95 = 31.30 fps vs 35.1 fps (ratio 1.12, divergence <= 1.5x).
  * Classic active (44.6s, 1434 frames): 32.1 fps, build p50/p90/p99 = 1.76/2.50/7.06 ms (worst 18.18 ms), raster p50/p90/p99 = 31.92/32.46/33.95 ms (worst 42.06 ms), jank 97.07% (1392/1434). Self-check: 1000/31.92 = 31.33 fps vs 32.1 fps (ratio 1.02, divergence <= 1.5x).
  * Tetris idle (32.4s, 1031 frames): 31.9 fps, build p50/p90/p99 = 2.14/3.89/10.09 ms (worst 28.64 ms), raster p50/p90/p99 = 34.02/34.66/36.06 ms (worst 67.26 ms), jank 98.16% (1012/1031). Self-check: 1000/34.02 = 29.39 fps vs 31.9 fps (ratio 1.085, divergence <= 1.5x).
  * Tetris active (37.2s, 1082 frames): 29.1 fps, build p50/p90/p99 = 5.17/7.95/17.80 ms (worst 39.62 ms), raster p50/p90/p99 = 36.20/41.07/42.68 ms (worst 63.83 ms), jank 92.98% (1006/1082). Self-check: 1000/36.20 = 27.62 fps vs 29.1 fps (ratio 1.053, divergence <= 1.5x).
  * Match-3 idle (32.3s, 1015 frames): 31.4 fps, build p50/p90/p99 = 9.07/11.95/29.96 ms (worst 34.59 ms), raster p50/p90/p99 = 38.91/39.54/40.72 ms (worst 88.90 ms), jank 82.56% (838/1015). Self-check: 1000/38.91 = 25.70 fps vs 31.4 fps (ratio 1.22, divergence <= 1.5x).
  * Match-3 active (42.2s, 1261 frames): 29.9 fps, build p50/p90/p99 = 8.71/12.46/29.86 ms (worst 35.13 ms), raster p50/p90/p99 = 38.61/39.33/41.18 ms (worst 77.32 ms), jank 87.87% (1108/1261). Self-check: 1000/38.61 = 25.90 fps vs 29.9 fps (ratio 1.15, divergence <= 1.5x).
- 1c RepaintBoundary Remeasurement (Before vs After):
  * Classic idle: Before raster p50 31.95 ms (35.1 fps) -> After raster p50 32.03 ms (35.0 fps, window 32.5s, 1136 frames, jank 95.33%, worst raster 78.30 ms). Self-check: 1000/32.03 = 31.22 fps vs 35.0 fps (ratio 1.12).
  * Match-3 idle: Before raster p50 38.91 ms (31.4 fps) -> After raster p50 38.94 ms (27.4 fps, window 32.4s, 886 frames, jank 95.49%, worst raster 119.14 ms). Self-check: 1000/38.94 = 25.68 fps vs 27.4 fps (ratio 1.067).

Next step: Claude reviews steps 1b, 1c, and 5 against criteria and draws conclusions (DEC-0025); continues Step 3 (MusicPlaylistManager) in parallel.

Open: Google Play Console access for Stage C; Firebase Blaze upgrade.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:b94662fb8ff6ea77ed30bb35f0bd81ca34e394e3211d0222afd0f955788eb3d9 over 487 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T05:24:33.937Z by gemini-a9fddb2389c5621b
- entry: sha256:06bda9ab676a56ed5b05997f126071ea8222c9ed069a4a8069120db0cde62534 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

### Archived from claude-bd0bce05de513f55 on 2026-09-16 (1f review)

- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-16 - 1d answered: the glass costs render passes, not pixels

Agent: Claude / claude-bd0bce05de513f55.

Action: Reviewed the batch of five against the criteria, scored both
pre-registered experiments against their own thresholds, verified the audio
assets arithmetically and the reverts by diff, and specified step 1f. Wrote
docs/design/07_DEC0024_STEP1D1E4_REVIEW.md. No product code changed.

Result: **Five accepted, five checked.** Running tally is one partial redo in
nine steps, which is the number that justifies the split.
**My 1e prediction held on all three counts** - build p50 9.07 -> 3.23 idle and
8.71 -> 1.57 active, raster unchanged at 38.88 because it is the other thread.
The third line matters most: it confirms the paint-phase diagnosis and shows the
recording cost was real but never the binding constraint.
**Experiment A scored against my own bands: 15.61 ms falls in the second band,
not the first.** 15.61 > 15.00, so "contributes but is not the whole story" -
rounding that in my favour is exactly what writing thresholds beforehand is
supposed to prevent. The result also splits: Skia halves Classic (31.95 ->
15.61) and makes Match-3 a third worse (38.91 -> 52.77). One renderer cannot be
both, so the difference is in what each scene asks for.
**A and B together answer 1d's question.** It is cost, not wait - a vsync wait
would not care which renderer draws. But it is not fill rate either: a
sixteenth of the pixels removed only 22%, leaving ~25 of 31.95 ms independent of
area. What is left is a fixed per-frame price in render-target switches, which
on a tiled GPU means a tile resolve and reload each time. `paintGlassFacet`
spends up to three blurs and one clipPath **per piece**: about 128 blurs and 64
clips per frame on an idle Match-3 board. That also explains the split - Match-3
is blur-dominated and Impeller's gaussian beats Skia's here, Classic is not.
**Skia is not an escape**: worst raster 233 ms on Classic and 787 ms on Match-3,
shader-compilation jank of exactly the kind Impeller exists to prevent.
**The conclusion is mine to own.** The glass material I designed in the visual
session costs more than this device can pay, and the cost is structural - the
number of passes, not the number of pixels. Lowering resolution does not help,
changing renderer is not available, so the only lever is fewer passes, which
means giving up some of the look.
Step 1f prices the two candidates separately - blurs, then clipPath - because
removing both at once would leave the owner choosing the look blind. The changes
deliberately stay in the tree afterwards: what to restore is the owner's call on
the prices, not mine on taste.
flutter analyze --fatal-infos --fatal-warnings exit 0; flutter test exit 0, 350
tests. validate-protocol.ps1 exit 0.

Next step: Gemini runs 1f-A then 1f-B. Claude starts step 3 in parallel.

Open: this has stopped being a polish question. Even after 1e, Match-3 sits near
28 fps on a 120 Hz panel; if 1f does not recover the budget there is nothing
left to decorate and steps 4c and 6 have no room. The owner decides between the
glass and the frame rate once 1f puts a price on each pass. Nothing is committed
and main is 28 ahead of origin.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present

Newest entry first. Limit 150 lines.

---

### Archived from deepseek-f7cc6b98736bc1f6 on 2026-09-17 (1j review, exit branch 3)

## 2026-09-17 - Review of step 1j: exit branch 3, no fix, owner decides

Agent: DeepSeek / deepseek-f7cc6b98736bc1f6, stand-in for Claude
(claude-0789722ac9b82f43) at the owner's request while Claude is rate-limited.

Action:
- Reviewed Gemini's step 1j against docs/design/04, section "Шаг 1j": checked
  the seven diag screenshots against the report line by line, the board
  screenshots for geometry and the half-filled board, the decomposition code
  (compile-time flag, hideB..hideE call sites, reset before each run), and
  re-derived every number. Did not redo the device measurements.
- Ran the checks myself: flutter analyze exit 0 (0 issues), flutter test
  357/357, validate-protocol.ps1 Protocol OK / 0 warnings, handoff verify:
  "evidence matches the current tree". Confirmed device props by adb:
  2209116AG, ro.board.platform=sm6150, ro.soc.model=SM7150, Android 13.
- Wrote docs/design/11_DEC0024_STEP1J_REVIEW.md. Updated .ai/TASK.md (72/80)
  and .ai/PLAN.md (196/200) under the lock. No product code changed.

Result:
- **Measurement accepted.** Every number reconciles; all seven screenshots
  match the report digit for digit; cumulative == window frames proves the
  reset; self-check ratios 0.98..1.34, all <= 1.5.
- Layers on the empty board: B +2.01, C +0.70, D +0.52, E +0.93 ms; sum 4.16;
  F 3.68; additivity 0.48 <= 3.0. No layer >= 4 ms.
- **Exit rule: branch 2 and branch 3 both fired.** Branch 2 needs no layer
  >= 4 ms and additivity - true. Branch 3 needs "sum much smaller than the
  gap" - 4.16 vs 17.67 ms, 24%, also true. The author's own journal resolves
  it: if the four candidates do not close the gap, a fifth term exists that
  nobody has named. Verdict: branch 3 - frame model incomplete, fix nothing,
  owner decides. **Step 6 is not unblocked by this review.** The literal
  branch-2 promise "42.9 fps accepted as is" also fails on the numbers: the
  same scene measured 37.4 fps in 1j (25.52/42.9 in 1i).
- Half-filled board: +12.10 ms, isolated by no config; the starfield half of
  the pieces picture costs only 0.52 ms on an empty board, so the likely
  carrier is the occupied-cell half - a hypothesis, not a measurement.
- Corrections to the record: item 4 of the 1i review is withdrawn - 2209116AG
  is a Redmi Note 12 Pro (4G) on SM7150 (Adreno 618) reporting
  ro.board.platform=sm6150; 1j's report was right. Cross-session drift:
  25.52/42.9 (1i) -> 26.25/37.4 (1j, same scene).
- Non-blocking notes: flag tests are conditional on the compile define, so CI
  without --dart-define exercises no mapping; the jank-metric defect (DEC-0025
  p.3) is still unassigned; the report contains no verdict.

Next step: Owner decision on the 1j exit - (a) accept current numbers and set
the step 6 budget from the half-filled frame (38.35 ms / 35.0 fps), (b) one
more within-scene measurement (D on a half-filled board) to name the fifth
term, or (c) stop. Recommendation: (b), one measurement, not a spiral.

Open: step 6 gating; jank metric fix unassigned; steps 3 and 4c remain
Claude's and are blocked by nothing but the rate limit.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:5ea780f7adf1cdb15a58c940121acec56559b28f3f69087f3bc05c0d073b9ad4 over 537 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T22:24:11.628Z by deepseek-f7cc6b98736bc1f6
- entry: sha256:5de49f78e9f265f031826c1ab835ff225bac0c50545c642b00f00d371091cdd9 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

---

### Sessions that opened a journal and wrote nothing, removed 2026-09-17

Removed by `claude-0789722ac9b82f43` during the DEC-0024 consolidation audit.
Each file held only the template header (148-151 bytes) and not one dated
entry, so no text was lost; this line records that the sessions existed.

- `.ai/worklog/claude-12aa5b86e72607da.md` (created 2026-09-16)
- `.ai/worklog/claude-1eae3f70a9454c96.md` (created 2026-09-16)
- `.ai/worklog/claude-7403188e7bbf5630.md` (created 2026-09-15)
- `.ai/worklog/claude-c92f79aa5b343336.md` (created 2026-09-16)
- `.ai/worklog/codex-b1c8cad19f547a8d.md` (created 2026-09-14)
- `.ai/worklog/deepseek-ae23e5c218d3fe82.md` (created 2026-09-16)
- `.ai/worklog/gemini-ac38cf757f17f508.md` (created 2026-09-16)

Four of them are tracked by Git and can be restored from `d5ae947` if the fact
of the file itself ever matters; three were never committed.

---

### From .ai/worklog/claude-0789722ac9b82f43.md, archived 2026-09-17

Moved to keep the journal inside its 150-line limit. Text unchanged.

## 2026-09-16 - Review of step 1i, and criteria for step 1j

Agent: claude-0789722ac9b82f43

Action:
- Reviewed Gemini's step 1i (`gemini-fb4abe3f81b4b68b`) against the criteria and
  the prediction written before the step. Checked, did not redo: read the four
  call sites, `rasterizeBoardWell`/`drawBoardWellImage`, the new tests, the
  recorder, the benchmark stand and the Classic widget tree, then reconciled
  1i's numbers against 1h's.
- Wrote `docs/design/10_DEC0024_STEP1I_REVIEW.md`.
- Appended step 1j criteria to `docs/design/04_DEC0024_ACCEPTANCE_CRITERIA.md`,
  with predictions, an additivity check and three exit thresholds, all recorded
  before the measurement (DEC-0025 point 4).
- Updated `.ai/PLAN.md` and `.ai/TASK.md` under the lock. Touched no code.

Result:
- Step 1i accepted on its primary prediction: layer-4 delta +11.35 -> **-0.05 ms**
  against a 2 ms bar. Code correct at all four sites; `toImageSync`, physical
  pixel scale, disposal on resize and in `onRemove`; tests check the rule.
- Three corrections to the record, all from 1i's own numbers:
  1. "The gems are free" is withdrawn. Layer 5 was -0.01 ms in 1h and is
     **+3.84 ms** raster (+4.3 ms build) in 1i. It measured as free only while
     the well masked it. Classic's 25.52 ms was taken on an **empty** board, so
     a real game is ~29 ms (~34 fps) by projection - stated as a projection.
  2. The second, non-blocking prediction missed and was not named in the report:
     Classic idle was to land under 22 ms and landed at 25.52 ms.
  3. The chrome attribution is withdrawn. The rack is a Flame component inside
     `GameWidget`, not chrome; and the estimate came from subtracting one
     scene's p50 from another's, which drifted 12.70 -> 17.67 ms after a change
     that touched neither scene's chrome.
- Four `drawPicture` calls survive in the hot path - the same defect 1i proved:
  `block_puzzle_game.dart:1231` (~30 blurred stars re-executed every frame on an
  idle empty board), `:1482`, `:1485`, `match3_game.dart:309`. A fifth candidate
  is the antialiased `ClipRRect` at `game_loop_screen.dart:261`. Prices unknown
  and deliberately not guessed; 1j measures first.
- Tool defects recorded: the jank threshold is derived correctly (8.33 ms at
  120 Hz) but the report is labelled 16.7 ms, and the metric compares the
  threshold against `build + raster` summed, which are pipelined stages - it
  overstates. Percentages come from the 3600-frame ring while fps comes from the
  whole window. Device chipset in the report is misattributed.
- Checks run by me: `validate-protocol.ps1` exit 0, 0 warnings.
  `test-protocol.ps1` is absent here and was not run - `protocol-manifest.json`
  carries `role: installed`, and AGENTS.md section 7 keeps the regression suite
  in the protocol source repository. I did not run the Flutter suite either; the
  353/353 green result is Gemini's, recorded in their journal, and my own
  changes are documents only.
- `.ai/TASK.md` 79 lines, `.ai/PLAN.md` 200 lines - both at the limit.

Next step:
- Owner hands step 1j to Gemini. Criteria are in the repository, not in chat.
- Step 3 (MusicPlaylistManager) is mine and blocked by nothing; 4c follows it.

Open:
- The additivity check in 1j can invalidate the whole decomposition. My own
  predicted sum (3.5-11 ms) is below the observed 17.67 ms gap on purpose: if
  the four candidates do not close it, a fifth term exists that nobody has named.
- The jank metric fix is unassigned. It is a tool defect under DEC-0025 point 3,
  not a 1j deliverable.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:475f3a981f31202864741f8f2a03e3a1f3b05263234a52140206519ddfe95829 over 515 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T20:39:35.060Z by claude-0789722ac9b82f43
- entry: sha256:aab670e36b110e9fd12425b6fe5f75d0e8b39a93fa88ff0644e2fcf9f0a16387 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-21 from .ai/worklog/deepseek-99fe1db1ec0c6d5e.md

## 2026-09-20 - Full repo audit: DEC-0024 closure, Stage C boundaries, repo risks

Agent: DeepSeek / deepseek-99fe1db1ec0c6d5e, owner's request.

Action:
- Audited the whole repository at 5ada2b9 (branch dec-0024/av-polish): code,
  tests, CI, config, docs, .ai protocol, git state. Device, Play Console,
  Firebase console and release builds not re-run (DEC-0025 p.6).
- Ran the checks myself: flutter analyze --fatal-infos --fatal-warnings (0
  issues, exit 0), flutter test (380/380, exit 0), validate-protocol.ps1
  (Protocol OK, 0 warnings, protocol 1.9.0).
- Read review 14, audit 13, DEC-0001..0025, PLAN, plan 14, audits 04/05; read
  the music controller/integration, DI lifetimes, billing catalog, bundled RC
  defaults, CI workflows, build.gradle, manifest, firestore.rules, analytics
  schema and Classic/Tetris/Match-3 event payloads.
- Wrote docs/audit/06_FULL_REPO_AUDIT_2026-09-20.md; added the pointer and the
  Stage C boundary list to .ai/TASK.md under the lock. No product code touched.

Result:
- Green tree confirmed; no TODO/FIXME; secrets and saplesmusic untracked.
- DEC-0024: only step 3 + 4c remain (music layer reverted; screens restart the
  track on navigation; audioplayers absent from pubspec; no AudioContext), plus
  the four masters, the missing step-7 crash.txt/20-min protocol, and the
  eyes-on effect composition.
- Stage C boundaries found: Google Sign-In linking absent (DEC-0018);
  verifyPurchase has no explicit serviceAccount (index.js:34); utility_tools_pass
  (non-cosmetic) still sold and set as the engaged-segment primary SKU
  (defaults:19,29; billing:90) contrary to DEC-0008; Classic emits mode:'classic'
  without game_id (game_loop_controller.dart:338,1175); ABExperiment/Onboarding/
  Progression still lazySingleton (DEC-0016); widget_test.dart:7 is expect(true);
  7 Cyrillic strings remain in store_controller.
- Repo risk: 38 commits local-only (main 28 ahead of origin/main plus 10 on the
  branch); 18 MB of PNG receipts already in history; docs README, 05 and
  DOCS_CHANGELOG stale since June; operations/17:233 still assigns stage A to
  Codex. Frame budget stays closed at 26.1 ms / 38 fps.

Next step: owner - push decision; Claude - steps 3/4c per review 14 then
masters; owner - utility_tools_pass decision and effect composition eyes-on;
then C1-C5 to unblock the commercial scenario (see audit 06 section 6).

Open: C1-C8 from audit 06 section 4; step 7 evidence gap; doc sync; 38 unpushed
commits; the ~27 ms single well-blit mystery is unowned but closed for now.

Evidence:
- anchor: 5ada2b9e08cc6175453e2a948486e11b5fa3dc4b, uncommitted changes present
- digest: sha256:e8363bbb1f11326e48b2ee147aac07f6fffe4dad4abd47138caf179e5f711734 over 561 tracked and untracked files
- digest format: 4
- recorded: 2026-09-20T19:21:09.420Z by deepseek-99fe1db1ec0c6d5e
- entry: sha256:9a9b023242f611f16414ba27d83faca50f53befe5ae76d51e9e47d6ac9899832 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-21 from .ai/worklog/deepseek-99fe1db1ec0c6d5e.md (2)

## 2026-09-21 - Adversarial review of audits 06/07/08; next-stage plan; Gemini live channel failed

Agent: DeepSeek / deepseek-99fe1db1ec0c6d5e, owner's request.

Action:
- Owner asked: add the next-stage order to the plan (do not start), run two
  adversarial rounds with Gemini over audits 06/07/08 and their proposals, then
  compose the final plan and run two approval rounds with Gemini.
- Attempted the live Gemini channel: Agent Manager created a local session and a
  worktree session (Gemini 3.1 Pro Preview) and accepted prompts; both stayed
  `activity: idle` with zero messages in `.kilo/agent-manager.json` and wrote no
  files over ~15 minutes; both were stopped. No Gemini CLI exists in the
  environment (only claude/codex). The worktree `gemini-debate` remains for the
  owner to remove in the Agent Manager UI; `agent-manager.json` was not edited.
- Ran the rounds against the published audit 08 as Gemini's position and marked
  the limitation: docs/audit/09_ADVERSARIAL_REVIEW_06_07_08_2026-09-21.md
  (nine attacks, Gemini's textual replies, arbitration, forks F1-F7). Verified
  independently: Flutter enables R8 + shrinkResources by default
  (`FlutterPlugin.kt:214-217`, `FlutterPluginUtils.kt:209-213`), so D2 in audits
  07 and 08 is a false defect; D1 confirmed (`build.gradle:57-59`,
  `android-release.yml:14-17` `use_signing` default false); C5, DEC-0008 and
  DEC-0012 conflicts confirmed.
- Wrote docs/roadmap/15_POST_DEC0024_PLAN_2026-09-21.md; added a pointer section
  to `.ai/PLAN.md` (198 lines) and audit/plan pointers plus the F3 conflict to
  `.ai/TASK.md` (78 lines) under the cooperative lock. No product code touched.
- Created `.ai/runtime/debate/` prompt files for a live Gemini run
  (round1, round2, plan-review).

Result:
- Consensus of all three audits: push the 38 commits; D1 fail-fast signing;
  first signed build to 10-20 testers precedes Stage C; C5 `game_id`; music per
  review 14; step 7 evidence closure; docs sync. D2 withdrawn as an error.
- Forks with no consensus, for the owner: F1 frame-rate experiments vs doc
  alignment; F2 monetization model/channel; F3 music executor (owner directive
  says Gemini, DEC-0024 p.8 says Claude); F4 localization scope; F5 distribution
  path; F6 empty feature dirs; F7 RU Google Play payments check.
- Plan 15 status: proposed, NOT started, not live-verified by Gemini; the two
  approval rounds were not executed.

Next step: owner - confirm F3 and F2/F7, approve plan 15, decide push; then the
music layer per review 14.

Open: F1-F7; live Gemini channel; step 7 evidence; doc sync.

Evidence:
- anchor: 5ada2b9e08cc6175453e2a948486e11b5fa3dc4b, uncommitted changes present
- digest: sha256:ded858141f3fadea03d6f0f0261103d92bdbea9c00c6ed1e484c7f1198c806c1 over 565 tracked and untracked files
- digest format: 4
- recorded: 2026-09-20T22:47:37.511Z by deepseek-99fe1db1ec0c6d5e
- entry: sha256:c94187fb28d655ea6cbc223b456299e5b0c6fde663f2d4131419c4d261c19575 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-21 from .ai/worklog/deepseek-99fe1db1ec0c6d5e.md (3)

## 2026-09-21 - Live Gemini channel (agy): 2 adversarial rounds + 2 plan approval rounds; plan approved

Agent: DeepSeek / deepseek-99fe1db1ec0c6d5e, owner's request.

Action:
- Owner opened the channel: `C:\Users\Dmitry\AppData\Local\agy\bin\agy.exe`,
  `--model gemini-3.8-flash-high`, print mode + `--conversation` resume
  (conversation `f2d5d9b2-af8a-40e2-8e14-85704f0bed18`).
- Round 1: nine theses plus a request to attack audits 06/07. Gemini conceded D2
  as a factual error in 07 and 08, withdrew its "Б or В" monetization
  recommendation to the owner fork, accepted the frame-experiment fork, the
  music-executor fork, D1, C5, D3 (annotate), C6/C8; questioned RuStore as the
  first-test path; added three findings (test DI harness needed, widget_test
  comment; cold-kill/resume risk, no such test exists while
  roadmap/05:57 claims green; Play App Signing SHA checklist).
- Round 2: arbitration with three corrections (music causality was reversed -
  Claude followed DEC-0024/0025, the owner's Gemini directive came later; Play
  App Signing is already in DEC-0018 Consequences, not a missed discovery;
  citation paths must be exact). Gemini accepted all three, confirmed the
  consolidated list, the direct signed APK as the base path, and listed the W1
  acceptance prerequisites.
- Updated `docs/roadmap/15_POST_DEC0024_PLAN_2026-09-21.md` to edition 2.
  Approval round 1: "одобряю с правками" (reviewer for W1, test_di.dart path,
  Crashlytics mapping/symbols check) - applied. Approval round 2: "ОДОБРЯЮ",
  no comments.
- Updated `docs/audit/09` with a postscript, `.ai/PLAN.md` (198 lines) and
  `.ai/TASK.md` (78 lines) under the lock. No product code touched.
- Transcripts: `.ai/runtime/debate/round1-gemini.md`, `round2-gemini.md`,
  `plan-review-1-gemini.md`, `plan-review-2-gemini.md` (prompts prompt1..4).

Result:
- Consensus: push 38 commits; D1 fail-fast signing; D2 withdrawn; C5 game_id;
  D3 annotate; C6 + RU-only l10n before distribution; C7 with a test DI module;
  cold-kill device check; step 7 evidence closure; docs sync; first external
  test (direct signed APK) before Stage C.
- Forks for the owner: F3 (music executor, blocks W1), F2 (monetization, blocks
  W5), F7 (RU Google Play payments, blocks W5), F1 (frame experiments), F5
  (distribution path). F4 (RU-only) and F6 (annotate) resolved.
- Plan 15 approved by Gemini in two rounds; owner approval pending; no work
  started.

Next step: owner - confirm F3, decide F2/F7 and the push, approve plan 15; then
W1 (music per review 14).

Open: F1, F2, F3, F5, F7; owner approval of plan 15.

Evidence:
- anchor: 5ada2b9e08cc6175453e2a948486e11b5fa3dc4b, uncommitted changes present
- digest: sha256:a9d146d47abf57934f5fab0b9540918fc300c052d87b22a005b10c115c7dec10 over 565 tracked and untracked files
- digest format: 4
- recorded: 2026-09-20T23:12:30.682Z by deepseek-99fe1db1ec0c6d5e
- entry: sha256:b7dee1ff4609c7bfb1d182378a4fc54f829d4231d3136beab2818a768ea2bee8 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-21 from .ai/worklog/deepseek-99fe1db1ec0c6d5e.md (4)

## 2026-09-21 - Owner decisions recorded in DEC-0026; plan 15 approved

Agent: DeepSeek / deepseek-99fe1db1ec0c6d5e, owner's request.

Action:
- Owner answered all forks: F3 executor Gemini; F2 ad-free confirmed, no
  monetization in the first release (Stage C frozen); F7 deferred; W2 merge
  dec-0024/av-polish into main, then push; F1 KPI docs to 38-40 fps; F5 direct
  signed APK.
- Appended DEC-0026 (owner-approved): supersedes DEC-0024 p.8 for the music
  executor; no monetization now; utility_tools_pass not sold, removed from
  catalog/RC when the store surface is next touched; merge then push; KPI 38-40;
  RU-only l10n; annotate feature dirs.
- Updated docs/roadmap/15, .ai/PLAN.md, .ai/TASK.md under the lock. No product
  code touched; no work started.

Result: all forks closed; plan approved by Gemini (2 rounds) and the owner;
TASK status = Planned.

Next step: owner's go, then W1 (music, Gemini) and W2 (merge+push).

Open: W3 execution; step 7 evidence; docs sync (F1 KPI edits).

Evidence:
- anchor: 5ada2b9e08cc6175453e2a948486e11b5fa3dc4b, uncommitted changes present
- digest: sha256:76e9c63c6b004600d25059bd3ca3274fe659e7dec93e2f0831e92915e88941a4 over 565 tracked and untracked files
- digest format: 4
- recorded: 2026-09-20T23:20:08.458Z by deepseek-99fe1db1ec0c6d5e
- entry: sha256:8aa6489e245df0ba7a16452c1d3c26bc306bbb245f65b1e782a3c3031e0ac343 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-21 from .ai/worklog/deepseek-99fe1db1ec0c6d5e.md (5)

## 2026-09-21 - Full-prompt rerun with Gemini: 2 adversarial + 2 approval rounds

Agent: DeepSeek / deepseek-99fe1db1ec0c6d5e, owner's request.

Action:
- Owner corrected the earlier compressed delivery. Sent the complete owner
  prompt verbatim (60,681 chars) via agy stdin (PowerShell argument passing
  breaks on embedded quotes; stdin with UTF-8 works), fresh conversation
  `3fbf8df3-7b4a-4f6f-bae4-62d16f013d16`.
- Rerun rounds 1-2: same nine theses and attacks. Consensus in substance
  identical to the first session, with sharper attacks and three new findings.
  Verified: `keepScreenOn` absent (`AndroidManifest.xml`, `pubspec.yaml`) - real
  new product item; `android-release.yml:49-63` has no early secret validation -
  folded into D1; `kEffectTimeScale = 3.5` is the owner's intended product value
  (`TASK.md:38`, `effect_timing_test.dart:18-19`), no reset needed, only the
  eyes-on gate.
- Corrected the rerun's "sabotage" framing of audit 07 (it predates the owner's
  moratorium); Gemini accepted.
- Updated plan 15 to edition 3 (DEC-0026 basis; keepScreenOn; CI fail-fast; push
  in W2 after W1; step 7 protocol note; W4 gate); approval round 1 "одобряю с
  правками" (three applied), round 2 "ОДОБРЯЮ". No product code touched; work
  not started.

Result:
- Outcome unchanged in substance: D2 withdrawn; no monetization now (ad-free,
  Stage C frozen); frame experiments not sanctioned (docs to 38-40 fps); music
  by Gemini (DEC-0026); direct signed APK first; D1/C5/C6/C7/C8/D3 as planned.
- New since the first run: keepScreenOn, CI secret fail-fast, explicit
  kEffectTimeScale clarification.
- Gemini requires from the owner: an explicit start command and the W1 reviewer
  assignment (Claude or DeepSeek).

Next step: owner's start command for W1 and reviewer confirmation; W2 merge+push.

Open: owner start/reviewer; W3 execution; doc sync.

Evidence:
- anchor: 5ada2b9e08cc6175453e2a948486e11b5fa3dc4b, uncommitted changes present
- digest: sha256:6e0680b5300351bc2450fa753921bd4170170c6b2be208ffcb9935fb0ec867d1 over 565 tracked and untracked files
- digest format: 4
- recorded: 2026-09-20T23:30:13.092Z by deepseek-99fe1db1ec0c6d5e
- entry: sha256:8915309e2a271468e1f7d53c2c3adf6a9cf441da54b369535f130bbfa27d21e1 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-21 from .ai/worklog/deepseek-99fe1db1ec0c6d5e.md (6)

## 2026-09-21 - Start W1: DEC-0027, criteria, MAR prompt, Gemini implementation, review

Agent: DeepSeek / deepseek-99fe1db1ec0c6d5e, reviewer for the cycle (DEC-0027).

Action:
- Owner authorised the start and named DeepSeek reviewer; recorded as DEC-0027
  (start of plan ed.3 W0-W4, implementer Gemini, MAR consortium before owner
  acceptance). Updated `.ai/TASK.md` status/agents and plan 15 status.
- Wrote the reviewer's acceptance criteria for steps 3/4c into
  `docs/design/04_DEC0024_ACCEPTANCE_CRITERIA.md` before any code (DEC-0025
  p.1-2), and the Mandatory Adversarial Review prompt with launch commands in
  `docs/audit/10_MANDATORY_ADVERSARIAL_REVIEW_PROMPT.md`.
- Started Gemini (`gemini-3.8-flash-high`, new agy conversation) as W1
  implementer; it delivered the music layer: `audioplayers` dependency,
  `MusicPlaylistManager` (two players, 1.2 s equal-power crossfade, cyclic
  playlist, explicit AudioContext, ducking), rewritten app-scope
  `MusicController`, screens decoupled, SFX duck triggers, DI + bootstrap
  wiring, 12 new tests, journal with evidence.
- Reviewed independently: read every diff and test; ran `flutter analyze
  --fatal-infos --fatal-warnings` (0 issues), `flutter test` (392/392),
  `validate-protocol.ps1` (OK); checked scope (no out-of-scope edits),
  `kEffectTimeScale` untouched, no `FlameAudio.bgm` usage left, criteria not
  edited by the implementer.
- Wrote `docs/design/15_DEC0024_STEPS_3_4C_REVIEW.md`: **PASS WITH
  CONDITIONS**. Findings: F1 device check of continuity/focus still open (no
  adb device); F2 permanent audio-focus loss leaves Dart state desynced
  (plugin pauses natively, `play()` then no-ops); F3 minor jump when a new
  crossfade interrupts one in flight; F4 note on player-A asymmetry.

Result:
- Code accepted for review; step 3/4c closes after the owner's device check,
  F2 decision, and the four masters.
- 392/392 tests and clean analyze confirmed by the reviewer, not only claimed.

Next step: owner - device check on Redmi (transitions, Home, call); Gemini -
F2 decision/fix and the four masters; then W2 merge into main and push.

Open: F1 device, F2 focus-loss state, F3 minor, masters.

Evidence:
- anchor: 5ada2b9e08cc6175453e2a948486e11b5fa3dc4b, uncommitted changes present
- digest: sha256:b317fe8e200491ca120af2a454f438e1e9d39732792cd81fa25cfecc8c248c89 over 569 tracked and untracked files
- digest format: 4
- recorded: 2026-09-20T23:52:54.710Z by deepseek-99fe1db1ec0c6d5e
- entry: sha256:b728bda6e8df769d663b1a41457840b22e692d221aad0e98bc21a172f49598ee of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## 2026-09-21 - Gameplay research cycle with Gemini: 2 research + 2 discussion + 2 solution + 2 critique rounds; top-20 report

Agent: DeepSeek / deepseek-71c5c0b3bece591d, owner's request (research outside the DEC-0024 cycle).

Action:
- Ran the owner-requested full cycle with Gemini via agy CLI
  (`gemini-3.8-flash-high`, conversation c89cd708-18a9-4552-acab-d985056dab2b):
  two independent Gemini studies (R1-P positive, R1-N negative, fresh sessions),
  two independent DeepSeek studies (24 negative sources with direct quotes/RSS
  feeds/MWM; ~30 positive sources incl. App Store pages, WorldsApps, APKPure,
  Playgama, mobilegamer.biz), a code inventory with file:line facts, then
  D1/D2 discussions (Gemini self-retracted unsupported citations and the
  "Tetris/Match-3 blocked" error), S1/S2 solution rounds (30 -> merged top-20),
  plan ed.1, hostile C1 (3 P0: benchmark-after-VFX inversion, generator
  sequencing blindness, Undo snapshot exploit) and plan ed.2, then C2 = ACCEPT.
- Verified Gemini's code claims independently (diagonal shake :656-666,
  count:3 particles :683, audioFocus.gain, baseVolume 0.32, "that is fair"
  :259, missing hasUsedFreeUndo in GameSnapshot) and corrected three factual
  errors (all modes reachable; headless simulation harness exists at
  test/internal_playtest; maxParticles=320 already in burst_field.dart:14).
- Wrote `docs/research/01_GAMEPLAY_TOP20_2026-09-21.md` (20 proposals in the
  owner's format + infra gates + 10 owner decisions); work artifacts under
  `.ai/runtime/lumina-research/`. No product code touched; TASK/PLAN/DECISIONS
  intentionally not edited (not this session's task).
- One operational incident: agy auth expired mid-cycle; rerun after
  `applyAuthResult` (consumer) succeeded; all rounds captured to files.

Result: plan accepted by the hostile reviewer (C2 ACCEPT); top-20 list, gates
and owner decisions are recorded in the research doc; unverifiable Gemini
citation fractions are marked as expert estimates, DeepSeek counts are
source-based.

Next step: owner decisions 1-10; if approved - Wave 0 (Step 6+ benchmark,
telemetry, audio rebalance/sliders, track wiring, ducking/SFX guard, shake,
popup timings, honest New Best, free Undo + snapshot flag, AudioFocus).

Open: no live player telemetry; Reddit/TouchArcade/Google Play unreachable
(403) from this environment; agy may request owner login again; Gemini
citation quality varies (self-downgraded in D1).

Evidence:
- anchor: e5c9382f48705f339250e4df928ffcf89f5df39f, uncommitted changes present
- digest: sha256:ffaf41593f4f5a45a8fb6c15388efadee95b0cfe8eba6dcd9a8135d3fc0a433f over 577 tracked and untracked files
- digest format: 4
- recorded: 2026-09-21T05:34:22.693Z by deepseek-71c5c0b3bece591d
- entry: sha256:16ea09e313428c1a41505811b4fbf19792c2cc349c833a56070e7a154491a06f of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## 2026-09-21 - Owner votes recorded: DEC-0028 (10 gameplay decisions); G1 sprint prompt prepared

Agent: DeepSeek / deepseek-71c5c0b3bece591d.

Action:
- Owner voted all 10 forks (timings split; All Clear celebration-only; free undo
  with streak reset; three palettes free in v1.0; anti-chunking; soft Danger Pulse;
  hide monetization SKUs; technical directives; first-game-over tip;
  prerequisites-first order).
- Acquired the shared-document lock and appended `DEC-0028` to `.ai/DECISIONS.md`
  (Approved by: RuslanFomenko, owner vote 2026-09-21), then released the lock.
- Wrote `docs/research/04_OWNER_DECISIONS_2026-09-21.md` (vote table, G1 sprint
  scope A/B/C, acceptance gates, process) and drafted the implementation prompt
  `.ai/runtime/lumina-research/impl-sprint-prompt.md` for Gemini via agy.

Result: decisions are binding in the repo; sprint prompt ready; implementation not
started (waits for the owner's explicit start command per DEC-0027 p.1).

Next step: on the owner's go - create a dedicated worktree, launch agy with the
sprint prompt, then run the separate DeepSeek review sprint.

Open: no product code touched in G1 yet; no commits made.

Evidence:
- anchor: e5c9382f48705f339250e4df928ffcf89f5df39f, uncommitted changes present
- digest: sha256:87f060fa21867c1ceb6d38579eb5fc7eccd320a04c6bc3b30000b8bd8d13140f over 580 tracked and untracked files
- digest format: 4
- recorded: 2026-09-21T10:36:52.433Z by deepseek-71c5c0b3bece591d
- entry: sha256:9b73c040f1c495e86a3d4813405302d6c7a1704fce11e5d64728e91843723a4f of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## 2026-09-21 - Round R3: three-report review (Claude 02 + external opinion-2), verification pass, consolidated v3

Agent: DeepSeek / deepseek-71c5c0b3bece591d (owner request; research task).

Action:
- Read Claude's independent report `docs/research/02_GAMEPLAY_INDEPENDENT_EVALUATION.md`
  and saved the external opinion-2 verbatim to `.ai/runtime/lumina-research/opinion-2.md`.
- Verified contested claims against code: `piece_placed` volume 0.75 confirmed
  (`flame_game_sfx_player.dart:190`); `duck()` is idempotent in depth but restarts
  the 150 ms timer and spams `setVolume` (`music_playlist_manager.dart:347-366`) —
  Claude's "double -3 dB" corrected; Undo blocked by `insufficient_tools_credits`
  confirmed (`game_loop_controller.dart:722`); Claude's GameSnapshot path is wrong
  (actual `lib/domain/session/game_snapshot.dart`).
- Ran Gemini round R3 (delta of reports 01/02/opinion-2, accepted/rejected items,
  verification table for retracted claims); output `g-r3.md`.
- Wrote `docs/research/03_CONSOLIDATED_V3_2026-09-21.md`: 5 accepted improvements
  (drop volume 0.35, ducking coalescing, haptic thresholds, danger-pulse params,
  party-protection split), rejections from opinion-2 (percentage stats, difficulty
  ramp, new modes, social, currency, fever), verification table for unsupported claims.

Result: consolidated v3 saved; deltas agreed with Gemini; no product code touched;
TASK/PLAN/DECISIONS untouched.

Next step: owner decisions (UI timings, All Clear bonus, Undo combo reset, palettes,
anti-chunking boundary, Danger Pulse, SKU hygiene, tech directives).

Open: external report percentages unverifiable; R3's "scissor-clip <=0.3 ms" and
"maxRadius x3.8" stay unverified until Step 6+ runs; agy auth may need owner login.

Evidence:
- anchor: e5c9382f48705f339250e4df928ffcf89f5df39f, uncommitted changes present
- digest: sha256:dab324023cb4c44ad91702ce6d6a1eb043a2c1ed69ad1f7ad2eaea07a5dd46a2 over 579 tracked and untracked files
- digest format: 4
- recorded: 2026-09-21T06:51:34.349Z by deepseek-71c5c0b3bece591d
- entry: sha256:a6137922db41ea6ec9eee315fdcff2b9b8d6af7f23e960ba9bce6ffb58f1e1b0 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## 2026-09-21 - G1 review: independent verification, ACCEPT with conditions, mini-patch launched

Agent: DeepSeek / deepseek-71c5c0b3bece591d (reviewer per DEC-0025/DEC-0027).

Action:
- Verified G1 independently in D:\Block-Puzzle-g1: `flutter analyze` 0 issues,
  `flutter test` All tests passed (419), `validate-protocol.ps1` PASS 0 warnings,
  `protocol-handoff.cjs verify` matches the tree; anti-chunking simulation ran
  ("5,000 deals ... max 1 heavy piece and 0 instant deadlocks").
- Audited all 22 DEC-0028 items in code (audio volumes/pitch, duck coalescing
  110 ms + floor 0.70, timings 0.85 s, snapshot flag, free undo, AudioFocus,
  reduced motion, danger pulse, palettes/SKU, anti-chunking) and reproduced the
  test evidence.
- Defects: P2 diagonal All Clear shake (`block_puzzle_game.dart:896-902`);
  P2 generated windows files noise from pub get; P1-process palette contrast
  audit missing; device gates (Step 6+ numbers, audio/MIUI, screen wake, haptics)
  still open. Wrote `docs/research/05_G1_REVIEW_2026-09-21.md`.
- Launched mini-patch G1.1 to Gemini (isotropic All Clear shake, revert generated
  files, contrast audit doc) via agy; prompt in
  `.ai/runtime/lumina-research/impl-patch-prompt.md`.

Result: code-level ACCEPT with conditions; owner device acceptance and commit
decision outstanding; no commits made anywhere.

Next step: read G1.1 result, confirm the three fixes, then hand to the owner for
device/audio acceptance and the commit decision.

Open: agy status=ERROR quirk on completion (content intact); docs/research copied
into the G1 worktree (untracked) - owner decides.

Evidence:
- anchor: e5c9382f48705f339250e4df928ffcf89f5df39f, uncommitted changes present
- digest: sha256:3af36f7c5941fd9e12d852b784ccf2e44b126ebc27a124b820077c66b7441316 over 581 tracked and untracked files
- digest format: 4
- recorded: 2026-09-21T12:05:51.777Z by deepseek-71c5c0b3bece591d
- entry: sha256:42341b5f33c3b8e24561d2721f15ca6bb6b56f6acb1c191f88173e38cb7901ed of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-25 from .ai/worklog/codex-d56f1c2c371b35a6.md

# Worklog: codex-d56f1c2c371b35a6

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-14 - Independent review of Claude changes and media preparation

Agent: Codex / codex-d56f1c2c371b35a6.

Action: Reviewed current diff, Claude plans/operations documents, decisions,
journals and related product contracts; checked primary platform/model sources.
Inspected D:/AI installations read-only while Claude continued preparation.
Wrote docs/audit/04_CLAUDE_CHANGES_REVIEW_2026-09-14.md with R1-R12, assessment
of all fifteen decisions, revised execution order and media acceptance criteria.
Updated TASK under the shared lock; did not edit Claude's journal or decisions.
Assumption: user requested review, not implementation or media generation.

Result: Strict Flutter analyze exit 0; unit/widget run exit 0, 195 tests passed.
Excluded the simulation test that writes tracked JSON in this repeat run.
ComfyUI imports/CUDA, CLI help and uv pip check passed. Stable Audio initially
lacked torch/audio; Claude installed them during review. Final torch 2.7.1,
torchaudio 2.7.1 and flash-attn 2.8.3 imports/CUDA and pip check passed; that
transient missing-dependency finding is closed. Inference was not run.
First final validator found TASK at 81 lines; shortened it below the 80-line
limit before recording the final receipt.
Claude's protocol receipt verified before our edits. Git diff/check and the
new report diff were reviewed. Product code and external installations were
not changed by this review. Detailed findings distinguish inherited defects,
documentation gaps, upstream launcher behavior and unverified acceptance.

Next step: Claude addresses R1-R12 as applicable, accepts a bounded generated
asset sample, and consolidates the approved plans before executing S0/A.

Open: Real inference/VRAM/quality, runtime service account, RC transport keys,
recoverable identity before purchase, SDK/device/cloud/store checks and ADR-004
lifetime choice. Existing DEC blocks stay binding; proposals need applicable
owner approval if they change a decision. No commits, pushes or deployments.

Evidence:
- anchor: 357300ccddff7f7c62bda8639dc966419442453a, uncommitted changes present
- digest: sha256:40db0ae056c001c55c5238bef5266075bc418c6bc09e9ba108cc8c52fd1e53db over 435 tracked and untracked files
- digest format: 4
- recorded: 2026-09-14T18:33:38.036Z by codex-d56f1c2c371b35a6
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-14 - Repository development plan and handoff

Agent: Codex / codex-d56f1c2c371b35a6.

Action: Read task, Git state/logs, journals, decisions and product/roadmap/audit/
architecture/operations/release documents; checked relevant runtime and tests.
Created docs/development-plan-2026-09-14 from 357300c. Wrote plan 13 and updated
TASK/PLAN under the shared lock. Preserved parallel plan 12 and recorded
disagreements. Assumptions: planning only, one engineer, Google Play first,
one non-consumable cosmetic, existing modes individually gated.

Result: Strict Flutter analyze exit 0; flutter test exit 0, 196 tests passed.
Initial sandbox analyzer gave no output and was interrupted; escalated run
passed. Protocol validator initially failed Bash inside sandbox, then passed
outside sandbox. Product code unchanged. Test-generated run_001 JSON was
restored from HEAD; later status showed a content-identical line-ending change
while another session was active, left alone. Pre-existing protocol setup
and .gitignore edits belong to earlier/concurrent work and were preserved.
Confirmed sibling db8d05e contains fixes absent from HEAD; local origin/main
already includes batch 1 despite stale local main. New plan includes release
defines/package mismatch, purchase identity recovery, RC limitations,
snapshot/lifecycle gaps, phased priorities, estimates and acceptance gates.
Reviewed the new plan with git diff --no-index (exit 1 means new content),
and tracked changes with git diff. git diff --check passed. Checked all four
authored files for LF/no BOM, size limits and local Markdown links: passed.
First final receipt failed because TASK used a free-form status; corrected to
the validator's allowed Completed status (planning complete, no implementation).

Next step: Owner selects/consolidates proposals and records applicable
architecture/product decisions; begin A0/A1 from detailed plan after approval
of implementation scope. Obtain store/device/cloud access for runtime gates.

Open: Shop priority, release modes, account/purchase recovery, shared game
layer, KPI definitions and team capacity. Cloud deployment, device behavior,
real billing and cohorts remain unverified. No commits, pushes or deployments.

Evidence:
- anchor: 357300ccddff7f7c62bda8639dc966419442453a, uncommitted changes present
- digest: sha256:574c67218996e73673e3f65648edca2f806a26f74a92527bb8e5bdad12ae72cc over 431 tracked and untracked files
- digest format: 4
- recorded: 2026-09-14T13:16:00.282Z by codex-d56f1c2c371b35a6
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-25 from .ai/worklog/claude-bd0bce05de513f55.md

# Worklog: claude-bd0bce05de513f55

Session journal. Owned by this session. No other session writes here.

## 2026-09-16 - Bisection found it: the board well is 81%, the glass is free

Agent: Claude / claude-bd0bce05de513f55.

Action: Reviewed 1g and 1h against the criteria, scored the floor against its
pre-registered bands, attributed the cost across the five layers, verified the
revert and the checks, and specified 1i. Wrote
docs/design/09_DEC0024_STEP1G1H_REVIEW.md. No product code changed.

Result: **Both accepted. The change of method paid on its first measurement.**
Three guesses found nothing; one bisection found everything.
The floor is 5.29 ms at 118.3 fps - band two by the letter of my own thresholds,
band one in substance, because the device hit the panel's 120 Hz cap rather than
its own limit. The fear that an empty frame costs 30 ms here is dead: **the
hardware can do 118 fps.**
The bisection: control 5.29, + nebula 6.31 (+1.02, 7%), + empty GameWidget 7.90
(+1.59, 11%), **+ board well 19.25 (+11.35, 81%)**, + 64 glass gems 19.24
(-0.01, **free**).
**That inverts my model completely.** I spent three experiments suspecting the
gems - their blurs, their clipPath, their halo - and the gems cost nothing. The
cost is the cached board background I had assumed was free by definition. My
first hypothesis, the nebula, is worth 1 ms out of 26.
The mechanism I should have understood earlier: `drawPicture` does not draw a
finished image. A `Picture` is a command list and the GPU re-executes it every
frame - about 130 gradient shaders in the well, two per socket, plus two blurs.
Caching into a Picture removes the recording cost on the UI thread and nothing
else. **Step 1e proved exactly this and I failed to generalise it**: caching the
gems dropped build 64% and left raster untouched to the hundredth. I read that
as "different threads" and stopped.
**For the owner this closes the question they were facing.** Glass versus frame
rate is not a trade any more: the gems are measured free, the look stays, and
the earlier recommendation to revert 1f was right - there was nothing to buy
with it. 1i rasterises the well once into an Image and blits it.
A second target fell out of the same run: the benchmark's full stack is 19.24 ms
against the real Classic screen's 31.95, so ~12.7 ms lives in the Flutter chrome
the benchmark lacks - AppBar, HUD, rack, cards. One target at a time.
My self-check rule turned out to have a directional blind spot - it flagged a
perfectly good measurement at 1.60x because fps was *lower* than raster allowed,
which is what a vsync cap looks like. Reworded in the criteria: only fps
*exceeding* 1000/raster_p50 by 1.5x invalidates a run. Another fix in the tool
rather than in a reviewer's vigilance.
flutter analyze exit 0; flutter test exit 0, 350 tests. validate-protocol.ps1
exit 0.

Next step: Gemini runs 1i. Claude starts step 3.

Open: 1i's prediction could still fail, though unlike the first three this one
comes from an isolating measurement and a known mechanism rather than from
picking a suspect by eye. The ~12.7 ms of widget chrome is unexplained and
untouched. Six measurement screenshots sit untracked in the repository root and
belong in docs/design/ or .gitignore. Nothing is committed and main is 28 ahead
of origin.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:a80695a33d939750d7aa60a304926963a3e31a0d5e06e94e5f92aa47c6fac612 over 526 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T18:14:47.236Z by claude-bd0bce05de513f55
- entry: sha256:0506aec100e22ce305b845fb74ed7c1c22af49c635944d40f17921a1d50d39e0 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-16 - 1f falsified both guesses; the method was wrong, not the experiments

Agent: Claude / claude-bd0bce05de513f55.

Action: Reviewed 1f-A and 1f-B against their pre-registered thresholds, scored
them, and specified a change of approach as steps 1g and 1h. Wrote
docs/design/08_DEC0024_STEP1F_REVIEW.md. No product code changed.

Result: **Both accepted, both falsified.** Blurs cost 11.6% against a 25%
falsifier, clipPath 5.1% against 15%. Removing both leaves Match-3 near 32.6 ms
- about 31 fps against a 16.67 ms target, still short by a factor of two. The
prediction had been below 20 ms.
**That is three falsified guesses in a row - nebula repaint at 0%, blurs,
clipPath - and the fault is mine and structural.** I kept guessing *what in the
drawing* costs money and kept subtracting things from a scene without ever
measuring what an empty frame costs on this device. Subtraction without a
baseline is guessing with numbers attached rather than measuring.
The fact that was in plain sight the whole time: **Classic costs 31.95 ms on an
EMPTY board** - no pieces, the well cached in a Picture - and removing blurs only
took it to 29.03. The cost is present where there is almost nothing to draw, so
it lives in frame composition, not content. That also explains why 1d-B moved
only 22%: it shrank the game canvas but not the background, the Stack or the
full-screen layers above it. And one more sign from the fresh numbers: Match-3's
raster fell 11.6% while its frame rate did not rise at all (31.4 -> 29.9 ->
29.7), so frames are not bound by raster p50 either.
Next is not a fourth guess. 1g measures the floor - a diagnostics-only route
with a solid colour and one animating box, no nebula, no Flame, no glass - with
thresholds written before the measurement, including a band that says the cost
is environmental and no edit to our drawing will touch it. 1h bisects by adding
one layer at a time, five measurements, and terminates.
Recommended reverting both 1f edits, for a methodological reason more than an
aesthetic one: the bisection has to run against the real app, and 17% that does
not change the outcome is not worth paying for in look.
flutter analyze exit 0; flutter test exit 0, 350 tests. validate-protocol.ps1
exit 0.

Next step: revert 1f, then Gemini runs 1g and 1h. Claude starts step 3.

Open: the glass-versus-frames question still cannot be answered and I will not
guess at it a fourth time. If 1g finds a high floor, this stops being a question
about the look and becomes one about the engine on this class of device. Nothing
is committed and main is 28 ahead of origin.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:9006bd3c95703fccc6900d3050ca08ccd685b006de89380b4612bc1297448b57 over 499 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T14:08:07.162Z by claude-bd0bce05de513f55
- entry: sha256:985bd54443552088f8eefe6dc02ee7ba87ef77a2ce76c752d8148b24c1acb74c of this entry without this block
- scope: protocol checks only; host-project tests run separately

Newest entry first. Limit 150 lines.

## Archived 2026-09-25 from .ai/worklog/codex-53895f33df88f871.md

# Worklog: codex-53895f33df88f871

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-15 - Focused review of the latest fixes and gameplay work

Agent: Codex / codex-53895f33df88f871.

Action: Reviewed changes after eb47a89 through 261a2cb plus in-progress
Match-3/Home/Tetris work. Read DEC-0022: gameplay work is now authorized.

Result: Client/rules schema alignment, CI config provisioning, const defines
and serialized RNG address the earlier defects. Remaining F3 gap: DI captures
getCached() into a fixed GameModeAvailability reader; only Classic fetches fresh
RC and does not update that reader. Menu reopen therefore does not apply a new
flag, and Tetris/Match-3-only users have no fresh fetch path. ModeGate wraps Home
routes, not the screens themselves. Release/fatal acceptance remains open.
Strict analyze exit 0; Flutter test exit 0, 283 tests; diff --check exit 0.

Next step: Refresh shared mode availability independently of Classic and test
remote disable followed by re-entry. Continue DEC-0022 with scenario tests.

Open: Concurrent edits continued while reviewing; no device/playtest, clean CI
or emulator rerun in this focused review. No product edits by Codex.

Evidence:
- anchor: 261a2cba4c00ce5cd51f0220f02bf8a664b5b5cc, uncommitted changes present
- digest: sha256:afae83c0391d13121f89a65ab3d6453cb146f13e43a2ce36cc086dc1f59d8e8d over 465 tracked and untracked files
- digest format: 4
- recorded: 2026-09-15T17:23:06.140Z by codex-53895f33df88f871
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 1s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-15 - Independent audit of Claude execution and next priorities

Agent: Codex / codex-53895f33df88f871.

Action: At the owner's request, audited recorded Claude sessions, archived
worklogs, decisions, plan 14, source and recent history through eb47a89.
Created docs/audit/05_CLAUDE_EXECUTION_AUDIT_2026-09-15.md. Corrected stale TASK
under the cooperative lock and recorded the A6 evidence disagreement. Assumption:
this is an audit, not authorization to implement fixes or deploy. No product
code, external configuration, commits or pushes by this audit.

Result: Reproduced rejection of the actual Dart progress JSON in Firestore
emulator; the 16 existing tests use a different schema. Three diagnostic checks
also pass, confirming the rejection, acceptance of malformed permitted values,
and rejection of owner merge when a server field exists (19 total). Reproduced
Tetris/Match-3 RNG divergence after restore and optional AppConfig overrides
lost in AOT. Static gaps: missing google-services.json provisioning in CI,
unused mode flags, RC restart/offline fallback and incomplete purchase linking.
Read-only Firebase check: 57 live RC parameters exactly match tracked template;
utility pass remains enabled despite DEC-0008. Gradle dependencyInsight exit 0:
actual Billing 8.0.0, not the v7 described by older docs. Strict Flutter analyze
exit 0 and Flutter tests exit 0, 214. Diagnostics commits a6c0c2e/eb47a89 reviewed;
Claude's reported Redmi profile telemetry is useful but not release/fatal proof.

Next step: Fix client/rules contract and reproducible CI, then mode controls,
offline config, release observability and deterministic recovery; finish one
linked cosmetic purchase/restore before using cohorts to choose mode depth.
The detailed report distinguishes reproduced bugs, static findings and evidence
reported by Claude; its proposals do not amend DEC-0001..0021.

Open: No independent device purchase, release launch, live fatal/ANR or live
rules readback. Claude continued editing Home/Tetris UI during this audit;
those uncommitted layout changes are outside the eb47a89 review cutoff and left
to their writer. Generated Windows plugin status entries were also left intact.
Runtime probes/logs are disposable; observations are preserved in the report.

Evidence:
- anchor: eb47a898f2b0ae5ab75c02dce4dff8674b9a4047, uncommitted changes present
- digest: sha256:e5dae67b5a0f6b13d105d261835ae83575b9301cf631b357fac09629d54ef335 over 452 tracked and untracked files
- digest format: 4
- recorded: 2026-09-15T14:47:45.767Z by codex-53895f33df88f871
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 1s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-15 - Complete the interrupted Codex environment and MCP repair

Agent: Codex / codex-53895f33df88f871.

Action: Resumed the MCP repair from session 01a0a160 after the owner clarified
that this was environment work, not product stage A. Read its persisted user
instructions: disable missing L5 and temporarily disable L2/L3, preserving
configuration and data. Confirmed the earlier repair in D:/codex/config.toml:
removed embedded command quotes and disabled those six servers. No additional
configuration changes were necessary. C:/Users/Dmitry/.codex is a junction to
D:/codex. Re-ran stdio initialize, tools/list and a read-only tool call on every
enabled server. Added a disposable check through Codex 0.154.0 app-server
initialize + mcpServerStatus/list; no model turn or deployment was started.

Result: All five enabled MCP servers pass initialization, discovery and calls:
Playwright 0.0.68 (33 tools, browser_tabs/list), Chroma 1.6.0 (13 tools,
chroma_list_collections), DBHub 0.18.0 twice (2 tools each, SELECT 1), UI/UX Pro
1.0.0 (7 tools, search_all). Fresh Codex app-server discovers all 57 tools with
toolsError=null; stderr contains no WARN/ERROR/failed/warning matches. Runtime
status is null for this non-thread inventory request, so this is discovery
evidence, not a claim about the already-open desktop session. codex mcp list
outside the shell sandbox exits 0 without its sandbox-only arg0 warnings.
Configuration SHA256: 0afc182a30aed0c37bd4bb9d3c4175f59f010ccf09a0d7632cbe82e7d5c63372.
Details: .ai/runtime/mcp-probe-results.json and codex-mcp-host-results.json are
disposable; the verified summary above is the durable record. Mandatory project
checks: strict Flutter analyze exit 0; flutter test exit 0, 214 tests; protocol
validator exit 0, zero warnings. Git diff and diff --check reviewed.

Next step: Environment repair is complete within the owner's chosen scope.
Restart an already-open Codex client if it still shows the old MCP catalog.
Re-enabling L2/L3 requires a separate deployment and data-location check; L5
requires the missing launchers/runtime. No such restoration was attempted.

Open: The five-hour usage notice is account quota, not a server fault. Startup
checks do not certify vector search quality or database write workflows. Product
TASK/PLAN remain unchanged because this session's actual task was host repair;
their stale product statements were noticed but not acted upon. Before the
clarification, created a temporary stage-A branch and attempted read-only Firebase
discovery; returned to main, removed that empty branch, and moved its local debug
log into ignored runtime. No product implementation, commits or pushes by this
session. Concurrent changes observed in Gradle/.gitignore were left to their
writer. Two generated Windows plugin files have Git status entries but no
content diff and already match HEAD bytes; left their contents intact.

Evidence:
- anchor: ffb36508d240b3925f4db669d0c915b0a7faafb7, uncommitted changes present
- digest: sha256:df409dacd4e8b45426ba8898213011392502ae4610e188474a59454839142919 over 439 tracked and untracked files
- digest format: 4
- recorded: 2026-09-15T13:01:37.287Z by codex-53895f33df88f871
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 1s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-25 from .ai/worklog/gemini-a9fddb2389c5621b.md

# Worklog: gemini-a9fddb2389c5621b

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-16 - DEC-0024 Step 1g (Control Floor) and Step 1h (Render Pass Bisection)

Agent: Gemini / gemini-a9fddb2389c5621b.

Action: Executed Step 1g and Step 1h on physical Xiaomi Redmi Note 12 Pro (2209116AG, 120 Hz, Adreno 618, release build with `ENABLE_DIAGNOSTICS=true`):
1. Pre-check: Confirmed `git diff apps/mobile/lib/ui/effects/glass_board.dart` completely clean and unmodified before starting bisection.
2. Built dedicated `BenchmarkSceneScreen` implementing layers 1g (Control scene floor: solid color + moving small rectangle), 1h.2 (+ NebulaBackground), 1h.3 (+ Empty GameWidget), 1h.4 (+ Board Well: `paintBoardWell`), and 1h.5 (+ Stones: `paintGlassFacet` on 64 cells).
3. Reset timing stats before each run, sampled each layer for >= 34s, captured high-resolution timing receipts (`m16_step1g_control_scene.png` .. `m20_step1h5_stones.png`).
4. Re-ran full test suite (350/350 passed) and static analysis (0 warnings/infos).

Result: Raw measurement numbers on Xiaomi 2209116AG (all measurement windows >= 34s):
- Step 1g Control Scene (Floor):
  * Raster p50 / p90 / p99 = 5.29 / 8.60 / 10.08 ms (worst 16.64 ms), build p50 / p90 / p99 = 1.92 / 2.24 / 2.74 ms (worst 17.80 ms).
  * Window: 34.4s, 4065 frames, 118.3 fps. Jank: 31.75% (1143 / 3600). Total worst frame: 23.90 ms.
  * Self-check: 1000 / 5.29 = 189.0 fps vs 118.3 fps (hardware-clamped at 120 Hz panel). Screenshot: `m16_step1g_control_scene.png`.
- Step 1h Layer-by-layer Bisection:
  * 1h.2 (+ NebulaBackground): Raster p50 / p90 / p99 = 6.31 / 8.96 / 10.26 ms (worst 17.94 ms), build p50 = 2.27 ms. Window: 34.4s, 4070 frames, 118.5 fps. Delta to Layer 1: +1.02 ms. Self-check: 1000 / 6.31 = 158.5 fps vs 118.5 fps (ratio 1.34 <= 1.5x). Screenshot: `m17_step1h2_nebula.png`.
  * 1h.3 (+ Empty GameWidget): Raster p50 / p90 / p99 = 7.90 / 8.88 / 9.71 ms (worst 14.54 ms), build p50 = 1.90 ms. Window: 34.4s, 4068 frames, 118.3 fps. Delta to Layer 2: +1.59 ms. Self-check: 1000 / 7.90 = 126.6 fps vs 118.3 fps (ratio 1.07 <= 1.5x). Screenshot: `m18_step1h3_gamewidget.png`.
  * 1h.4 (+ Board Well): Raster p50 / p90 / p99 = 19.25 / 20.09 / 21.13 ms (worst 56.51 ms), build p50 = 7.59 ms. Window: 35.5s, 1863 frames, 52.5 fps. Delta to Layer 3: +11.35 ms. Self-check: 1000 / 19.25 = 51.95 fps vs 52.5 fps (ratio 1.01 <= 1.5x). Screenshot: `m19_step1h4_well.png`.
  * 1h.5 (+ Stones): Raster p50 / p90 / p99 = 19.24 / 20.04 / 21.47 ms (worst 53.64 ms), build p50 = 7.64 ms. Window: 36.9s, 1841 frames, 49.9 fps. Delta to Layer 4: -0.01 ms (~0.00 ms). Self-check: 1000 / 19.24 = 51.97 fps vs 49.9 fps (ratio 1.04 <= 1.5x). Screenshot: `m20_step1h5_stones.png`.
- Summary comparative bisection table (Raster p50):
  * Layer 1 (Control floor): 5.29 ms (118.3 fps)
  * Layer 2 (+ Nebula): 6.31 ms (+1.02 ms, 118.5 fps)
  * Layer 3 (+ GameWidget): 7.90 ms (+1.59 ms, 118.3 fps)
  * Layer 4 (+ Board Well): 19.25 ms (+11.35 ms, 52.5 fps)
  * Layer 5 (+ Stones): 19.24 ms (-0.01 ms, 49.9 fps)
- Checks: `flutter analyze --fatal-infos --fatal-warnings` exit 0; `flutter test` exit 0, 350/350 tests passing.

Next step: Reviewer evaluates Step 1g and 1h bisection numbers; owner and reviewer determine optimization path for board well / render pass.

Open: Google Play Console access for Stage C; Firebase Blaze upgrade.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:ce96dbc98f6dfa87e32c2807e8740fcb1aea3152fc73f17ee5628d4df32f9500 over 525 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T18:00:48.855Z by gemini-a9fddb2389c5621b
- entry: sha256:b9e0d9cf3af0deab5ec3c730fa9d082ebcc301581c4483480841b6bc3595b1e5 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

---



## 2026-09-16 - DEC-0024 Step 1f render pass pricing (1f-A blurs and 1f-B clipPath)

Agent: Gemini / gemini-a9fddb2389c5621b.

Action: Executed Step 1f render-pass price measurement on Xiaomi 2209116AG (120 Hz, Adreno 618, release build with `ENABLE_DIAGNOSTICS=true`):
1. Step 1f-A (Remove Blurs): Removed `MaskFilter.blur` from `halo` and `spark` in `paintGlassFacet` and from `groove` and `rim` in `paintBoardWell` in `apps/mobile/lib/ui/effects/glass_board.dart`. Built release APK, installed on device, and measured Classic idle and Match-3 idle. Captured board and diagnostics screenshots.
2. Step 1f-B (Remove ClipPath): Restored all 4 blurs. Removed `canvas.clipPath(path)`, `canvas.save()`, and `canvas.restore()` from `paintGlassFacet`, drawing inner bevel on contracted path scaled by 0.92 around centre. Built release APK, installed on device, and measured Classic idle and Match-3 idle. Captured board and diagnostics screenshots.
3. State in tree: Edits from 1f-B are preserved in `glass_board.dart` and marked temporary per owner instruction pending visual price decision.

Result: Raw measurement numbers on Xiaomi 2209116AG (method: reset timing stats -> enter mode -> 33s idle window -> capture board screenshot -> return to diagnostics -> capture diagnostics screenshot):
- 1f-A (Blurs removed, clipPath present):
  * Classic idle: build p50 / p90 / p99 = 1.95 / 2.40 / 5.36 ms (worst 35.23 ms), raster p50 / p90 / p99 = 29.03 / 29.42 / 30.34 ms (worst 76.03 ms), window 45.4s, 1671 frames, 36.8 fps, jank 97.73% (1633/1671). Self-check: 1000 / 29.03 = 34.45 fps vs 36.8 fps (ratio 1.068). Board screenshot: `m12_classic_board_1fa.png`.
  * Match-3 idle: build p50 / p90 / p99 = 3.88 / 4.25 / 6.67 ms (worst 23.23 ms), raster p50 / p90 / p99 = 34.38 / 34.99 / 36.22 ms (worst 67.22 ms), window 43.7s, 1306 frames, 29.9 fps, jank 97.63% (1275/1306). Self-check: 1000 / 34.38 = 29.08 fps vs 29.9 fps (ratio 1.028). Board screenshot: `m13_match3_board_1fa.png`.
- 1f-B (Blurs restored, clipPath removed):
  * Classic idle: build p50 / p90 / p99 = 2.02 / 2.43 / 6.51 ms (worst 50.02 ms), raster p50 / p90 / p99 = 31.27 / 31.73 / 33.39 ms (worst 92.10 ms), window 45.6s, 1533 frames, 33.6 fps, jank 96.35% (1477/1533). Self-check: 1000 / 31.27 = 31.98 fps vs 33.6 fps (ratio 1.051). Board screenshot: `m14_classic_board_1fb.png`.
  * Match-3 idle: build p50 / p90 / p99 = 2.23 / 3.75 / 5.91 ms (worst 29.99 ms), raster p50 / p90 / p99 = 36.94 / 37.58 / 39.97 ms (worst 127.02 ms), window 47.3s, 1407 frames, 29.7 fps, jank 91.68% (1290/1407). Self-check: 1000 / 36.94 = 27.07 fps vs 29.7 fps (ratio 1.097). Board screenshot: `m15_match3_board_1fb.png`.
- Summary comparative table (raster p50):
  * Classic idle: Baseline 31.95 ms -> 1f-A (no blurs) 29.03 ms (-9.14%) -> 1f-B (no clip) 31.27 ms (-2.13%).
  * Match-3 idle: Baseline 38.91 ms -> 1f-A (no blurs) 34.38 ms (-11.64%) -> 1f-B (no clip) 36.94 ms (-5.06%).
- Checks: `flutter analyze --fatal-infos --fatal-warnings` exit 0; `flutter test` exit 0, 350/350 tests passing.

Next step: Claude reviews step 1f measurements against pre-registered criteria and thresholds (DEC-0025); owner evaluates visual price from board screenshots. Claude continues step 3 (MusicPlaylistManager) and ducking (step 4c).

Open: Google Play Console access for Stage C; Firebase Blaze upgrade; owner visual tradeoff decision for glass material.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:ff4b26110f3cc74d488cf6b957fab8974b1d67bb2cca74e7d9abf7c2fbf2db8f over 498 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T13:08:48.255Z by gemini-a9fddb2389c5621b
- entry: sha256:54ac18adc27f9c20cd14a19fb3a86893f0a90e7be2fa70086c50df6beed6186a of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

---



## 2026-09-16 - DEC-0024 Steps 1d (Exp A & B), 1e (Match-3 Picture cache), 4a (Combo ladder), 4b (Hybrid placement)

Agent: Gemini / gemini-a9fddb2389c5621b.

Action: Executed batch under DEC-0024/DEC-0025 and acceptance criteria doc 04 (ed. 2):
1. Step 1d.A (Renderer comparison): Built release APK with `--enable-impeller=false` (`io.flutter.embedding.android.EnableImpeller=false`), measured Classic idle and Match-3 idle on Xiaomi 2209116AG (120 Hz display, Adreno 618). Reverted flag immediately; git diff clean.
2. Step 1d.B (Surface area): Temporarily wrapped `GameWidget` in `FractionallySizedBox(widthFactor: 0.25, heightFactor: 0.25)` in `game_loop_screen.dart`. Measured Classic idle on 2209116AG. Reverted edit immediately via git checkout; git diff clean.
3. Step 1e (Match-3 board cache): Added `_staticGemsPicture` caching in `match3_game.dart` keyed by board grid, igniting set, cell dimension, and geometry. Bonus gems with `_clock` shimmer, igniting, and hints remain dynamic. Disposed on rebuild/remove. Measured idle and active on 2209116AG.
4. Step 4a (Combo ladder): Resampled `combo.wav` deterministically into 7 mono PCM WAVs (`combo_01`..`07`) by $2^{n/12}$ ($n \in \{0, 2, 4, 7, 9, 12, 14\}$). Wired into `FlameGameSfxPlayer` with injected `nowUtcProvider`, 1..7 clamp, and 2.5s streak reset. Added 4 unit tests. Auditioned on device.
5. Step 4b (Placement thud): Backed up original to `data/audio_masters/piece_placed_v1_mono.wav`. Synthesized deterministic 100 ms mono PCM WAV (`piece_placed.wav`, 8864 B) with 110 Hz body + 2-3 kHz transient. Auditioned on phone speaker and headphones separately.

Result: Raw measurement numbers on Xiaomi 2209116AG (release build, `ENABLE_DIAGNOSTICS=true`):
- 1d.A Renderer (Skia vs Impeller baseline):
  * Classic idle: Impeller raster p50 = 31.95 ms (35.1 fps) -> Skia raster p50/p90/p99 = 15.61 / 16.39 / 19.53 ms (worst 233.74 ms), build p50/p90/p99 = 0.58 / 1.32 / 3.50 ms, window 33.7s, 2154 frames, 63.9 fps, jank 97.49%. Self-check: 1000/15.61 = 64.06 fps vs 63.9 fps (ratio 1.0025).
  * Match-3 idle: Impeller raster p50 = 38.91 ms (31.4 fps) -> Skia raster p50/p90/p99 = 52.77 / 54.93 / 64.56 ms (worst 787.29 ms), build p50/p90/p99 = 0.93 / 2.26 / 4.66 ms, window 33.6s, 716 frames, 21.3 fps, jank 95.25%. Self-check: 1000/52.77 = 18.95 fps vs 21.3 fps (ratio 1.124).
- 1d.B Surface Area (1/16 pixels, Impeller):
  * Classic idle: Full canvas raster p50 = 31.95 ms (35.1 fps) -> 1/4 canvas raster p50/p90/p99 = 24.96 / 25.29 / 26.80 ms (worst 54.60 ms), build p50/p90/p99 = 2.02 / 2.53 / 7.04 ms, window 37.2s, 1559 frames, 41.9 fps, jank 95.57%. Self-check: 1000/24.96 = 40.06 fps vs 41.9 fps (ratio 1.046).
- 1e Match-3 Picture Cache:
  * Idle: Before build p50 = 9.07 ms, raster p50 = 38.91 ms (31.4 fps) -> After build p50/p90/p99 = 3.23 / 3.70 / 8.53 ms (worst 49.73 ms), raster p50/p90/p99 = 38.88 / 39.63 / 41.79 ms (worst 112.72 ms), window 35.6s, 1022 frames, 28.7 fps, jank 97.55%. Self-check: 1000/38.88 = 25.72 fps vs 28.7 fps (ratio 1.116).
  * Active: Before build p50 = 8.71 ms, raster p50 = 38.61 ms (29.9 fps) -> After build p50/p90/p99 = 1.57 / 3.58 / 7.71 ms (worst 23.35 ms), raster p50/p90/p99 = 38.83 / 39.66 / 42.55 ms (worst 90.03 ms), window 38.7s, 1063 frames, 27.5 fps, jank 95.95%. Self-check: 1000/38.83 = 25.75 fps vs 27.5 fps (ratio 1.068).
- 4a Combo ladder: 7 WAVs (C4 D4 E4 G4 A4 C5 D5, +70.66 KB net delta). Injected clock unit tests pass (1..7 clamp, 2.5s reset, 2.4s non-reset). Melodic progression audible on device.
- 4b Placement thud: 100.0 ms mono PCM WAV (8864 B, -882 B). Speaker: 2-3 kHz transient is crisp and punchy with vibration; 110 Hz body is rolled off. Headphones: 110 Hz body is prominent and warm with crisp click attack. Zero latency on rapid placements.
- Checks: `flutter analyze --fatal-infos --fatal-warnings` exit 0; `flutter test` exit 0, 350/350 tests passing.

Next step: Claude reviews steps 1d, 1e, 4a, 4b against acceptance criteria and draws conclusions (DEC-0025); continues Step 3 (MusicPlaylistManager) and ducking (Step 4c).

Open: Google Play Console access for Stage C; Firebase Blaze upgrade.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:676206286363642ef758e0183e07094b5395e9016840b454498aac4614212c1f over 497 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T06:28:23.659Z by gemini-a9fddb2389c5621b
- entry: sha256:92ea92a585a75683ab686d385c8a4be1a8627601b7e01eaf9ecc2c082d98a8b6 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 5s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

---

## Archived 2026-09-25 from .ai/worklog/deepseek-5f13ae54cae74a62.md

# Worklog: deepseek-5f13ae54cae74a62

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-16 - Lead design/audio review of the overhaul proposals and a DEC-0023 draft

Agent: DeepSeek / deepseek-5f13ae54cae74a62.

Action: Owner asked for a Lead Game Designer / Audio-Core Engineer review of
docs/design/02_AUDIO_VISUAL_GAMEPLAY_OVERHAUL_PROPOSALS.md, the four Parkan
references in saplesmusic/, and a proposal package for DEC-0023. Read the
proposal document, the Gemini journal, TASK, the media manifest 20, and the
code the proposals would touch: music_controller.dart, flame_game_sfx_player,
haptics_controller, tetris_engine (lock delay already present), tetris_screen
(_PadButton repeat), block_puzzle_game (drag anchor), match3_game (idle hint
already present), tile.dart (SpecialKind), match_detector (reward rules),
basic_piece_generation_service. Measured the audio assets on disk. Re-ran the
suite. No product code, no shared document and no other journal was modified.

Result: The proposal document is good on diagnosis and weak on cost. Verified
against code, several of its items are already implemented and should be struck
from the scope rather than re-proposed: Tetris lock delay (500ms with a 15-reset
cap, guideline "infinity with cap"), DAS/ARR (130ms delay, 45ms repeat), the
Match-3 idle hint (4.5s, pulsing aura), and the Match-3 special gems (line,
bomb, colour bomb, plus a full special-on-special combo matrix in
special_combo.dart). Proposing them again would spend the round re-deciding
what is already shipped.

Measured facts the document does not state:
- music_loop.wav is 3.36 MB of the 3.77 MB audio directory. Four 3-minute
  tracks as 16-bit 44.1 kHz stereo WAV would be ~30 MB, an 8x growth of the
  audio payload and roughly +27 MB on a 53.4 MB APK. That is the single largest
  cost in the proposal and it is not priced anywhere in it.
- The SFX path already uses AudioPool with preload, a fallback and a recovery
  path; the music path uses FlameAudio.bgm, which is a single looping player
  with no crossfade. A playlist manager is therefore a real piece of work, not
  a config change, and FlameAudio.bgm cannot crossfade at all.

My position on the four areas:
1. Music: agree with the goal, reject the format. Ship Ogg Vorbis (or AAC/M4A)
   at ~96-128 kbps, not WAV: four 3-minute tracks land at ~6-9 MB total instead
   of ~30 MB, and the loop seam problem disappears because a 3-minute track does
   not need to be seamless. Keep one short WAV loop as the fallback for the
   first launch and for devices where the decoder fails. Do not build shuffle,
   favourites and a track picker in the same round - that is a settings surface
   for a game with no players yet.
2. Sound design: the pentatonic combo ladder is the best idea in the document
   and the cheapest to implement, because the engine already reports a combo
   streak and the player already has a pool. The sub-bass thud is a real
   improvement but needs a measured low-frequency check on a phone speaker,
   which reproduces almost nothing below ~150 Hz; pair it with the haptic or it
   will be inaudible on the device it is designed for. The Match-3 refusal
   sound is the highest-value single SFX in the list: silence on an invalid
   move is the worst feedback in the game.
3. Visual: shockwave and floating score text are the two that change how the
   game feels. Snap projection in Classic is already half-present (the anchor
   is computed and a preview is drawn); what is missing is the ghost silhouette
   under the finger. Screen shake must ship with an off switch and a default
   that respects the OS reduce-motion setting, or it is an accessibility
   regression.
4. Gameplay: the Fair Bag Randomizer is the only item in the document that
   changes whether the game is fair, and it is the one I would do first. The
   current generator weights hard pieces and caps them per triplet but never
   checks that the triplet is placeable, so a dead board can be dealt. Adaptive
   drag anchor is a real friction fix. Tetris swipes are a preference, not a
   defect, and should wait. Match-3 specials are already done.

Highest impact / lowest effort, in the order I would take them:
1. Fair Bag Randomizer in Classic (correctness, not polish).
2. Match-3 invalid-move feedback (sound + haptic + a small shake).
3. Pentatonic combo ladder (reuses the existing combo event and pool).
4. Floating score text (pure view, no engine change).
5. Ghost silhouette under the dragged piece in Classic.

Drafted a DEC-0023 proposal for the owner in the review message: scope limited
to those five plus the music format decision, with the WAV-to-Ogg conversion
and the playlist manager explicitly deferred to a second block. I did not write
it into DECISIONS.md - a proposal by an agent is not a decision, and the file is
append-only under a lock I did not take.

Next step: Owner decides on DEC-0023. If approved, the first three items are
independent of each other and of Blaze, Play Console and the device matrix.

Open: I did not listen to the Parkan references or to the generated assets, so
my judgement on the music is about format, size and architecture, not about
whether the tracks are good. I did not measure frame cost of the proposed VFX;
the shockwave and the shard particles are the two that could cost frames on the
Redmi and neither has a budget. The proposal document is untracked and has no
reviewer yet. I did not take the shared-document lock and did not edit TASK,
PLAN, DECISIONS or ARCHIVE.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:142d6288d65489da587a639bc253c28b6519b53be9b0c86de03a1d8eedc685cb over 481 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T02:42:35.614Z by deepseek-5f13ae54cae74a62
- entry: sha256:4efe4cad5a975816bfffadb540670be3047f478ec77bcff05d9fd65075b7e19b of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

---

## Archived 2026-09-25 from .ai/worklog/gemini-aaf28405ea94be70.md

# Worklog: gemini-aaf28405ea94be70

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-17 - Step 1j option (b): within-scene Config D measurement and pieces rasterization

Agent: Gemini (gemini-aaf28405ea94be70)

Action:
1. Within-scene measurement of Config D on half-filled board (26 occupied cells) to isolate the 5th term (rendering cost of `_cachedPiecesPicture`):
   - Used in-scene diagnostic bottom sheet in Classic Mode to switch config in-place with `FrameTimingRecorder.instance.reset()`.
   - Measured idle on Redmi Note 12 Pro (2209116AG, `ro.board.platform` = `sm6150`, 1080x2400 AMOLED 120 Hz) with release build (`--dart-define=APP_ENV=prod --dart-define=APP_FLAVOR=release --dart-define=ENABLE_DIAGNOSTICS=true`).
   - Window: 128.5 s, 3963 frames (cumulative 3963).
   - Captured receipts: `docs/design/m24_step1j_config_d_half_board.png` and `docs/design/m24_step1j_config_d_half_diag.png`.
2. Evaluated delta:
   - Baseline A (half-filled): raster p50 = 38.35 ms (35.0 fps).
   - Config D (half-filled): raster p50 = 31.93 ms (30.9 fps).
   - Delta: 38.35 - 31.93 = +6.42 ms (>= 4.0 ms).
3. Applied `ui.Image` rasterization to occupied board pieces (`_BoardComponent` in `block_puzzle_game.dart`) following Step 1i scheme:
   - Replaced `ui.Picture` caching with `toImageSync` scaled by physical pixel ratio (`boardWellPixelRatio()`).
   - Rendered using single texture blit via `canvas.drawImageRect` with `FilterQuality.low`.
   - Disposed image on board state changes, palette changes, visual preset changes, and component removal.
4. Measured Baseline A on half-filled board (26 occupied cells) after rasterization:
   - Window: 68.2 s, 2599 frames (cumulative 2599).
   - Captured receipts: `docs/design/m24_step1j_rasterized_pieces_half_board.png` and `docs/design/m24_step1j_rasterized_pieces_half_diag.png`.

Result:
- Config D half-filled board:
  - Window: 128.5 s, 3963 frames, 30.9 fps.
  - Build p50 / p90 / p99: 2.09 / 2.53 / 3.32 ms, worst build: 70.63 ms.
  - Raster p50 / p90 / p99: 31.93 / 33.42 / 33.97 ms, worst raster: 37.79 ms.
  - Total worst frame: 78.79 ms.
  - Delta from Baseline A: 38.35 - 31.93 = +6.42 ms.
- Baseline A with rasterized pieces on half-filled board:
  - Window: 68.2 s, 2599 frames, 38.1 fps.
  - Build p50 / p90 / p99: 1.81 / 2.15 / 2.85 ms, worst build: 11.41 ms.
  - Raster p50 / p90 / p99: 26.14 / 26.46 / 27.57 ms, worst raster: 34.48 ms.
  - Total worst frame: 37.61 ms.
  - Delta against pre-rasterization Baseline A: 38.35 -> 26.14 ms (-12.21 ms, -31.8%).
- Verification:
  - `flutter analyze --fatal-infos --fatal-warnings`: 0 issues found.
  - `flutter test`: 357 unit tests passed.
  - `validate-protocol.ps1`: Protocol OK, 0 warnings.

Next step:
- Handoff receipts and numbers to reviewer/owner for decision on Stage B / Step 6 unblocking.

Open:
- None for this measurement.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:bd5b52345201537c6a52ae762144a20c255a20b07b4f5453fc6eee43d263d75c over 536 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T23:29:07.327Z by gemini-aaf28405ea94be70
- entry: sha256:2f9e399b83b459312d371ed20a0fa64888c7d26505e6ad8533a59c892706574b of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-25 from .ai/worklog/gemini-918d5c9ee64c083e.md

# Worklog: gemini-918d5c9ee64c083e

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-17 - Step 1b.5 & Step 6 DEC-0024 measurements and implementation

Agent: gemini-918d5c9ee64c083e

Action:
- Fixed jank calculation in `FrameTimingRecorder` from `build + raster > threshold` to `max(build, raster) > threshold` (Step 1b.5).
- Added rule unit tests in `frame_timing_recorder_test.dart` verifying that at 120 Hz, build 5ms / raster 5ms is not jank, and raster 9ms is jank.
- Ran within-scene A/D comparison on Redmi Note 12 Pro (2209116AG, 120 Hz) with half-filled board (26 cells).
- Added pre-registered Step 6 benchmark harness (`Step6Benchmark`, `_Step6BenchRunnerComponent`, bottom sheet controls) supporting 8 concurrent events.
- Recorded Step 6 Baseline window on device with Effects OFF.
- Implemented lightweight vector `ShockwaveRingComponent` clipped to board via non-AA `clipRect` (scissor) and zero-blur pre-laid-out `ScorePopComponent` originating from `computeClearedCentroid`.
- Added unit tests for `computeClearedCentroid`, `ShockwaveRingComponent`, and `ScorePopComponent` lifecycle/slot independence (369/369 tests green).
- Recorded Step 6 Control window on device with Effects ON (8 simultaneous shockwave rings + 8 floating score popups).

Result:
- Step 1b.5 on-device measurement (half-board, 26 cells):
  - Config A (Baseline): 58.4 s, 2157 frames, 36.9 fps; build p50/p90/p99 = 1.82 / 2.15 / 3.25 ms; raster p50/p90/p99 = 26.13 / 26.45 / 27.62 ms; worst raster = 34.72 ms; jank = 98.42%. Self-check: 1000 / 26.13 = 38.3 fps vs 36.9 fps. Receipts: `m25_step1b5_config_a_half_board.png`, `m25_step1b5_config_a_half_diag.png`.
  - Config D (No Pieces Image): 58.3 s, 2152 frames, 36.9 fps; build p50/p90/p99 = 1.83 / 2.17 / 2.97 ms; raster p50/p90/p99 = 25.79 / 26.08 / 27.58 ms; worst raster = 32.41 ms; jank = 98.28%. Self-check: 1000 / 25.79 = 38.8 fps vs 36.9 fps. Receipts: `m25_step1b5_config_d_half_board.png`, `m25_step1b5_config_d_half_diag.png`.
  - Delta A - D: raster p50 = +0.34 ms; raster p99 = +0.04 ms.
- Step 6 on-device benchmark (8 concurrent events, half-board 26 cells):
  - Pre-registered thresholds: delta raster p99 <= 2.0 ms, delta raster p50 <= 1.0 ms. Pre-registered prediction: delta raster p99 <= 1.0 ms.
  - Baseline (Effects OFF): 52.8 s, 1960 frames, 37.1 fps; build p50/p90/p99 = 1.84 / 2.18 / 3.21 ms (worst build = 19.38 ms); raster p50/p90/p99 = 26.15 / 26.46 / 27.92 ms (worst raster = 34.51 ms); total worst frame = 51.15 ms; jank = 98.16%. Self-check: 1000 / 26.15 = 38.2 fps vs 37.1 fps. Receipts: `m26_step6_baseline_bench_half_board.png`, `m26_step6_baseline_bench_half_diag.png`.
  - Control (Effects ON): 93.4 s, 3527 frames, 37.7 fps; build p50/p90/p99 = 2.80 / 3.26 / 3.92 ms (worst build = 16.14 ms); raster p50/p90/p99 = 26.30 / 26.58 / 27.25 ms (worst raster = 39.26 ms); total worst frame = 43.14 ms; jank = 99.74%. Self-check: 1000 / 26.30 = 38.0 fps vs 37.7 fps. Receipts: `m26_step6_control_bench_half_board.png`, `m26_step6_control_bench_half_diag.png`.
  - Delta Control - Baseline: delta raster p50 = +0.15 ms; delta raster p99 = -0.67 ms; delta worst raster = +4.75 ms; delta build p50 = +0.96 ms.
- Validation:
  - `flutter analyze --fatal-infos --fatal-warnings` -> 0 issues.
  - `flutter test` -> 369/369 tests green.

Next step:
- Review by reviewer (DeepSeek / Claude / RuslanFomenko).
- Claude to implement Step 3 (MusicPlaylistManager) and Step 4c (ducking multiplier).

Open:
- None for steps 1b.5 and 6. External questions 1 and 4 remain unchanged.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:6d7af8625cb55c1b430a83eaebfa1cf1fb95fcd4c55695fca48b0381d1318085 over 548 tracked and untracked files
- digest format: 4
- recorded: 2026-09-17T00:43:50.911Z by gemini-918d5c9ee64c083e
- entry: sha256:19d1d4617630bd3c7452d4a71b986019e6766f11bfe5d1548981229d9cb22701 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-25 from .ai/worklog/gemini-2d06f930ed9e09d5.md

# Worklog: gemini-2d06f930ed9e09d5

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-17 - DEC-0024 Step 1j measurements and frame decomposition

Agent: gemini-2d06f930ed9e09d5 (Gemini, implementer)

Action:
- Measured Classic mode frame timing deconstructed by subtraction inside one scene across configs A..F, plus Config A on half-filled board (28/64 cells).
- Device: Xiaomi Redmi Note 12 Pro (2209116AG), platform `sm6150` (`adb shell getprop ro.board.platform`), GPU Adreno 618, 120 Hz AMOLED.
- Method: Diagnostic switch `Step1jDecomposition` behind `ENABLE_DIAGNOSTICS=true`. Layout and board size identical across all configs (verified via screenshots).
- Addressed four 1i review notes in timing signatures:
  1. Threshold is 8.33 ms (120 Hz vsync budget), not 16.7 ms.
  2. Jank metric sums build + raster, overstating jank rate due to pipeline parallelism.
  3. Percentiles/jank calculated over ring buffer (`sampleFrameCount <= 3600`), FPS over full window (`totalWindowFrames / windowDuration`).
  4. Processor platform `sm6150` confirmed via adb command.

Result:
- Raw measurement data:

| Config | Window | Frames (W/S) | FPS | Build p50/p90/p99 (worst) | Raster p50/p90/p99 (worst) | 1000/raster_p50 | FPS / (1000/p50) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A: Baseline | 61.9 s | 2318 / 2318 | 37.4 | 1.92 / 2.35 / 4.37 (18.31) | 26.25 / 26.64 / 28.90 (38.79) | 38.10 | 0.98 |
| B: No HUD/AppBar | 39.0 s | 1591 / 1591 | 40.8 | 1.90 / 2.39 / 4.50 (11.26) | 24.24 / 24.56 / 25.61 (29.24) | 41.25 | 0.99 |
| C: No ClipRRect | 39.1 s | 1524 / 1524 | 39.0 | 1.82 / 2.24 / 4.82 (15.95) | 25.55 / 25.88 / 27.23 (34.48) | 39.14 | 1.00 |
| D: No PiecesPic | 39.0 s | 1482 / 1482 | 38.0 | 1.78 / 2.23 / 4.44 (13.62) | 25.73 / 26.06 / 27.84 (31.52) | 38.87 | 0.98 |
| E: No RackPic | 38.9 s | 1507 / 1507 | 38.7 | 1.68 / 2.15 / 4.30 (12.33) | 25.32 / 25.66 / 26.56 (30.16) | 39.49 | 0.98 |
| F: No B+C+D+E | 38.9 s | 1710 / 1710 | 43.9 | 1.44 / 1.85 / 3.67 (20.30) | 22.57 / 22.93 / 23.99 (27.10) | 44.31 | 0.99 |
| A: Half-filled | 1568.7 s | 54836 / 3600 | 35.0 | 2.76 / 3.23 / 3.74 (7.86) | 38.35 / 38.70 / 39.09 (41.26) | 26.08 | 1.34 |

- Individual deltas vs Baseline A (raster p50 = 26.25 ms):
  - B (HUD / AppBar / Combo): 26.25 - 24.24 = +2.01 ms
  - C (ClipRRect / DecoratedBox): 26.25 - 25.55 = +0.70 ms
  - D (Starfield / Pieces Picture): 26.25 - 25.73 = +0.52 ms
  - E (Rack Pieces Picture): 26.25 - 25.32 = +0.93 ms
- Additivity comparison:
  - Sum of individual deltas (B+C+D+E): 2.01 + 0.70 + 0.52 + 0.93 = 4.16 ms
  - Measured combined reduction (F): 26.25 - 22.57 = 3.68 ms
  - Additivity discrepancy: |4.16 - 3.68| = 0.48 ms (threshold <= 3.0 ms)
- Half-filled board delta vs Baseline A:
  - Raster p50: 38.35 ms vs 26.25 ms (+12.10 ms for 28 glass pieces on board)
- Directed self-check: ratio `observed FPS / (1000 / raster_p50)` <= 1.50 for all 7 runs.
- Receipts: `docs/design/m24_step1j_config_{a..f}_board.png`, `docs/design/m24_step1j_config_{a..f}_diag.png`, `docs/design/m24_step1j_config_a_half_board.png`, `docs/design/m24_step1j_config_a_half_diag.png`.
- Checks: `flutter analyze --fatal-infos --fatal-warnings` (exit 0), `flutter test` (357 passed), `validate-protocol.ps1` (0 warnings).

Next step:
- Handoff to Reviewer for Step 1j evaluation and decision against exit criteria.

Open:
- None for Gemini on Step 1j.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:3604d010781c25868139b0d3e2ce034db9c0fb1b4f685c2beecdb528f6fe3e94 over 536 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T21:48:24.102Z by gemini-2d06f930ed9e09d5
- entry: sha256:c037404e5eec1eb9e69bd4da694068fde1a31bd482af749d04dbe67775178368 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-25 from .ai/worklog/gemini-fb4abe3f81b4b68b.md

# Worklog: gemini-fb4abe3f81b4b68b

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-16 - Step 1i: Board well rasterization to ui.Image

Agent: gemini-fb4abe3f81b4b68b

Action:
- Implemented DEC-0024 Step 1i: rasterized board well into `ui.Image` once via `picture.toImageSync(width, height)` at physical pixel scale (`boardWellPixelRatio` using `devicePixelRatio` and camera zoom). Rendered using `canvas.drawImageRect`.
- Added image disposal on geometry/pixelRatio changes and in `onRemove()` to prevent GPU memory leaks across Classic (`block_puzzle_game.dart`), Tetris (`tetris_game.dart`), Match-3 (`match3_game.dart`), and benchmark stand (`benchmark_scene_screen.dart`).
- Added unit tests in `apps/mobile/test/unit/ui/effects/glass_board_test.dart` for `rasterizeBoardWell`, `drawBoardWellImage`, and `boardWellPixelRatio`.
- Cleaned root repository directory by moving untracked screenshots `m16..m20` into `docs/design/`.
- Built release APK (`--dart-define=APP_ENV=prod --dart-define=APP_FLAVOR=release --dart-define=ENABLE_DIAGNOSTICS=true`), deployed to Xiaomi Redmi Note 12 Pro (2209116AG, 120 Hz, Adreno 618).
- Measured Stand Layer 4 (+Well), Stand Layer 5 (+Stones), and Classic (idle) on device with timing stats reset prior to each run. Captured board and diagnostics receipts in `docs/design/`.

Result:
- Verification: `flutter analyze --fatal-infos --fatal-warnings` -> 0 issues. `flutter test` -> 353/353 passed. `validate-protocol.ps1` -> 0 warnings.
- Raw on-device measurements (window >= 35 s):
  - Stand Layer 4 (+ Well via `ui.Image`):
    - Window: 130.2 s, 15443 frames, 118.6 fps, Jank (>16.7ms): 0.28% (10 / 3600)
    - Build p50 / p90 / p99: 2.32 / 2.67 / 3.17 ms, worst build: 12.57 ms
    - Raster p50 / p90 / p99: 7.85 / 9.26 / 10.43 ms, worst raster: 20.47 ms
    - Total worst frame: 22.65 ms
    - Receipts: `docs/design/m21_board_layer4.png`, `docs/design/m21_step1i_layer4_well.png`
    - Delta vs Layer 3 (7.90 ms): 7.85 - 7.90 = -0.05 ms (down from +11.35 ms in 1h.4)
    - Directed self-check: `1000 / raster_p50` = 127.39 fps; 1.5x threshold = 191.08 fps. Observed FPS: 118.6 fps <= 191.08 fps. Valid.
  - Stand Layer 5 (+ Stones via `paintGlassFacet`):
    - Window: 36.8 s, 2815 frames, 76.4 fps, Jank (>16.7ms): 94.60% (2663 / 2815)
    - Build p50 / p90 / p99: 6.62 / 10.45 / 12.99 ms, worst build: 23.55 ms
    - Raster p50 / p90 / p99: 11.69 / 12.94 / 16.12 ms, worst raster: 42.51 ms
    - Total worst frame: 52.42 ms
    - Receipts: `docs/design/m22_board_layer5.png`, `docs/design/m22_step1i_layer5_stones.png`
    - Directed self-check: `1000 / raster_p50` = 85.54 fps; 1.5x threshold = 128.31 fps. Observed FPS: 76.4 fps <= 128.31 fps. Valid.
  - Classic Mode (idle, no touches):
    - Window: 38.5 s, 1652 frames, 42.9 fps, Jank (>16.7ms): 86.44% (1428 / 1652)
    - Build p50 / p90 / p99: 1.82 / 2.27 / 5.77 ms, worst build: 73.79 ms
    - Raster p50 / p90 / p99: 25.52 / 26.16 / 26.92 ms, worst raster: 38.57 ms
    - Total worst frame: 80.49 ms
    - Receipts: `docs/design/m23_board_classic.png`, `docs/design/m23_step1i_classic_idle.png`
    - Directed self-check: `1000 / raster_p50` = 39.18 fps; 1.5x threshold = 58.78 fps. Observed FPS: 42.9 fps <= 58.78 fps. Valid.

Next step:
- Review of Step 1i measurements by reviewer / owner per DEC-0025.

Open:
- None for Step 1i.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:51f0720f4e36c3e1c5c124ee4909588ad754d442a82a4420d06a30a09e259e16 over 514 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T19:58:52.429Z by gemini-fb4abe3f81b4b68b
- entry: sha256:2e786b8d7370ba488da5810354bb6dca35e9d8d660d5531d0d4f950f01a3ad20 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-25 from .ai/worklog/deepseek-f7cc6b98736bc1f6.md

# Worklog: deepseek-f7cc6b98736bc1f6

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-17 - Review 14: 1k/7 accepted with corrections; 3/4c rejected on DEC constraints

Agent: DeepSeek / deepseek-f7cc6b98736bc1f6, stand-in for Claude, owner's request.

Action:
- Verified the day's work against the repo, not the relayed summary: read
  audit 13, journals gemini-918d5c/a9392d/da962c/1d2b79, the uncommitted diff,
  the music manager and the sfx ring, commits 36cf736 and 9dab5a9, and the 1k
  receipts. Device measurements not redone.
- Ran the checks myself: analyze 0 issues, tests 389/389, validator OK,
  handoff verify matches the tree.
- Wrote docs/design/14_DEC0024_STEPS_1K_7_3_4C_REVIEW.md; corrected .ai/TASK.md
  and .ai/PLAN.md under the lock. No product code touched.

Result:
- 1k accepted with corrections: stand floor 7.85 -> 31.55 ms on the Classic
  canvas (prediction 14..24 overshot; falsification not hit); 1k.2 was a
  5.89 ms regression (32.02 vs 26.13), not "0 gain"; post run on a seeded
  board across sessions, so not a within-scene measurement; closure per exit
  threshold stands at 26.1 ms / 38 fps. New open question: one well texture
  blit at full canvas costs ~27 ms.
- 7 accepted with corrections: bounded ring of six lowLatency players; live
  11-combo pass; crash.txt absent, the 20-min/10-restart protocol not
  documented.
- 3/4c not accepted: built by Gemini although DEC-0024 p.8 / DEC-0025 p.5
  assign the music layer to Claude; criteria written by the implementer.
  DEC-0024 p.2 (continuity across navigation) violated by integration (screens
  play on init and stop on dispose, track restarts); p.7a violated
  (audioplayers not in pubspec); p.7d violated (no AudioContext/focus).
  Ducking multiplier itself correct and unit-tested; no device check.
- Status "Completed" was an overclaim; corrected. Junk receipt
  m27_step1k_config_a_post_diag.png (notification shade) flagged.

Next step: owner - fix the music layer (Claude per p.8) plus device check, then
commit 1k/7/test and the music layer separately; masters after that.

Open: music p.2/7a/7d; step 7 protocol docs; PNG receipts and push decision.

Evidence:
- anchor: ce725354fd180f634dac5aedec2f008d11b94820, uncommitted changes present
- digest: sha256:50518c570e5c4af6fe448ae251a1e51753c4c00445f526cc71ae563eaca4d882 over 563 tracked and untracked files
- digest format: 4
- recorded: 2026-09-17T19:30:11.369Z by deepseek-f7cc6b98736bc1f6
- entry: sha256:07586799c475a0af4abd962d697f62cf2f543edbf2153c15c60622eb7a7aed16 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-17 - Step 1b.5 and 6 criteria written; budget closure recorded; prompt prepared

Agent: DeepSeek / deepseek-f7cc6b98736bc1f6, stand-in for Claude, owner's request.

Action:
- Wrote criteria for step 1b.5 (jank = max(build, raster), DEC-0025 p.3) and
  step 6 (shockwave + score numbers, 2 ms bench cap) into
  docs/design/04_DEC0024_ACCEPTANCE_CRITERIA.md; the step 6 measurement is
  pre-registered before any code.
- Updated .ai/TASK.md (74/80) and .ai/PLAN.md under the lock: frame budget
  closed on review 12's numbers; 1b.5 + 6 assigned to Gemini; open questions
  5 and 6 updated. No product code touched.

Result:
- Step 6 criteria built from DEC-0024 points 4 and 7c: vector ring clipped to
  the field, no fragment shaders; one number per clear step at the centroid,
  never per cell, `_pulse` slot untouched; Classic only.
- Pre-registered measurement: diagnostics bench of 8 concurrent events on the
  half-filled board, in-session on/off windows >= 35 s; p99 delta cap 2 ms,
  p50 cap 1 ms; prediction p99 <= 1 ms; a failed threshold means rework in the
  same step, reported as numbers.
- 1b.5 also carries the cheap A/D check from review 12 (expect A - D within
  ~1 ms, the blit cost) and the note that Classic jank stays ~100% after the
  fix because raster p50 ~26 ms really is over the 8.3 ms budget.
- Prompt for Gemini prepared for the owner: 1b.5 first, then step 6.

Next step: Gemini executes 1b.5 and 6; reviewer verifies both.

Open: steps 3 and 4c remain Claude's, gated only by the rate limit.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:1e59ee61f61333bb02756b8f48f567d785e06e60c1d160a8ff5816f4e35f6694 over 537 tracked and untracked files
- digest format: 4
- recorded: 2026-09-17T00:01:35.175Z by deepseek-f7cc6b98736bc1f6
- entry: sha256:6587fb65ac83490ed7a39d051b64f4381b8e81d407d7229ce223f474bf4a18ba of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-17 - Review of step 1j option (b): pieces rasterisation accepted, deltas unverified

Agent: DeepSeek / deepseek-f7cc6b98736bc1f6, stand-in for Claude, owner's request.

Action:
- Reviewed Gemini's follow-up (session gemini-aaf28405ea94be70) against review
  11, section 8, option (b): read the D-half and post-fix receipts, the
  in-scene bottom sheet, and the pieces rasterisation in block_puzzle_game.dart;
  re-derived every number; ran analyze (0 issues), tests (357/357), validator
  (OK), and verified Gemini's evidence digest. Did not redo device runs.
- Wrote docs/design/12_DEC0024_STEP1J_FOLLOWUP_REVIEW.md; updated .ai/TASK.md
  and .ai/PLAN.md under the lock. No product code touched.

Result:
- Both new windows verify digit for digit: D-half 31.93 ms p50 / 30.9 fps /
  128.5 s / 3963 frames; post-fix control 26.14 ms / 38.1 fps / 68.2 s / 2599.
  Self-check 0.99 and 1.00. Resets confirmed (cumulative == window).
- **The deltas do not stand as measurements.** +6.42 subtracts the old session's
  28-cell board (Goals 2/3, Best 190, 26-min window tail) from the new session's
  26-cell board; 1j's own rule forbids cross-scene subtraction. The two new runs
  are mutually inconsistent under equal conditions: post-fix A (26.14) is
  5.79 ms faster than pre-fix D (31.93), which hides more. One run is
  mis-conditioned; the saving is bounded (5.79 .. 12.21 ms) but unmeasured.
- The fix itself: code follows the 1i scheme (physical pixels, toImageSync,
  dispose on state/palette/preset/remove, drawImageRect + FilterQuality.low,
  hideD gate intact). Accepted on mechanism plus the post-fix control; current
  working numbers 26.25/37.4 empty and 26.14/38.1 half-filled.
- Recommended unblocking step 6 with the pre-registered 2 ms effect cap,
  measured on the half-filled board. Optional cheap check: post-fix in-scene
  A/D toggle to show the blit is ~free. Notes: no unit test for the new cache
  (357 unchanged; 1i extracted and tested rasterizeBoardWell); worst build
  70.63 ms is the switch transient.

Next step: Owner decision on closing the frame budget and starting step 6
(shockwave + score numbers) with the 2 ms cap.

Open: unit test for the pieces image cache; jank metric defect (DEC-0025 p.3)
unassigned; steps 3 and 4c remain Claude's, gated only by the rate limit.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:9e3b74d3f9adc22353fdde090e3b86c059fa963a569cf159134f498f4a39e5fc over 537 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T23:55:08.489Z by deepseek-f7cc6b98736bc1f6
- entry: sha256:b40dd6c674ef4162104f22777d26a1687695844f46ca50d3abc321f9ca8bc7e9 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-25 from .ai/worklog/claude-0789722ac9b82f43.md

# Worklog: claude-0789722ac9b82f43

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-17 - Commit DEC-0024, slow the effects, close a crash class

Agent: claude-0789722ac9b82f43

Action:
- Owner answered the three open questions: commit on a branch, run 1k, and the
  effects run 3-5x too fast. Owner also reported Match-3 closing on some
  combos and some restarts.
- Created `dec-0024/av-polish` and committed the whole effort in six thematic
  commits, then two more for this session's work. Nothing pushed.
- Investigated the crash by reading, since no device or log was available.
- Slowed the clear effects and added tests for the rule.
- Wrote criteria for step 1k and a new step 7 into doc 04; updated TASK and
  PLAN under the lock.

Result:
- **Committed.** Eight commits on the branch, working tree clean. The split is
  by area, not by step: step isolation was no longer recoverable, which is the
  same gap reviews 11 and 12 had to work around. Receipts (~18 MB) went in;
  nothing is pushed, so that is still reversible.
- **The crash is a native crash, not an exception.** `bootstrap.dart` wires the
  zone guard, `FlutterError.onError` and `PlatformDispatcher.onError` to
  Crashlytics, so a Dart error would be reported and the app would survive. An
  app that closes outright is SIGSEGV/SIGABRT or OOM - which is what drawing a
  disposed `ui.Image` or replaying a disposed `ui.Picture` does.
- Found and fixed five caches written as `field?.dispose(); field = rebuild()`,
  which holds a disposed handle for the length of the rebuild and keeps it
  forever if the rebuild throws. In Match-3 there are forty lines of drawing
  inside that window. Every one now clears the field first; every draw site
  tolerates a null cache instead of asserting with `!`.
- Three more lifecycle holes: `RackPieceComponent` replaced its cached Picture
  without disposing it on every palette change, preset change and **drag** - a
  native-memory leak; Match-3 and Tetris stayed installed as the controller's
  visual listener after `onRemove`; and `toImageSync` images live on the GPU,
  so all three screens now drop their caches on resume.
- **This is a defence, not a diagnosis.** I could not reproduce the crash and
  had no logcat. Step 7 asks for the log before anyone calls it fixed, and
  says not to revert these fixes either way, because the defects are real
  independently.
- **Effects slowed 3.5x** via one constant, `kEffectTimeScale`, applied to the
  effects' own clock rather than only to durations - stretching a particle's
  life while gravity keeps running only rains it off the board. Input-driven
  motion (rack tween, camera shake) deliberately untouched: a slow answer to a
  touch reads as lag, not weight.
- Checks: `flutter analyze --fatal-infos --fatal-warnings` exit 0;
  `flutter test` **375 passed** (369 + 6 new), exit 0; `validate-protocol.ps1`
  exit 0 (Evidence).

Next step:
- Owner hands steps 1k and 7 to Gemini; both have criteria in doc 04.
- Steps 3 and 4c are mine and start next.

Open:
- The crash is undiagnosed. Reproduce it with a logcat before believing it gone.
- Slower effects overlap more, not less. Whether a clear still reads as one
  beat is an eyes-on question on device, not something a profiler answers.
- 1k can still falsify the surface-area hypothesis, in which case the frame
  budget closes at 26.1 ms / 38 fps.
- Still no unit test for the occupied-cells image cache (review 12, 4.1).

Evidence:
- anchor: 9dab5a93882ae76dc272a6d9d455aa47bec54ef5, uncommitted changes present
- digest: sha256:c9635ed2b5c256c811390e12c949dbef68c9a6e8b2489fa7ead3fd309588b06e over 550 tracked and untracked files
- digest format: 4
- recorded: 2026-09-17T01:19:11.425Z by claude-0789722ac9b82f43
- entry: sha256:b171f0993036b950e52ca1d04ff96bd6b361fac63cd5e77f9bcc930f05fcc874 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 1s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-17 - Full DEC-0024 audit, consolidation and cleanup

Agent: claude-0789722ac9b82f43

Action:
- Audited steps 1b.5 and 6 (`gemini-918d5c9ee64c083e`), which had no review,
  and re-read reviews 05..12 to consolidate every number into one document.
- Ran the checks myself rather than quoting them: `flutter analyze
  --fatal-infos --fatal-warnings` and `flutter test`.
- Read the new code: the jank rule, `ShockwaveRingComponent`,
  `ScorePopComponent`, `computeClearedCentroid`, their wiring into real clears,
  and the step 6 bench harness.
- Wrote `docs/design/13_DEC0024_AUDIT_AND_STATE.md` - the consolidated state.
- Updated `.ai/TASK.md` and `.ai/PLAN.md` under the lock; added a pointer from
  doc 04 to doc 13. Touched no product code.
- Cleanup: removed seven journals that held only a template header and no
  entry, recording their existence in `.ai/ARCHIVE.md` first; removed the
  ignored `firestore-debug.log`. Worklog directory 20 files -> 12.

Result:
- Checks: analyze `No issues found!` exit 0; `flutter test` **369 passed**
  exit 0; `validate-protocol.ps1` exit 0 (Evidence). Gemini's reported numbers
  reproduce.
- **Step 1b.5 accepted.** `max(build, raster)` replaces the sum - correct, the
  stages are pipelined - and the rule has tests. The A/D pair on a half-filled
  board is +0.34 ms, inside the +-1.0 ms prediction, and it is an in-session
  subtraction, which is the form the step required.
- **Step 6: code accepted, measurement reformulated.** The code meets DEC-0024
  points 4, 7 and 7c: scissor clip, no saveLayer, no shader, text laid out
  once, self-removing, one effect per event at the centroid, `_pulse`
  untouched. But the raster deltas (+0.15 / +0.12 / **-0.67**) sit inside the
  instrument's resolution and fps rose with effects on, which no real cost
  does. The 2 ms cap holds as an **upper bound from noise**, not as a
  measurement. The resolvable cost is **+0.96 ms build**, and the report did
  not name it as the result.
- **Derived the instrument's resolution, which nobody had stated:** ~0.7 ms
  between sessions (25.52 vs 26.25 on an unchanged scene), ~0.3 ms within one.
  Several deltas across the project are smaller than that.
- **Consolidating the table exposed the real open fact:** Classic's raster p50
  has stayed inside 22.6-26.3 ms across *every* configuration ever measured,
  while the drawing inside them varied by multiples. Four named layers explain
  4.16 ms of 17.67; config F, with all of them gone, is still 14.7 ms above the
  stand.
- **Named a fifth-term candidate:** the stand draws `GameWidget` in a 360x360
  box, Classic gives it the full screen height and offsets the board with
  viewport insets. Two different surface sizes were being compared throughout.
  Pre-registered as step 1k with a falsification threshold and an exit rule.
  It is a hypothesis from reading code, and those are 0:3 in this project.
- Carried DeepSeek's correction: my 1i note "2209116AG has a different chip"
  was wrong. It is SM7150 / Adreno 618, checked by `adb` in review 11.

Next step:
- Owner decides on step 1k, and on committing DEC-0024 at all.
- Steps 3 and 4c are mine and blocked by nothing.

Open:
- **Nothing of DEC-0024 is in Git.** Last commit predates the effort; 28
  commits unpushed; reviews, tests, diagnostics and 39 receipts untracked.
- No unit test for the occupied-cells image cache (review 12, point 4.1).
- Diagnostics flag tests are inert in CI without the define (review 11, 7.1).
- Four or five effects now fire on one clear against DEC-0024 point 7.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:a46c2ba05487fe7c4e74e184ce2a86341e4cf86a35c24d4446ef9fd288994241 over 549 tracked and untracked files
- digest format: 4
- recorded: 2026-09-17T00:59:44.207Z by claude-0789722ac9b82f43
- entry: sha256:cda6a8a5c4deed79e2eca8205998fdc03e8d7b13b1ba6a8c489f70b1e9bd61c8 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 1s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-25 from .ai/worklog/antigravity-addff8667515dfd9.md

## 2026-09-25 - MAR execution and complete remediation of all 6 conditions

Agent: antigravity-addff8667515dfd9

Action:
1. Executed Mandatory Adversarial Review (MAR) per docs/audit/10_MANDATORY_ADVERSARIAL_REVIEW_PROMPT.md and DEC-0027 p.3 on cycle W1-W4 commits (0400582..e33e597). Review verdict recorded from independent DeepSeek channel in .ai/runtime/mar/judge-deepseek.md (REJECT with 6 conditions).
2. Condition 1 (P0): Restored missing DEC-0028 block (approved by RuslanFomenko on 2026-09-21) into .ai/DECISIONS.md on main branch; verified 28 blocks by validate-protocol.ps1.
3. Condition 2 (P1): Completely removed utility_tools_pass and includeUtilityPass from bundled_remote_config_defaults.dart, remoteconfig.template.json, LocalCatalogIapStoreService, GooglePlayBillingService, DebugIapStoreService, StoreController, GameLoopController, di_container.dart, and test suites. Added dedicated assertions in store_controller_test.dart and debug_iap_store_service_test.dart verifying absence of utility SKU in catalog and defaults per DEC-0026 p.2.
4. Condition 3 (P1): Aligned docs/product/01_PRODUCT_VISION_KPI.md (lines 8, 29) and docs/product/02_TECHNICAL_REQUIREMENTS_SPEC.md (line 62) to 38-40 FPS release baseline and cosmetics non-consumables only per DEC-0026 p.5.
5. Condition 4 (P1): Accurately qualified Stage W3 in docs/roadmap/05_IMPLEMENTATION_STATUS.md and .ai/runtime/mar/cycle-report.md as code & build pipeline test-ready (W3.1-W3.5), with W3.6-W3.8 (tester APK distribution and telemetry gathering) scheduled for external testing.
6. Condition 5 (P1/P2): Implemented pre-emptive seamless crossfade in MusicPlaylistManager (via duration & position stream monitoring before track end, with fallback on completion). Restored default ducking factor to -3 dB (0.70794578, kDuckFactorMinus3dB) across MusicPlaylistManager and MusicController per DEC-0024 and cycle-report line 33. Fixed play() mid-crossfade to restore activePlayer to full volume and restore currentTrackIndex. Removed screen-transition track switches from game_loop_screen, tetris_screen, match3_screen, and home_screen per DEC-0024. Added test cases 2b and 4b, and asserted lastDuckFactor in flame_game_sfx_player_test.dart.
7. Condition 6 (P2): Added __pycache__/, *.py[cod], and data/audio_masters/ to .gitignore. Untracked 96 WAV masters (881 MB) and 3 .pyc files from git index (git rm -r --cached) to eliminate repository bloat while preserving files on disk.

Result:
- `flutter analyze --fatal-infos --fatal-warnings`: Exit 0 (0 issues found).
- `flutter test --no-pub`: Exit 0 (457/457 tests passing, all unit and widget tests green).
- `powershell -File .\validate-protocol.ps1`: Protocol OK (28 decisions verified).

Next step:
- Record protocol evidence with protocol-handoff.cjs.
- Release protocol lock.
- Human owner accepts MAR remediation and commits the checkpoint.

Open:
None. All 6 MAR conditions satisfied.

Evidence:
- anchor: e33e59711a79cc4969f38accdc7d96e6c5c1d2a7, uncommitted changes present
- digest: sha256:c68fb592f7acd5f7b3693e1b2422e1bac86848f96943732ed5818df9c722b1de over 601 tracked and untracked files
- digest format: 4
- recorded: 2026-09-24T23:25:22.984Z by antigravity-addff8667515dfd9
- entry: sha256:f7964488663e25b7eb3b0cde463974efd2df0953741516201910e5896b103f87 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

## Archived 2026-09-25 from .ai/worklog/antigravity-addff8667515dfd9.md

## 2026-09-25 - Archive 11 oldest worklogs to eliminate protocol validator warning

Agent: antigravity-addff8667515dfd9

Action:
1. Checked .ai/worklog directory against AGENTS.md section 8 size limits (30-file maximum, 36 files present triggering a validator warning).
2. Selected 11 oldest closed journals from 2026-09-14 through 2026-09-17:
   - codex-d56f1c2c371b35a6.md
   - claude-bd0bce05de513f55.md
   - codex-53895f33df88f871.md
   - gemini-a9fddb2389c5621b.md
   - deepseek-5f13ae54cae74a62.md
   - gemini-aaf28405ea94be70.md
   - gemini-918d5c9ee64c083e.md
   - gemini-2d06f930ed9e09d5.md
   - gemini-fb4abe3f81b4b68b.md
   - deepseek-f7cc6b98736bc1f6.md
   - claude-0789722ac9b82f43.md
3. Appended complete verbatim contents of all 11 journals into .ai/ARCHIVE.md with source attribution headers under cooperative lock.
4. Removed the 11 archived files from .ai/worklog via git rm.
5. Updated .ai/TASK.md to Completed.

Result:
- .ai/worklog file count reduced from 36 to 25 (under the 30-file limit).
- validate-protocol.ps1: Protocol OK. 0 warning(s), 28 decisions verified, all checks PASS.
- No history deleted; all text preserved verbatim in .ai/ARCHIVE.md.

Next step:
- Record protocol handoff evidence with protocol-handoff.cjs.
- Release cooperative lock.
- Human owner reviews and commits the changes.

Open:
None.

Evidence:
- anchor: 463890ffaf5b2baf83a58676f15fffd021e803c2, uncommitted changes present
- digest: sha256:7cff92469932aac6659e3f3f26b16a6cb962cd2951fb5872c8f7e05e09ffaba7 over 601 tracked and untracked files
- digest format: 4
- recorded: 2026-09-25T00:02:26.187Z by antigravity-addff8667515dfd9
- entry: sha256:53263a590c562365dcc06e204880531a884602a86c51433e0b0798c2ca7fc501 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

### From .ai/worklog/antigravity-addff8667515dfd9.md, archived 2026-09-25

## 2026-09-25 - Comprehensive documentation synthesis and repository cleanup

Agent: antigravity-addff8667515dfd9

Action:
1. Synthesized DEC-0024 performance profiling, frame bisection, and 4 falsified hypotheses (nebula, blurs, clipPath, gem vs well) into docs/design/01_PERFORMANCE_AND_GRAPHICS_LESSONS.md.
2. Synthesized evaluated and rejected gameplay hypotheses (P2W, rubber-band difficulty, fever mode, social bloat) into docs/product/03_GAMEPLAY_HYPOTHESES_AND_DECISIONS.md.
3. Synthesized development history and completed plans (Plans 12-15, Sprints 1-9) into docs/roadmap/02_HISTORICAL_PLANS_SUMMARY.md.
4. Moved completed raw plans, architecture specs, and step reviews into docs/archive/ (roadmap, design, architecture, audit).
5. Deleted obsolete files: 48 diagnostic PNG screenshots (35 MB) from docs/design/, duplicate date-suffixed audio docs, obsolete sprint issue scripts, generate_placeholders.py, and early sprint backlogs.
6. Updated docs/archive/README.md, docs/DOCS_CHANGELOG.md, and docs/roadmap/05_IMPLEMENTATION_STATUS.md.

Result:
- Repository clean: 35 MB of heavy intermediate images and redundant documents removed.
- docs/ streamlined and authoritative.
- flutter analyze --fatal-infos --fatal-warnings: exit 0 (0 issues).
- flutter test --no-pub: exit 0 (457/457 tests passing).
- validate-protocol.ps1: exit 0 (0 warnings).

Next step:
- Record and verify protocol handoff evidence.
- Release protocol lock.
- Human owner reviews, commits, and pushes changes.

Open:
None.

Evidence:
- anchor: 475bbd2fc6ec43740e391941c9fd80c28ad8b184, uncommitted changes present
- digest: sha256:0c0a4d7f63e6fc81f116b2a5c8b9cf9530c85742d4871f625ef3e04040c3f9cb over 547 tracked and untracked files
- digest format: 4
- recorded: 2026-09-25T00:12:08.991Z by antigravity-addff8667515dfd9
- entry: sha256:72c42a372973b8243af6aefa2d12613481184ed0f494f64d7b0fbf34e47a595e of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

### From .ai/worklog/antigravity-addff8667515dfd9.md, archived 2026-09-25

## 2026-09-25 - Flame VFX Juice Research: Stage 0 audit and Stage 1 easing spikes

Agent: antigravity-addff8667515dfd9

Action:
1. Formalized the comprehensive research plan in docs/design/02_VFX_JUICE_RESEARCH_PLAN.md and updated .ai/PLAN.md (53 lines, within limits).
2. Stage 0 Audit: Mapped animation points across Classic, Tetris, Match-3. Verified Flame 1.18.0 EffectController APIs and confirmed procedural vector rendering pipeline (glass_board.dart, ui.Image baking).
3. Stage 1 Spike: Implemented EasingPresets in apps/mobile/lib/ui/effects/easing_presets.dart with standardized curves (pieceDropCurve, scorePopupCurve, rackSpawnCurve, cascadeDropCurve, squashCurve).
4. Stage 1 Optimization: Refactored ScorePopComponent in block_puzzle_game.dart — eliminated per-frame TextPainter and layout() allocations in render(), applied easeOutBack overshoot trajectory via EasingPresets.
5. Added unit test suites in easing_presets_test.dart and shockwave_and_score_test.dart.
6. Archived oldest MAR worklog entry into .ai/ARCHIVE.md to stay within 150-line journal limit.

Result:
- flutter analyze --fatal-infos --fatal-warnings: exit 0 (0 issues).
- flutter test --no-pub: exit 0 (465/465 tests passing, +8 new tests).
- validate-protocol.ps1: exit 0 (0 warnings, 28 decisions verified).

Next step:
- Record protocol handoff evidence with protocol-handoff.cjs.
- Release protocol lock.
- Human owner reviews and commits the checkpoint.

Open:
None.

Evidence:
- anchor: 3ecc715dd04a945c95810030df9763e9f050d944, uncommitted changes present
- digest: sha256:c4d4b853962181ef8b199e080be220f4396d56c29833734f5f41b7f67195a98c over 550 tracked and untracked files
- digest format: 4
- recorded: 2026-09-25T00:20:21.834Z by antigravity-addff8667515dfd9
- entry: sha256:851eceebb08e0667c21c8c5be2bbe3c1d28ce2b12bf4e01ca04d843eebf975bc of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 4s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

### From .ai/worklog/antigravity-addff8667515dfd9.md, archived 2026-09-25

## 2026-09-25 - Flame VFX Juice: Stage 1 Polish & Stage 2 VfxDirector Architecture

Agent: antigravity-addff8667515dfd9

Action:
1. Implemented strongly-typed VfxEvent sealed hierarchy and VfxLevel enum in apps/mobile/lib/ui/effects/vfx_events.dart.
2. Extracted and modularized VFX components into dedicated files under ui/effects/: shockwave_ring_component.dart, score_pop_component.dart, line_clear_flash_component.dart, combo_pulse_component.dart.
3. Optimized ComboPulseComponent: eliminated per-frame TextPaint/TextStyle allocations via cached TextPainter and matrix scaling.
4. Created VfxDirector in apps/mobile/lib/ui/effects/vfx_director.dart: manages BurstField particle budget, coordinates shockwaves, floating scores, combo pulses, full-board flashes, screen shakes, and All Clear fanfare with VfxLevel gating and Reduced Motion support.
5. Integrated VfxDirector into BlockPuzzleGame, decoupling game loops from direct component instantiation and adding tactile piece placement landing particle juice.
6. Re-exported all extracted VFX components from block_puzzle_game.dart for 100% backward compatibility.
7. Added unit test suite in test/unit/ui/effects/vfx_director_test.dart covering all events, VfxLevel, and Reduced Motion.

Result:
- flutter analyze --fatal-infos --fatal-warnings: exit 0 (0 issues).
- flutter test --no-pub: exit 0 (478/478 tests passing, +13 new tests).
- validate-protocol.ps1: exit 0 (0 warnings, 28 decisions verified).

Next step:
- Record protocol handoff evidence with protocol-handoff.cjs.
- Release cooperative lock.
- Human owner reviews, commits, and pushes changes.

Open:
None.

Evidence:
- anchor: ea9d2b666de2507613e806ab0666a8e46c41b4d4, uncommitted changes present
- digest: sha256:e359a4ef400f59a22b6acdbb293673fdd9893aa226a4f98b6d500aa6ba0983eb over 557 tracked and untracked files
- digest format: 4
- recorded: 2026-09-25T00:33:23.949Z by antigravity-addff8667515dfd9
- entry: sha256:2144ca1365166005e337dbdd4aeb6cc5fce7a5376ba4ae5f709a4f70345fa68c of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

### From .ai/worklog/antigravity-addff8667515dfd9.md, archived 2026-09-25

## 2026-09-25 - Flame VFX Juice: Stage 4 Shaders (FragmentProgram Piece & Gem Aura)

Agent: antigravity-addff8667515dfd9

Action:
1. Created GLSL runtime effect in shaders/piece_aura.frag: pulsing chromatic aura with 6-fold radial wave perturbation and smooth glow envelope.
2. Declared shaders/piece_aura.frag under flutter.shaders in apps/mobile/pubspec.yaml.
3. Created PieceAuraShader in apps/mobile/lib/ui/effects/piece_aura_shader.dart: manages FragmentProgram loading, uniforms (resolution, time, color, intensity), and provides a procedural radial gradient fallback for headless test runners and unsupported GPUs.
4. Integrated PieceAuraShader into VfxDirector with free-running clock and dynamic VfxLevel gating.
5. Wired PieceAuraShader through RackPieceComponent in block_puzzle_game.dart: pulses dynamic aura behind dragged piece in player's hand when vfxLevel == VfxLevel.full.
6. Added unit test suite in test/unit/ui/effects/piece_aura_shader_test.dart (5/5 tests passing).

Result:
- flutter analyze --no-pub --fatal-infos --fatal-warnings: exit 0 (0 issues).
- flutter test --no-pub: exit 0 (498/498 tests passing, +5 new tests).
- validate-protocol.ps1: exit 0 (0 warnings, 28 decisions verified).

Next step:
- Record protocol handoff evidence with protocol-handoff.cjs.
- Release cooperative lock.
- Human owner reviews, commits, and pushes changes.

Open:
None.

Evidence:
- anchor: 9d5fc45126618c85cea197fdbea8ebb4005ba339, uncommitted changes present
- digest: sha256:ff8ed0cdb25ad97703b37beee805e924c7345b6d0a6762a6eecbbecf420993db over 565 tracked and untracked files
- digest format: 4
- recorded: 2026-09-25T01:00:57.017Z by antigravity-addff8667515dfd9
- entry: sha256:a64040cb9593a853eb6dda13236f4ba6c2c544d73ff5d0d3e26ab0f8eac4a8bf of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

### From .ai/worklog/antigravity-addff8667515dfd9.md, archived 2026-09-25

## 2026-09-25 - Flame VFX Juice: Stage 6 Procedural Tile Atlas Baking & Batching

Agent: antigravity-addff8667515dfd9

Action:
1. Created GlassTileAtlas in apps/mobile/lib/ui/effects/glass_tile_atlas.dart: pre-bakes procedural paintGlassFacet tiles into a GPU-resident ui.Image texture atlas with physical-pixel scaling (devicePixelRatio) and transparent gutters.
2. Implemented drawTile (single-blit drawImageRect) and drawBatch (single-call drawRawAtlas with RSTransform scaling) for high-performance rendering.
3. Provided pre-configured factories bakeTetris (7 neon tetromino types) and bakeMatch3 (6 distinct geometric gem shapes and colors).
4. Integrated GlassTileAtlas into TetrisFlameGame: cached _tileAtlas, replaced per-frame multi-pass paintGlassFacet calls for locked and active minos with instant atlas blits, with graceful fallback for clearing squash animations.
5. Integrated GlassTileAtlas into Match3Game: cached _tileAtlas, optimized gem rendering in _paintGem with instant atlas blits, with graceful fallback for charged ignitions.
6. Handled surface lifecycle safety in dropCachedSurfaces() across both TetrisFlameGame and Match3Game.
7. Added unit test suite in test/unit/ui/effects/glass_tile_atlas_test.dart (6/6 tests passing).

Result:
- flutter analyze --fatal-infos --fatal-warnings: exit 0 (0 issues).
- flutter test --no-pub: exit 0 (493/493 tests passing, +6 new tests).
- validate-protocol.ps1: exit 0 (0 warnings, 28 decisions verified).

Next step:
- Record protocol handoff evidence with protocol-handoff.cjs.
- Release cooperative lock.
- Human owner reviews, commits, and pushes changes.

Open:
None.

Evidence:
- anchor: 5ff3aeae33ca375c94989766bd501c29e98a4ff8, uncommitted changes present
- digest: sha256:2b0476c0cb62803b327cfcf278933d086b19097bc885acf48faace413cd5e348 over 562 tracked and untracked files
- digest format: 4
- recorded: 2026-09-25T00:53:41.952Z by antigravity-addff8667515dfd9
- entry: sha256:5ae2e56aa83a410060b6961c27ac11f2a0df5785751d5f99921d1dbbcc16f50b of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

### From .ai/worklog/antigravity-addff8667515dfd9.md, archived 2026-09-25

## 2026-09-25 - Flame VFX Juice: Stage 3 Game Feel (Camera Shake, Zoom Punch, Squash & Stretch, Hit-stop)

Agent: antigravity-addff8667515dfd9

Action:
1. Created CameraShakeEffect and ZoomPunchEffect in apps/mobile/lib/ui/effects/camera_shake_effect.dart: isotropic damped harmonic oscillation (exp(-3.2 * t) * (1 - t)) with guaranteed drift-free return on completion/disposal, and smooth quadratic elastic micro-zoom (1.0 -> 1.025 -> 1.0).
2. Created LandingSquashComponent in apps/mobile/lib/ui/effects/landing_squash_component.dart: bounds-centered vertical squash (scaleY 0.88 -> 1.0, scaleX 1.08 -> 1.0) with translucent glass glow when pieces snap to grid.
3. Added evaluateProgress(t, curve) helper to apps/mobile/lib/ui/effects/easing_presets.dart.
4. Extended VfxEvent in ui/effects/vfx_events.dart: cellRects on PiecePlacedVfxEvent and zoomPunch flag on ScreenShakeVfxEvent.
5. Upgraded VfxDirector in ui/effects/vfx_director.dart: bound Viewfinder camera, implemented micro hit-stop freeze-frame support (45ms for mega combo, 60ms for All Clear), landing squash spawning, and screen shake / zoom punch dispatching with Reduced Motion and VfxLevel gating.
6. Integrated camera viewfinder and hit-stop in BlockPuzzleGame.
7. Added unit test suite in test/unit/ui/effects/camera_shake_test.dart and verified clean static analysis.

Result:
- flutter analyze --fatal-infos --fatal-warnings: exit 0 (0 issues).
- flutter test --no-pub: exit 0 (487/487 tests passing, +9 new tests).
- validate-protocol.ps1: exit 0 (0 warnings, 28 decisions verified).

Next step:
- Record protocol handoff evidence with protocol-handoff.cjs.
- Release cooperative lock.
- Human owner reviews, commits, and pushes changes.

Open:
None.

Evidence:
- anchor: 9c7db64c9fdca9eb9b51d692e8f7f6b5ad56facd, uncommitted changes present
- digest: sha256:7d0f23956ca67ce18c2f35663b18f37554a1de4c99a985e491d1349c75e25b32 over 560 tracked and untracked files
- digest format: 4
- recorded: 2026-09-25T00:44:08.503Z by antigravity-addff8667515dfd9
- entry: sha256:be2094edc035a3a15544df43c4a3e3ccfea4451b2303d269778bf75d3e4aaac0 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

### From .ai/worklog/antigravity-addff8667515dfd9.md, archived 2026-09-25

## 2026-09-25 - Flame VFX Juice: Stage 5 Rive Animations & Celebration Architecture Spike

Agent: antigravity-addff8667515dfd9

Action:
1. Conducted technical runtime evaluation in docs/design/03_RIVE_RUNTIME_SPIKE_EVALUATION.md comparing Rive native runtime (+2.8-3.6 MB per ABI, +45-70ms cold start dlopen, 18-26 MB heap RSS) vs bundled procedural vector rendering (<1.2 MB heap, 0 MB APK overhead, 0ms cold start, 100% headless CI compatible).
2. Defined Rive State Machine contract inputs (isWin, score, stars, triggerCelebration, reducedMotion) for Stage C dynamic cosmetic packs.
3. Implemented pluggable celebration architecture in apps/mobile/lib/ui/effects/celebration_director.dart: CelebrationDirector facade, CelebrationType enum (dailyChallengeVictory, newRecord, allClear), CelebrationProvider interface.
4. Created ProceduralCelebrationProvider: radiant sweeping starbursts, geometric gold trophy / daily star medal / all-clear diamond crystal badges, and Reduced Motion compliance.
5. Created RiveCelebrationAdapter: maps contract inputs and delegates gracefully to procedural fallback when native runtime/asset is absent.
6. Integrated celebration feedback into GameOverOverlayCard for New Best score and Daily Challenge completion.
7. Added unit test suite in test/unit/ui/effects/celebration_director_test.dart (16/16 tests passing).

Result:
- flutter analyze --fatal-infos --fatal-warnings: exit 0 (0 issues).
- flutter test --no-pub: exit 0 (514/514 tests passing, +16 new tests).
- validate-protocol.ps1: exit 0 (0 warnings, 28 decisions verified).

Next step:
- Record protocol handoff evidence with protocol-handoff.cjs.
- Release cooperative lock.
- Human owner reviews, commits, and pushes changes.

Open:
None.

Evidence:
- anchor: 3c17da771c9f9bb11f00d725c9e5327dd63951e4, uncommitted changes present
- digest: sha256:21d7efb495262285180463c639593e1af9f00f597782eae6e328b1c97660631e over 568 tracked and untracked files
- digest format: 4
- recorded: 2026-09-25T01:12:43.807Z by antigravity-addff8667515dfd9
- entry: sha256:f4f366e461f6bf5e819576c01a7d1053bedfe0663026bde1cb3b6a5b74ccc73c of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify




