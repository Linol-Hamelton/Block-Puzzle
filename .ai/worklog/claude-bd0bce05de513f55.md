# Worklog: claude-bd0bce05de513f55

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

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
