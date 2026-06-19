import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../domain/tetris/falling_piece.dart';
import '../../../domain/tetris/tetris_engine.dart';
import '../../../domain/tetris/tetromino.dart';
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

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  void update(double dt) {
    super.update(dt);
    controller.tick(Duration(microseconds: (dt * 1000000).round()));
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

    _renderBackground(canvas, ox, oy, boardW, boardH, cell, cols, rows);

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final TetrominoType? type = engine.board.cellAt(x, y);
        if (type != null) {
          _paintCell(canvas, ox, oy, x, y, cell, tetrominoColors[type]!);
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
    final Rect rect = Rect.fromLTWH(ox, oy, boardW, boardH);
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
      final double gx = ox + (x * cell);
      canvas.drawLine(Offset(gx, oy), Offset(gx, oy + boardH), grid);
    }
    for (int y = 1; y < rows; y++) {
      final double gy = oy + (y * cell);
      canvas.drawLine(Offset(ox, gy), Offset(ox + boardW, gy), grid);
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
    Color color,
  ) {
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
