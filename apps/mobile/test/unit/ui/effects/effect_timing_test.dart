import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/features/game_loop/presentation/block_puzzle_game.dart';
import 'package:block_puzzle_mobile/ui/effects/burst_field.dart';
import 'package:block_puzzle_mobile/ui/effects/effect_timing.dart';

void main() {
  group('kEffectTimeScale', () {
    test('stays inside the three-to-five band the owner asked for', () {
      // The rule, not the number: the owner's instruction was that the clear
      // effects run three to five times slower than they were written. A later
      // edit may retune inside that band; leaving it is a decision, not a
      // tweak, and should fail here first.
      expect(kEffectTimeScale, greaterThanOrEqualTo(3.0));
      expect(kEffectTimeScale, lessThanOrEqualTo(5.0));
    });
  });

  group('BurstField time scale', () {
    test('scales the clock, so the arc is the same throw played slower', () {
      // Same particle, same throw, two clocks. After the same real time the
      // slow field must have travelled 1/timeScale of the distance - not a
      // longer life with unchanged speed, which would only rain the particle
      // off the board.
      const double dt = 1 / 60;
      const int steps = 12;

      double travelWith(double timeScale) {
        final BurstField field = BurstField(
          random: math.Random(7),
          timeScale: timeScale,
        );
        field.spawnBurst(
          x: 0,
          y: 0,
          color: const Color(0xFFFFFFFF),
          count: 1,
        );
        for (int i = 0; i < steps; i++) {
          field.update(dt);
        }
        return _onlyParticleDistance(field);
      }

      final double fast = travelWith(1);
      final double slow = travelWith(4);

      expect(fast, greaterThan(0));
      expect(slow, greaterThan(0));
      expect(slow, lessThan(fast));
      // Position is not linear in time once gravity is integrated, so this
      // checks the direction and rough magnitude rather than an exact ratio.
      expect(slow, lessThan(fast / 2));
    });

    test('a particle outlives its unscaled lifetime by the scale', () {
      const double dt = 1 / 60;
      // maxLife is 0.5..0.85 s, so one second empties an unscaled field.
      final BurstField unscaled =
          BurstField(random: math.Random(3), timeScale: 1);
      final BurstField scaled =
          BurstField(random: math.Random(3), timeScale: 4);
      for (final BurstField field in <BurstField>[unscaled, scaled]) {
        field.spawnBurst(
          x: 0,
          y: 0,
          color: const Color(0xFFFFFFFF),
          count: 4,
        );
      }

      for (int i = 0; i < 60; i++) {
        unscaled.update(dt);
        scaled.update(dt);
      }

      expect(unscaled.isEmpty, isTrue);
      expect(scaled.isEmpty, isFalse);
    });

    test('rejects a non-positive scale instead of dividing by zero', () {
      expect(() => BurstField(timeScale: 0), throwsA(isA<AssertionError>()));
    });
  });

  group('clear effects carry the scale', () {
    test('the shockwave and the score pop are scaled, not hardcoded', () {
      final ShockwaveRingComponent ring = ShockwaveRingComponent(
        center: Vector2.zero(),
        boardRect: const Rect.fromLTWH(0, 0, 100, 100),
      );
      final ScorePopComponent pop = ScorePopComponent(
        text: '+100',
        startPosition: Vector2.zero(),
      );

      expect(ring.duration, closeTo(0.8 * kEffectTimeScale, 1e-9));
      expect(pop.duration, closeTo(0.8 * kEffectTimeScale, 1e-9));
    });

    test('a scaled effect is not finished at its unscaled lifetime', () {
      final ShockwaveRingComponent ring = ShockwaveRingComponent(
        center: Vector2.zero(),
        boardRect: const Rect.fromLTWH(0, 0, 100, 100),
      );
      // 0.8 s used to be the whole life of the ring.
      for (int i = 0; i < 48; i++) {
        ring.update(1 / 60);
      }
      expect(ring.isFinished, isFalse);
    });
  });
}

double _onlyParticleDistance(BurstField field) {
  // BurstField keeps its particles private, so distance is read the way the
  // game reads them: by painting and recording where the circle landed.
  final _ProbeCanvas probe = _ProbeCanvas();
  field.render(probe);
  expect(probe.centers, hasLength(1));
  final Offset c = probe.centers.single;
  return math.sqrt((c.dx * c.dx) + (c.dy * c.dy));
}

/// Records the circles a painter draws, so a private particle list can still
/// be asserted on through the one surface it is observable from.
class _ProbeCanvas implements Canvas {
  final List<Offset> centers = <Offset>[];

  @override
  void drawCircle(Offset c, double radius, Paint paint) => centers.add(c);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
