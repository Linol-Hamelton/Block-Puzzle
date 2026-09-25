# Pre-merge Review Follow-ups — PR #42 (game-feel + Tetris + P0)

Date: 2026-06-21
Source: multi-agent pre-merge review of `feat/p0-fixes-and-tetris-domain` (5 review dimensions → adversarial verification of 12 P0/P1 findings → verdict).
Verdict: **GO_WITH_NITS** — no merge blockers (`mustFix` empty). Branch is `flutter analyze`-clean, 162 tests pass, CI green. Items below are tracked follow-ups to do *after* the merge; none break a core game/payment flow or crash.

## Resolved — batch 1 (2026-06-21)
Done on branch `fix/review-followups-p1` (analyze clean, 163 tests):
- ✅ **#1 Billing token atomicity** — the cross-account/replay check now runs inside `runTransaction` (`tx.get(tokenRef)` before the writes) in `infra/cloud_functions/functions/index.js`.
- ✅ **#2 Duplicate `game_end` after revive** — `game_end` is now emitted at most once per round via a `_gameEndEmitted` guard, in **both** Tetris (`tetris_controller.dart`) and Classic (`game_loop_controller.dart`, reset in `startNewGame`).
- ✅ **#3 Snapshot lost during the clear window** — `saveActiveGame()` now calls `engine.flushPendingClear()` (collapse + commit) before snapshotting; added `TetrisEngine.flushPendingClear` + test.
- ✅ **#5 Tetris teardown** — `TetrisController` is now disposed-guarded (`_disposed` short-circuits tick/input/revive) and clears `onVisualEvent` on dispose; `TetrisScreen.dispose()` pauses the Flame loop before disposing.

## Resolved — batch 2 (2026-06-21)
Done on branch `fix/review-followups-p2` (analyze clean, 167 tests):
- ✅ **#4 Revive flag persisted** — `revive_used` is now written into the resume snapshot (`saveActiveGame`) and read back in `initialize()`, so backgrounding after a revive can't grant a second one.
- ✅ **#6 Perfect clear on the zero-delay path** — extracted `_awardPerfectClearIfEmpty()`, called from both `_finishClear` and the `lineClearDelay <= 0` fast path in `_lockActivePiece`. (+test)
- ✅ **#7 Lock-flash position on hard drop** — the engine captures the visible locked cells at lock time (`lastLockedCells`); the view flashes those instead of the last *rendered* active cells (which are stale after a hard drop).
- ✅ **#8 Gravity no longer consumes the lock-reset cap** — `_tryMove(..., isGravity: true)` skips `_onPieceShifted()`; only player moves/rotations burn a reset. (Clearing `_lastActionWasRotation` on a *successful* gravity step is kept intentionally — guideline "last action = rotation"; a grounded gravity tick fails the collision check before touching the flag, so valid T-spins still register. +T-spin test.)
- ✅ **#9 `restore()` validates the active piece** — if the restored piece collides with the board, it is dropped and re-spawned (block-out surfaces normally). (+test)
- ✅ **#12 `move_rejected` null reason** — Classic now passes `placeResult.failureReason ?? 'invalid_move'` so the event is never quarantined for a null `reason`.
- ✅ **#13 Resumed `game_start`** — a `resumed` flag is emitted with `game_start` (true when restored from a snapshot) and added to the analytics schema, so resumes can be distinguished from fresh sessions.
- ✅ **Perf** — Tetris board chrome (gradient + grid + border) is recorded once into a cached `ui.Picture` and re-recorded only when geometry changes, instead of rebuilding shaders + drawing every grid line each frame.
- ✅ **`reviveClearTop` resets `_combo`/`_backToBack`** — a revive breaks the run chain so no stale b2b/combo multiplier carries across the gap.
- Tests: +combo accounting, +perfect-clear zero-delay, +T-spin detection, +restore-collision re-spawn.

**Deferred (need a Play sandbox + the function deployed):** #10 (`restorePurchases` fixed-window) and #11 (receipt retry/backoff). These touch live billing flows that can't be exercised until `verifyPurchase` is deployed and a Play sandbox account is wired; tracked for the billing-enablement pass.

Remaining items (perf/polish nits, the music-on-pop-back cosmetic, broader test/widget gaps) are still open below.

## Confirmed — prioritize first
1. **Billing token binding is not atomic (TOCTOU).** `verifyPurchase` reads the token doc with a plain `get()` outside the transaction and never re-reads it inside `runTransaction`, so two concurrent calls with the same `purchaseToken` under different UIDs can both grant. Move the existence/uid check inside `runTransaction` (`tx.get` before `tx.set`). `infra/cloud_functions/functions/index.js:60-116`. (Function not yet deployed — fix before deploy.)
2. **Duplicate `game_end` after revive.** `revive()` does not call `_beginRound()`, so a post-revive top-out emits a second `game_end` with the same `round_id` → one `game_start`, two `game_end` per round (skews funnels). Add a `_gameEndEmitted` guard reset only in `_beginRound`, or a `post_revive` flag. `tetris_controller.dart` (`revive`/`_onGameEnd`). **Note (verified):** Classic's `useRewardedRevive` has the same exposure — fix both.

## Confirmed — correctness / data-integrity
3. **Snapshot lost during the ~120 ms clear window.** `saveActiveGame()` is gated on `hasActiveGame` (active != null), which is false during the clearing hold, and `toSnapshot` does not serialize `_clearingRows`/`_clearTimerMs`. Backgrounding mid-clear loses the lock + cleared lines + score. Treat clearing as active (`hasActiveGame || isClearing`) and force-collapse before snapshot, or serialize the clear phase. `tetris_engine.dart:110, 496-508`.
4. **Revive once-per-run flag not persisted.** `_reviveUsed` lives on the controller and is reset in `initialize()`/`restart()`; it is not in the engine snapshot, so backgrounding after a revive lets the player revive again in the same run. Persist it with the snapshot. `tetris_controller.dart:71`.
5. **Tetris teardown asymmetry.** `TetrisScreen.dispose()` does not clear `_controller.onVisualEvent` nor pause/shutdown the Flame game, and `TetrisController.tick()` has no disposed-guard → a post-dispose `update()` could `notifyListeners()` on a disposed `ChangeNotifier` (currently masked by teardown order). Clear `onVisualEvent`, add a disposed flag, and pause the game on dispose. `tetris_screen.dart:63`, `tetris_game.dart:167`, `tetris_controller.dart:124`.
6. **Perfect-clear bypassed on the zero-delay path.** All-clear detection lives only in `_finishClear`; the `lineClearDelay <= 0` fast path collapses without checking `isEmpty`, so a zero-delay engine never awards the bonus. Factor the check into a helper called from both paths. `tetris_engine.dart:340, 359`.
7. **Lock-flash position on hard drop.** `_lastActiveCells` is captured in `render()`, but the lock event is drained during the hard-drop input before a render at the landed position, so the flash draws at the stale mid-air cells. Capture the locked cells from the engine/event at lock time. `tetris_game.dart:101`.
8. **Gravity/soft-drop consume the lock-reset cap and clear the T-spin flag.** Downward `_tryMove(0,1)` from gravity/soft-drop runs `_onPieceShifted` (burns a lock reset) and sets `_lastActionWasRotation=false`; a gravity tick between a rotation and lock can suppress a valid T-spin. Only count player horizontal moves/rotations. `tetris_engine.dart:292, 260`.
9. **`restore()` does not validate the active piece fits the board.** A corrupt/incompatible snapshot can resume into a colliding active piece (no block-out on the restore path). After restore, if `_board.collides(_active!)`, re-spawn or end the game. `tetris_engine.dart:519`.

## Confirmed — billing edges / analytics hygiene
10. **`restorePurchases` fixed 2 s window vs 20 s validation** can return a stale owned set / wrong `restored_count`. Await in-flight restores instead of a fixed delay. `google_play_billing_service.dart:238-249`.
11. **Receipt rejection never acknowledges and re-validates on every redelivery, no retry cap.** Distinguish hard-invalid (`not_purchased`) from transient (`play_verify_failed`/timeout) and retry-with-backoff the latter (else a good purchase risks Play's 3-day auto-refund). `google_play_billing_service.dart:311-346`.
12. **`move_rejected` quarantined when `reason` is null.** Pass `placeResult.failureReason ?? 'invalid_move'`. `game_loop_controller.dart:383-391`.
13. **Resuming a Tetris snapshot still emits a fresh `game_start`** (inflates session counts). Consider a `resumed` flag / suppress.

## Performance / polish (non-blocking)
- Tetris `render()` allocates Paints/Gradients/Shaders + `TextPainter` every frame; cache board/grid/shaders in a `Picture` (like `BoardComponent`) and cache popup painters for low-end Android. `tetris_game.dart:201`.
- After popping Tetris→Classic, the shared `MusicController.stop()` leaves Classic silent (initState doesn't re-run on pop) — deterministic, cosmetic. Restart music on resume/`didPopNext`.
- Settings toggles for sound/haptics don't propagate to an already-running game screen; music-enable toggle is a no-op when no game is active (by design).
- `reviveClearTop` should intentionally reset `_combo`/`_backToBack` (stale b2b multiplier otherwise).

## Test gaps (add alongside the fixes)
- Engine T-spin detection (`_detectTSpin`) true/false cases; `_lastActionWasRotation` vs gravity.
- Engine combo accounting + back-to-back chaining across consecutive locks.
- Lock-delay + gravity timing (`tick`); lock-reset "infinity with cap".
- SRS wall-kick **against an obstacle** at the engine level.
- Snapshot/restore mid-clear, hold, combo/b2b continuity; `reviveClearTop` "still blocked" branch.
- Widget/render tests (the current `widget_test` is a placeholder).
