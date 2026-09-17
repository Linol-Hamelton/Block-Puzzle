# Worklog: gemini-2d06f930ed9e09d5

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-17 - DEC-0024 Step 1j measurements and frame decomposition

Agent: gemini-2d06f930ed9e09d5 (Gemini, implementer)

Action:
- Measured Classic mode frame timing deconstructed by subtraction inside one scene across configs A..F, plus Config A on half-filled board (28/64 cells).
- Device: Xiaomi Redmi Note 12 Pro (2209116AG), platform `sm6150` (`adb shell getprop ro.board.platform`), GPU Adreno 618, 120 Hz AMOLED.
- Method: Diagnostic switch `Step1jDecomposition` behind `ENABLE_DIAGNOSTICS=true`. Layout and board size identical across all configs (verified via screenshots).
- Addressed four 1i review notes in timing signatures:
  1. Threshold is 8.33 ms (120 Hz vsync budget), not 16.7 ms.
  2. Jank metric sums build + raster, overstating jank rate due to pipeline parallelism.
  3. Percentiles/jank calculated over ring buffer (`sampleFrameCount <= 3600`), FPS over full window (`totalWindowFrames / windowDuration`).
  4. Processor platform `sm6150` confirmed via adb command.

Result:
- Raw measurement data:

| Config | Window | Frames (W/S) | FPS | Build p50/p90/p99 (worst) | Raster p50/p90/p99 (worst) | 1000/raster_p50 | FPS / (1000/p50) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A: Baseline | 61.9 s | 2318 / 2318 | 37.4 | 1.92 / 2.35 / 4.37 (18.31) | 26.25 / 26.64 / 28.90 (38.79) | 38.10 | 0.98 |
| B: No HUD/AppBar | 39.0 s | 1591 / 1591 | 40.8 | 1.90 / 2.39 / 4.50 (11.26) | 24.24 / 24.56 / 25.61 (29.24) | 41.25 | 0.99 |
| C: No ClipRRect | 39.1 s | 1524 / 1524 | 39.0 | 1.82 / 2.24 / 4.82 (15.95) | 25.55 / 25.88 / 27.23 (34.48) | 39.14 | 1.00 |
| D: No PiecesPic | 39.0 s | 1482 / 1482 | 38.0 | 1.78 / 2.23 / 4.44 (13.62) | 25.73 / 26.06 / 27.84 (31.52) | 38.87 | 0.98 |
| E: No RackPic | 38.9 s | 1507 / 1507 | 38.7 | 1.68 / 2.15 / 4.30 (12.33) | 25.32 / 25.66 / 26.56 (30.16) | 39.49 | 0.98 |
| F: No B+C+D+E | 38.9 s | 1710 / 1710 | 43.9 | 1.44 / 1.85 / 3.67 (20.30) | 22.57 / 22.93 / 23.99 (27.10) | 44.31 | 0.99 |
| A: Half-filled | 1568.7 s | 54836 / 3600 | 35.0 | 2.76 / 3.23 / 3.74 (7.86) | 38.35 / 38.70 / 39.09 (41.26) | 26.08 | 1.34 |

- Individual deltas vs Baseline A (raster p50 = 26.25 ms):
  - B (HUD / AppBar / Combo): 26.25 - 24.24 = +2.01 ms
  - C (ClipRRect / DecoratedBox): 26.25 - 25.55 = +0.70 ms
  - D (Starfield / Pieces Picture): 26.25 - 25.73 = +0.52 ms
  - E (Rack Pieces Picture): 26.25 - 25.32 = +0.93 ms
- Additivity comparison:
  - Sum of individual deltas (B+C+D+E): 2.01 + 0.70 + 0.52 + 0.93 = 4.16 ms
  - Measured combined reduction (F): 26.25 - 22.57 = 3.68 ms
  - Additivity discrepancy: |4.16 - 3.68| = 0.48 ms (threshold <= 3.0 ms)
- Half-filled board delta vs Baseline A:
  - Raster p50: 38.35 ms vs 26.25 ms (+12.10 ms for 28 glass pieces on board)
- Directed self-check: ratio `observed FPS / (1000 / raster_p50)` <= 1.50 for all 7 runs.
- Receipts: `docs/design/m24_step1j_config_{a..f}_board.png`, `docs/design/m24_step1j_config_{a..f}_diag.png`, `docs/design/m24_step1j_config_a_half_board.png`, `docs/design/m24_step1j_config_a_half_diag.png`.
- Checks: `flutter analyze --fatal-infos --fatal-warnings` (exit 0), `flutter test` (357 passed), `validate-protocol.ps1` (0 warnings).

Next step:
- Handoff to Reviewer for Step 1j evaluation and decision against exit criteria.

Open:
- None for Gemini on Step 1j.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:3604d010781c25868139b0d3e2ce034db9c0fb1b4f685c2beecdb528f6fe3e94 over 536 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T21:48:24.102Z by gemini-2d06f930ed9e09d5
- entry: sha256:c037404e5eec1eb9e69bd4da694068fde1a31bd482af749d04dbe67775178368 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
