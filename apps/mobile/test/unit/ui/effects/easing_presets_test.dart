import 'package:block_puzzle_mobile/ui/effects/easing_presets.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EasingPresets - Standardized Curves & Controllers', () {
    test('curves match design specifications', () {
      expect(EasingPresets.pieceDropCurve, equals(Curves.easeOutQuint));
      expect(EasingPresets.scorePopupCurve, equals(Curves.easeOutBack));
      expect(EasingPresets.rackSpawnCurve, equals(Curves.elasticOut));
      expect(EasingPresets.cascadeDropCurve, equals(Curves.easeOutQuad));
      expect(EasingPresets.squashCurve, equals(Curves.easeOutBack));
    });

    test('durations are properly configured', () {
      expect(EasingPresets.durationDrop, 0.20);
      expect(EasingPresets.durationScorePopup, 0.85);
      expect(EasingPresets.durationRackSpawn, 0.35);
      expect(EasingPresets.durationCascadeStep, 0.18);
      expect(EasingPresets.staggerDelayStep, 0.04);
    });

    test('dropController creates EffectController with correct curve and duration', () {
      final EffectController controller = EasingPresets.dropController();
      expect(controller.duration, 0.20);
    });

    test('scorePopupController creates EffectController with overshoot curve', () {
      final EffectController controller = EasingPresets.scorePopupController();
      expect(controller.duration, 0.85);
    });

    test('staggerController scales startDelay linearly with step index', () {
      final EffectController c3 = EasingPresets.staggerController(index: 3, duration: 0.20);

      // index 3 * 0.04s = 0.12s start delay
      // At dt = 0.05s (< 0.12s delay), progress should remain 0
      c3.advance(0.05);
      expect(c3.progress, 0.0);

      // Advance past delay (0.05 + 0.10 = 0.15s > 0.12s delay)
      c3.advance(0.10);
      expect(c3.progress, greaterThan(0.0));
    });

    test('evaluateScorePopupProgress produces expected easeOutBack overshoot', () {
      expect(EasingPresets.evaluateScorePopupProgress(0.0), 0.0);
      expect(EasingPresets.evaluateScorePopupProgress(1.0), 1.0);

      // easeOutBack overshoots 1.0 during its deceleration arc
      final double mid = EasingPresets.evaluateScorePopupProgress(0.6);
      expect(mid, greaterThan(1.0));

      // Clamps outside 0..1
      expect(EasingPresets.evaluateScorePopupProgress(-0.5), 0.0);
      expect(EasingPresets.evaluateScorePopupProgress(1.5), 1.0);
    });

    test('evaluatePieceDropProgress exhibits rapid quintic deceleration', () {
      expect(EasingPresets.evaluatePieceDropProgress(0.0), 0.0);
      expect(EasingPresets.evaluatePieceDropProgress(1.0), 1.0);

      // easeOutQuint covers the majority of distance in the first 25% of time
      final double quarterProgress = EasingPresets.evaluatePieceDropProgress(0.25);
      expect(quarterProgress, greaterThan(0.70));
    });
  });
}
