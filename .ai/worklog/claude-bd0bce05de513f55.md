# Worklog: claude-bd0bce05de513f55

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

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
