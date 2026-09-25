# Current Task

Status: Completed - Flame VFX Juice: Stage 4 Shaders (FragmentProgram Piece & Gem Aura)
Owner: RuslanFomenko
Last update: 2026-09-25

---

## Objective

Elevate visual juice and dynamic lighting via hardware-accelerated fragment shaders:
- Compile organic pulsing chromatic aura fragment shader (`shaders/piece_aura.frag`).
- Implement `PieceAuraShader` manager with runtime shader compilation and graceful procedural radial gradient fallback.
- Integrate into `VfxDirector` and active dragged piece in `RackPieceComponent` when `vfxLevel == VfxLevel.full`.
- Strictly gate behind `vfxLevel == VfxLevel.full` and `Reduced Motion` user settings.
- Ensure 100% green test suite (498+ tests) and 0 static analysis issues.

## Problem & Acceptance

- [x] Create GLSL fragment shader in `shaders/piece_aura.frag` and declare in `pubspec.yaml`
- [x] Implement `PieceAuraShader` in `apps/mobile/lib/ui/effects/piece_aura_shader.dart`
- [x] Provide graceful fallback for headless test runners and unsupported GPUs
- [x] Integrate `PieceAuraShader` into `VfxDirector` and `RackPieceComponent`
- [x] Strictly gate behind `VfxLevel.full` and reduced motion settings
- [x] Add unit test suite in `apps/mobile/test/unit/ui/effects/piece_aura_shader_test.dart`
- [x] Verify `flutter analyze`, `flutter test`, and `validate-protocol.ps1` pass cleanly

## Current state

- Stage 0, Stage 1, Stage 2, Stage 3, Stage 4 and Stage 6 complete.
- 498/498 tests passing, flutter analyze 0 issues, protocol valid.
- Ready for owner review and commit.

## Roles

- implementer: antigravity
- owner: RuslanFomenko

## Open questions

None.

---

Keep this file under 80 lines. It describes the current task only.
