# Worklog: gemini-a9fddb2389c5621b

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-16 - DEC-0024 Step 1g (Control Floor) and Step 1h (Render Pass Bisection)

Agent: Gemini / gemini-a9fddb2389c5621b.

Action: Executed Step 1g and Step 1h on physical Xiaomi Redmi Note 12 Pro (2209116AG, 120 Hz, Adreno 618, release build with `ENABLE_DIAGNOSTICS=true`):
1. Pre-check: Confirmed `git diff apps/mobile/lib/ui/effects/glass_board.dart` completely clean and unmodified before starting bisection.
2. Built dedicated `BenchmarkSceneScreen` implementing layers 1g (Control scene floor: solid color + moving small rectangle), 1h.2 (+ NebulaBackground), 1h.3 (+ Empty GameWidget), 1h.4 (+ Board Well: `paintBoardWell`), and 1h.5 (+ Stones: `paintGlassFacet` on 64 cells).
3. Reset timing stats before each run, sampled each layer for >= 34s, captured high-resolution timing receipts (`m16_step1g_control_scene.png` .. `m20_step1h5_stones.png`).
4. Re-ran full test suite (350/350 passed) and static analysis (0 warnings/infos).

Result: Raw measurement numbers on Xiaomi 2209116AG (all measurement windows >= 34s):
- Step 1g Control Scene (Floor):
  * Raster p50 / p90 / p99 = 5.29 / 8.60 / 10.08 ms (worst 16.64 ms), build p50 / p90 / p99 = 1.92 / 2.24 / 2.74 ms (worst 17.80 ms).
  * Window: 34.4s, 4065 frames, 118.3 fps. Jank: 31.75% (1143 / 3600). Total worst frame: 23.90 ms.
  * Self-check: 1000 / 5.29 = 189.0 fps vs 118.3 fps (hardware-clamped at 120 Hz panel). Screenshot: `m16_step1g_control_scene.png`.
- Step 1h Layer-by-layer Bisection:
  * 1h.2 (+ NebulaBackground): Raster p50 / p90 / p99 = 6.31 / 8.96 / 10.26 ms (worst 17.94 ms), build p50 = 2.27 ms. Window: 34.4s, 4070 frames, 118.5 fps. Delta to Layer 1: +1.02 ms. Self-check: 1000 / 6.31 = 158.5 fps vs 118.5 fps (ratio 1.34 <= 1.5x). Screenshot: `m17_step1h2_nebula.png`.
  * 1h.3 (+ Empty GameWidget): Raster p50 / p90 / p99 = 7.90 / 8.88 / 9.71 ms (worst 14.54 ms), build p50 = 1.90 ms. Window: 34.4s, 4068 frames, 118.3 fps. Delta to Layer 2: +1.59 ms. Self-check: 1000 / 7.90 = 126.6 fps vs 118.3 fps (ratio 1.07 <= 1.5x). Screenshot: `m18_step1h3_gamewidget.png`.
  * 1h.4 (+ Board Well): Raster p50 / p90 / p99 = 19.25 / 20.09 / 21.13 ms (worst 56.51 ms), build p50 = 7.59 ms. Window: 35.5s, 1863 frames, 52.5 fps. Delta to Layer 3: +11.35 ms. Self-check: 1000 / 19.25 = 51.95 fps vs 52.5 fps (ratio 1.01 <= 1.5x). Screenshot: `m19_step1h4_well.png`.
  * 1h.5 (+ Stones): Raster p50 / p90 / p99 = 19.24 / 20.04 / 21.47 ms (worst 53.64 ms), build p50 = 7.64 ms. Window: 36.9s, 1841 frames, 49.9 fps. Delta to Layer 4: -0.01 ms (~0.00 ms). Self-check: 1000 / 19.24 = 51.97 fps vs 49.9 fps (ratio 1.04 <= 1.5x). Screenshot: `m20_step1h5_stones.png`.
- Summary comparative bisection table (Raster p50):
  * Layer 1 (Control floor): 5.29 ms (118.3 fps)
  * Layer 2 (+ Nebula): 6.31 ms (+1.02 ms, 118.5 fps)
  * Layer 3 (+ GameWidget): 7.90 ms (+1.59 ms, 118.3 fps)
  * Layer 4 (+ Board Well): 19.25 ms (+11.35 ms, 52.5 fps)
  * Layer 5 (+ Stones): 19.24 ms (-0.01 ms, 49.9 fps)
- Checks: `flutter analyze --fatal-infos --fatal-warnings` exit 0; `flutter test` exit 0, 350/350 tests passing.

Next step: Reviewer evaluates Step 1g and 1h bisection numbers; owner and reviewer determine optimization path for board well / render pass.

Open: Google Play Console access for Stage C; Firebase Blaze upgrade.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:ce96dbc98f6dfa87e32c2807e8740fcb1aea3152fc73f17ee5628d4df32f9500 over 525 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T18:00:48.855Z by gemini-a9fddb2389c5621b
- entry: sha256:b9e0d9cf3af0deab5ec3c730fa9d082ebcc301581c4483480841b6bc3595b1e5 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

---



## 2026-09-16 - DEC-0024 Step 1f render pass pricing (1f-A blurs and 1f-B clipPath)

Agent: Gemini / gemini-a9fddb2389c5621b.

Action: Executed Step 1f render-pass price measurement on Xiaomi 2209116AG (120 Hz, Adreno 618, release build with `ENABLE_DIAGNOSTICS=true`):
1. Step 1f-A (Remove Blurs): Removed `MaskFilter.blur` from `halo` and `spark` in `paintGlassFacet` and from `groove` and `rim` in `paintBoardWell` in `apps/mobile/lib/ui/effects/glass_board.dart`. Built release APK, installed on device, and measured Classic idle and Match-3 idle. Captured board and diagnostics screenshots.
2. Step 1f-B (Remove ClipPath): Restored all 4 blurs. Removed `canvas.clipPath(path)`, `canvas.save()`, and `canvas.restore()` from `paintGlassFacet`, drawing inner bevel on contracted path scaled by 0.92 around centre. Built release APK, installed on device, and measured Classic idle and Match-3 idle. Captured board and diagnostics screenshots.
3. State in tree: Edits from 1f-B are preserved in `glass_board.dart` and marked temporary per owner instruction pending visual price decision.

Result: Raw measurement numbers on Xiaomi 2209116AG (method: reset timing stats -> enter mode -> 33s idle window -> capture board screenshot -> return to diagnostics -> capture diagnostics screenshot):
- 1f-A (Blurs removed, clipPath present):
  * Classic idle: build p50 / p90 / p99 = 1.95 / 2.40 / 5.36 ms (worst 35.23 ms), raster p50 / p90 / p99 = 29.03 / 29.42 / 30.34 ms (worst 76.03 ms), window 45.4s, 1671 frames, 36.8 fps, jank 97.73% (1633/1671). Self-check: 1000 / 29.03 = 34.45 fps vs 36.8 fps (ratio 1.068). Board screenshot: `m12_classic_board_1fa.png`.
  * Match-3 idle: build p50 / p90 / p99 = 3.88 / 4.25 / 6.67 ms (worst 23.23 ms), raster p50 / p90 / p99 = 34.38 / 34.99 / 36.22 ms (worst 67.22 ms), window 43.7s, 1306 frames, 29.9 fps, jank 97.63% (1275/1306). Self-check: 1000 / 34.38 = 29.08 fps vs 29.9 fps (ratio 1.028). Board screenshot: `m13_match3_board_1fa.png`.
- 1f-B (Blurs restored, clipPath removed):
  * Classic idle: build p50 / p90 / p99 = 2.02 / 2.43 / 6.51 ms (worst 50.02 ms), raster p50 / p90 / p99 = 31.27 / 31.73 / 33.39 ms (worst 92.10 ms), window 45.6s, 1533 frames, 33.6 fps, jank 96.35% (1477/1533). Self-check: 1000 / 31.27 = 31.98 fps vs 33.6 fps (ratio 1.051). Board screenshot: `m14_classic_board_1fb.png`.
  * Match-3 idle: build p50 / p90 / p99 = 2.23 / 3.75 / 5.91 ms (worst 29.99 ms), raster p50 / p90 / p99 = 36.94 / 37.58 / 39.97 ms (worst 127.02 ms), window 47.3s, 1407 frames, 29.7 fps, jank 91.68% (1290/1407). Self-check: 1000 / 36.94 = 27.07 fps vs 29.7 fps (ratio 1.097). Board screenshot: `m15_match3_board_1fb.png`.
- Summary comparative table (raster p50):
  * Classic idle: Baseline 31.95 ms -> 1f-A (no blurs) 29.03 ms (-9.14%) -> 1f-B (no clip) 31.27 ms (-2.13%).
  * Match-3 idle: Baseline 38.91 ms -> 1f-A (no blurs) 34.38 ms (-11.64%) -> 1f-B (no clip) 36.94 ms (-5.06%).
- Checks: `flutter analyze --fatal-infos --fatal-warnings` exit 0; `flutter test` exit 0, 350/350 tests passing.

Next step: Claude reviews step 1f measurements against pre-registered criteria and thresholds (DEC-0025); owner evaluates visual price from board screenshots. Claude continues step 3 (MusicPlaylistManager) and ducking (step 4c).

Open: Google Play Console access for Stage C; Firebase Blaze upgrade; owner visual tradeoff decision for glass material.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:ff4b26110f3cc74d488cf6b957fab8974b1d67bb2cca74e7d9abf7c2fbf2db8f over 498 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T13:08:48.255Z by gemini-a9fddb2389c5621b
- entry: sha256:54ac18adc27f9c20cd14a19fb3a86893f0a90e7be2fa70086c50df6beed6186a of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

---



## 2026-09-16 - DEC-0024 Steps 1d (Exp A & B), 1e (Match-3 Picture cache), 4a (Combo ladder), 4b (Hybrid placement)

Agent: Gemini / gemini-a9fddb2389c5621b.

Action: Executed batch under DEC-0024/DEC-0025 and acceptance criteria doc 04 (ed. 2):
1. Step 1d.A (Renderer comparison): Built release APK with `--enable-impeller=false` (`io.flutter.embedding.android.EnableImpeller=false`), measured Classic idle and Match-3 idle on Xiaomi 2209116AG (120 Hz display, Adreno 618). Reverted flag immediately; git diff clean.
2. Step 1d.B (Surface area): Temporarily wrapped `GameWidget` in `FractionallySizedBox(widthFactor: 0.25, heightFactor: 0.25)` in `game_loop_screen.dart`. Measured Classic idle on 2209116AG. Reverted edit immediately via git checkout; git diff clean.
3. Step 1e (Match-3 board cache): Added `_staticGemsPicture` caching in `match3_game.dart` keyed by board grid, igniting set, cell dimension, and geometry. Bonus gems with `_clock` shimmer, igniting, and hints remain dynamic. Disposed on rebuild/remove. Measured idle and active on 2209116AG.
4. Step 4a (Combo ladder): Resampled `combo.wav` deterministically into 7 mono PCM WAVs (`combo_01`..`07`) by $2^{n/12}$ ($n \in \{0, 2, 4, 7, 9, 12, 14\}$). Wired into `FlameGameSfxPlayer` with injected `nowUtcProvider`, 1..7 clamp, and 2.5s streak reset. Added 4 unit tests. Auditioned on device.
5. Step 4b (Placement thud): Backed up original to `data/audio_masters/piece_placed_v1_mono.wav`. Synthesized deterministic 100 ms mono PCM WAV (`piece_placed.wav`, 8864 B) with 110 Hz body + 2-3 kHz transient. Auditioned on phone speaker and headphones separately.

Result: Raw measurement numbers on Xiaomi 2209116AG (release build, `ENABLE_DIAGNOSTICS=true`):
- 1d.A Renderer (Skia vs Impeller baseline):
  * Classic idle: Impeller raster p50 = 31.95 ms (35.1 fps) -> Skia raster p50/p90/p99 = 15.61 / 16.39 / 19.53 ms (worst 233.74 ms), build p50/p90/p99 = 0.58 / 1.32 / 3.50 ms, window 33.7s, 2154 frames, 63.9 fps, jank 97.49%. Self-check: 1000/15.61 = 64.06 fps vs 63.9 fps (ratio 1.0025).
  * Match-3 idle: Impeller raster p50 = 38.91 ms (31.4 fps) -> Skia raster p50/p90/p99 = 52.77 / 54.93 / 64.56 ms (worst 787.29 ms), build p50/p90/p99 = 0.93 / 2.26 / 4.66 ms, window 33.6s, 716 frames, 21.3 fps, jank 95.25%. Self-check: 1000/52.77 = 18.95 fps vs 21.3 fps (ratio 1.124).
- 1d.B Surface Area (1/16 pixels, Impeller):
  * Classic idle: Full canvas raster p50 = 31.95 ms (35.1 fps) -> 1/4 canvas raster p50/p90/p99 = 24.96 / 25.29 / 26.80 ms (worst 54.60 ms), build p50/p90/p99 = 2.02 / 2.53 / 7.04 ms, window 37.2s, 1559 frames, 41.9 fps, jank 95.57%. Self-check: 1000/24.96 = 40.06 fps vs 41.9 fps (ratio 1.046).
- 1e Match-3 Picture Cache:
  * Idle: Before build p50 = 9.07 ms, raster p50 = 38.91 ms (31.4 fps) -> After build p50/p90/p99 = 3.23 / 3.70 / 8.53 ms (worst 49.73 ms), raster p50/p90/p99 = 38.88 / 39.63 / 41.79 ms (worst 112.72 ms), window 35.6s, 1022 frames, 28.7 fps, jank 97.55%. Self-check: 1000/38.88 = 25.72 fps vs 28.7 fps (ratio 1.116).
  * Active: Before build p50 = 8.71 ms, raster p50 = 38.61 ms (29.9 fps) -> After build p50/p90/p99 = 1.57 / 3.58 / 7.71 ms (worst 23.35 ms), raster p50/p90/p99 = 38.83 / 39.66 / 42.55 ms (worst 90.03 ms), window 38.7s, 1063 frames, 27.5 fps, jank 95.95%. Self-check: 1000/38.83 = 25.75 fps vs 27.5 fps (ratio 1.068).
- 4a Combo ladder: 7 WAVs (C4 D4 E4 G4 A4 C5 D5, +70.66 KB net delta). Injected clock unit tests pass (1..7 clamp, 2.5s reset, 2.4s non-reset). Melodic progression audible on device.
- 4b Placement thud: 100.0 ms mono PCM WAV (8864 B, -882 B). Speaker: 2-3 kHz transient is crisp and punchy with vibration; 110 Hz body is rolled off. Headphones: 110 Hz body is prominent and warm with crisp click attack. Zero latency on rapid placements.
- Checks: `flutter analyze --fatal-infos --fatal-warnings` exit 0; `flutter test` exit 0, 350/350 tests passing.

Next step: Claude reviews steps 1d, 1e, 4a, 4b against acceptance criteria and draws conclusions (DEC-0025); continues Step 3 (MusicPlaylistManager) and ducking (Step 4c).

Open: Google Play Console access for Stage C; Firebase Blaze upgrade.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:676206286363642ef758e0183e07094b5395e9016840b454498aac4614212c1f over 497 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T06:28:23.659Z by gemini-a9fddb2389c5621b
- entry: sha256:92ea92a585a75683ab686d385c8a4be1a8627601b7e01eaf9ecc2c082d98a8b6 of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 5s
- reproduce: node .ai/bin/protocol-handoff.cjs verify

---

