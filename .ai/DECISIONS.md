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
