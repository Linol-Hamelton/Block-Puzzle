# Worklog: claude-bd0bce05de513f55

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

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
