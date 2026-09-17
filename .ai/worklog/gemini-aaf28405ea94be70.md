# Worklog: gemini-aaf28405ea94be70

Session journal. Owned by this session. No other session writes here.

Newest entry first. Limit 150 lines.

---

## 2026-09-17 - Step 1j option (b): within-scene Config D measurement and pieces rasterization

Agent: Gemini (gemini-aaf28405ea94be70)

Action:
1. Within-scene measurement of Config D on half-filled board (26 occupied cells) to isolate the 5th term (rendering cost of `_cachedPiecesPicture`):
   - Used in-scene diagnostic bottom sheet in Classic Mode to switch config in-place with `FrameTimingRecorder.instance.reset()`.
   - Measured idle on Redmi Note 12 Pro (2209116AG, `ro.board.platform` = `sm6150`, 1080x2400 AMOLED 120 Hz) with release build (`--dart-define=APP_ENV=prod --dart-define=APP_FLAVOR=release --dart-define=ENABLE_DIAGNOSTICS=true`).
   - Window: 128.5 s, 3963 frames (cumulative 3963).
   - Captured receipts: `docs/design/m24_step1j_config_d_half_board.png` and `docs/design/m24_step1j_config_d_half_diag.png`.
2. Evaluated delta:
   - Baseline A (half-filled): raster p50 = 38.35 ms (35.0 fps).
   - Config D (half-filled): raster p50 = 31.93 ms (30.9 fps).
   - Delta: 38.35 - 31.93 = +6.42 ms (>= 4.0 ms).
3. Applied `ui.Image` rasterization to occupied board pieces (`_BoardComponent` in `block_puzzle_game.dart`) following Step 1i scheme:
   - Replaced `ui.Picture` caching with `toImageSync` scaled by physical pixel ratio (`boardWellPixelRatio()`).
   - Rendered using single texture blit via `canvas.drawImageRect` with `FilterQuality.low`.
   - Disposed image on board state changes, palette changes, visual preset changes, and component removal.
4. Measured Baseline A on half-filled board (26 occupied cells) after rasterization:
   - Window: 68.2 s, 2599 frames (cumulative 2599).
   - Captured receipts: `docs/design/m24_step1j_rasterized_pieces_half_board.png` and `docs/design/m24_step1j_rasterized_pieces_half_diag.png`.

Result:
- Config D half-filled board:
  - Window: 128.5 s, 3963 frames, 30.9 fps.
  - Build p50 / p90 / p99: 2.09 / 2.53 / 3.32 ms, worst build: 70.63 ms.
  - Raster p50 / p90 / p99: 31.93 / 33.42 / 33.97 ms, worst raster: 37.79 ms.
  - Total worst frame: 78.79 ms.
  - Delta from Baseline A: 38.35 - 31.93 = +6.42 ms.
- Baseline A with rasterized pieces on half-filled board:
  - Window: 68.2 s, 2599 frames, 38.1 fps.
  - Build p50 / p90 / p99: 1.81 / 2.15 / 2.85 ms, worst build: 11.41 ms.
  - Raster p50 / p90 / p99: 26.14 / 26.46 / 27.57 ms, worst raster: 34.48 ms.
  - Total worst frame: 37.61 ms.
  - Delta against pre-rasterization Baseline A: 38.35 -> 26.14 ms (-12.21 ms, -31.8%).
- Verification:
  - `flutter analyze --fatal-infos --fatal-warnings`: 0 issues found.
  - `flutter test`: 357 unit tests passed.
  - `validate-protocol.ps1`: Protocol OK, 0 warnings.

Next step:
- Handoff receipts and numbers to reviewer/owner for decision on Stage B / Step 6 unblocking.

Open:
- None for this measurement.

Evidence:
- anchor: d5ae9471efb847be55af422574c8dd254468bf46, uncommitted changes present
- digest: sha256:bd5b52345201537c6a52ae762144a20c255a20b07b4f5453fc6eee43d263d75c over 536 tracked and untracked files
- digest format: 4
- recorded: 2026-09-16T23:29:07.327Z by gemini-aaf28405ea94be70
- entry: sha256:2f9e399b83b459312d371ed20a0fa64888c7d26505e6ad8533a59c892706574b of this entry without this block
- scope: protocol checks only; host-project tests run separately
- validate-protocol.ps1: exit 0 in 2s
- reproduce: node .ai/bin/protocol-handoff.cjs verify
