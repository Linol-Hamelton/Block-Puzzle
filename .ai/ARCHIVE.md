# Worklog Archive

Cold storage for worklog entries moved out of `.ai/worklog/`. Never trimmed,
never summarized away.

Entries keep the exact text they had when they were current. Add the agent name
and the date they were archived; change nothing else.

Information needed to understand an accepted decision belongs in
`.ai/DECISIONS.md`, not here. This file is history, not authority.

---

## Archive

No archived entries yet.

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
