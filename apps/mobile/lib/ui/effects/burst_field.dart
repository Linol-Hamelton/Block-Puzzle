import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Reusable particle-burst system for game juice: spawn short-lived colored
/// particles, advance with [update], and draw with [render]. Adopted by Tetris;
/// designed to be shared with Classic as the games converge on one engine
/// (see docs/architecture/04_MULTI_GAME_ENGINE_PLAN.md).
class BurstField {
  BurstField({math.Random? random, this.maxParticles = 320})
      : _rng = random ?? math.Random();

  final math.Random _rng;
  final int maxParticles;
  final List<_BurstParticle> _particles = <_BurstParticle>[];

  bool get isEmpty => _particles.isEmpty;

  /// Spawns [count] particles flying outward (and slightly up) from (x, y).
  void spawnBurst({
    required double x,
    required double y,
    required Color color,
    int count = 2,
    double sizeBase = 4,
    double sizeJitter = 3,
    double speedMin = 40,
    double speedJitter = 95,
  }) {
    for (int i = 0; i < count; i++) {
      final double angle = _rng.nextDouble() * math.pi * 2;
      final double speed = speedMin + (_rng.nextDouble() * speedJitter);
      _particles.add(
        _BurstParticle(
          x: x,
          y: y,
          vx: math.cos(angle) * speed,
          vy: (math.sin(angle) * speed) - 45,
          color: color,
          maxLife: 0.5 + (_rng.nextDouble() * 0.35),
          size: sizeBase + (_rng.nextDouble() * sizeJitter),
        ),
      );
    }
    if (_particles.length > maxParticles) {
      _particles.removeRange(0, _particles.length - maxParticles);
    }
  }

  void update(double dt, {double gravity = 360}) {
    if (_particles.isEmpty) {
      return;
    }
    for (final _BurstParticle p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += gravity * dt;
      p.life -= dt;
    }
    _particles.removeWhere((_BurstParticle p) => p.life <= 0);
  }

  void render(Canvas canvas) {
    if (_particles.isEmpty) {
      return;
    }
    for (final _BurstParticle p in _particles) {
      final double a = (p.life / p.maxLife).clamp(0, 1).toDouble();
      final Paint paint = Paint()
        ..color = p.color.withValues(alpha: a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawCircle(Offset(p.x, p.y), p.size * (0.4 + (0.6 * a)), paint);
    }
  }
}

class _BurstParticle {
  _BurstParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.maxLife,
    required this.size,
  }) : life = maxLife;

  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double maxLife;
  final Color color;
  final double size;
}
