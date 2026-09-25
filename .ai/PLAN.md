# Development Plan: Flame VFX Juice System

Status: Approved by owner RuslanFomenko (2026-09-25).
Governing document: docs/design/02_VFX_JUICE_RESEARCH_PLAN.md
Core decisions: DEC-0024 (frame budget), DEC-0026 (release scope), DEC-0028 (gameplay baseline).

## Objective

Elevate the visual game juice of Lumina Blocks (Classic / Tetris / Match-3) using
Flame 1.18.0 built-in effects, easing curves, pooled particle bursts, and an event-driven
VfxDirector architecture without degrading performance (>=38-40 FPS baseline) or breaking
the 457 passing tests.

## Phased Approach (Ranked by ROI)

1. **Stage 0: Audit & Baseline**
   - Map all animation points across Classic, Tetris, Match-3.
   - Verify Flame 1.18.0 EffectController APIs and procedural Canvas render pipeline.
   - Profile raster time and identify allocation bottlenecks (e.g. ScorePopComponent TextPainter).

2. **Stage 1: Easing Curves & Stagger (Highest ROI)**
   - Create `EasingPresets` (elasticOut, easeOutBack, easeOutQuint, easeOutExpo, bounceOut).
   - Refactor `ScorePopComponent` to pre-cache layout and apply `easeOutBack` overshoot.
   - Implement Anticipation + Follow-Through and Stagger for clear sequences.

3. **Stage 2: Particle Systems & VfxDirector Event Bus**
   - Introduce `VfxEvent` stream (`pieceDropped`, `lineCleared`, `scorePopped`, `allClear`).
   - Implement `VfxDirector` component to decouple VFX orchestration from gameplay loops.
   - Integrate pooled `BurstField` and `ShockwaveRingComponent` under `VfxDirector`.
   - Feature-flag via Remote Config `vfx_level: off / standard / full`.

4. **Stage 3: Game Feel (Camera Shake, Squash & Stretch, Hit-Stop)**
   - Damped isotropic `CameraShakeEffect` (0.1-0.2s) on combo milestones.
   - Vertical squash & stretch (scaleY 0.85 -> 1.0) on piece placement.
   - Micro hit-stop (40-60ms) for high-tier combos and All Clear fanfare.
   - Full integration with `Reduced Motion` user settings.

5. **Stage 4: Shaders (FragmentProgram)**
   - Pulse/glow fragment shader for Match-3 gems and hand piece aura (vfx_level: full only).

6. **Stage 5: Rive Animations**
   - Spike Rive runtime for victory fanfare, Daily Challenge milestone, and cosmetic skins.

7. **Stage 6: Procedural Tile Atlas Baking**
   - Pre-bake procedural glass facets (`paintGlassFacet`) into a `ui.Image` texture atlas.
   - Batch 8x8 grid rendering to minimize per-cell canvas overhead.

## Acceptance Criteria

- `raster p50` <= 20 ms on target device during worst-case multi-line cascades.
- Zero regressions in existing test suite (457/457 tests remain green).
- Full compliance with `Reduced Motion` setting.
- Clean code architecture: `VfxDirector` encapsulates all visual flourishes.
