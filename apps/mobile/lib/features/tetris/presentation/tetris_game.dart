import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../domain/tetris/falling_piece.dart';
import '../../../domain/tetris/tetris_engine.dart';
import '../../../domain/tetris/tetromino.dart';
import '../../../ui/effects/burst_field.dart';
import '../../../ui/effects/glass_board.dart';
import '../application/tetris_controller.dart';

/// Mino colors (neon palette consistent with the Lumina look).
const Map<TetrominoType, Color> tetrominoColors = <TetrominoType, Color>{
  TetrominoType.i: Color(0xFF44E0EA),
  TetrominoType.o: Color(0xFFF2D24E),
  TetrominoType.t: Color(0xFFB672EC),
  TetrominoType.s: Color(0xFF5FE08A),
  TetrominoType.z: Color(0xFFF06A86),
  TetrominoType.j: Color(0xFF5A8CEC),
  TetrominoType.l: Color(0xFFF0A44E),
};

/// Flame view for Tetris. Renders the board, locked cells, ghost, and the
/// active piece in screen space, and drives the model clock by forwarding each
/// frame's `dt` to the [TetrisController]. Input arrives from Flutter controls
/// (see `TetrisScreen`), not from Flame gesture components.
class TetrisFlameGame extends FlameGame {
  TetrisFlameGame({required this.controller});

  final TetrisController controller;

  // Visual-juice state (driven by controller.onVisualEvent, decayed in update).
  double _flash = 0;
  int _flashStrength = 0;
  double _shake = 0;
  String? _pulseText;
  double _pulseElapsed = 0;
  int _pulsePriority = 0;
  String? _scorePopText;
  double _scorePopElapsed = 0;
  double _clock = 0; // free-running clock for pulsing effects
  final BurstField _burst = BurstField();
  final List<_LockFlash> _lockFlashes = <_LockFlash>[];

  // Last computed board layout (screen space), so event handlers can place
  // particles / popups without recomputing geometry.
  double _lox = 0;
  double _loy = 0;
  double _lcell = 0;

  // Cached static board background (gradient + grid + border), rasterised once
  // into a texture at physical resolution. Blitting the texture is close to free,
  // avoiding replaying ~130 gradient shaders and blurs every frame from a Picture.
  ui.Image? _bgImage;
  double _bgW = -1;
  double _bgH = -1;
  double _bgCell = -1;
  double _bgRatio = 0;
  int _bgCols = 0;
  int _bgRows = 0;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    controller.onVisualEvent = _onVisualEvent;
    await super.onLoad();
  }

  @override
  void onRemove() {
    _bgImage?.dispose();
    _bgImage = null;
    super.onRemove();
  }

  void _onVisualEvent(TetrisEvent event) {
    switch (event.type) {
      case TetrisEventType.lineClear:
        _flash = 1;
        _flashStrength = event.value;
        _spawnClearParticles();
        if (event.detail > 0) {
          _spawnScorePop('+${event.detail}');
        }
        // Scaled, not switched on at four. A double should feel like more than
        // a single, or three quarters of the game's clears feel identical.
        const List<double> shakeByRows = <double>[0, 0.22, 0.4, 0.62, 1];
        _shake = math.max(
          _shake,
          shakeByRows[event.value.clamp(0, 4)],
        );
        if (event.value >= 4) {
          _pulse('TETRIS!', 3);
        }
        break;
      case TetrisEventType.combo:
        _pulse('COMBO x${event.value + 1}', 2);
        break;
      case TetrisEventType.tSpin:
        _shake = math.max(_shake, 0.7);
        _pulse(
          event.value > 0 ? 'T-SPIN ${_clearWord(event.value)}' : 'T-SPIN',
          4,
        );
        break;
      case TetrisEventType.perfectClear:
        _shake = math.max(_shake, 1);
        _pulse('PERFECT CLEAR!', 5);
        if (event.detail > 0) {
          _spawnScorePop('+${event.detail}');
        }
        break;
      case TetrisEventType.levelUp:
        _pulse('LEVEL ${event.value}', 1);
        break;
      case TetrisEventType.hardDrop:
        _shake = math.max(_shake, 0.22);
        break;
      case TetrisEventType.gameOver:
        _shake = math.max(_shake, 0.8);
        break;
      case TetrisEventType.lock:
        // Flash exactly where the piece locked. Read the engine's captured
        // locked cells (not the last rendered active cells) so a hard drop —
        // which locks before any render at the landed position — flashes the
        // landing spot, not the stale mid-air position.
        for (final TCell c in controller.engine.lastLockedCells) {
          _lockFlashes.add(_LockFlash(c.x, c.y));
        }
        break;
      case TetrisEventType.spawn:
      case TetrisEventType.move:
      case TetrisEventType.rotate:
      case TetrisEventType.softDrop:
      case TetrisEventType.hold:
        break;
    }
  }

  void _pulse(String text, int priority) {
    if (_pulseText != null &&
        priority < _pulsePriority &&
        _pulseElapsed < 0.5) {
      return;
    }
    _pulseText = text;
    _pulsePriority = priority;
    _pulseElapsed = 0;
  }

  void _spawnScorePop(String text) {
    _scorePopText = text;
    _scorePopElapsed = 0;
  }

  void _spawnClearParticles() {
    final TetrisEngine engine = controller.engine;
    if (!engine.isClearing || _lcell <= 0) {
      return;
    }
    for (final int row in engine.clearingRows) {
      for (int x = 0; x < engine.board.width; x++) {
        final TetrominoType? type = engine.board.cellAt(x, row);
        if (type == null) {
          continue;
        }
        _burst.spawnBurst(
          x: _lox + (x * _lcell) + (_lcell / 2),
          y: _loy + (row * _lcell) + (_lcell / 2),
          color: tetrominoColors[type]!,
          sizeBase: _lcell * 0.12,
          sizeJitter: _lcell * 0.1,
        );
      }
    }
  }

  static String _clearWord(int rows) {
    switch (rows) {
      case 1:
        return 'SINGLE';
      case 2:
        return 'DOUBLE';
      case 3:
        return 'TRIPLE';
      default:
        return '';
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    controller.tick(Duration(microseconds: (dt * 1000000).round()));
    if (_flash > 0) {
      _flash = math.max(0, _flash - (dt * 3.0));
    }
    if (_shake > 0) {
      _shake = math.max(0, _shake - (dt * 3.6));
    }
    if (_pulseText != null) {
      _pulseElapsed += dt;
      if (_pulseElapsed > 1.1) {
        _pulseText = null;
        _pulseElapsed = 0;
      }
    }
    if (_scorePopText != null) {
      _scorePopElapsed += dt;
      if (_scorePopElapsed > 0.9) {
        _scorePopText = null;
        _scorePopElapsed = 0;
      }
    }
    _burst.update(dt);
    _clock += dt;
    if (_lockFlashes.isNotEmpty) {
      for (final _LockFlash f in _lockFlashes) {
        f.life -= dt;
      }
      _lockFlashes.removeWhere((_LockFlash f) => f.life <= 0);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) {
      return;
    }

    final TetrisEngine engine = controller.engine;
    final int cols = engine.board.width;
    final int rows = engine.board.height;
    final double cell = math.min(size.x / cols, size.y / rows);
    final double boardW = cell * cols;
    final double boardH = cell * rows;
    final double ox = (size.x - boardW) / 2;
    final double oy = (size.y - boardH) / 2;
    _lox = ox;
    _loy = oy;
    _lcell = cell;

    final Set<int> clearing =
        engine.isClearing ? engine.clearingRows.toSet() : const <int>{};
    final _ClearBeats beats = _ClearBeats(engine.clearProgress);

    final double sx = _shake > 0 ? math.sin(_shake * 53) * _shake * 7 : 0;
    final double sy = _shake > 0 ? math.cos(_shake * 61) * _shake * 7 : 0;
    canvas.save();
    canvas.translate(sx, sy);

    _renderBackground(canvas, ox, oy, boardW, boardH, cell, cols, rows);

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final TetrominoType? type = engine.board.cellAt(x, y);
        if (type != null) {
          final bool isClearing = clearing.contains(y);
          _paintCell(
            canvas,
            ox,
            oy,
            x,
            y,
            cell,
            tetrominoColors[type]!,
            beats: isClearing ? beats : null,
          );
        }
      }
    }

    final FallingPiece? active = engine.active;
    final FallingPiece? ghost = engine.ghost;
    if (ghost != null && active != null) {
      final Color color = tetrominoColors[active.type]!;
      _paintDropShaft(canvas, ox, oy, cell, color, active, ghost);
      for (final TCell c in ghost.absoluteCells()) {
        if (c.y >= 0) {
          _paintGhost(canvas, ox, oy, c.x, c.y, cell, color);
        }
      }
    }
    if (active != null) {
      final Color color = tetrominoColors[active.type]!;
      for (final TCell c in active.absoluteCells()) {
        if (c.y >= 0) {
          _paintCell(canvas, ox, oy, c.x, c.y, cell, color);
        }
      }
    }

    if (_lockFlashes.isNotEmpty) {
      for (final _LockFlash f in _lockFlashes) {
        final double a = (f.life / _LockFlash.maxLife).clamp(0, 1).toDouble();
        final Rect r = Rect.fromLTWH(
          ox + (f.x * cell) + (cell * 0.06),
          oy + (f.y * cell) + (cell * 0.06),
          cell - (cell * 0.12),
          cell - (cell * 0.12),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(cell * 0.18)),
          Paint()..color = Colors.white.withValues(alpha: a * 0.75),
        );
      }
    }

    final int topRow = _topOccupiedRow(engine);
    const int dangerRows = 4;
    if (topRow < dangerRows) {
      final double intensity = (dangerRows - topRow) / dangerRows;
      final double pulse = 0.55 + (0.45 * math.sin(_clock * 6));
      final double a = (intensity * 0.5 * pulse).clamp(0, 0.6).toDouble();
      final Rect dRect =
          Rect.fromLTWH(ox, oy, boardW, cell * dangerRows.toDouble());
      canvas.drawRect(
        dRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color.fromRGBO(255, 80, 110, a),
              const Color(0x00FF506E),
            ],
          ).createShader(dRect),
      );
    }

    if (_flash > 0) {
      final double alpha =
          (_flash * (0.1 + (_flashStrength * 0.05))).clamp(0, 0.55).toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(ox, oy, boardW, boardH),
          const Radius.circular(14),
        ),
        Paint()..color = Color.fromRGBO(150, 224, 255, alpha),
      );
    }

    canvas.restore();

    _burst.render(canvas);
    _renderScorePop(canvas, ox, oy, boardW, boardH);
    _renderPulse(canvas, ox, oy, boardW, boardH);
  }

  void _renderScorePop(
    Canvas canvas,
    double ox,
    double oy,
    double boardW,
    double boardH,
  ) {
    final String? text = _scorePopText;
    if (text == null) {
      return;
    }
    final double t = (_scorePopElapsed / 0.9).clamp(0, 1).toDouble();
    final double opacity = (1 - t).clamp(0, 1).toDouble();
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Color.fromRGBO(214, 255, 224, opacity),
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          shadows: <Shadow>[
            Shadow(
              color: Color.fromRGBO(95, 224, 138, opacity * 0.9),
              blurRadius: 14,
            ),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: boardW);
    painter.paint(
      canvas,
      Offset(
        ox + ((boardW - painter.width) / 2),
        oy + (boardH * 0.5) - (t * 46),
      ),
    );
  }

  void _renderPulse(
    Canvas canvas,
    double ox,
    double oy,
    double boardW,
    double boardH,
  ) {
    final String? text = _pulseText;
    if (text == null) {
      return;
    }
    final double t = (_pulseElapsed / 1.1).clamp(0, 1).toDouble();
    final double opacity = (1 - t).clamp(0, 1).toDouble();
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Color.fromRGBO(196, 240, 255, opacity),
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          shadows: <Shadow>[
            Shadow(
              color: Color.fromRGBO(86, 212, 255, opacity * 0.9),
              blurRadius: 18,
            ),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: boardW);
    painter.paint(
      canvas,
      Offset(
        ox + ((boardW - painter.width) / 2),
        oy + (boardH * 0.34) - (t * 22),
      ),
    );
  }

  int _topOccupiedRow(TetrisEngine engine) {
    for (int y = 0; y < engine.board.height; y++) {
      for (int x = 0; x < engine.board.width; x++) {
        if (engine.board.cellAt(x, y) != null) {
          return y;
        }
      }
    }
    return engine.board.height;
  }

  void _renderBackground(
    Canvas canvas,
    double ox,
    double oy,
    double boardW,
    double boardH,
    double cell,
    int cols,
    int rows,
  ) {
    final double ratio = boardWellPixelRatio();
    if (_bgImage == null ||
        _bgW != boardW ||
        _bgH != boardH ||
        _bgCell != cell ||
        _bgCols != cols ||
        _bgRows != rows ||
        _bgRatio != ratio) {
      _bgImage?.dispose();
      _bgImage = rasterizeBoardWell(
        width: boardW,
        height: boardH,
        cell: cell,
        cols: cols,
        rows: rows,
        devicePixelRatio: ratio,
        cornerRadius: 14,
        // Quiet. Match-3 fills every cell, so a full-strength socket frames the
        // gem in it; Tetris is mostly empty, and two hundred of them turned the
        // field into the loudest thing on screen.
        socketStrength: 0.3,
      );
      _bgW = boardW;
      _bgH = boardH;
      _bgCell = cell;
      _bgCols = cols;
      _bgRows = rows;
      _bgRatio = ratio;
    }
    canvas.save();
    canvas.translate(ox, oy);
    drawBoardWellImage(
      canvas,
      _bgImage!,
      width: boardW,
      height: boardH,
    );
    canvas.restore();
  }

  /// One locked or falling mino.
  ///
  /// [beats] is non-null only while this cell's row is clearing, and it carries
  /// the whole sequence: ignite, hold, collapse.
  void _paintCell(
    Canvas canvas,
    double ox,
    double oy,
    int x,
    int y,
    double cell,
    Color color, {
    _ClearBeats? beats,
  }) {
    final double inset = cell * 0.075;
    Rect rect = Rect.fromLTWH(
      ox + (x * cell) + inset,
      oy + (y * cell) + inset,
      cell - (inset * 2),
      cell - (inset * 2),
    );

    if (beats != null) {
      // The row squashes shut about its own centre rather than blinking out.
      final double midY = rect.center.dy;
      final double h = rect.height * beats.squash;
      if (h <= 0.5) {
        return;
      }
      rect = Rect.fromLTWH(rect.left, midY - (h / 2), rect.width, h);
    }

    final Path path = roundedSquarePath(rect, cell * 0.2);

    // The same glass the gems are cut from. Tetris used to paint a three-pass
    // block of its own - body, sheen, edge - and next to Match-3 it read as a
    // different game by a different hand.
    paintGlassFacet(
      canvas,
      path: path,
      bounds: rect,
      tint: color,
      unit: cell,
      opacity: beats?.alpha ?? 1,
      // A clearing row charges up before it goes: the bloom is what makes the
      // clear an event rather than a disappearance.
      glow: beats?.ignite ?? 0,
    );

    if (beats != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
              .withValues(alpha: beats.whiteness.clamp(0, 1).toDouble()),
      );
    }
  }

  /// The landing footprint of the active piece.
  ///
  /// It used to be a single dim outline, which on a dark board was nearly
  /// invisible - and the ghost is the primary aiming aid in the game, not
  /// decoration. It is now a filled translucent piece under a bright rim, so it
  /// reads as the same shape waiting in place.
  void _paintGhost(
    Canvas canvas,
    double ox,
    double oy,
    int x,
    int y,
    double cell,
    Color color,
  ) {
    final double inset = cell * 0.09;
    final Rect rect = Rect.fromLTWH(
      ox + (x * cell) + inset,
      oy + (y * cell) + inset,
      cell - (inset * 2),
      cell - (inset * 2),
    );
    final Path path = roundedSquarePath(rect, cell * 0.18);

    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.16));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, cell * 0.055)
        ..color = color.withValues(alpha: 0.6),
    );
  }

  /// The column the active piece will fall down, tinted from the piece to its
  /// landing place.
  ///
  /// This is the cheapest readability win in the game: the eye can follow the
  /// path instead of comparing two positions twenty rows apart, and on a fast
  /// level that is the difference between aiming and guessing.
  void _paintDropShaft(
    Canvas canvas,
    double ox,
    double oy,
    double cell,
    Color color,
    FallingPiece active,
    FallingPiece ghost,
  ) {
    final Map<int, int> topByColumn = <int, int>{};
    for (final TCell c in active.absoluteCells()) {
      final int existing = topByColumn[c.x] ?? 1 << 30;
      if (c.y < existing) {
        topByColumn[c.x] = c.y;
      }
    }
    final Map<int, int> bottomByColumn = <int, int>{};
    for (final TCell c in ghost.absoluteCells()) {
      final int existing = bottomByColumn[c.x] ?? -1;
      if (c.y > existing) {
        bottomByColumn[c.x] = c.y;
      }
    }

    for (final MapEntry<int, int> entry in topByColumn.entries) {
      final int bottom = bottomByColumn[entry.key] ?? entry.value;
      final double top = oy + (math.max(entry.value, 0) * cell);
      final double end = oy + ((bottom + 1) * cell);
      if (end - top <= cell) {
        continue;
      }
      final Rect shaft = Rect.fromLTWH(
        ox + (entry.key * cell) + (cell * 0.22),
        top,
        cell - (cell * 0.44),
        end - top,
      );
      canvas.drawRect(
        shaft,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              color.withValues(alpha: 0.02),
              color.withValues(alpha: 0.13),
            ],
          ).createShader(shaft),
      );
    }
  }
}

class _LockFlash {
  _LockFlash(this.x, this.y) : life = maxLife;

  static const double maxLife = 0.16;
  final int x;
  final int y;
  double life;
}

/// The three beats a clearing row plays out, derived from the engine's
/// 0..1 clear progress.
///
/// A line clear used to be a linear fade to white over 120ms, which read as the
/// row briefly glitching. The same event staged in three beats - ignite, hold,
/// collapse - reads as something happening *to* the row, and the hold is what
/// gives the eye time to see it. This is the whole reason the clear delay went
/// up: the extra time is spent on a beat, not on a longer fade.
class _ClearBeats {
  _ClearBeats(double progress)
      : ignite = (progress / _igniteEnd).clamp(0, 1).toDouble(),
        collapse =
            ((progress - _holdEnd) / (1 - _holdEnd)).clamp(0, 1).toDouble(),
        hold = progress >= _igniteEnd && progress < _holdEnd
            ? ((progress - _igniteEnd) / (_holdEnd - _igniteEnd))
                .clamp(0, 1)
                .toDouble()
            : (progress < _igniteEnd ? 0 : 1);

  static const double _igniteEnd = 0.26;
  static const double _holdEnd = 0.58;

  /// 0 -> 1 as the row goes white-hot.
  final double ignite;

  /// 0 -> 1 across the burn, used to sweep a light bar along the row.
  final double hold;

  /// 0 -> 1 as the row squashes shut and drains.
  final double collapse;

  /// Vertical scale of the row about its own centre: 1 while it burns, 0 when
  /// it is gone. Eased in, so the collapse accelerates like a thing falling.
  double get squash => 1 - (collapse * collapse);

  double get whiteness => ignite * (1 - (collapse * 0.55));

  double get alpha => 1 - (collapse * collapse * collapse);
}
