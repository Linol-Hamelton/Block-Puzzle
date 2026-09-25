# Current Task

Status: Completed
Owner: RuslanFomenko
Last update: 2026-09-25

---

## Objective

Fix all 6 blocking/actionable findings from DeepSeek's adversarial audit:
1. Fix Tetris LineClear flash and shockwave hardcoded 8x8 size; derive from boardSize.
2. Fix Match-3 cascadeDropCurve by using a dedicated drop clock reset per frame serial.
3. Fix Match-3 ScorePop by carrying points on Match3Event and asserting ScorePopComponent.
4. Gate game-level canvas shake/flash and shockwaves by reduced motion.
5. Enable PieceAuraShader on standard tier, reuse/dispose FragmentShader to prevent GPU leak.
6. Update tech-debt matrix in docs/design/02 and ensure strict score > best for new record.

## Problem & Acceptance

- [x] 1. Tetris: boardSize passed to LineClearedVfxEvent, flash/shockwave covers 10x20
- [x] 2. Match-3: cascade drop clock resets per serial, animate terminal/common refills
- [x] 3. Match-3: Match3Event carries points, score pop spawns and tested
- [x] 4. Accessibility: Canvas shakes/flashes & shockwaves fully gated by reducedMotion
- [x] 5. Shader: Aura enabled on standard/full, FragmentShader cached & disposed
- [x] 6. Docs & Badges: Update matrix in docs/design/02, strict score > best for tie
- [x] 7. Full suite passes (flutter test 536/536, analyze 0, validate-protocol clean)

## Current state

- All 6 DeepSeek audit findings resolved with regression tests. Ready for DeepSeek re-review and acceptance.

## Roles

- implementer: antigravity
- reviewer: deepseek (hostile audit after Track B completion)
- owner: RuslanFomenko

## Open questions

None.

---

Keep this file under 80 lines. It describes the current task only.


