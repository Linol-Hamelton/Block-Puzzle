import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/diagnostics/step6_benchmark.dart';
import 'easing_presets.dart';

/// Celebration event types recognized by the celebration VFX system.
enum CelebrationType {
  /// Daily Challenge completion with streak and star awards.
  dailyChallengeVictory,

  /// New all-time or session high score record.
  newRecord,

  /// Full-board or multi-line All Clear milestone.
  allClear,
}

/// Pluggable abstraction for victory and milestone celebrations.
///
/// Implements Stage 5 of the Flame VFX Juice system (docs/design/02_VFX_JUICE_RESEARCH_PLAN.md).
/// Allows switching between bundled procedural vector rendering and
/// dynamic vector runtime adapters (such as Rive).
abstract class CelebrationProvider {
  /// Unique identifier of the provider.
  String get name;

  /// Whether the provider runtime and assets are loaded and ready.
  bool get isReady;

  /// Builds a celebratory widget presenting the milestone.
  Widget buildCelebrationWidget({
    required BuildContext context,
    required CelebrationType type,
    int? score,
    int? stars,
    VoidCallback? onComplete,
    double size = 140.0,
  });

  /// Triggers corresponding acoustic or haptic feedback.
  void playSoundOrHaptic(CelebrationType type);
}

/// Out-of-the-box celebration provider using procedural Flutter Canvas graphics.
///
/// Features:
/// - 0 MB APK binary overhead (no native C++ runtime).
/// - 0 ms cold-start delay.
/// - Elastic badge entrance via [EasingPresets.rackSpawnCurve].
/// - Radiant starburst background with sweeping rays.
/// - Golden sparkle particles.
/// - Full compliance with Reduced Motion (disables rotation and bounce).
/// - 100% headless test runner compatible.
class ProceduralCelebrationProvider implements CelebrationProvider {
  ProceduralCelebrationProvider({
    this.isReducedMotion,
  });

  /// Custom motion preference callback. Defaults to [Step6Benchmark.reducedMotion.value].
  final bool Function()? isReducedMotion;

  @override
  String get name => 'procedural';

  @override
  bool get isReady => true;

  bool _checkReducedMotion(BuildContext context) {
    if (isReducedMotion?.call() ?? Step6Benchmark.reducedMotion.value) {
      return true;
    }
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  Widget buildCelebrationWidget({
    required BuildContext context,
    required CelebrationType type,
    int? score,
    int? stars,
    VoidCallback? onComplete,
    double size = 140.0,
  }) {
    final bool reduced = _checkReducedMotion(context);
    return _ProceduralCelebrationWidget(
      type: type,
      score: score,
      stars: stars,
      size: size,
      reducedMotion: reduced,
      onComplete: onComplete,
    );
  }

  @override
  void playSoundOrHaptic(CelebrationType type) {
    switch (type) {
      case CelebrationType.newRecord:
        HapticFeedback.heavyImpact();
      case CelebrationType.dailyChallengeVictory:
        HapticFeedback.mediumImpact();
      case CelebrationType.allClear:
        HapticFeedback.selectionClick();
    }
  }
}

/// Rive state machine contract adapter for future dynamic cosmetic asset packs (Stage C).
///
/// Implements the Stage 5 evaluation specification (docs/design/03_RIVE_RUNTIME_SPIKE_EVALUATION.md).
/// Provides strongly-typed state machine input mappings and falls back seamlessly
/// to [fallbackProvider] if assets or native runtimes are absent.
class RiveCelebrationAdapter implements CelebrationProvider {
  RiveCelebrationAdapter({
    this.assetPaths = const <CelebrationType, String>{
      CelebrationType.dailyChallengeVictory: 'assets/rive/daily_victory.riv',
      CelebrationType.newRecord: 'assets/rive/new_record.riv',
      CelebrationType.allClear: 'assets/rive/all_clear.riv',
    },
    CelebrationProvider? fallbackProvider,
  }) : fallbackProvider = fallbackProvider ?? ProceduralCelebrationProvider();

  // State machine input constants matching Rive editor contract.
  static const String stateMachineName = 'CelebrationController';
  static const String inputIsWin = 'isWin';
  static const String inputScore = 'score';
  static const String inputStars = 'stars';
  static const String inputTriggerCelebration = 'triggerCelebration';
  static const String inputReducedMotion = 'reducedMotion';

  /// File paths for .riv celebration artboards.
  final Map<CelebrationType, String> assetPaths;

  /// Fallback provider utilized when native runtime is unlinked or asset is missing.
  final CelebrationProvider fallbackProvider;

  /// Audit record of inputs applied to the state machine (useful for validation & tests).
  final Map<String, Object?> lastAppliedInputs = <String, Object?>{};

  @override
  String get name => 'rive_adapter';

  @override
  bool get isReady => fallbackProvider.isReady;

  /// Computes and applies state machine inputs according to contract.
  Map<String, Object?> computeStateMachineInputs({
    required CelebrationType type,
    int? score,
    int? stars,
    bool reducedMotion = false,
  }) {
    final Map<String, Object?> inputs = <String, Object?>{
      inputIsWin: true,
      inputScore: (score ?? 0).toDouble(),
      inputStars: (stars ?? 3).toDouble(),
      inputTriggerCelebration: true,
      inputReducedMotion: reducedMotion,
    };
    lastAppliedInputs
      ..clear()
      ..addAll(inputs);
    return inputs;
  }

  @override
  Widget buildCelebrationWidget({
    required BuildContext context,
    required CelebrationType type,
    int? score,
    int? stars,
    VoidCallback? onComplete,
    double size = 140.0,
  }) {
    final bool reduced = (fallbackProvider is ProceduralCelebrationProvider)
        ? (fallbackProvider as ProceduralCelebrationProvider)._checkReducedMotion(context)
        : (MediaQuery.maybeOf(context)?.disableAnimations ?? false);

    // Apply contract inputs
    computeStateMachineInputs(
      type: type,
      score: score,
      stars: stars,
      reducedMotion: reduced,
    );

    // Render through fallback provider (ensures zero native build breaks in CI)
    return fallbackProvider.buildCelebrationWidget(
      context: context,
      type: type,
      score: score,
      stars: stars,
      onComplete: onComplete,
      size: size,
    );
  }

  @override
  void playSoundOrHaptic(CelebrationType type) {
    fallbackProvider.playSoundOrHaptic(type);
  }
}

/// Central director coordinating celebratory rewards across the game.
class CelebrationDirector {
  CelebrationDirector({
    CelebrationProvider? initialProvider,
  }) : activeProvider = initialProvider ?? ProceduralCelebrationProvider();

  /// Shared singleton instance.
  static final CelebrationDirector instance = CelebrationDirector();

  /// Active celebration provider.
  CelebrationProvider activeProvider;

  /// Convenience method to build a celebration badge.
  Widget buildBadge({
    required BuildContext context,
    required CelebrationType type,
    int? score,
    int? stars,
    double size = 140.0,
    VoidCallback? onComplete,
  }) {
    return activeProvider.buildCelebrationWidget(
      context: context,
      type: type,
      score: score,
      stars: stars,
      onComplete: onComplete,
      size: size,
    );
  }

  /// Plays associated sound or haptic feedback.
  void celebrate(CelebrationType type) {
    activeProvider.playSoundOrHaptic(type);
  }
}

/// Stateful procedural celebration widget with entrance bounce and sweeping rays.
class _ProceduralCelebrationWidget extends StatefulWidget {
  const _ProceduralCelebrationWidget({
    required this.type,
    required this.size,
    required this.reducedMotion,
    this.score,
    this.stars,
    this.onComplete,
  });

  final CelebrationType type;
  final int? score;
  final int? stars;
  final double size;
  final bool reducedMotion;
  final VoidCallback? onComplete;

  @override
  State<_ProceduralCelebrationWidget> createState() => _ProceduralCelebrationWidgetState();
}

class _ProceduralCelebrationWidgetState extends State<_ProceduralCelebrationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.70, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: -0.35 * math.pi,
      end: 0.15 * math.pi,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    if (widget.reducedMotion) {
      _controller.value = 1.0;
      widget.onComplete?.call();
    } else {
      _controller.forward().then((_) {
        if (mounted) {
          widget.onComplete?.call();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ProceduralCelebrationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion != oldWidget.reducedMotion) {
      if (widget.reducedMotion) {
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;

    return Semantics(
      label: _semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double scale = widget.reducedMotion ? 1.0 : _scaleAnimation.value;
            final double opacity = widget.reducedMotion ? 1.0 : _opacityAnimation.value.clamp(0.0, 1.0);
            final double rotation = widget.reducedMotion ? 0.0 : _rotationAnimation.value;

            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _CelebrationPainter(
                    type: widget.type,
                    rotation: rotation,
                    reducedMotion: widget.reducedMotion,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String get _semanticLabel {
    switch (widget.type) {
      case CelebrationType.newRecord:
        return 'New Record Celebration Trophy';
      case CelebrationType.dailyChallengeVictory:
        return 'Daily Challenge Victory Medal';
      case CelebrationType.allClear:
        return 'All Clear Celebration Diamond';
    }
  }
}

/// Custom painter rendering radiant starburst rays and vector celebration badges.
class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter({
    required this.type,
    required this.rotation,
    required this.reducedMotion,
  });

  final CelebrationType type;
  final double rotation;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    _paintStarburst(canvas, center, radius);

    switch (type) {
      case CelebrationType.newRecord:
        _paintTrophyBadge(canvas, center, radius * 0.58);
      case CelebrationType.dailyChallengeVictory:
        _paintDailyMedal(canvas, center, radius * 0.58);
      case CelebrationType.allClear:
        _paintDiamondStar(canvas, center, radius * 0.58);
    }

    if (!reducedMotion) {
      _paintSparkles(canvas, center, radius);
    }
  }

  void _paintStarburst(Canvas canvas, Offset center, double radius) {
    const int rayCount = 14;
    final Paint rayPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    Color rayBaseColor;
    switch (type) {
      case CelebrationType.newRecord:
        rayBaseColor = const Color(0xFFFFD54F);
      case CelebrationType.dailyChallengeVictory:
        rayBaseColor = const Color(0xFF81D4FA);
      case CelebrationType.allClear:
        rayBaseColor = const Color(0xFFB388FF);
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    for (int i = 0; i < rayCount; i++) {
      final double angle = (i * 2 * math.pi) / rayCount;
      final double nextAngle = angle + (math.pi / rayCount) * 0.55;

      final Path rayPath = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(angle) * radius, math.sin(angle) * radius)
        ..lineTo(math.cos(nextAngle) * radius, math.sin(nextAngle) * radius)
        ..close();

      final double alpha = (i % 2 == 0) ? 0.22 : 0.10;
      rayPaint.color = rayBaseColor.withValues(alpha: alpha);
      canvas.drawPath(rayPath, rayPaint);
    }

    canvas.restore();
  }

  void _paintTrophyBadge(Canvas canvas, Offset center, double r) {
    // Pedestal base
    final Paint basePaint = Paint()
      ..color = const Color(0xFFD4A017)
      ..style = PaintingStyle.fill;
    final Rect baseRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + r * 0.72),
      width: r * 0.85,
      height: r * 0.22,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(4)), basePaint);

    // Stem
    final Paint stemPaint = Paint()
      ..color = const Color(0xFFFFDF00)
      ..style = PaintingStyle.fill;
    final Rect stemRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + r * 0.45),
      width: r * 0.25,
      height: r * 0.38,
    );
    canvas.drawRect(stemRect, stemPaint);

    // Trophy cup body
    final Paint cupPaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFFFFEE58), Color(0xFFFFB300)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..style = PaintingStyle.fill;

    final Path cupPath = Path()
      ..moveTo(center.dx - r * 0.52, center.dy - r * 0.35)
      ..lineTo(center.dx + r * 0.52, center.dy - r * 0.35)
      ..cubicTo(
        center.dx + r * 0.48, center.dy + r * 0.35,
        center.dx - r * 0.48, center.dy + r * 0.35,
        center.dx - r * 0.52, center.dy - r * 0.35,
      )
      ..close();
    canvas.drawPath(cupPath, cupPaint);

    // Handles
    final Paint handlePaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round;

    final Path leftHandle = Path()
      ..moveTo(center.dx - r * 0.48, center.dy - r * 0.25)
      ..cubicTo(
        center.dx - r * 0.85, center.dy - r * 0.25,
        center.dx - r * 0.85, center.dy + r * 0.15,
        center.dx - r * 0.32, center.dy + r * 0.22,
      );
    canvas.drawPath(leftHandle, handlePaint);

    final Path rightHandle = Path()
      ..moveTo(center.dx + r * 0.48, center.dy - r * 0.25)
      ..cubicTo(
        center.dx + r * 0.85, center.dy - r * 0.25,
        center.dx + r * 0.85, center.dy + r * 0.15,
        center.dx + r * 0.32, center.dy + r * 0.22,
      );
    canvas.drawPath(rightHandle, handlePaint);

    // Center star emblem
    _paintStar(canvas, Offset(center.dx, center.dy - r * 0.05), r * 0.22, const Color(0xFFFFFFFF));
  }

  void _paintDailyMedal(Canvas canvas, Offset center, double r) {
    // Outer laurel / rim
    final Paint rimPaint = Paint()
      ..color = const Color(0xFFFFA000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r * 0.72, rimPaint);

    // Inner medal disk
    final Paint diskPaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFF29B6F6), Color(0xFF0288D1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.7))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r * 0.65, diskPaint);

    // Ribbon tails below
    final Paint ribbonPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;
    final Path ribbonPath = Path()
      ..moveTo(center.dx - r * 0.4, center.dy + r * 0.45)
      ..lineTo(center.dx - r * 0.6, center.dy + r * 0.95)
      ..lineTo(center.dx - r * 0.25, center.dy + r * 0.82)
      ..lineTo(center.dx, center.dy + r * 0.5)
      ..lineTo(center.dx + r * 0.25, center.dy + r * 0.82)
      ..lineTo(center.dx + r * 0.6, center.dy + r * 0.95)
      ..lineTo(center.dx + r * 0.4, center.dy + r * 0.45)
      ..close();
    canvas.drawPath(ribbonPath, ribbonPaint);

    // Star icon inside medal
    _paintStar(canvas, center, r * 0.32, const Color(0xFFFFD54F));
  }

  void _paintDiamondStar(Canvas canvas, Offset center, double r) {
    final Paint diamondPaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFFE040FB), Color(0xFF7C4DFF), Color(0xFF00E5FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..style = PaintingStyle.fill;

    final Path diamondPath = Path()
      ..moveTo(center.dx, center.dy - r * 0.85)
      ..cubicTo(center.dx + r * 0.15, center.dy - r * 0.15, center.dx + r * 0.15, center.dy - r * 0.15, center.dx + r * 0.85, center.dy)
      ..cubicTo(center.dx + r * 0.15, center.dy + r * 0.15, center.dx + r * 0.15, center.dy + r * 0.15, center.dx, center.dy + r * 0.85)
      ..cubicTo(center.dx - r * 0.15, center.dy + r * 0.15, center.dx - r * 0.15, center.dy + r * 0.15, center.dx - r * 0.85, center.dy)
      ..cubicTo(center.dx - r * 0.15, center.dy - r * 0.15, center.dx - r * 0.15, center.dy - r * 0.15, center.dx, center.dy - r * 0.85)
      ..close();
    canvas.drawPath(diamondPath, diamondPaint);

    // Inner bright glint
    final Paint glintPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r * 0.14, glintPaint);
  }

  void _paintStar(Canvas canvas, Offset center, double r, Color color) {
    final Paint starPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path starPath = Path();
    for (int i = 0; i < 5; i++) {
      final double outerAngle = -math.pi / 2 + (i * 2 * math.pi / 5);
      final double innerAngle = outerAngle + math.pi / 5;

      final double ox = center.dx + math.cos(outerAngle) * r;
      final double oy = center.dy + math.sin(outerAngle) * r;
      final double ix = center.dx + math.cos(innerAngle) * (r * 0.42);
      final double iy = center.dy + math.sin(innerAngle) * (r * 0.42);

      if (i == 0) {
        starPath.moveTo(ox, oy);
      } else {
        starPath.lineTo(ox, oy);
      }
      starPath.lineTo(ix, iy);
    }
    starPath.close();
    canvas.drawPath(starPath, starPaint);
  }

  void _paintSparkles(Canvas canvas, Offset center, double radius) {
    final Paint sparklePaint = Paint()
      ..color = const Color(0xFFFFF9C4)
      ..style = PaintingStyle.fill;

    const List<Offset> offsets = <Offset>[
      Offset(-0.68, -0.62),
      Offset(0.72, -0.55),
      Offset(-0.75, 0.48),
      Offset(0.65, 0.60),
      Offset(0.05, -0.82),
    ];

    for (final Offset off in offsets) {
      final Offset pt = Offset(center.dx + off.dx * radius, center.dy + off.dy * radius);
      canvas.drawCircle(pt, 3.0, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.rotation != rotation ||
        oldDelegate.reducedMotion != reducedMotion;
  }
}
