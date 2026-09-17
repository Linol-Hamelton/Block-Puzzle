# Worklog: gemini-fb4abe3f81b4b68b

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-16 - Step 1i: Board well rasterization to ui.Image

Agent: gemini-fb4abe3f81b4b68b

Action:
- Implemented DEC-0024 Step 1i: rasterized board well into `ui.Image` once via `picture.toImageSync(width, height)` at physical pixel scale (`boardWellPixelRatio` using `devicePixelRatio` and camera zoom). Rendered using `canvas.drawImageRect`.
- Added image disposal on geometry/pixelRatio changes and in `onRemove()` to prevent GPU memory leaks across Classic (`block_puzzle_game.dart`), Tetris (`tetris_game.dart`), Match-3 (`match3_game.dart`), and benchmark stand (`benchmark_scene_screen.dart`).
- Added unit tests in `apps/mobile/test/unit/ui/effects/glass_board_test.dart` for `rasterizeBoardWell`, `drawBoardWellImage`, and `boardWellPixelRatio`.
- Cleaned root repository directory by moving untracked screenshots `m16..m20` into `docs/design/`.
- Built release APK (`--dart-define=APP_ENV=prod --dart-define=APP_FLAVOR=release --dart-define=ENABLE_DIAGNOSTICS=true`), deployed to Xiaomi Redmi Note 12 Pro (2209116AG, 120 Hz, Adreno 618).
- Measured Stand Layer 4 (+Well), Stand Layer 5 (+Stones), and Classic (idle) on device with timing stats reset prior to each run. Captured board and diagnostics receipts in `docs/design/`.

Result:
- Verification: `flutter analyze --fatal-infos --fatal-warnings` -> 0 issues. `flutter test` -> 353/353 passed. `validate-protocol.ps1` -> 0 warnings.
- Raw on-device measurements (window >= 35 s):
  - Stand Layer 4 (+ Well via `ui.Image`):
    - Window: 130.2 s, 15443 frames, 118.6 fps, Jank (>16.7ms): 0.28% (10 / 3600)
    - Build p50 / p90 / p99: 2.32 / 2.67 / 3.17 ms, worst build: 12.57 ms
    - Raster p50 / p90 / p99: 7.85 / 9.26 / 10.43 ms, worst raster: 20.47 ms
    - Total worst frame: 22.65 ms
    - Receipts: `docs/design/m21_board_layer4.png`, `docs/design/m21_step1i_layer4_well.png`
    - Delta vs Layer 3 (7.90 ms): 7.85 - 7.90 = -0.05 ms (down from +11.35 ms in 1h.4)
    - Directed self-check: `1000 / raster_p50` = 127.39 fps; 1.5x threshold = 191.08 fps. Observed FPS: 118.6 fps <= 191.08 fps. Valid.
  - Stand Layer 5 (+ Stones via `paintGlassFacet`):
    - Window: 36.8 s, 2815 frames, 76.4 fps, Jank (>16.7ms): 94.60% (2663 / 2815)
    - Build p50 / p90 / p99: 6.62 / 10.45 / 12.99 ms, worst build: 23.55 ms
    - Raster p50 / p90 / p99: 11.69 / 12.94 / 16.12 ms, worst raster: 42.51 ms
    - Total worst frame: 52.42 ms
    - Receipts: `docs/design/m22_board_layer5.png`, `docs/design/m22_step1i_layer5_stones.png`
    - Directed self-check: `1000 / raster_p50` = 85.54 fps; 1.5x threshold = 128.31 fps. Observed FPS: 76.4 fps <= 128.31 fps. Valid.
  - Classic Mode (idle, no touches):
    - Window: 38.5 s, 1652 frames, 42.9 fps, Jank (>16.7ms): 86.44% (1428 / 1652)
    - Build p50 / p90 / p99: 1.82 / 2.27 / 5.77 ms, worst build: 73.79 ms
    - Raster p50 / p90 / p99: 25.52 / 26.16 / 26.92 ms, worst raster: 38.57 ms
    - Total worst frame: 80.49 ms
    - Receipts: `docs/design/m23_board_classic.png`, `docs/design/m23_step1i_classic_idle.png`
    - Directed self-check: `1000 / raster_p50` = 39.18 fps; 1.5x threshold = 58.78 fps. Observed FPS: 42.9 fps <= 58.78 fps. Valid.

Next step:
- Review of Step 1i measurements by reviewer / owner per DEC-0025.

Open:
- None for Step 1i.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:51f0720f4e36c3e1c5c124ee4909588ad754d442a82a4420d06a30a09e259e16 over 514 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T19:58:52.429Z by gemini-fb4abe3f81b4b68b
- entry: sha256:2e786b8d7370ba488da5810354bb6dca35e9d8d660d5531d0d4f950f01a3ad20 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
