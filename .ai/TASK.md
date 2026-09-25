# Current Task

Status: Completed - Flame VFX Juice: Stage 6 Procedural Tile Atlas Baking & Render Batching
Owner: RuslanFomenko
Last update: 2026-09-25

---

## Objective

Elevate rendering performance and eliminate multi-pass vector canvas bottlenecks by:
- Creating `GlassTileAtlas` to pre-bake procedural `paintGlassFacet` facets into a GPU `ui.Image` texture atlas at runtime.
- Supporting tile shapes (rounded square, circle, hexagon, diamond, pentagon, star) and game palettes (Tetris 7-mino colors, Match-3 6-gem colors).
- Integrating atlas blitting into `TetrisFlameGame` and `Match3Game` with graceful fallback for custom glows/clearing squashes.
- Providing lifecycle-safe disposal and recreation on `dropCachedSurfaces()`.
- Verifying frame rate benefits and ensuring 100% green tests (493+ tests) with 0 static analysis issues.

## Problem & Acceptance

- [x] Create `apps/mobile/lib/ui/effects/glass_tile_atlas.dart` with atlas generation and `drawTile` / batching APIs
- [x] Support physical pixel scaling via `devicePixelRatio` to prevent blurriness
- [x] Integrate atlas into `TetrisFlameGame` mino rendering
- [x] Integrate atlas into `Match3Game` gem rendering
- [x] Ensure safe GPU surface cleanup in `dropCachedSurfaces()`
- [x] Add unit test suite in `apps/mobile/test/unit/ui/effects/glass_tile_atlas_test.dart`
- [x] Verify `flutter analyze`, `flutter test`, and `validate-protocol.ps1` pass cleanly

## Current state

- Stage 0, Stage 1, Stage 2, Stage 3 and Stage 6 complete.
- 493/493 tests passing, flutter analyze 0 issues, protocol valid.
- Ready for owner review and commit.

## Roles

- implementer: antigravity
- owner: RuslanFomenko

## Open questions

None.

---

Keep this file under 80 lines. It describes the current task only.
