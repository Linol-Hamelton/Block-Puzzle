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
- [x] 2. Match-3: cascade drop clock resets per serial, animate refills; drop progress tested on active fall distances & intermediate progress
- [x] 3. Match-3: step.gained wired to Match3Event, score pop spawns and verified via real swap pipeline test
- [x] 4. Accessibility: Canvas shakes/flashes & shockwaves fully gated by reducedMotion (including AllClear perfectClear & roundComplete)
- [x] 5. Shader: Aura enabled on standard/full, FragmentShader cached & disposed
- [x] 6. Docs & Badges: strict score > best for tie fixed; docs line 145 accurately specifies full Reduced Motion gating
- [x] 7. Full suite passes (flutter test 540/540, analyze 0, validate-protocol clean)

## Current state

- DeepSeek adversarial re-audit verdict: ACCEPT on commit eca6187.
- P3 residuals hardened: ScorePop test and drop progress test now strictly discriminate mechanisms; docs line 145 wording polished for flash attenuation.
- Checks: `flutter analyze` exit 0 (0 issues); `flutter test --no-pub` exit 0 (540/540); `validate-protocol.ps1` exit 0.

## Roles

- implementer: antigravity
- reviewer: deepseek (hostile audit after Track B completion)
- owner: RuslanFomenko

## Open questions

- P2-6/P2-7 from initial audit remain outside the selected six; owner to schedule in future sprints.

---

Keep this file under 80 lines. It describes the current task only.
