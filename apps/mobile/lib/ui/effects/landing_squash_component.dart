import 'dart:ui';
import 'package:flame/components.dart';
import 'easing_presets.dart';

/// Tactile landing squash-and-stretch highlight overlay when blocks snap into the board.
///
/// Springs from scaleY 0.88 to 1.0 using [EasingPresets.squashCurve] and fades out,
/// providing physical "weight" and tactile snap without modifying board state logic.
class LandingSquashComponent extends PositionComponent {
  LandingSquashComponent({
    required this.cellRects,
    required this.color,
    this.duration = 0.20,
  }) {
    priority = 208;
    _initBoundingBox();
  }

  final List<Rect> cellRects;
  final Color color;
  final double duration;

  double _elapsed = 0;
  late final Rect _bounds;
  late final Offset _center;
  final Paint _paint = Paint()..isAntiAlias = true;

  void _initBoundingBox() {
    if (cellRects.isEmpty) {
      _bounds = Rect.zero;
      _center = Offset.zero;
      return;
    }
    double l = cellRects.first.left;
    double t = cellRects.first.top;
    double r = cellRects.first.right;
    double b = cellRects.first.bottom;

    for (int i = 1; i < cellRects.length; i++) {
      final Rect rect = cellRects[i];
      if (rect.left < l) l = rect.left;
      if (rect.top < t) t = rect.top;
      if (rect.right > r) r = rect.right;
      if (rect.bottom > b) b = rect.bottom;
    }
    _bounds = Rect.fromLTRB(l, t, r, b);
    _center = _bounds.center;
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
    if (cellRects.isEmpty) {
      return;
    }

    final double t = (_elapsed / duration).clamp(0.0, 1.0);
    // Squash curve starts compressed then bounces back to 1.0
    final double progress = EasingPresets.evaluateProgress(
      t,
      EasingPresets.squashCurve,
    );
    final double scaleY = 0.88 + (0.12 * progress);
    final double scaleX = 1.08 - (0.08 * progress);
    final double alpha = (1.0 - t).clamp(0.0, 1.0) * 0.45;

    _paint.color = color.withValues(alpha: alpha);
    _paint.style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(_center.dx, _center.dy);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-_center.dx, -_center.dy);

    for (final Rect rect in cellRects) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5.0)),
        _paint,
      );
    }
    canvas.restore();
  }
}
