# Worklog: deepseek-5f13ae54cae74a62

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

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
- digest: sha256:b299722abbb090502f70440246f02b648c642c1e795d3f8a1957bd56e615b149 over 470 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T01:11:32.598Z by deepseek-5f13ae54cae74a62
- entry: sha256:db988b2aa48e8f40fc2412e0c99b43b98b57078837cc012e3a3175dec6a7a12e of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
