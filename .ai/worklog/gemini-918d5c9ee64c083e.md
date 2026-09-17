# Worklog: gemini-918d5c9ee64c083e

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-17 - Step 1b.5 & Step 6 DEC-0024 measurements and implementation

Agent: gemini-918d5c9ee64c083e

Action:
- Fixed jank calculation in `FrameTimingRecorder` from `build + raster > threshold` to `max(build, raster) > threshold` (Step 1b.5).
- Added rule unit tests in `frame_timing_recorder_test.dart` verifying that at 120 Hz, build 5ms / raster 5ms is not jank, and raster 9ms is jank.
- Ran within-scene A/D comparison on Redmi Note 12 Pro (2209116AG, 120 Hz) with half-filled board (26 cells).
- Added pre-registered Step 6 benchmark harness (`Step6Benchmark`, `_Step6BenchRunnerComponent`, bottom sheet controls) supporting 8 concurrent events.
- Recorded Step 6 Baseline window on device with Effects OFF.
- Implemented lightweight vector `ShockwaveRingComponent` clipped to board via non-AA `clipRect` (scissor) and zero-blur pre-laid-out `ScorePopComponent` originating from `computeClearedCentroid`.
- Added unit tests for `computeClearedCentroid`, `ShockwaveRingComponent`, and `ScorePopComponent` lifecycle/slot independence (369/369 tests green).
- Recorded Step 6 Control window on device with Effects ON (8 simultaneous shockwave rings + 8 floating score popups).

Result:
- Step 1b.5 on-device measurement (half-board, 26 cells):
  - Config A (Baseline): 58.4 s, 2157 frames, 36.9 fps; build p50/p90/p99 = 1.82 / 2.15 / 3.25 ms; raster p50/p90/p99 = 26.13 / 26.45 / 27.62 ms; worst raster = 34.72 ms; jank = 98.42%. Self-check: 1000 / 26.13 = 38.3 fps vs 36.9 fps. Receipts: `m25_step1b5_config_a_half_board.png`, `m25_step1b5_config_a_half_diag.png`.
  - Config D (No Pieces Image): 58.3 s, 2152 frames, 36.9 fps; build p50/p90/p99 = 1.83 / 2.17 / 2.97 ms; raster p50/p90/p99 = 25.79 / 26.08 / 27.58 ms; worst raster = 32.41 ms; jank = 98.28%. Self-check: 1000 / 25.79 = 38.8 fps vs 36.9 fps. Receipts: `m25_step1b5_config_d_half_board.png`, `m25_step1b5_config_d_half_diag.png`.
  - Delta A - D: raster p50 = +0.34 ms; raster p99 = +0.04 ms.
- Step 6 on-device benchmark (8 concurrent events, half-board 26 cells):
  - Pre-registered thresholds: delta raster p99 <= 2.0 ms, delta raster p50 <= 1.0 ms. Pre-registered prediction: delta raster p99 <= 1.0 ms.
  - Baseline (Effects OFF): 52.8 s, 1960 frames, 37.1 fps; build p50/p90/p99 = 1.84 / 2.18 / 3.21 ms (worst build = 19.38 ms); raster p50/p90/p99 = 26.15 / 26.46 / 27.92 ms (worst raster = 34.51 ms); total worst frame = 51.15 ms; jank = 98.16%. Self-check: 1000 / 26.15 = 38.2 fps vs 37.1 fps. Receipts: `m26_step6_baseline_bench_half_board.png`, `m26_step6_baseline_bench_half_diag.png`.
  - Control (Effects ON): 93.4 s, 3527 frames, 37.7 fps; build p50/p90/p99 = 2.80 / 3.26 / 3.92 ms (worst build = 16.14 ms); raster p50/p90/p99 = 26.30 / 26.58 / 27.25 ms (worst raster = 39.26 ms); total worst frame = 43.14 ms; jank = 99.74%. Self-check: 1000 / 26.30 = 38.0 fps vs 37.7 fps. Receipts: `m26_step6_control_bench_half_board.png`, `m26_step6_control_bench_half_diag.png`.
  - Delta Control - Baseline: delta raster p50 = +0.15 ms; delta raster p99 = -0.67 ms; delta worst raster = +4.75 ms; delta build p50 = +0.96 ms.
- Validation:
  - `flutter analyze --fatal-infos --fatal-warnings` -> 0 issues.
  - `flutter test` -> 369/369 tests green.

Next step:
- Review by reviewer (DeepSeek / Claude / RuslanFomenko).
- Claude to implement Step 3 (MusicPlaylistManager) and Step 4c (ducking multiplier).

Open:
- None for steps 1b.5 and 6. External questions 1 and 4 remain unchanged.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:6d7af8625cb55c1b430a83eaebfa1cf1fb95fcd4c55695fca48b0381d1318085 over 548 tracked and untracked files
- digest format: 4
- recorded: 2026-09-17T00:43:50.911Z by gemini-918d5c9ee64c083e
- entry: sha256:19d1d4617630bd3c7452d4a71b986019e6766f11bfe5d1548981229d9cb22701 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
