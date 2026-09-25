import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'effect_timing.dart';

/// Lightweight vector shockwave ring expanding from centroid, clipped to board.
/// Implements DEC-0024 step 6 (no fragment shaders, no fullscreen blur, no saveLayer).
class ShockwaveRingComponent extends Component {
  ShockwaveRingComponent({
    required this.center,
    required this.boardRect,
    Color? color,
    this.maxRadius = 140.0,
    this.duration = 0.8 * kEffectTimeScale,
  }) : color = color ?? const Color(0xFF64D2FF) {
    priority = 210;
  }

  final Vector2 center;
  final Rect boardRect;
  final Color color;
  final double maxRadius;
  final double duration;

  double _elapsed = 0;
  bool get isFinished => _elapsed >= duration;

  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;

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
    final double progress = 1.0 - math.pow(1.0 - t, 2.0).toDouble();
    final double radius = progress * maxRadius;
    final double opacity = (1.0 - t).clamp(0.0, 1.0);
    final double strokeWidth = (3.5 * (1.0 - t)).clamp(0.5, 3.5);

    _paint.strokeWidth = strokeWidth;
    _paint.color = color.withValues(alpha: opacity * 0.7);

    canvas.save();
    canvas.clipRect(boardRect, doAntiAlias: false);
    canvas.drawCircle(Offset(center.x, center.y), radius, _paint);
    canvas.restore();
  }
}
