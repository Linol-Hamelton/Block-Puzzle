# Worklog: claude-bd0bce05de513f55

Session journal. Owned by this session. No other session writes here.

## 2026-09-16 - Bisection found it: the board well is 81%, the glass is free

Agent: Claude / claude-bd0bce05de513f55.

Action: Reviewed 1g and 1h against the criteria, scored the floor against its
pre-registered bands, attributed the cost across the five layers, verified the
revert and the checks, and specified 1i. Wrote
docs/design/09_DEC0024_STEP1G1H_REVIEW.md. No product code changed.

Result: **Both accepted. The change of method paid on its first measurement.**
Three guesses found nothing; one bisection found everything.
The floor is 5.29 ms at 118.3 fps - band two by the letter of my own thresholds,
band one in substance, because the device hit the panel's 120 Hz cap rather than
its own limit. The fear that an empty frame costs 30 ms here is dead: **the
hardware can do 118 fps.**
The bisection: control 5.29, + nebula 6.31 (+1.02, 7%), + empty GameWidget 7.90
(+1.59, 11%), **+ board well 19.25 (+11.35, 81%)**, + 64 glass gems 19.24
(-0.01, **free**).
**That inverts my model completely.** I spent three experiments suspecting the
gems - their blurs, their clipPath, their halo - and the gems cost nothing. The
cost is the cached board background I had assumed was free by definition. My
first hypothesis, the nebula, is worth 1 ms out of 26.
The mechanism I should have understood earlier: `drawPicture` does not draw a
finished image. A `Picture` is a command list and the GPU re-executes it every
frame - about 130 gradient shaders in the well, two per socket, plus two blurs.
Caching into a Picture removes the recording cost on the UI thread and nothing
else. **Step 1e proved exactly this and I failed to generalise it**: caching the
gems dropped build 64% and left raster untouched to the hundredth. I read that
as "different threads" and stopped.
**For the owner this closes the question they were facing.** Glass versus frame
rate is not a trade any more: the gems are measured free, the look stays, and
the earlier recommendation to revert 1f was right - there was nothing to buy
with it. 1i rasterises the well once into an Image and blits it.
A second target fell out of the same run: the benchmark's full stack is 19.24 ms
against the real Classic screen's 31.95, so ~12.7 ms lives in the Flutter chrome
the benchmark lacks - AppBar, HUD, rack, cards. One target at a time.
My self-check rule turned out to have a directional blind spot - it flagged a
perfectly good measurement at 1.60x because fps was *lower* than raster allowed,
which is what a vsync cap looks like. Reworded in the criteria: only fps
*exceeding* 1000/raster_p50 by 1.5x invalidates a run. Another fix in the tool
rather than in a reviewer's vigilance.
flutter analyze exit 0; flutter test exit 0, 350 tests. validate-protocol.ps1
exit 0.

Next step: Gemini runs 1i. Claude starts step 3.

Open: 1i's prediction could still fail, though unlike the first three this one
comes from an isolating measurement and a known mechanism rather than from
picking a suspect by eye. The ~12.7 ms of widget chrome is unexplained and
untouched. Six measurement screenshots sit untracked in the repository root and
belong in docs/design/ or .gitignore. Nothing is committed and main is 28 ahead
of origin.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:a80695a33d939750d7aa60a304926963a3e31a0d5e06e94e5f92aa47c6fac612 over 526 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T18:14:47.236Z by claude-bd0bce05de513f55
- entry: sha256:0506aec100e22ce305b845fb74ed7c1c22af49c635944d40f17921a1d50d39e0 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
## 2026-09-16 - 1f falsified both guesses; the method was wrong, not the experiments

Agent: Claude / claude-bd0bce05de513f55.

Action: Reviewed 1f-A and 1f-B against their pre-registered thresholds, scored
them, and specified a change of approach as steps 1g and 1h. Wrote
docs/design/08_DEC0024_STEP1F_REVIEW.md. No product code changed.

Result: **Both accepted, both falsified.** Blurs cost 11.6% against a 25%
falsifier, clipPath 5.1% against 15%. Removing both leaves Match-3 near 32.6 ms
- about 31 fps against a 16.67 ms target, still short by a factor of two. The
prediction had been below 20 ms.
**That is three falsified guesses in a row - nebula repaint at 0%, blurs,
clipPath - and the fault is mine and structural.** I kept guessing *what in the
drawing* costs money and kept subtracting things from a scene without ever
measuring what an empty frame costs on this device. Subtraction without a
baseline is guessing with numbers attached rather than measuring.
The fact that was in plain sight the whole time: **Classic costs 31.95 ms on an
EMPTY board** - no pieces, the well cached in a Picture - and removing blurs only
took it to 29.03. The cost is present where there is almost nothing to draw, so
it lives in frame composition, not content. That also explains why 1d-B moved
only 22%: it shrank the game canvas but not the background, the Stack or the
full-screen layers above it. And one more sign from the fresh numbers: Match-3's
raster fell 11.6% while its frame rate did not rise at all (31.4 -> 29.9 ->
29.7), so frames are not bound by raster p50 either.
Next is not a fourth guess. 1g measures the floor - a diagnostics-only route
with a solid colour and one animating box, no nebula, no Flame, no glass - with
thresholds written before the measurement, including a band that says the cost
is environmental and no edit to our drawing will touch it. 1h bisects by adding
one layer at a time, five measurements, and terminates.
Recommended reverting both 1f edits, for a methodological reason more than an
aesthetic one: the bisection has to run against the real app, and 17% that does
not change the outcome is not worth paying for in look.
flutter analyze exit 0; flutter test exit 0, 350 tests. validate-protocol.ps1
exit 0.

Next step: revert 1f, then Gemini runs 1g and 1h. Claude starts step 3.

Open: the glass-versus-frames question still cannot be answered and I will not
guess at it a fourth time. If 1g finds a high floor, this stops being a question
about the look and becomes one about the engine on this class of device. Nothing
is committed and main is 28 ahead of origin.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:9006bd3c95703fccc6900d3050ca08ccd685b006de89380b4612bc1297448b57 over 499 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T14:08:07.162Z by claude-bd0bce05de513f55
- entry: sha256:985bd54443552088f8eefe6dc02ee7ba87ef77a2ce76c752d8148b24c1acb74c of this entry without this block
- scope: protocol checks only; host-project tests run separately

Newest entry first. Limit 150 lines.
