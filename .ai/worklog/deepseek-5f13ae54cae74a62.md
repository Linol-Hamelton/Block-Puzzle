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



