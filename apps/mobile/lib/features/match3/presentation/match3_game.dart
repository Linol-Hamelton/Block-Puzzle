import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../domain/match3/match3_engine.dart';
import '../../../domain/match3/tile.dart';
import '../../../domain/match3/tile_grid.dart';
import '../../../ui/effects/burst_field.dart';
import '../application/match3_controller.dart';

/// Gem colors (neon palette consistent with the Lumina look).
const Map<TileColor, Color> gemColors = <TileColor, Color>{
  TileColor.ruby: Color(0xFFF0566E),
  TileColor.amber: Color(0xFFF0A24E),
  TileColor.citrine: Color(0xFFF2D24E),
  TileColor.emerald: Color(0xFF5FE08A),
  TileColor.sapphire: Color(0xFF4DA6F0),
  TileColor.amethyst: Color(0xFFB672EC),
};

/// Flame view for Match-3. Renders the gem grid, the current selection, and the
/// clear/cascade juice. Input arrives from the Flutter layer (see
/// `Match3Screen`), which maps a tap/swipe to a cell and calls [onCellTapped] /
/// [onSwipe]; the view tracks the selection and asks the controller to swap.
class Match3FlameGame extends FlameGame {
  Match3FlameGame({required this.controller});

  final Match3Controller controller;

  GridPos? _selected;

  // Visual-juice state.
  double _flash = 0;
  double _shake = 0;
  String? _pulseText;
  double _pulseElapsed = 0;
  String? _scorePopText;
  double _scorePopElapsed = 0;
  double _clock = 0;
  int _lastScore = 0;
  bool _burstThisSwap = false;
  final BurstField _burst = BurstField();

  // Last board geometry (screen space).
  double _ox = 0;
  double _oy = 0;
  double _cell = 0;

  int get _cols => controller.engine.width;
  int get _rows => controller.engine.height;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    controller.onVisualEvent = _onVisualEvent;
    _lastScore = controller.score;
    await super.onLoad();
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
    _selected = null;
    controller.trySwap(from, GridPos(from.x + dx, from.y + dy));
  }

  bool _isAdjacent(GridPos a, GridPos b) =>
      ((a.x - b.x).abs() + (a.y - b.y).abs()) == 1;

  void _onVisualEvent(Match3Event event) {
    switch (event.type) {
      case Match3EventType.swap:
        _burstThisSwap = false;
        break;
      case Match3EventType.match:
        if (!_burstThisSwap) {
          _spawnClearParticles();
          _burstThisSwap = true;
          _flash = math.max(_flash, (event.value / 9).clamp(0.3, 1).toDouble());
        }
        if (event.detail >= 2) {
          _shake = math.max(_shake, 0.5);
          _pulse('COMBO x${event.detail}');
        } else if (event.value >= 5) {
          _pulse('NICE!');
        }
        break;
      case Match3EventType.invalidSwap:
        _shake = math.max(_shake, 0.25);
        break;
      case Match3EventType.shuffle:
        _pulse('SHUFFLE');
        _flash = math.max(_flash, 0.4);
        break;
      case Match3EventType.gameOver:
        _shake = math.max(_shake, 0.7);
        break;
    }
  }

  void _spawnClearParticles() {
    if (_cell <= 0) {
      return;
    }
    for (final ({GridPos pos, TileColor color}) c in controller.engine.lastCleared) {
      _burst.spawnBurst(
        x: _ox + (c.pos.x * _cell) + (_cell / 2),
        y: _oy + (c.pos.y * _cell) + (_cell / 2),
        color: gemColors[c.color]!,
        sizeBase: _cell * 0.12,
        sizeJitter: _cell * 0.1,
      );
    }
  }

  void _pulse(String text) {
    _pulseText = text;
    _pulseElapsed = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
    if (_flash > 0) {
      _flash = math.max(0, _flash - (dt * 2.6));
    }
    if (_shake > 0) {
      _shake = math.max(0, _shake - (dt * 3.4));
    }
    if (_pulseText != null) {
      _pulseElapsed += dt;
      if (_pulseElapsed > 1.0) {
        _pulseText = null;
      }
    }
    if (_scorePopText != null) {
      _scorePopElapsed += dt;
      if (_scorePopElapsed > 0.9) {
        _scorePopText = null;
      }
    }
    final int score = controller.score;
    if (score > _lastScore) {
      _scorePopText = '+${score - _lastScore}';
      _scorePopElapsed = 0;
    }
    _lastScore = score;
    _burst.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    final TileGrid grid = controller.grid;
    final double cell = math.min(size.x / _cols, size.y / _rows);
    final double boardW = cell * _cols;
    final double boardH = cell * _rows;
    final double ox = (size.x - boardW) / 2;
    final double oy = (size.y - boardH) / 2;
    _ox = ox;
    _oy = oy;
    _cell = cell;

    final double sx = _shake > 0 ? math.sin(_shake * 51) * _shake * 6 : 0;
    final double sy = _shake > 0 ? math.cos(_shake * 59) * _shake * 6 : 0;
    canvas.save();
    canvas.translate(sx, sy);

    _renderBackground(canvas, ox, oy, boardW, boardH);

    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _cols; x++) {
        final TileColor? color = grid.at(x, y);
        if (color != null) {
          _paintGem(canvas, ox, oy, x, y, cell, gemColors[color]!);
        }
      }
    }

    final GridPos? sel = _selected;
    if (sel != null) {
      _paintSelection(canvas, ox, oy, sel, cell);
    }

    if (_flash > 0) {
      final double alpha = (_flash * 0.35).clamp(0, 0.5).toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(ox, oy, boardW, boardH),
          const Radius.circular(14),
        ),
        Paint()..color = Color.fromRGBO(180, 235, 255, alpha),
      );
    }

    canvas.restore();

    _burst.render(canvas);
    _renderScorePop(canvas, ox, oy, boardW, boardH);
    _renderPulse(canvas, ox, oy, boardW, boardH);
  }

  void _renderBackground(
    Canvas canvas,
    double ox,
    double oy,
    double boardW,
    double boardH,
  ) {
    final Rect rect = Rect.fromLTWH(ox, oy, boardW, boardH);
    final RRect rr = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF101A33), Color(0xFF0B1326)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0x99B6E6FF),
    );
  }

  void _paintGem(
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
    final RRect rr = RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.28));

    final Color light = Color.lerp(color, Colors.white, 0.4) ?? color;
    final Color dark = Color.lerp(color, const Color(0xFF0A1222), 0.42) ?? color;
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[light, color, dark],
          stops: const <double>[0, 0.5, 1],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x66FFFFFF), Color(0x00FFFFFF)],
          stops: <double>[0, 0.5],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Color.lerp(color, Colors.white, 0.5) ?? color,
    );
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
          fontSize: 24,
          fontWeight: FontWeight.w800,
          shadows: <Shadow>[
            Shadow(
              color: Color.fromRGBO(95, 224, 138, opacity * 0.9),
              blurRadius: 14,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: boardW);
    painter.paint(
      canvas,
      Offset(ox + ((boardW - painter.width) / 2), oy + (boardH * 0.42) - (t * 40)),
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
    final double t = (_pulseElapsed / 1.0).clamp(0, 1).toDouble();
    final double opacity = (1 - t).clamp(0, 1).toDouble();
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Color.fromRGBO(196, 240, 255, opacity),
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          shadows: <Shadow>[
            Shadow(
              color: Color.fromRGBO(86, 212, 255, opacity * 0.9),
              blurRadius: 18,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: boardW);
    painter.paint(
      canvas,
      Offset(ox + ((boardW - painter.width) / 2), oy + (boardH * 0.32) - (t * 20)),
    );
  }
}
