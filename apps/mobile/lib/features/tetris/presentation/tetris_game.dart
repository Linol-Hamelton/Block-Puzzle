import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../domain/tetris/falling_piece.dart';
import '../../../domain/tetris/tetris_engine.dart';
import '../../../domain/tetris/tetromino.dart';
import '../../../ui/effects/burst_field.dart';
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

  // Cached static board background (gradient + grid + border), recorded at a
  // local origin and re-recorded only when the board geometry changes. Avoids
  // rebuilding gradient shaders and drawing every grid line each frame.
  ui.Picture? _bgPicture;
  double _bgW = -1;
  double _bgH = -1;
  double _bgCell = -1;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    controller.onVisualEvent = _onVisualEvent;
    await super.onLoad();
  }

  @override
  void onRemove() {
    _bgPicture?.dispose();
    _bgPicture = null;
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
        if (event.value >= 4) {
          _shake = math.max(_shake, 1);
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
    final double clearHi = engine.clearProgress;

    final double sx = _shake > 0 ? math.sin(_shake * 53) * _shake * 7 : 0;
    final double sy = _shake > 0 ? math.cos(_shake * 61) * _shake * 7 : 0;
    canvas.save();
    canvas.translate(sx, sy);

    _renderBackground(canvas, ox, oy, boardW, boardH, cell, cols, rows);

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final TetrominoType? type = engine.board.cellAt(x, y);
        if (type != null) {
          _paintCell(
            canvas,
            ox,
            oy,
            x,
            y,
            cell,
            tetrominoColors[type]!,
            highlight: clearing.contains(y) ? clearHi : 0,
          );
        }
      }
    }

    final FallingPiece? active = engine.active;
    final FallingPiece? ghost = engine.ghost;
    if (ghost != null && active != null) {
      final Color color = tetrominoColors[active.type]!;
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
    if (_bgPicture == null ||
        _bgW != boardW ||
        _bgH != boardH ||
        _bgCell != cell) {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      _paintBackground(Canvas(recorder), boardW, boardH, cell, cols, rows);
      _bgPicture?.dispose();
      _bgPicture = recorder.endRecording();
      _bgW = boardW;
      _bgH = boardH;
      _bgCell = cell;
    }
    canvas.save();
    canvas.translate(ox, oy);
    canvas.drawPicture(_bgPicture!);
    canvas.restore();
  }

  /// Paints the static board chrome at a local (0,0) origin (the caller
  /// translates). Kept separate so it can be recorded into a cached [ui.Picture].
  void _paintBackground(
    Canvas canvas,
    double boardW,
    double boardH,
    double cell,
    int cols,
    int rows,
  ) {
    final Rect rect = Rect.fromLTWH(0, 0, boardW, boardH);
    final RRect rr = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    final Paint bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF0C1B37), Color(0xFF0A1326)],
      ).createShader(rect);
    canvas.drawRRect(rr, bg);

    final Paint grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x2278B5DE);
    for (int x = 1; x < cols; x++) {
      final double gx = x * cell;
      canvas.drawLine(Offset(gx, 0), Offset(gx, boardH), grid);
    }
    for (int y = 1; y < rows; y++) {
      final double gy = y * cell;
      canvas.drawLine(Offset(0, gy), Offset(boardW, gy), grid);
    }

    final Paint border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0x99B6E6FF);
    canvas.drawRRect(rr, border);
  }

  void _paintCell(
    Canvas canvas,
    double ox,
    double oy,
    int x,
    int y,
    double cell,
    Color color, {
    double highlight = 0,
  }) {
    final double inset = cell * 0.06;
    final Rect rect = Rect.fromLTWH(
      ox + (x * cell) + inset,
      oy + (y * cell) + inset,
      cell - (inset * 2),
      cell - (inset * 2),
    );
    final RRect rr = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cell * 0.18),
    );

    final Color light = Color.lerp(color, Colors.white, 0.36) ?? color;
    final Color dark = Color.lerp(color, const Color(0xFF0A1222), 0.4) ?? color;

    final Paint body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[light, color, dark],
        stops: const <double>[0, 0.5, 1],
      ).createShader(rect);
    canvas.drawRRect(rr, body);

    final Paint sheen = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0x59FFFFFF), Color(0x00FFFFFF)],
        stops: <double>[0, 0.55],
      ).createShader(rect);
    canvas.drawRRect(rr, sheen);

    final Paint edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Color.lerp(color, Colors.white, 0.5) ?? color;
    canvas.drawRRect(rr, edge);

    if (highlight > 0) {
      canvas.drawRRect(
        rr,
        Paint()
          ..color = Colors.white
              .withValues(alpha: (highlight * 0.85).clamp(0, 1).toDouble()),
      );
    }
  }

  void _paintGhost(
    Canvas canvas,
    double ox,
    double oy,
    int x,
    int y,
    double cell,
    Color color,
  ) {
    final double inset = cell * 0.1;
    final Rect rect = Rect.fromLTWH(
      ox + (x * cell) + inset,
      oy + (y * cell) + inset,
      cell - (inset * 2),
      cell - (inset * 2),
    );
    final RRect rr = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cell * 0.16),
    );
    final Paint outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, cell * 0.06)
      ..color = Color.lerp(color, const Color(0x00101A30), 0.55) ?? color;
    canvas.drawRRect(rr, outline);
  }
}

class _LockFlash {
  _LockFlash(this.x, this.y) : life = maxLife;

  static const double maxLife = 0.16;
  final int x;
  final int y;
  double life;
}
