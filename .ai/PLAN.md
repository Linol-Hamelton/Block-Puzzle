# Development Plan: Flame VFX Juice System

Status: Approved by owner RuslanFomenko (2026-09-25).
Governing document: docs/design/02_VFX_JUICE_RESEARCH_PLAN.md
Core decisions: DEC-0024 (frame budget), DEC-0026 (release scope), DEC-0028 (gameplay baseline).

## Objective

Elevate the visual game juice of Lumina Blocks (Classic / Tetris / Match-3) using
Flame 1.18.0 built-in effects, easing curves, pooled particle bursts, and an event-driven
VfxDirector architecture without degrading performance (>=38-40 FPS baseline) or breaking
existing tests.

## Completed Stages (Reference Implementation on Classic)

1. **Stage 0: Audit & Baseline** (completed)
   - Animation point mapping and raster profiling baseline.
2. **Stage 1: Easing Curves & Stagger** (completed)
   - `EasingPresets` and zero-allocation `ScorePopComponent` overshoot.
3. **Stage 2: Particle Systems & VfxDirector Event Bus** (completed)
   - Strongly-typed `VfxEvent` hierarchy and decoupled `VfxDirector`.
4. **Stage 3: Game Feel** (completed)
   - `CameraShakeEffect`, `ZoomPunchEffect`, `LandingSquashComponent`, micro hit-stop.
5. **Stage 4: Shaders** (completed)
   - `PieceAuraShader` GLSL chromatic glow with procedural gradient fallback.
6. **Stage 5: Rive Animations & Celebration Architecture** (completed)
   - `03_RIVE_RUNTIME_SPIKE_EVALUATION.md`, `CelebrationDirector`, `ProceduralCelebrationProvider`.
7. **Stage 6: Procedural Tile Atlas Baking** (completed for Tetris & Match-3)
   - GPU-resident `GlassTileAtlas` baking and batching.

## Active Phase: Calibration & Multi-Game Scaling

### Track A: Feedback Calibration (Timings, SFX, Haptics)
- Synchronize physical impact: `LandingSquashComponent` (0.18-0.20s), `playPiecePlaced()` SFX, and `HapticsController.mediumImpact()` on grid snap.
- Tiered haptics & camera shake on line clears:
  - 1-2 lines: `lightImpact()` + subtle flash.
  - 3 lines / combo x2-x3: `mediumImpact()` + `ShockwaveRingComponent`.
  - 4+ lines / combo x4+: `heavyImpact()` + 45ms hit-stop + `CameraShakeEffect`.
  - All Clear: `doubleHeavyImpact()` + 60ms hit-stop + fireworks fanfare.

### Track B: Multi-Game Adoption Tech Debt (Tetris & Match-3)
- **Tetris**:
  - Connect `TetrisFlameGame` to `VfxDirector` events (`piecePlaced` on hard drop, `lineCleared`).
  - Add `LandingSquashComponent` on hard drop and `PieceAuraShader` to Ghost Piece.
  - Integrate `CelebrationDirector.instance.buildBadge` into game over / high score.
- **Match-3**:
  - Apply `EasingPresets.cascadeDropCurve` to gem refill fall.
  - Connect swap cascades, bomb explosions, and color bursts to `VfxDirector`.
  - Add `PieceAuraShader` to charged special gems.

## Acceptance Criteria

- `raster p50` <= 20 ms on target device during worst-case multi-line cascades.
- Zero regressions in existing test suite (514+ tests green).
- Full compliance with `Reduced Motion` setting.
- Clean code architecture: `VfxDirector` encapsulates all visual flourishes.
