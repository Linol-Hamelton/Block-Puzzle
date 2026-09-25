import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../../../domain/gameplay/board_state.dart';
import '../../../domain/match3/match3_engine.dart';
import '../../../domain/match3/tile.dart';
import '../../../domain/match3/tile_grid.dart';
import '../../../features/diagnostics/step6_benchmark.dart';
import '../../../ui/effects/burst_field.dart';
import '../../../ui/effects/easing_presets.dart';
import '../../../ui/effects/effect_timing.dart';
import '../../../ui/effects/glass_board.dart';
import '../../../ui/effects/glass_tile_atlas.dart';
import '../../../ui/effects/vfx_director.dart';
import '../../../ui/effects/vfx_events.dart';
import '../application/match3_controller.dart';

/// Gem colors (neon palette consistent with the Lumina look).
const Map<TileColor, Color> gemColors = defaultGemColors;

/// Flame view for Match-3. Renders the gem grid, the current selection, and the
/// clear/cascade juice. Input arrives from the Flutter layer (see
/// `Match3Screen`), which maps a tap/swipe to a cell and calls [onCellTapped] /
/// [onSwipe]; the view tracks the selection and asks the controller to swap.
class Match3FlameGame extends FlameGame {
  Match3FlameGame({required this.controller});

  final Match3Controller controller;

  GridPos? _selected;
  double _idleElapsed = 0;
  (GridPos, GridPos)? _hintPair;

  // Visual-juice state.
  double _flash = 0;
  double _shake = 0;
  double _clock = 0;
  int _lastScore = 0;
  int _chargeSerial = -1;
  double _chargeElapsed = 0;
  final BurstField _burst = BurstField();

  late final VfxDirector _vfxDirector = VfxDirector(
    burstField: _burst,
    viewfinder: camera.viewfinder,
    isReducedMotion: () => Step6Benchmark.reducedMotion.value,
    onScreenShake: (double amplitude) {
      _shake = math.max(_shake, (amplitude / 4.0).clamp(0.2, 1.0));
    },
  );
  VfxDirector get vfxDirector => _vfxDirector;

  // Fall distance and cascade drop tracking.
  int _dropSerial = -1;
  double _dropElapsed = 0;
  Map<GridPos, double> _fallDistances = const <GridPos, double>{};

  // Last board geometry (screen space).
  double _ox = 0;
  double _oy = 0;
  double _cell = 0;

  // The board behind the gems: sockets, grooves and rim. None of it moves, so
  // it is recorded once and replayed, and re-recorded only when the geometry
  // actually changes (rotation, a different board size).
  ui.Image? _boardWellImage;
  double _boardWellCell = 0;
  int _boardWellCols = 0;
  int _boardWellRows = 0;
  double _boardWellRatio = 0;

  // Cached picture for static gems (plain gems without effects, not igniting).
  // Recorded once per settled board, re-recorded only when the board, igniting set,
  // or geometry changes.
  ui.Picture? _staticGemsPicture;
  TileGrid? _cachedGemsGrid;
  Set<GridPos> _cachedIgniting = const <GridPos>{};
  double _cachedGemsCell = 0;
  int _cachedGemsCols = 0;
  int _cachedGemsRows = 0;
  GlassTileAtlas<TileColor>? _tileAtlas;

  int get _cols => controller.engine.width;
  int get _rows => controller.engine.height;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    controller.onVisualEvent = _onVisualEvent;
    _lastScore = controller.score;
    add(_vfxDirector);
    await super.onLoad();
  }

  @override
  void onRemove() {
    // onLoad made this game the controller's visual listener. The controller
    // outlives the game, so leaving the reference in place points a live
    // controller at a removed game holding disposed surfaces.
    if (identical(controller.onVisualEvent, _onVisualEvent)) {
      controller.onVisualEvent = null;
    }
    _vfxDirector.clearAll();
    dropCachedSurfaces();
    super.onRemove();
  }

  /// Releases every GPU-resident surface this game caches.
  ///
  /// `toImageSync` hands back an image that lives on the GPU. A surface can be
  /// torn down and rebuilt underneath us - backgrounding the app is the common
  /// way - and an image from the old one is not guaranteed to survive it.
  /// Dropping the caches costs one re-rasterisation and removes the question.
  void dropCachedSurfaces() {
    final ui.Image? staleWell = _boardWellImage;
    _boardWellImage = null;
    staleWell?.dispose();

    final ui.Picture? staleGems = _staticGemsPicture;
    _staticGemsPicture = null;
    staleGems?.dispose();
    _cachedGemsGrid = null;

    final GlassTileAtlas<TileColor>? staleAtlas = _tileAtlas;
    _tileAtlas = null;
    staleAtlas?.dispose();
  }

  /// Maps a local pixel offset (within the GameWidget) to a cell, or null.
  GridPos? cellAt(Offset local) {
    if (_cell <= 0) {
      return null;
    }
    final int x = ((local.dx - _ox) / _cell).floor();
    final int y = ((local.dy - _oy) / _cell).floor();
    if (x < 0 || x >= _cols || y < 0 || y >= _rows) {
      return null;
    }
    return GridPos(x, y);
  }

  /// Tap-to-select, tap-adjacent-to-swap. Tapping the selected cell deselects;
  /// tapping a non-adjacent cell re-selects it.
  void onCellTapped(GridPos pos) {
    _idleElapsed = 0;
    _hintPair = null;
    final GridPos? sel = _selected;
    if (sel == null) {
      _selected = pos;
      return;
    }
    if (sel == pos) {
      _selected = null;
      return;
    }
    if (_isAdjacent(sel, pos)) {
      _selected = null;
      controller.trySwap(sel, pos);
    } else {
      _selected = pos;
    }
  }

  /// Swipe a tile toward a neighbor: swap it with that neighbor.
  void onSwipe(GridPos from, int dx, int dy) {
    _idleElapsed = 0;
    _hintPair = null;
    _selected = null;
    controller.trySwap(from, GridPos(from.x + dx, from.y + dy));
  }

  bool _isAdjacent(GridPos a, GridPos b) =>
      ((a.x - b.x).abs() + (a.y - b.y).abs()) == 1;

  void _onVisualEvent(Match3Event event) {
    _idleElapsed = 0;
    _hintPair = null;
    final double cell = _cell > 0 ? _cell : 20.0;
    switch (event.type) {
      case Match3EventType.swap:
        break;
      case Match3EventType.match:
        _spawnClearParticles();
        _flash = math.max(_flash, (event.value / 9).clamp(0.3, 1).toDouble());

        final Iterable<GridPos> burstKeys = controller.frameBurst.keys;
        final double cx;
        final double cy;
        if (burstKeys.isNotEmpty) {
          final double sumX =
              burstKeys.fold(0.0, (double acc, GridPos p) => acc + p.x);
          final double sumY =
              burstKeys.fold(0.0, (double acc, GridPos p) => acc + p.y);
          cx = _ox + (((sumX / burstKeys.length) + 0.5) * cell);
          cy = _oy + (((sumY / burstKeys.length) + 0.5) * cell);
        } else {
          cx = _ox + (_cols * cell * 0.5);
          cy = _oy + (_rows * cell * 0.5);
        }
        final Vector2 centroid = Vector2(cx, cy);

        final Color matchColor = controller.frameBurst.isNotEmpty
            ? (gemColors[controller.frameBurst.values.first] ??
                const Color(0xFF00E5FF))
            : const Color(0xFF00E5FF);

        final Set<BoardCell> clearedCells = <BoardCell>{
          for (final GridPos p in burstKeys) BoardCell(x: p.x, y: p.y),
        };

        final int strength = (event.value / 3).ceil().clamp(1, 4);
        _vfxDirector.handleEvent(
          VfxEvent.lineCleared(
            cells: clearedCells,
            centroid: centroid,
            strength: strength,
            color: matchColor,
            boardOrigin: Vector2(_ox, _oy),
            cellSize: cell,
            boardSize: Vector2(_cols * cell, _rows * cell),
          ),
        );

        final int scoreDelta = event.points > 0 ? event.points : (controller.score - _lastScore);
        if (scoreDelta > 0) {
          _vfxDirector.handleEvent(
            VfxEvent.scorePopped(
              text: '+$scoreDelta',
              position: centroid,
              color: const Color(0xFFD6FFE0),
            ),
          );
        }

        if (event.detail >= 2) {
          _shake = math.max(_shake, 0.5);
          _vfxDirector.handleEvent(
            VfxEvent.comboPulse(
              text: 'COMBO x${event.detail}',
              position: centroid,
              comboStreak: event.detail,
            ),
          );
        } else if (event.value >= 5) {
          _vfxDirector.handleEvent(
            VfxEvent.comboPulse(
              text: 'NICE!',
              position: centroid,
              comboStreak: 1,
            ),
          );
        }
        break;
      case Match3EventType.specialSpawned:
        _flash = math.max(_flash, 0.5);
        break;
      case Match3EventType.combo:
        _flash = math.max(_flash, 0.9);
        _shake = math.max(_shake, 0.6);
        final Vector2 center =
            Vector2(_ox + (_cols * cell * 0.5), _oy + (_rows * cell * 0.5));
        _vfxDirector.handleEvent(
          VfxEvent.comboPulse(
            text: event.combo?.label ?? 'COMBO',
            position: center,
            comboStreak: 3,
          ),
        );
        _vfxDirector.handleEvent(
          const VfxEvent.screenShake(amplitude: 2.8, zoomPunch: true),
        );
        _vfxDirector.triggerHitStop(0.045);
        break;
      case Match3EventType.roundComplete:
        _flash = math.max(_flash, 0.8);
        _vfxDirector.handleEvent(
          VfxEvent.allClear(
            boardOrigin: Vector2(_ox, _oy),
            boardSize: Vector2(_cols * cell, _rows * cell),
          ),
        );
        _vfxDirector.handleEvent(
          VfxEvent.comboPulse(
            text: 'ROUND ${event.value} + ${event.detail} MOVES',
            position:
                Vector2(_ox + (_cols * cell * 0.5), _oy + (_rows * cell * 0.35)),
            comboStreak: 4,
          ),
        );
        break;
      case Match3EventType.invalidSwap:
        _shake = math.max(_shake, 0.25);
        _vfxDirector.handleEvent(
          const VfxEvent.screenShake(amplitude: 1.0),
        );
        break;
      case Match3EventType.shuffle:
        _flash = math.max(_flash, 0.4);
        _vfxDirector.handleEvent(
          VfxEvent.comboPulse(
            text: 'SHUFFLE',
            position:
                Vector2(_ox + (_cols * cell * 0.5), _oy + (_rows * cell * 0.5)),
            comboStreak: 2,
          ),
        );
        break;
      case Match3EventType.gameOver:
        _shake = math.max(_shake, 0.7);
        _vfxDirector.handleEvent(
          const VfxEvent.screenShake(amplitude: 3.5),
        );
        break;
    }
  }

  void _spawnClearParticles() {
    if (_cell <= 0) {
      return;
    }
    controller.frameBurst.forEach((GridPos pos, TileColor color) {
      _burst.spawnBurst(
        x: _ox + (pos.x * _cell) + (_cell / 2),
        y: _oy + (pos.y * _cell) + (_cell / 2),
        color: gemColors[color]!,
        count: 3,
        sizeBase: _cell * 0.12,
        sizeJitter: _cell * 0.1,
      );
    });
  }

  /// How far into the current playback frame the view is, 0..1.
  ///
  /// Timed against the controller's frame serial rather than a shared clock, so
  /// the charge always starts at zero when a new board appears however long the
  /// previous frame was held.
  double _frameCharge() {
    final int serial = controller.frameSerial;
    if (serial != _chargeSerial) {
      _chargeSerial = serial;
      _chargeElapsed = 0;
    }
    final double hold = controller.frameHold.inMilliseconds / 1000;
    if (hold <= 0) {
      return 0;
    }
    return (_chargeElapsed / hold).clamp(0, 1).toDouble();
  }

  /// Computes how many cells each tile drops following gravity and refill.
  static Map<GridPos, double> computeFallDistances(
    int cols,
    int rows,
    Iterable<GridPos> burstPositions,
  ) {
    final Map<GridPos, double> distances = <GridPos, double>{};
    if (burstPositions.isEmpty) {
      return distances;
    }

    final Map<int, List<int>> clearedByCol = <int, List<int>>{};
    for (final GridPos p in burstPositions) {
      if (p.x >= 0 && p.x < cols && p.y >= 0 && p.y < rows) {
        (clearedByCol[p.x] ??= <int>[]).add(p.y);
      }
    }

    for (final MapEntry<int, List<int>> entry in clearedByCol.entries) {
      final int x = entry.key;
      final Set<int> clearedRows = entry.value.toSet();
      final int totalCleared = clearedRows.length;

      int writeY = rows - 1;
      for (int origY = rows - 1; origY >= 0; origY--) {
        if (!clearedRows.contains(origY)) {
          final int dist = writeY - origY;
          if (dist > 0) {
            distances[GridPos(x, writeY)] = dist.toDouble();
          }
          writeY--;
        }
      }
      while (writeY >= 0) {
        distances[GridPos(x, writeY)] = totalCleared.toDouble();
        writeY--;
      }
    }
    return distances;
  }

  /// Evaluates cascade drop progress along [EasingPresets.cascadeDropCurve].
  double _dropProgress() {
    final int serial = controller.frameSerial;
    if (serial != _dropSerial) {
      _dropSerial = serial;
      _dropElapsed = 0.0;
      _fallDistances = computeFallDistances(
        _cols,
        _rows,
        controller.frameBurst.keys,
      );
    }
    if (_fallDistances.isEmpty) {
      return 1.0;
    }
    final double holdSec = controller.frameHold.inMilliseconds / 1000.0;
    final double dropDuration = math.min(
      EasingPresets.durationCascadeStep,
      holdSec > 0 ? holdSec : EasingPresets.durationCascadeStep,
    );
    if (dropDuration <= 0) {
      return 1.0;
    }
    final double t = (_dropElapsed / dropDuration).clamp(0.0, 1.0);
    return EasingPresets.evaluateProgress(t, EasingPresets.cascadeDropCurve);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_vfxDirector.isHitStopActive) {
      return;
    }
    _clock += dt;
    if (_flash > 0) {
      _flash = math.max(0, _flash - (dt * 2.6 / kEffectTimeScale));
    }
    if (_shake > 0) {
      _shake = math.max(0, _shake - (dt * 3.4 / kEffectTimeScale));
    }
    _lastScore = controller.score;
    _chargeElapsed += dt;
    _dropElapsed += dt;

    // Idle hint: softly pulse one legal swap after 4.5s of player inactivity.
    if (_selected == null && !controller.isBusy && !controller.isGameOver) {
      _idleElapsed += dt;
      if (_idleElapsed >= 4.5 && _hintPair == null) {
        _hintPair = controller.engine.findHint();
      }
    } else {
      _idleElapsed = 0;
      _hintPair = null;
    }
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    // The board the player is looking at, not the one the rules have settled
    // on. While a cascade plays these differ by a few hundred milliseconds.
    final TileGrid grid = controller.displayGrid;
    final Set<GridPos> igniting = controller.ignitingCells;
    final double charge = igniting.isEmpty ? 0 : _frameCharge();
    final double dropProgress = _dropProgress();
    final double cell = math.min(size.x / _cols, size.y / _rows);
    final double boardW = cell * _cols;
    final double boardH = cell * _rows;
    final double ox = (size.x - boardW) / 2;
    final double oy = (size.y - boardH) / 2;
    _ox = ox;
    _oy = oy;
    _cell = cell;

    final bool reduced = Step6Benchmark.reducedMotion.value;
    final double sx = (!reduced && _shake > 0) ? math.sin(_shake * 51) * _shake * 6 : 0;
    final double sy = (!reduced && _shake > 0) ? math.cos(_shake * 59) * _shake * 6 : 0;
    canvas.save();
    canvas.translate(sx, sy);

    _renderBackground(canvas, ox, oy, boardW, boardH, cell);

    final double ratio = boardWellPixelRatio();
    if (_tileAtlas == null || !_tileAtlas!.isValidFor(unit: cell, devicePixelRatio: ratio)) {
      final GlassTileAtlas<TileColor>? staleAtlas = _tileAtlas;
      _tileAtlas = null;
      staleAtlas?.dispose();
      _tileAtlas = GlassTileAtlas.bakeMatch3(
        cell: cell,
        devicePixelRatio: ratio,
        palette: gemColors,
      );
    }

    final bool isDropping = _fallDistances.isNotEmpty && dropProgress < 1.0;

    // Static gems pre-recorded picture is only reused when gems are settled
    if (!isDropping) {
      _updateStaticGemsPicture(grid, igniting, cell, _cols, _rows);
      if (_staticGemsPicture != null) {
        canvas.save();
        canvas.translate(ox, oy);
        canvas.drawPicture(_staticGemsPicture!);
        canvas.restore();
      }
    }

    // Clip dynamic falling / special gems to the board well
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(ox, oy, boardW, boardH),
        const Radius.circular(14),
      ),
    );

    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _cols; x++) {
        final Tile? tile = grid.tileAt(x, y);
        if (tile == null) {
          continue;
        }
        final bool isIgniting = igniting.contains(GridPos(x, y));
        final bool isSpecial = tile.isSpecial;

        // Skip static gems if they were already painted via cached picture
        if (!isDropping && !isSpecial && !isIgniting) {
          continue;
        }

        final double fallDist = _fallDistances[GridPos(x, y)] ?? 0.0;
        final double yOffset = (isDropping && fallDist > 0)
            ? -(1.0 - dropProgress) * fallDist * cell
            : 0.0;

        final Color color = gemColors[tile.color]!;

        // Render PieceAuraShader behind special / charged gems
        if (_vfxDirector.auraShader.isEnabled && (isSpecial || isIgniting)) {
          final double inset = cell * 0.115;
          final Rect gemRect = Rect.fromLTWH(
            ox + (x * cell) + inset,
            oy + (y * cell) + inset + yOffset,
            cell - (inset * 2),
            cell - (inset * 2),
          );
          final Color auraColor = tile.special == SpecialKind.colorBomb
              ? const Color(0xFFFFFFFF)
              : color;
          _vfxDirector.auraShader.drawAura(
            canvas,
            targetBounds: gemRect,
            color: auraColor,
            time: _vfxDirector.clock,
            intensity: isIgniting ? 0.95 : 0.65,
          );
        }

        _paintGem(
          canvas,
          ox,
          oy,
          x,
          y,
          cell,
          tile.color,
          color,
          charge: isIgniting ? charge : 0,
          yOffset: yOffset,
        );
        if (isSpecial) {
          _paintSpecial(
            canvas,
            ox,
            oy,
            x,
            y,
            cell,
            tile.special,
            color,
            yOffset: yOffset,
          );
        }
      }
    }

    canvas.restore(); // restore clip

    final GridPos? sel = _selected;
    if (sel != null) {
      _paintSelection(canvas, ox, oy, sel, cell);
    } else if (_hintPair != null &&
        !controller.isBusy &&
        !controller.isGameOver) {
      _paintHint(canvas, ox, oy, _hintPair!.$1, _hintPair!.$2, cell);
    }

    if (_flash > 0) {
      final double maxA = reduced ? 0.08 : 0.5;
      final double alpha = (_flash * 0.35).clamp(0, maxA).toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(ox, oy, boardW, boardH),
          const Radius.circular(14),
        ),
        Paint()..color = Color.fromRGBO(180, 235, 255, alpha),
      );
    }

    canvas.restore(); // restore shake translation

    super.render(canvas); // renders VfxDirector, shockwaves, combo pulses, score pops, particles
  }

  /// The board the gems sit in, from the shared well so all three games are
  /// played on the same field. Rasterised once - nothing in it moves, and a
  /// replayed picture costs its shaders again on every frame.
  void _renderBackground(
    Canvas canvas,
    double ox,
    double oy,
    double boardW,
    double boardH,
    double cell,
  ) {
    final double ratio = boardWellPixelRatio();
    if (_boardWellImage == null ||
        _boardWellCell != cell ||
        _boardWellCols != _cols ||
        _boardWellRows != _rows ||
        _boardWellRatio != ratio) {
      // Cleared before disposal, never after. Drawing a disposed ui.Image is a
      // native crash: the zone guard, FlutterError.onError and
      // PlatformDispatcher.onError all miss it and the app closes outright.
      final ui.Image? staleWell = _boardWellImage;
      _boardWellImage = null;
      staleWell?.dispose();
      _boardWellImage = rasterizeBoardWell(
        width: boardW,
        height: boardH,
        cell: cell,
        cols: _cols,
        rows: _rows,
        devicePixelRatio: ratio,
      );
      _boardWellCell = cell;
      _boardWellCols = _cols;
      _boardWellRows = _rows;
      _boardWellRatio = ratio;
    }
    final ui.Image? wellImage = _boardWellImage;
    if (wellImage == null) {
      return;
    }
    canvas.save();
    canvas.translate(ox, oy);
    drawBoardWellImage(
      canvas,
      wellImage,
      width: boardW,
      height: boardH,
    );
    canvas.restore();
  }

  /// Checks if the cached static gems picture is still valid for the given board
  /// state, igniting cells, and cell geometry.
  bool _canReuseGemsPicture(
    TileGrid grid,
    Set<GridPos> igniting,
    double cell,
    int cols,
    int rows,
  ) {
    if (_staticGemsPicture == null) {
      return false;
    }
    if (_cachedGemsCell != cell ||
        _cachedGemsCols != cols ||
        _cachedGemsRows != rows) {
      return false;
    }
    if (!setEquals(_cachedIgniting, igniting)) {
      return false;
    }
    if (identical(_cachedGemsGrid, grid)) {
      return true;
    }
    if (_cachedGemsGrid == null ||
        _cachedGemsGrid!.width != grid.width ||
        _cachedGemsGrid!.height != grid.height) {
      return false;
    }
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final Tile? a = _cachedGemsGrid!.tileAt(x, y);
        final Tile? b = grid.tileAt(x, y);
        if (a?.color != b?.color || a?.special != b?.special) {
          return false;
        }
      }
    }
    return true;
  }

  /// Pre-records all unchanged static gems (plain gems, not igniting, no special)
  /// into a single replayed [ui.Picture].
  void _updateStaticGemsPicture(
    TileGrid grid,
    Set<GridPos> igniting,
    double cell,
    int cols,
    int rows,
  ) {
    if (_canReuseGemsPicture(grid, igniting, cell, cols, rows)) {
      return;
    }
    // Cleared before disposal, never after. There are forty lines of drawing
    // between here and endRecording; if any of it throws, a disposed
    // ui.Picture left in the field is replayed on the next frame, and that
    // closes the app without a Dart exception anyone can catch.
    final ui.Picture? staleGems = _staticGemsPicture;
    _staticGemsPicture = null;
    staleGems?.dispose();
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas recorderCanvas = Canvas(recorder);

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final Tile? tile = grid.tileAt(x, y);
        if (tile == null || tile.isSpecial || igniting.contains(GridPos(x, y))) {
          continue;
        }
        final Color color = gemColors[tile.color]!;
        _paintGem(
          recorderCanvas,
          0,
          0,
          x,
          y,
          cell,
          tile.color,
          color,
          charge: 0,
        );
      }
    }

    _staticGemsPicture = recorder.endRecording();
    _cachedGemsGrid = grid;
    _cachedIgniting = Set<GridPos>.of(igniting);
    _cachedGemsCell = cell;
    _cachedGemsCols = cols;
    _cachedGemsRows = rows;
  }

  /// The silhouette a gem of this colour is cut to.
  ///
  /// Six colours, six shapes. Modern match-3 games do not ask colour to carry
  /// the board on its own, and neither should this one: a player scanning for a
  /// run reads silhouette faster than hue, the board stays legible through
  /// motion and a cascade, and it keeps working for a player who sees colour
  /// poorly. Colour and shape say the same thing twice.
  Path _gemPath(TileColor color, Rect rect) => match3GemPath(color, rect);

  /// One gem, cut from the shared glass to its colour's silhouette.
  ///
  /// [charge] is how close the gem is to going off: it blooms outward as a
  /// cascade step ignites, which is what turns a clear into an event rather
  /// than a disappearance.
  void _paintGem(
    Canvas canvas,
    double ox,
    double oy,
    int x,
    int y,
    double cell,
    TileColor tileColor,
    Color color, {
    double charge = 0,
    double yOffset = 0,
  }) {
    if (charge == 0 && _tileAtlas != null) {
      _tileAtlas!.drawTile(
        canvas,
        key: tileColor,
        dstCellRect: Rect.fromLTWH(
          ox + (x * cell),
          oy + (y * cell) + yOffset,
          cell,
          cell,
        ),
      );
      return;
    }

    // Inset enough that the socket shows as a ring around the gem. An earlier
    // pass filled 83% of the cell and hid the board it was meant to sit in.
    final double inset = cell * 0.115;
    final Rect rect = Rect.fromLTWH(
      ox + (x * cell) + inset,
      oy + (y * cell) + inset + yOffset,
      cell - (inset * 2),
      cell - (inset * 2),
    );
    paintGlassFacet(
      canvas,
      path: _gemPath(tileColor, rect),
      bounds: rect,
      tint: color,
      unit: cell,
      glow: charge,
    );
  }

  /// Draws what a bonus gem does, on top of the gem itself.
  ///
  /// The glyph has to survive a 40px cell in motion, so each one is a different
  /// *shape* and not a different decoration of the same shape: a bar lying the
  /// way it will sweep, a ringed core for the blast, a rosette for the colour
  /// bomb. The gem keeps its own colour underneath, because the player still
  /// needs to match it with its neighbours.
  void _paintSpecial(
    Canvas canvas,
    double ox,
    double oy,
    int x,
    int y,
    double cell,
    SpecialKind kind,
    Color color, {
    double yOffset = 0,
  }) {
    final double cx = ox + (x * cell) + (cell / 2);
    final double cy = oy + (y * cell) + (cell / 2) + yOffset;
    // A slow shared shimmer, so bonuses read as "alive" against plain gems.
    final double glow = 0.72 + (0.28 * math.sin((_clock * 3.4) + x + y));
    final Color ink = Color.lerp(Colors.white, color, 0.12) ?? Colors.white;
    final Paint fill = Paint()..color = ink.withValues(alpha: glow);
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, cell * 0.055)
      ..color = ink.withValues(alpha: glow);

    switch (kind) {
      case SpecialKind.none:
        return;

      case SpecialKind.lineHorizontal:
      case SpecialKind.lineVertical:
        final bool horizontal = kind == SpecialKind.lineHorizontal;
        final double long = cell * 0.62;
        final double thick = cell * 0.16;
        final Rect bar = Rect.fromCenter(
          center: Offset(cx, cy),
          width: horizontal ? long : thick,
          height: horizontal ? thick : long,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bar, Radius.circular(thick / 2)),
          fill,
        );
        // Two chevrons pointing the way the sweep will travel.
        for (final double side in <double>[-1, 1]) {
          final Path chevron = Path();
          final double tip = (cell * 0.42) * side;
          final double back = (cell * 0.28) * side;
          final double spread = cell * 0.12;
          if (horizontal) {
            chevron.moveTo(cx + back, cy - spread);
            chevron.lineTo(cx + tip, cy);
            chevron.lineTo(cx + back, cy + spread);
          } else {
            chevron.moveTo(cx - spread, cy + back);
            chevron.lineTo(cx, cy + tip);
            chevron.lineTo(cx + spread, cy + back);
          }
          canvas.drawPath(chevron, stroke);
        }

      case SpecialKind.bomb:
        canvas.drawCircle(Offset(cx, cy), cell * 0.17, fill);
        canvas.drawCircle(Offset(cx, cy), cell * 0.3, stroke);
        // Four spokes: the 3x3 reach, stated rather than implied.
        for (int i = 0; i < 4; i++) {
          final double angle = (math.pi / 2) * i;
          canvas.drawLine(
            Offset(cx + (math.cos(angle) * cell * 0.3),
                cy + (math.sin(angle) * cell * 0.3)),
            Offset(cx + (math.cos(angle) * cell * 0.42),
                cy + (math.sin(angle) * cell * 0.42)),
            stroke,
          );
        }

      case SpecialKind.colorBomb:
        // Every gem colour in one rosette - the only gem on the board that is
        // not about its own colour.
        final List<Color> wheel = gemColors.values.toList(growable: false);
        final double radius = cell * 0.3;
        for (int i = 0; i < wheel.length; i++) {
          final double angle =
              ((math.pi * 2) / wheel.length) * i - (math.pi / 2) + (_clock * 0.8);
          canvas.drawCircle(
            Offset(cx + (math.cos(angle) * radius),
                cy + (math.sin(angle) * radius)),
            cell * 0.085,
            Paint()..color = wheel[i].withValues(alpha: glow),
          );
        }
        canvas.drawCircle(
          Offset(cx, cy),
          cell * 0.13,
          Paint()..color = Colors.white.withValues(alpha: glow),
        );
    }
  }

  void _paintSelection(
    Canvas canvas,
    double ox,
    double oy,
    GridPos sel,
    double cell,
  ) {
    final double pulse = 0.6 + (0.4 * math.sin(_clock * 7));
    final double pad = cell * 0.04;
    final Rect rect = Rect.fromLTWH(
      ox + (sel.x * cell) + pad,
      oy + (sel.y * cell) + pad,
      cell - (pad * 2),
      cell - (pad * 2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.28)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.0, cell * 0.08)
        ..color = Colors.white.withValues(alpha: (0.55 + 0.45 * pulse).clamp(0, 1).toDouble()),
    );
  }

  void _paintHint(
    Canvas canvas,
    double ox,
    double oy,
    GridPos a,
    GridPos b,
    double cell,
  ) {
    final double pulse = 0.5 + (0.5 * math.sin(_clock * 4.5));
    final double alpha = (0.22 + (0.38 * pulse)).clamp(0, 0.8).toDouble();
    final double pad = cell * 0.04;
    for (final GridPos pos in <GridPos>[a, b]) {
      final Rect rect = Rect.fromLTWH(
        ox + (pos.x * cell) + pad,
        oy + (pos.y * cell) + pad,
        cell - (pad * 2),
        cell - (pad * 2),
      );
      final RRect rr =
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.28));
      canvas.drawRRect(
        rr.inflate(cell * 0.03 * pulse),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.8, cell * 0.055)
          ..color = const Color(0xFFC5F2FF).withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.1),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, cell * 0.04)
          ..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }
}

