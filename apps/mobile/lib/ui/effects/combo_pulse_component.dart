import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show FontWeight, Shadow, TextDirection, TextPainter, TextSpan, TextStyle;
import 'easing_presets.dart';

/// Bouncing praise text component shown in the HUD during combo streaks.
///
/// Refactored to eliminate per-frame TextPaint/TextStyle allocations.
class ComboPulseComponent extends PositionComponent {
  ComboPulseComponent({
    required this.text,
    required this.startPosition,
    this.duration = 0.85,
    Color? color,
  }) : color = color ?? const Color.fromRGBO(188, 236, 255, 1.0) {
    priority = 210;
    _initTextPainter();
  }

  final String text;
  final Vector2 startPosition;
  final double duration;
  final Color color;
  double _elapsed = 0;

  late final TextPainter _painter;
  late final double _halfWidth;
  late final double _halfHeight;
  final Paint _textPaint = Paint();

  void _initTextPainter() {
    _textPaint.color = color;
    _painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w800,
          foreground: _textPaint,
          shadows: const <Shadow>[
            Shadow(
              color: Color.fromRGBO(86, 202, 255, 0.9),
              blurRadius: 12,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _halfWidth = _painter.width / 2;
    _halfHeight = _painter.height / 2;
  }

  bool get isFinished => _elapsed >= duration;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double t = (_elapsed / duration).clamp(0.0, 1.0);
    final double opacity;
    if (t < 0.12) {
      opacity = (t / 0.12).clamp(0.0, 1.0);
    } else if (t < 0.76) {
      opacity = 1.0;
    } else {
      opacity = ((1.0 - t) / 0.24).clamp(0.0, 1.0);
    }

    final double progress = EasingPresets.evaluateScorePopupProgress(t);
    final double yOffset = progress * 26.0;
    final double scale = 1.0 - (t * 0.12);

    _textPaint.color = color.withValues(alpha: opacity);

    canvas.save();
    canvas.translate(startPosition.x, startPosition.y - yOffset);
    if (scale != 1.0) {
      canvas.scale(scale, scale);
    }
    _painter.paint(canvas, Offset(-_halfWidth, -_halfHeight));
    canvas.restore();
  }
}
