# Worklog: claude-bd0bce05de513f55

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

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
