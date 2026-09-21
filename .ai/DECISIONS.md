# Architectural and Technical Decisions

Decisions that are binding for this project. This is not a discussion log.
Discussion belongs in the Open questions section of `.ai/TASK.md`.

Append new blocks at the bottom. Never edit or delete an existing block, not
even its status line. When a decision is replaced, append a new approved block
carrying a `Supersedes:` line that names the old one. The old block keeps the
exact text it had when it was written.

This file is trustworthy only because nothing in it is ever rewritten. To find
whether a decision still stands, read forward for a later block that supersedes
it.

A proposal by an AI agent is not a decision. A decision needs `Approved by:`
with a human name.

---

## Decisions

### DEC-0001

Status: Accepted
Date: 2026-09-14

Context:
Classic, Tetris and Match-3 each ship their own board type, engine and screen.
No GameId, GameDefinition, GameRegistry or GameEngine exists anywhere in the
tree. ADR-002 proposed Strategy A, whose expensive step is generalizing
BoardState into RectBoardState and BoardCell into a typed GridCell.

Decision:
Adopt the reduced Strategy A: introduce the outer seam only - GameId,
GameDefinition, GameRegistry, a Mode Hub screen, one snapshot envelope and one
analytics keying path. Do not migrate Classic BoardState, and do not unify the
three board models. Each game keeps BoardState, TetrisBoard and TileGrid.

Reasoning:
The board generalization was priced when one game existed. Two engines have
since been written with their own working boards and test suites, so the
migration now buys nothing a release needs, while still touching every domain
consumer. The Claude and Codex plans reached this conclusion independently.

Alternatives rejected:
Full Strategy A as written in ADR-002 - highest-risk phase for no remaining
benefit. Leaving three parallel stacks unseamed - duplicates snapshot handling,
mode routing and analytics keying, and diverges further with every change.

Consequences:
Phase 1 of ADR-002 Strategy A is withdrawn. No code path may construct a game
class directly once the registry exists. A future genre needing a shared board
model must reopen this decision rather than assume it.

Approved by: RuslanFomenko

### DEC-0002

Status: Accepted
Date: 2026-09-14

Context:
The Codex plan placed the game registry and per-game flags in stage B1, after
A0-A7, while the acceptance gate of A6 requires demonstrating a per-mode kill
switch on a device. B1 delivers the flags that A6 must demonstrate, so the two
stages depended on each other in a cycle.

Decision:
Move per-game feature flags and mode gating forward into stage A, ahead of the
rest of the registry work. A6 may then be accepted on its own terms, and the
remaining registry and Mode Hub UI work stays in stage B.

Reasoning:
Kill switches are a reliability control, not a content feature: the ability to
disable a failing mode without shipping a patch belongs with the other release
gates, not after them.

Alternatives rejected:
Keeping flags in B1 and weakening the A6 gate - removes the only control that
makes shipping three modes at once safe.

Consequences:
Stage A grows slightly. The flag keys must be defined before Remote Config work
completes, so the naming has to be settled early rather than during B1.

Approved by: RuslanFomenko

### DEC-0003

Status: Accepted
Date: 2026-09-14

Context:
Entitlements are bound to a Firebase Anonymous Auth UID. verifyPurchase rejects
a purchase token already bound to a different UID. An anonymous UID is lost on
reinstall or device change, so a paying player can lose access to a purchase
while the server correctly refuses to rebind the token. The billing document
describes a different flow.

Decision:
Recover entitlements by linking the anonymous account to a recoverable account,
not by rebinding a purchase token to a new UID on client request. The server
check stays as it is.

Reasoning:
The cross-UID token check is the only defense against one purchase granting
entitlements on several accounts. Weakening it to solve a recovery problem
trades a revenue-integrity control for a convenience.

Alternatives rejected:
Allowing the client to request a token rebind - reopens the replay path that
the transactional check in verifyPurchase was written to close.

Consequences:
An account-linking flow and its UI become part of the billing scope, and must
be specified before stage A5 is estimated as done. Restore on a fresh install
without linking will not return purchases; this must be stated in the store
listing and support material.

Approved by: RuslanFomenko

### DEC-0004

Status: Accepted
Date: 2026-09-14

Context:
Three documents state different targets: the roadmap (D1 45%, D7 18%, D30 8%,
crash-free 99.7%), the product vision (D7 15%, D30 5%, crash-free 99.5%) and
the rollout gates checklist. Two consecutive 72-hour cohort windows cannot
measure D7 or D30 at all.

Decision:
Split the numbers into three named sets that are never mixed: closed-test
acceptance criteria, rollout-expansion gates, and long-term product goals.
Retention metrics are measured only after the matching cohort has matured -
D7 after seven days, D30 after thirty.

Reasoning:
A gate that cannot be measured inside its own window is not a gate. Mixing
target levels from different horizons is what let the existing documents
contradict each other without anyone noticing.

Alternatives rejected:
Picking one document numbers as canonical - the three sets answer different
questions and collapsing them loses the distinction.

Consequences:
The rollout gates document and the roadmap KPI block both need rewriting under
this split. The 30-session minimum stays an operational filter and is not to be
described as statistical proof.

Approved by: RuslanFomenko

### DEC-0005

Status: Accepted
Date: 2026-09-14

Context:
Match-3 runs move-limited at 30 moves. Special tiles, stepwise animations with
input locking, and objective variety are all deferred. The alternative use of
the same budget is depth in Tetris - control tuning, daily parity, score chase.

Decision:
Do not commit the budget now. Decide between Match-3 depth and Tetris depth
from cohort data after stage C, using measured per-mode engagement.

Reasoning:
Neither mode has ever been played by a real cohort. Any allocation made today
is a guess, and this is exactly the kind of guess that produced three games and
no release.

Alternatives rejected:
Committing to Match-3 specials now - the detonation matrix is the highest
clone-bug risk in the mode and would be paid for before knowing anyone plays it.

Consequences:
Match-3 ships to closed test in its current move-limited form. The per-mode
analytics split required to make this decision must exist before stage C ends.

Approved by: RuslanFomenko

### DEC-0006

Status: Accepted
Date: 2026-09-14

Context:
The roadmap planning rule puts foundation gates above new modes and engagement
features. In practice the last five months delivered Tetris and Match-3 while
no Phase 1 gate was closed.

Decision:
The foundation-before-content rule is restored and binding. New modes and
engagement systems do not start until the reliability, data and commerce gates
for the existing three modes are green.

Reasoning:
The rule was never repealed, only ignored, and the result is the current state:
three finished games, none of them shippable. Restoring it explicitly gives the
next session something to be held to.

Alternatives rejected:
Repealing the rule to match actual practice - would formalize the pattern that
caused the problem.

Consequences:
Stage D and anything in Phase 4 stay closed until stage C reports. Any agent
proposing content work before that must cite this decision and explain why it
does not apply.

Approved by: RuslanFomenko

### DEC-0007

Status: Accepted
Date: 2026-09-14

Context:
Neither workflow under .github passes --dart-define, so AppConfig.fromEnvironment
resolves APP_ENV to dev and APP_FLAVOR to debug. di_container then sets
useDebugAdapters true, and a build produced by CI resolves DebugIapStoreService,
DebugAnalyticsTracker, InMemoryRemoteConfigRepository and NoopCrashReporter.

Decision:
Track this as a standalone P0 with its own acceptance gate, not as a line item
inside general release-workflow hygiene. The gate: a release build proves, by
test or on-device check, that DI resolved the production adapters.

Reasoning:
The consequence is a published build that simulates purchases and reports no
telemetry. Folded into a configuration checklist it can be marked done without
anyone verifying the adapters actually changed.

Alternatives rejected:
Treating it as part of the workflow fix - the fix is one line, the verification
is the valuable part, and only a separate gate forces the verification.

Consequences:
The release checklist gains an explicit adapter-resolution check. This item
blocks any distribution build, including internal test tracks.

Approved by: RuslanFomenko

### DEC-0008

Status: Accepted
Date: 2026-09-14

Context:
Season Pass, the daily wheel and purchasable currency packs appear in Phase 3
of the roadmap. Each needs a wallet ledger, spend and restore accounting, a
content cadence and an entitlement model with an expiry.

Decision:
Do not start Season Pass, the wheel or currency packs until game production is
complete for the shipped modes. Cosmetic non-consumable purchases are the only
commerce surface until then.

Reasoning:
These systems are ongoing operational commitments, not features that are
finished when merged. Starting them while core production is unfinished adds a
recurring content obligation the project cannot yet meet.

Alternatives rejected:
Building the wallet early so later systems plug in - the wallet shape depends on
economy decisions that have not been made.

Consequences:
Revenue until then rests entirely on cosmetic IAP, which raises the importance
of the single verified SKU in stage A5. Soft-currency rewards that other systems
might have granted must not be promised in UI before the wallet exists.

Approved by: RuslanFomenko

### DEC-0009

Status: Accepted
Date: 2026-09-14

Context:
The Android applicationId is com.blockpuzzle.game while the verifyPurchase
function defaults ANDROID_PACKAGE_NAME to com.luminablocks.app. Nothing is
published, so the identity can still be chosen freely. After the first upload to
Google Play an applicationId can never be changed.

Decision:
The canonical product identity is the domain luminablocks.ru. The Android
applicationId and the server package name are the same string, derived from that
domain in reverse-DNS form: ru.luminablocks.game. Both com.blockpuzzle.game and
com.luminablocks.app are retired.

Reasoning:
One identity in both places removes the mismatch that would make receipt
validation fail. Reverse-DNS is the Android convention and the form Google Play
and the Play Developer API expect; writing the domain forward as luminablocks.ru
would be a package whose segments read backwards.

Alternatives rejected:
Keeping com.blockpuzzle.game - not tied to the owner domain. Keeping
com.luminablocks.app - the com namespace does not match the actual domain.

Consequences:
applicationId, namespace, the Firebase Android app registration, the Play
Console listing, the signing config and ANDROID_PACKAGE_NAME on the server must
all be changed together and before the first upload. The exact final string is
confirmed by the owner before any distribution build; after publication this
decision cannot be revisited.

Approved by: RuslanFomenko

### DEC-0010

Status: Accepted
Date: 2026-09-14

Context:
Classic, Tetris and Match-3 are all playable. The closed test could ship all
three or a subset, with the rest kept behind flags until each meets its own
criteria.

Decision:
The closed test ships all three modes at once. Per-mode kill switches from
DEC-0002 remain the control for disabling any mode that fails in the field.

Reasoning:
All three are already written and tested; withholding a mode delays the only
data that can tell the modes apart, which DEC-0005 depends on. The kill switches
make shipping them together recoverable.

Alternatives rejected:
Shipping Classic only and adding modes later - would leave DEC-0005 undecidable
for another cycle and waste work already finished.

Consequences:
Stage B3 device QA must cover three input models, not one: Classic drag, Tetris
DAS/ARR, Match-3 swipe. Store metadata and screenshots must describe three modes
from the first submission. Per-mode analytics splitting is required before the
test, not after.

Approved by: RuslanFomenko

### DEC-0011

Status: Accepted
Date: 2026-09-14

Context:
The rollout gates use an early game-over rate threshold calibrated on Classic,
where a round ends when no placement is legal. Match-3 runs a fixed 30-move
budget, so a round ending is the normal outcome and the Classic threshold has no
meaning there.

Decision:
The early game-over metric is not applied to Match-3 at all. It stays a gate for
Classic and, where it is defined, for Tetris. Match-3 is judged on its own
measures instead.

Reasoning:
A metric whose denominator means something different per genre produces numbers
that look comparable and are not. Declaring it inapplicable is honest; inventing
a Match-3 equivalent now, before any cohort data exists, would be a guess
embedded in a gate.

Alternatives rejected:
Reusing the Classic threshold - would fail or pass Match-3 for reasons unrelated
to player experience. Defining a substitute now - no data to calibrate it.

Consequences:
The rollout gates document must state per-mode applicability for every metric,
not one global list. Any aggregate early game-over figure must exclude Match-3
sessions and say so. If Match-3 later needs a health gate, it requires a new
decision and cohort data to calibrate.

Approved by: RuslanFomenko

### DEC-0012

Status: Accepted
Date: 2026-09-14

Context:
The project targets Google Play and RuStore. Both plans estimated stage A
against Google Play. RuStore first would need its own billing adapter, its own
server-side verification and its own device QA.

Decision:
Google Play is the first store. A Play developer account already exists. RuStore
is out of scope until the Google Play closed test has reported.

Reasoning:
The billing code, the receipt validation function and the Play Developer API
integration already exist for Play. Doing both at once doubles the least
verified part of the system before either is proven once.

Alternatives rejected:
RuStore first - full re-estimate of stage A5 and a second unverified billing
path. Both in parallel - two unproven payment integrations at the same time.

Consequences:
Estimates for stage A stand as written. RuStore-specific compliance work in the
release docs is deferred, not deleted. Store metadata is produced for Play
first, in RU and EN.

Approved by: RuslanFomenko

### DEC-0013

Status: Accepted
Date: 2026-09-14

Context:
Two AI agents work in this repository through the filesystem. In the planning
session each found defects the other missed: Codex found the release adapter
chain, the package mismatch, the unserialized 7-bag and the absent Firestore
rules; Claude found the A6/B1 dependency cycle, the stale main ref reading and
the premature task status.

Decision:
Two executors work in parallel. Claude is the primary executor and owns branch
convergence, the registry and flag seam, tests and documents. Codex is the
auxiliary executor and owns stage A: release wiring, billing and configuration.
Mutual review before handoff is mandatory: no stage is reported done until the
other agent has reviewed it.

Reasoning:
Every mistake found in the planning session was found by the reviewer rather
than the author. A single-executor arrangement removes the mechanism that caught
them. The split follows the demonstrated strengths of each agent.

Alternatives rejected:
One executor - loses cross-review. Both agents on the same stage - the shared
document lock serializes them and the parallelism is lost.

Consequences:
Stages A and B may overlap, so the 32-55 engineer-day range compresses in
calendar terms but not in effort. The protocol lock and the one-writer rule for
shared documents become load-bearing rather than a formality. Each agent records
its review in the other handoff before a stage is accepted.

Approved by: RuslanFomenko

### DEC-0014

Status: Accepted
Date: 2026-09-14

Context:
The device matrix in the plans names Redmi, Samsung, Honor and Xiaomi. The only
physical device actually available is the owner personal Redmi phone.

Decision:
The device matrix for stage B3 is one physical Redmi plus emulators. The
cold-start and frame-rate targets are measured on that device and treated as a
single data point, not as matrix coverage.

Reasoning:
Stating the real coverage is better than a matrix that exists only on paper.
Emulators do not measure thermal behaviour, real GPU cost or cold start, so
they cannot substitute for the missing devices.

Alternatives rejected:
Claiming full matrix coverage - would make the performance gate untrue.
Blocking stage B3 until more devices exist - stops the release for a resource
that may not arrive.

Consequences:
The performance gate is weakened and must be labelled as such wherever it is
reported. Crash-free and ANR rates from the closed-test cohort become the main
evidence for device diversity instead. Vendor-specific defects on Samsung, Honor
and other Xiaomi models will surface in the field rather than in QA; this is an
accepted risk, and a broader matrix should be revisited before a wide rollout.

Approved by: RuslanFomenko

### DEC-0015

Status: Accepted
Date: 2026-09-14

Context:
Both planning documents produced a set of proposals that carried no fork: the
two agents agreed on each, and each has a single sensible form. They were put to
the owner as one block of seventeen items.

Decision:
All seventeen are approved and authorized as work: branch convergence with
batch 2; --dart-define in both workflows; one package contract; awaited
bootstrap under runZonedGuarded with no silent Firebase catch; a real Firebase
connection with google-services.json via CI secret; firestore.rules with
emulator tests; CI at --fatal-infos --fatal-warnings; 7-bag and Match-3 spawner
state in snapshots; cold_kill_recovery_test and a real widget test; the
simulation test writing to a temporary path; ADR-004 ratified; billing edges 10
and 11 closed with a non-consumable cosmetic as the first SKU; resolved Android
dependencies checked before release; status and README reconciled with the
three-game reality; config-api and analytics-pipeline left deferred; the old
issue packs not reused without revision; and plans 12 and 13 merged into one
document with stages A and B as the spine.

Reasoning:
Each item was independently reached or verified by both agents against code, and
none of them trades one direction against another. Approving them as a block
lets execution start without a further round of questions.

Alternatives rejected:
Approving them one at a time - no fork to resolve, so the round trip buys
nothing.

Consequences:
This block is the authorization for stages S0 and A to begin. An item that turns
out to hide a fork must come back as its own decision rather than be settled
inside the work.

Approved by: RuslanFomenko

### DEC-0016

Status: Accepted
Date: 2026-09-14

Context:
DEC-0015 ratified ADR-004, but ADR-004 itself left the lifetime open: either
bind the sub-services to the controller scope so they are recreated per session,
or make the controller a singleton with an explicit reset() on session start.
The Codex review (R12) pointed out that ratifying the ADR did not settle which
of the two was chosen. Today GameLoopController is registerFactory while
ABExperimentService, OnboardingFlowController and ProgressionSyncService are
registerLazySingleton with no reset on dispose.

Decision:
Scoped/factory. Mutable per-session state lives in services created with the
session and disposed with it, under an explicit dispose owner. Application-wide
services that are deliberately cross-session stay singletons and are documented
as such. The controller does not become a singleton with reset().

Reasoning:
Recreating the state is harder to get wrong than remembering to reset it. A
field added later to a scoped service cannot silently leak across sessions,
whereas a reset() has to be kept in sync by hand with every new field.

Alternatives rejected:
Singleton controller with explicit reset() - equally correct today, but every
future field is a chance to forget the reset, which is exactly the latent
footgun ADR-004 was written about.

Consequences:
The DI registrations for the three sub-services change from lazy singleton to
scoped/factory, and each session needs a clear dispose path. A test must assert
that a fresh session starts from clean sub-service state. Any service that is
intentionally shared across sessions must be named in the composition root with
a reason.

Approved by: RuslanFomenko

### DEC-0017

Status: Accepted
Date: 2026-09-14
Supersedes: DEC-0009 and DEC-0013

Context:
The Codex review (R10, R12) found two statements of fact wrong in earlier
blocks, while the choices those blocks recorded were sound. DEC-0009 justified
reverse-DNS as "the form Google Play and the Play Developer API expect"; it is
a naming convention, not a platform requirement, and namespace and applicationId
may legitimately differ. DEC-0013 said each agent "records its review in the
other handoff", which reads as writing into another session's journal - AGENTS
section 5 forbids that. Decision blocks are never edited, so both are restated
here with the errors removed.

Decision:
Package identity, restated and now confirmed by the owner: the canonical product
identity is the domain luminablocks.ru, and the Android applicationId, the
namespace, the Firebase Android app registration, the Play Console listing and
ANDROID_PACKAGE_NAME on the server are all the single string
**ru.luminablocks.game**. Reverse-DNS is chosen as a convention, not because a
platform demands it; namespace is aligned with applicationId by choice, and
changing the namespace must account for the Kotlin package and MainActivity.
Execution model, restated: two executors work in parallel, Claude primary
(branch convergence, registry and flag seam, tests, documents), Codex auxiliary
(stage A: release wiring, billing, configuration). Mutual review before handoff
stays mandatory, and a reviewer records the review in its own journal or in a
separate review file and never writes into the other session's journal.

Reasoning:
Both decisions were right; only their supporting statements were wrong. Leaving
an incorrect technical claim in the binding log invites someone to act on it,
and the review-recording wording contradicted the protocol it depends on.

Alternatives rejected:
Leaving the errors and noting the corrections only in a plan - the decision log
is the binding source, and a correction that lives elsewhere will be missed.

Consequences:
DEC-0009 and DEC-0013 keep their original text and are no longer in force.
Section 0 of the publish checklist can now be signed off for the string itself;
its scope is narrowed by the release-build point raised in R10, which is handled
as implementation, not as a decision.

Approved by: RuslanFomenko

### DEC-0018

Status: Accepted
Date: 2026-09-14

Context:
DEC-0003 keeps the server-side rule that a purchase token cannot be rebound to a
different UID, and recovers entitlements by linking the anonymous account to a
recoverable one. It did not name the provider. Review item R3 requires the
linking flow to exist before the first paid purchase, not after.

Decision:
Google Sign-In is the recoverable identity provider. The anonymous account is
linked to it before the first paid purchase can complete. Email-link sign-in is
not implemented for now.

Reasoning:
On Android the account is already present on the device, so linking is a single
tap and does not add an email round trip during a purchase flow. Fewer steps in
front of a payment means fewer abandoned purchases and fewer support cases.

Alternatives rejected:
Email-link - works without a Google account but inserts a mail round trip at the
worst moment. Both providers - doubles the linking UI and the merge rules before
either has been proven once.

Consequences:
Play App Signing SHA-1 and SHA-256 certificates must be registered in Firebase,
not just the debug and upload keys, or sign-in fails specifically in the
Play-delivered build (R7). The purchase flow gains a linking step that must
handle cancellation and credential-already-in-use, and progress-merge rules have
to be explicit. Users without a Google account cannot recover purchases; this is
accepted for the first release.

Approved by: RuslanFomenko

### DEC-0019

Status: Accepted
Date: 2026-09-14

Context:
Cosmetics are the only thing sold (DEC-0008) and the project has no artist. The
survey in docs/operations/18 compared service free tiers against local
open-weight models. Both candidates were installed on the owner machine and run:
SDXL produced a 1024x1024 image in 26.4s, and Stable Audio 3 Medium produced a
20s music bed in 5.8s and a 3s effect in 1.4s at a measured 5.06 GB peak VRAM.

Decision:
Adopt SDXL (in ComfyUI) for images and Stable Audio 3 Medium for music and sound
effects, both running locally. The acceptance set for this toolchain is one
coherent visual set for the first cosmetic, three short sound effects and one
music loop. Each asset carries a manifest: model and revision, applicable
licence, prompt, seed, workflow, format, generation time and peak memory. The
timebox for reaching that set is one working day after the installs; if it is
not reached, fall back to the Small audio models or to procedural effects. No
further model families are added until the acceptance set exists.

Reasoning:
Both were measured on the actual hardware rather than assumed, and local
execution removes per-request cost and free-tier commercial-rights ambiguity.
The timebox exists because tooling work expands to fill available time, and the
project already has a history of building capability instead of shipping.

Alternatives rejected:
Service free tiers - commercial rights differ per vendor and some reserve them.
Adding FLUX.1 schnell now - a cleaner licence, but another 12 GB and more setup
before a single asset has been accepted. FLUX.1 dev is excluded: its model
licence is not free for commercial use.

Consequences:
Licence texts and versions must be recorded per asset, and the Stability
Community License revenue threshold applies to the organisation, not to this
game alone. Purely AI-generated output has limited copyright protection in the
US and possibly elsewhere, so no exclusivity may be promised to a buyer. Art
direction, selection and final polish stay human work.

Approved by: RuslanFomenko

### DEC-0020

Status: Accepted
Date: 2026-09-14

Context:
The app forces portrait in bootstrap, which was used to argue that tablet and
landscape profiles need no testing. Review item R9 noted that target SDK 36
changes behaviour for screens at or above 600dp, with an exception for apps
recognised as games, and that the manifest does not declare appCategory.

Decision:
Declare android:appCategory="game" in the manifest and add a functional
large-screen test to the QA set. The test checks that the UI is usable and not
broken on a large screen; it is not a performance measurement, which stays on
the single physical Redmi under DEC-0014.

Reasoning:
The exception has to be claimed explicitly to be relied on, and verifying it on
the delivered artifact is cheap compared to discovering on release that a large
fraction of devices renders the board wrongly.

Alternatives rejected:
Staying phone-only and assuming portrait lock holds - the platform behaviour
changed and the assumption is no longer free.

Consequences:
One more emulator profile in the QA set. The exception must be re-checked on the
Play-delivered build, not only locally, since Play can treat the artifact
differently.

Approved by: RuslanFomenko

### DEC-0021

Status: Accepted
Date: 2026-09-14

Context:
apps/mobile/android/app/build.gradle sets minSdk = flutter.minSdkVersion, so the
lowest supported Android level moves whenever the Flutter SDK changes it. That
makes the supported device range undeclared, and the minimum-API emulator
profile in the QA set cannot be fixed to anything. The value in the installed
SDK is const minSdkVersionInt = 24 in
packages/flutter_tools/lib/src/android/gradle_utils.dart; Flutter itself errors
below 23 and warns below 24.

Decision:
Pin minSdk to the literal value 24 in build.gradle. Raising the floor is a
separate decision to be made from cohort data, not from convenience.

Reasoning:
Pinning makes the supported range an explicit, reviewable property of the
project rather than a side effect of a toolchain upgrade. 24 is what the project
already builds against today, so pinning it changes no behaviour and loses no
device; it only stops the floor from moving silently.

Alternatives rejected:
Leaving flutter.minSdkVersion - the floor moves with SDK upgrades and no test
profile can be fixed against it. Raising to 26 or 28 now - narrows reach before
any data exists showing which devices actually matter.

Consequences:
The min-API emulator profile is built at API 24. A Flutter upgrade that raises
its own default will no longer raise this project's floor silently; it becomes a
visible change to build.gradle. firebase_auth requires 21 and is satisfied.

Approved by: RuslanFomenko

### DEC-0022

Status: Accepted
Date: 2026-09-15
Supersedes: DEC-0005 and DEC-0006

Context:
DEC-0005 deferred the choice between Match-3 depth and Tetris depth until cohort
data existed after stage C, and DEC-0006 restored the rule that foundation work
precedes content. The owner has since decided to improve the three shipped modes
before the release build: reordering the home screen, reworking the Tetris
control layout, giving Match-3 the mechanics players expect from the genre, and
producing media for the games.

Decision:
A bounded round of gameplay and presentation work is authorized now, before the
release build and before stage C. Its scope is fixed:

- Home screen ordering, with the games grouped and Daily Challenge at the bottom.
- Tetris control ergonomics.
- Match-3 depth: bonus tiles from four-in-a-row, five-in-a-row, T shapes and L
  shapes; a move limit; scoring; round progression that grants further moves on
  completing a round.
- Media for the games and the app.

Everything DEC-0006 deferred that is not on this list stays deferred: new modes,
Puzzle Pack, Season Pass, the wheel and currency packs. The DEC-0019 acceptance
set and its timebox still bound the media work; this decision widens what the
media is for, not how much tooling may be built.

Reasoning:
The owner judges that the three modes are not yet good enough to put in front of
players, and that shipping them as they are would waste the cohort window that
stage C exists to produce. Data from a mode nobody enjoys answers a different
question than the one DEC-0005 wanted answered.

Alternatives rejected:
Holding to DEC-0005 and deciding from cohort data - defensible, and it was the
right call when nobody had played the modes, but it assumed the modes were
already worth measuring. Doing this after the release - would mean releasing the
version the owner has already judged insufficient.

Consequences:
Stage C moves later by the length of this work. The Match-3 special-tile
detonation matrix is the risk the multi-game plan named as the top source of
clone bugs, so it needs table-driven tests before any animation work. DEC-0005's
question - which mode deserves further depth - is not answered by this decision
and returns after stage C. The foundation gates of stage A remain binding: this
authorizes content work in parallel, not instead.

Approved by: RuslanFomenko

---

### DEC-0023

Status: Accepted
Date: 2026-09-16

Context:
Physical device playtest (Redmi 2209116AG) and review of proposals (02) and
audit (03) confirmed Stage A is closed, but audio immersion, sound juiciness,
and gameplay UX need a final polish pass before release. Long uncompressed WAV
audio is a release blocker due to Google Play AAB size limits (200 MB), while
pure RNG piece generation in Classic frustrates retention.

Decision:
1. Music format: encode full-length soundtrack tracks in AAC-LC 128 kbps (.m4a).
   Total audio asset footprint is bounded to <= 15 MB. Short SFX remain in WAV.
2. Music playback: global continuous playlist (MusicPlaylistManager) surviving
   screen navigation, with 1.2s equal-power crossfade between tracks.
3. Sound design: 7 pre-rendered pentatonic combo WAVs (combo_01..07) with 2.5s
   streak reset; hybrid placement thud (110 Hz body + 2-3 kHz click + haptics);
   music ducking (-3 dB for 150 ms) under mega clear/Tetris.
4. Visual juice: lightweight vector shockwave ring clipped to the board;
   floating score numbers ascending from clear origin. Static nebula preserved
   to protect 60 fps; no runtime fragment shaders.
5. Classic mode fairness: Fair Bag Randomizer guarantees the first piece of a
   new triplet is mathematically placeable on the current board; adaptive drag
   anchor centers piece pickup.
6. Scope bounds: boosters (Reroll/Hammer) stay rejected per DEC-0008; Tetris
   swipe controls deferred to v1.1.

Reasoning:
Decisions chosen directly by owner RuslanFomenko after multi-agent trade-off
analysis. AAC-LC keeps total build size well within Google Play limits while
delivering high-fidelity Parkan-inspired ambient audio. Fair Bag prevents
game-over RNG spikes that damage day-1 retention.

Alternatives rejected:
WAV music - exceeds AAB size limits (140-230 MB). Ogg Vorbis - lacks native iOS
support. Per-screen music restarts - breaks atmospheric flow state. Fullscreen
shader distortion & dynamic nebula repaints - risk dropping below 60 fps on
low-end devices. Boosters - rejected to uphold DEC-0008 foundation rules.

Consequences:
Requires converting music masters to AAC-LC (.m4a). SFX audio budget stays
strictly under 15 MB. Implementation proceeds in order: diagnostics timing
counter, audio player refactor, pentatonic combo ladder, Fair Bag generator,
vector shockwave ring, floating score popups.

Approved by: RuslanFomenko

---

### DEC-0024

Status: Accepted
Date: 2026-09-16
Supersedes: DEC-0023

Context:
DEC-0023 authorised the pre-release audio/visual polish. Reviewing it against
the code turned up one item that would make the game worse if built as written,
four engineering constraints the decision did not name and an implementer would
hit on day one, and an open question about who executes it. The owner accepted
all three corrections in session. DEC-0023 is restated here in full with those
corrections, because a decision that is 95% right is still read as 100% binding
and the log is only trustworthy when the newest block carries the whole truth.

Decision:
1. Music format: encode full-length soundtrack tracks in AAC-LC 128 kbps
   (.m4a). Total audio asset footprint is bounded to <= 15 MB. Short SFX stay
   uncompressed PCM WAV, converted to mono.
2. Music playback: one global continuous playlist (MusicPlaylistManager)
   surviving screen navigation, with a 1.2s equal-power crossfade between
   tracks. A track changes when it ends or when the player changes it, never on
   a screen transition.
3. Sound design: 7 pre-rendered pentatonic combo WAVs (combo_01..07) with a
   2.5s streak reset; hybrid placement thud (110 Hz body + 2-3 kHz click +
   haptics); music ducking (-3 dB for 150 ms) under mega clear / Tetris.
4. Visual juice: lightweight vector shockwave ring clipped to the board;
   floating score numbers ascending from the clear origin. Static nebula
   preserved to protect 60 fps; no runtime fragment shaders.
5. Classic mode fairness and grip: Fair Bag Randomizer guarantees the first
   piece of a new triplet is mathematically placeable on the current board.
   **The drag anchor centres the piece horizontally on its own bounding box and
   keeps the existing vertical lift** (`_touchDragLiftPixels = 50`). This
   corrects DEC-0023, which said the anchor "centers piece pickup": centring in
   both axes puts the piece under the thumb that is dragging it, and the lift
   exists precisely so the piece stays visible. Horizontal centring is what
   makes left/right placement predictable; the lift is what makes it visible.
6. Scope bounds: boosters (Reroll/Hammer) stay rejected per DEC-0008; Tetris
   swipe controls deferred to v1.1.
7. Engineering constraints, binding on the implementation:
   a. MusicPlaylistManager may not be built on `FlameAudio.bgm`, which is a
      single Bgm instance and cannot cross-fade. It uses two `audioplayers`
      players with independent volume, and `audioplayers` is declared
      explicitly in pubspec rather than relied on transitively.
   b. Volume has exactly one authority. The crossfade owns the envelope;
      ducking is a multiplier applied on top of it, never a direct set. A duck
      landing mid-crossfade must not be able to strand a track at a wrong
      level.
   c. Floating score numbers are one per cascade step, positioned at the
      centroid of that step's cleared cells - not one per cleared cell. They
      must not occupy the `_pulse` caption slot, which already owns the centre
      of the board.
   d. Music respects audio focus: a call or another app taking focus pauses
      playback and resumes after, via `AudioContext`.
8. Execution model. Gemini implements steps 1 and 2 (diagnostics frame timing,
   audio format migration) as a calibration batch; Claude reviews. The
   MusicPlaylistManager is written by Claude regardless of that outcome,
   because its failure mode - leaked players, a stranded volume, a missing
   dispose - does not fail tests, it fails on a player's phone. Claude writes
   the acceptance criteria for each step **before** that step starts; the
   implementer attaches a device frame measurement to each step. After the
   calibration batch the owner decides whether the split continues for steps 3,
   5 and 6.

Reasoning:
Chosen by owner RuslanFomenko after review. Point 5's correction is the only
item in DEC-0023 that could regress the game: the vertical lift is not
incidental spacing, it is what keeps the dragged piece out from under the
finger. The four engineering constraints are all failure modes this repository
has already been bitten by in another form - a single-instance API used as if
it were re-entrant, two writers and no owner for a piece of state, an effect
multiplied per cell instead of per event, and a lifecycle nobody released.
Naming them in the decision costs nothing and saves the implementer from
building the music manager twice. The execution split is a cost decision with a
measurement attached rather than an assumption: review is cheaper than
co-writing only while the work arrives mostly correct, so the cheapest and most
objectively checkable steps run first and the defect rate they produce decides
the rest.

Alternatives rejected:
Editing DEC-0023 in place - forbidden; the log is trustworthy because nothing
in it is rewritten. Amending point 5 without Supersedes - leaves a reader of
DEC-0023 with wording that regresses the game and no pointer to the correction.
Centring the drag anchor in both axes - puts the piece under the thumb.
Compressing SFX to AAC - adds decode latency to one-shots, where latency
matters more than size. Handing the whole plan to one implementer without a
checkpoint - decides a cost question by assumption instead of by measurement.

Consequences:
DEC-0023 is history; this block is the one to read. The drag anchor work is
horizontal-only and must not touch `_touchDragLiftPixels`. `audioplayers`
becomes a declared dependency. Acceptance criteria are a deliverable that
precedes each step, not a report after it. The owner re-decides the split after
steps 1 and 2.

Approved by: RuslanFomenko

---

### DEC-0025

Status: Accepted
Date: 2026-09-16

Context:
DEC-0024 point 8 left one question open on purpose: whether the
implementer/reviewer split continues past the calibration batch, to be decided
on evidence rather than on assumption. Gemini delivered steps 1 and 2; Claude
reviewed them (docs/design/05_DEC0024_STEP12_REVIEW.md). The evidence is
specific enough to answer the question and to change one thing about how the
split works.

What the batch showed: the code was right and the measurement was not. The
recorder reads the correct fields, computes percentiles correctly, gates itself
off at compile time, and ships with tests; step 2 was correct in every
particular. What failed was judgement - a baseline whose own numbers contradict
each other by 3.9x, a jank threshold hardcoded to 60 Hz on a 120 Hz device, and
a conclusion ("Classic holds a confident 60 fps") stated far more firmly than
the data allowed. Those are exactly the defects a reviewer catches cheaply: one
arithmetic check found all of them.

Decision:
1. The split continues. Gemini implements; Claude reviews against criteria
   written before the step.
2. **Producing and concluding are separated.** The implementer builds, measures
   and reports raw numbers with the method and the measurement window. The
   implementer does not write the verdict. The reviewer draws the conclusion.
   The acceptance criteria are reworded to ask for numbers rather than for an
   interpretation, because the previous wording invited one.
3. **A defect class caught twice is fixed in the tool, not in the checklist.**
   The frame panel prints frames-per-second over the measured window, so a
   self-contradictory measurement is visible to whoever takes it rather than
   only to whoever reviews it.
4. **Experiments are pre-registered.** Where a measurement tests a stated
   hypothesis, the prediction and the falsification threshold are written down
   before the measurement is taken. This applies immediately to the
   RepaintBoundary experiment, which tests Claude's hypothesis about Claude's
   own change.
5. Assignment for the remaining work:
   - Instrument corrections and the remeasure: Gemini.
   - RepaintBoundary experiment: Gemini, pre-registered.
   - Step 5 (Fair Bag, horizontal drag anchor): Gemini.
   - Step 6 (shockwave, score numbers): Gemini, but not started until the frame
     budget question is answered.
   - Step 3 (MusicPlaylistManager): Claude, in parallel, blocked by nothing.
   - Step 4: split - the seven samples and the ladder to Gemini; ducking as a
     multiplier over the crossfade envelope goes with whoever owns the music
     layer, which is Claude.
6. **Per step, the review records whether it checked or redid.** Checking is
   cheap and the split pays; redoing is not and it does not. If redoing becomes
   the pattern, the arrangement is moving work to the more expensive place
   rather than saving it, and the owner revisits this block.

Reasoning:
Decided by owner RuslanFomenko on the calibration evidence. The split is worth
keeping because the defects arrived in the shape review handles best - judgement
under uncertainty, not Dart. It is worth adjusting because the reviewer produced
more of step 1's value than the implementer did, and an arrangement where that
repeats is not a saving. Separating production from conclusion removes the
observed failure directly and costs neither side anything. Ordering step 6
behind the frame-budget answer follows from the same logic that put measurement
first in DEC-0024: decorating a game that renders at 26 fps on a 120 Hz panel
spends a budget that does not exist.

Alternatives rejected:
Handing everything to one implementer - discards the evidence that review is
catching real defects cheaply. Handing everything to the reviewer - discards the
cost saving the split exists for, on one batch of evidence where the
implementation itself was sound. Keeping the criteria as written - they asked
for a baseline in the journal, which invited the interpretation that went wrong.
Leaving the jank threshold to reviewer vigilance - the same class would recur.

Consequences:
docs/design/04_DEC0024_ACCEPTANCE_CRITERIA.md is rewritten to ask for raw
numbers and to carry criteria for the instrument corrections, the remeasure, the
pre-registered experiment and step 5. The frame panel gains a window timer and a
refresh-rate-derived threshold. Every later step carries a measurement taken
with the corrected instrument. Step 1 is not closed: its instrument is accepted,
its baseline is not.

Approved by: RuslanFomenko

---

### DEC-0026

Status: Accepted
Date: 2026-09-21
Supersedes: DEC-0024 point 8 (executor of the music layer only). All other
points of DEC-0024 and DEC-0025 remain in force.

Context:
DEC-0024 point 8 assigned the MusicPlaylistManager to Claude because its
failure mode fails on a player's phone rather than in tests. On 2026-09-20 the
owner directed that Gemini completes steps 3 and 4c instead. The full-repository
review (audits 06, 07, 08 and the two adversarial rounds recorded in
docs/audit/09) put seven forks to the owner; the owner answered all of them in
session on 2026-09-21, and plan docs/roadmap/15 records the resulting order.
A decision record is needed because the executor change contradicts a binding
block and because three of the answers change project scope.

Decision:
1. The music layer (DEC-0024 steps 3 and 4c) is implemented by Gemini, not by
   Claude. Every other DEC-0024/DEC-0025 requirement stands unchanged: criteria
   are written before the code, and the implementer does not accept its own
   work.
2. Monetization: the ad-free model is confirmed. The first external test ships
   with no monetization of any kind; Stage C (IAP, Google Sign-In linking, the
   verifyPurchase service account, Blaze and the Play Console work) is deferred
   until the owner revisits it. The DEC-0008 norm stands: cosmetic
   non-consumables are the only commerce surface. `utility_tools_pass` has no
   authorizing decision and is not to be offered for sale; it is removed from
   the catalog and Remote Config when the store surface is next touched.
3. First external test distribution: a direct release-signed APK to 10-20
   testers. Google Play internal testing and RuStore closed testing are not part
   of this step; DEC-0012 stands and RuStore remains out of scope until a Play
   closed-test report exists.
4. Repository: `dec-0024/av-polish` is merged into `main`, and `main` is then
   pushed to the private remote. The PNG measurement receipts already in
   history stay; the push decision is recorded here rather than assumed.
5. Frame rate: the frame-rate investigation is not reopened. Instead of the
   unattained 55-60 fps target, the product documents are aligned with the
   measured release figure of 38-40 fps on the 120 Hz test device.
6. Localization before the first external test is RU-only: the seven Cyrillic
   strings in the store controller move to l10n. Full RU/EN waits for the
   cohort data.
7. The ten empty feature directories are annotated, not deleted.

Reasoning:
The owner answered the forks the adversarial review surfaced. Keeping the
frame-rate experiments unauthorised and aligning the documents removes a
contradiction that has been carried since step 1k. Deferring all monetization
means the first external test measures the game, not the payment plumbing, and
removes C1/C2/C3 from the critical path. Merging before pushing puts the whole
history, including the measurement receipts, on the remote in one operation.

Alternatives rejected:
Reopening the frame investigation (forbidden by the owner; the exit threshold of
step 1k was met). Legalizing utility_tools_pass with a new decision (no data
justifies it, and the owner chose no monetization). RuStore-first or ads
(contradicts DEC-0012 and the confirmed ad-free model). Pushing
`dec-0024/av-polish` directly without merging (leaves `main` behind and keeps
the divergence). Full RU/EN before the first test (untargeted scope).

Consequences:
The music layer review and every later acceptance cannot invoke DEC-0024 point 8
to bar Gemini's work; the criteria written for steps 3/4c remain the standard.
Stage C work is blocked until a later owner decision; the billing code stays in
the tree but is not shipped as an offer, and the utility SKU removal becomes a
small pre-release task. `main` becomes the single line and is pushed. The KPI
documents change their fps target, which must be reported wherever the earlier
target was quoted. RU-only localization means the first build is not suitable
for non-Russian testers.

Approved by: RuslanFomenko

---

### DEC-0027

Status: Accepted
Date: 2026-09-21
Supersedes: nothing (declares the start DEC-0026 deferred)

Context:
DEC-0026 approved plan docs/roadmap/15 and stated that work does not start until
the owner says so. DEC-0025 requires production and conclusions to be separated:
the implementer does not write its own acceptance criteria and does not accept
its own work. The plan named the reviewer as Claude or DeepSeek, subject to the
owner's confirmation, and the owner has now (2026-09-21) authorised the start
and named the reviewer.

Decision:
1. The next stage starts: plan docs/roadmap/15 (edition 3), workstreams W0-W4,
   with Stage C frozen by DEC-0026.
2. The reviewer for this cycle is DeepSeek; the implementer is Gemini. The
   implementer does not write the acceptance criteria under itself and does not
   accept its own work.
3. At the end of the cycle, before the owner accepts the result, a Mandatory
   Adversarial Review is held with a consortium of independent models, using
   docs/audit/10_MANDATORY_ADVERSARIAL_REVIEW_PROMPT.md. Its unresolved
   disagreements and vetoes go to the owner.

Reasoning:
The start command and the reviewer appointment existed only in chat; a decision
block makes them binding and puts the reviewer in place before any code is
written, as DEC-0025 requires. The consortium review is required because the
whole cycle would otherwise be produced and accepted within one pairing.

Alternatives rejected:
Leaving the start and reviewer in chat (not a decision under AGENTS.md).
Nominating the implementer's own session as reviewer (violates DEC-0025).
Deferring the consortium review until after distribution (too late to catch a
systematic defect in the cycle).

Consequences:
Any deliverable of W1-W4 must carry a reviewer verdict by DeepSeek and, before
owner acceptance, survive the consortium review. The implementer cannot close
its own items. The MAR prompt and its launch commands live in docs/audit/10;
its verdicts do not replace owner approval.

Approved by: RuslanFomenko

---

## Template for new decisions

### DEC-nnnn

Status: Proposed | Accepted
Date:
Supersedes: _the DEC this one replaces, or omit the line_

Context:
_What situation forced a choice._

Decision:
_What was chosen, stated so it can be checked._

Reasoning:
_Why this over the alternatives._

Alternatives rejected:
_What else was on the table and what disqualified it._

Consequences:
_What this costs, and what it now constrains._

Approved by: _a human name; an agent may not fill this in for itself_
