import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

/// Centralized animation easing curves and effect controller presets for Lumina Blocks.
///
/// Implements Stage 1 of the Flame VFX Juice system (docs/design/02_VFX_JUICE_RESEARCH_PLAN.md).
/// Enforces consistent motion design language across Classic, Tetris, and Match-3.
abstract final class EasingPresets {
  // --- Standardized Motion Curves ---

  /// Rapid deceleration curve creating a sense of physical weight for dropped pieces.
  static const Curve pieceDropCurve = Curves.easeOutQuint;

  /// Overshoot curve with bounce-back for floating score numbers and banners.
  static const Curve scorePopupCurve = Curves.easeOutBack;

  /// Elastic spring curve with subtle oscillation for newly spawned rack pieces.
  static const Curve rackSpawnCurve = Curves.elasticOut;

  /// Smooth quadratic fall curve for cascading gems in Match-3.
  static const Curve cascadeDropCurve = Curves.easeOutQuad;

  /// Symmetric ease-in-out curve for pre-clear highlights and danger pulses.
  static const Curve pulseCurve = Curves.easeInOut;

  /// Snappy overshoot curve for squash-and-stretch landing impacts.
  static const Curve squashCurve = Curves.easeOutBack;

  // --- Base Durations (in seconds) ---

  /// Duration of piece drop and socket snap.
  static const double durationDrop = 0.20;

  /// Duration of floating score indicator popups.
  static const double durationScorePopup = 0.85;

  /// Duration of rack piece appearance in hand.
  static const double durationRackSpawn = 0.35;

  /// Duration of single gem fall step in Match-3 cascades.
  static const double durationCascadeStep = 0.18;

  /// Delay between staggered animations in a cascade or multi-line clear.
  static const double staggerDelayStep = 0.04;

  // --- EffectController Factory Helpers ---

  /// Controller for piece placement and grid snapping.
  static EffectController dropController({
    double duration = durationDrop,
  }) {
    return EffectController(
      duration: duration,
      curve: pieceDropCurve,
    );
  }

  /// Controller for floating score popups with overshoot.
  static EffectController scorePopupController({
    double duration = durationScorePopup,
  }) {
    return EffectController(
      duration: duration,
      curve: scorePopupCurve,
    );
  }

  /// Controller for piece appearance in the hand/rack.
  static EffectController rackSpawnController({
    double duration = durationRackSpawn,
  }) {
    return EffectController(
      duration: duration,
      curve: rackSpawnCurve,
    );
  }

  /// Staggered delay controller for chained animations (e.g. sequential clearing of cells).
  static EffectController staggerController({
    required int index,
    double stepDelay = staggerDelayStep,
    double duration = 0.20,
    Curve curve = Curves.linear,
  }) {
    return EffectController(
      duration: duration,
      startDelay: index * stepDelay,
      curve: curve,
    );
  }

  /// Evaluates progress [t] (0.0..1.0) along the score popup overshoot curve.
  static double evaluateScorePopupProgress(double t) {
    final double clamped = t.clamp(0.0, 1.0);
    return scorePopupCurve.transform(clamped);
  }

  /// Evaluates progress [t] (0.0..1.0) along the piece drop weight curve.
  static double evaluatePieceDropProgress(double t) {
    final double clamped = t.clamp(0.0, 1.0);
    return pieceDropCurve.transform(clamped);
  }

  /// Evaluates progress [t] (0.0..1.0) along an arbitrary [curve].
  static double evaluateProgress(double t, Curve curve) {
    final double clamped = t.clamp(0.0, 1.0);
    return curve.transform(clamped);
  }
}
