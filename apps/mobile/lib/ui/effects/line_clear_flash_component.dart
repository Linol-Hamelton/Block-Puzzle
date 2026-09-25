import 'dart:ui';
import 'package:flame/components.dart';
import '../../features/diagnostics/step6_benchmark.dart';
import 'effect_timing.dart';

/// Full-board soft flash overlay on line clearance.
class LineClearFlashComponent extends PositionComponent {
  LineClearFlashComponent({
    required this.boardOrigin,
    required this.boardSize,
    required this.strength,
    this.customMotionFactor,
  }) {
    priority = 200;
  }

  final Vector2 boardOrigin;
  final Vector2 boardSize;
  final int strength;
  final double? customMotionFactor;
  static const double _duration = 0.32 * kEffectTimeScale;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double t = (_elapsed / _duration).clamp(0, 1);
    final double baseAlpha = (1 - t) * (0.22 + (strength * 0.07));
    final double motionFactor = customMotionFactor ??
        (Step6Benchmark.reducedMotion.value ? 0.25 : 1.0);
    final double alpha = (baseAlpha * motionFactor).clamp(0, 0.6);
    final Paint paint = Paint()..color = Color.fromRGBO(92, 210, 255, alpha);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          boardOrigin.x,
          boardOrigin.y,
          boardSize.x,
          boardSize.y,
        ),
        const Radius.circular(18),
      ),
      paint,
    );
  }
}
