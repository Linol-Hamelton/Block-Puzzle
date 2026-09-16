# Worklog: claude-bd0bce05de513f55

Session journal. Owned by this session. No other session writes here.

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
