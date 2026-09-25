import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'effect_timing.dart';

/// Reusable particle-burst system for game juice: spawn short-lived colored
/// particles, advance with [update], and draw with [render]. Adopted by Tetris;
/// designed to be shared with Classic as the games converge on one engine
/// (see docs/architecture/04_MULTI_GAME_ENGINE_PLAN.md).
class BurstField {
  BurstField({
    math.Random? random,
    this.maxParticles = 320,
    this.timeScale = kEffectTimeScale,
  })  : assert(timeScale > 0, 'timeScale must be greater than zero'),
        _rng = random ?? math.Random();

  final math.Random _rng;
  final int maxParticles;

  /// How much slower than real time the particles move. Scaling the clock
  /// rather than the lifetime keeps the arc: the same throw, played slower.
  final double timeScale;
  final List<_BurstParticle> _particles = <_BurstParticle>[];
  final List<_BurstParticle> _pool = <_BurstParticle>[];
  static const MaskFilter _particleBlur = MaskFilter.blur(BlurStyle.normal, 1.2);
  final Paint _particlePaint = Paint()..maskFilter = _particleBlur;

  bool get isEmpty => _particles.isEmpty;
  int get pooledCount => _pool.length;
  int get activeCount => _particles.length;

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
      final double maxLife = 0.5 + (_rng.nextDouble() * 0.35);
      final double size = sizeBase + (_rng.nextDouble() * sizeJitter);
      final double vx = math.cos(angle) * speed;
      final double vy = (math.sin(angle) * speed) - 45;

      if (_pool.isNotEmpty) {
        final _BurstParticle p = _pool.removeLast();
        p.reset(
          x: x,
          y: y,
          vx: vx,
          vy: vy,
          color: color,
          maxLife: maxLife,
          size: size,
        );
        _particles.add(p);
      } else {
        _particles.add(
          _BurstParticle(
            x: x,
            y: y,
            vx: vx,
            vy: vy,
            color: color,
            maxLife: maxLife,
            size: size,
          ),
        );
      }
    }
    if (_particles.length > maxParticles) {
      final int excess = _particles.length - maxParticles;
      for (int i = 0; i < excess; i++) {
        if (_pool.length < maxParticles) {
          _pool.add(_particles[i]);
        }
      }
      _particles.removeRange(0, excess);
    }
  }

  void update(double dt, {double gravity = 360}) {
    if (_particles.isEmpty) {
      return;
    }
    final double scaled = dt / timeScale;
    for (int i = _particles.length - 1; i >= 0; i--) {
      final _BurstParticle p = _particles[i];
      p.x += p.vx * scaled;
      p.y += p.vy * scaled;
      p.vy += gravity * scaled;
      p.life -= scaled;
      if (p.life <= 0) {
        _particles.removeAt(i);
        if (_pool.length < maxParticles) {
          _pool.add(p);
        }
      }
    }
  }

  void render(Canvas canvas) {
    if (_particles.isEmpty) {
      return;
    }
    for (final _BurstParticle p in _particles) {
      final double a = (p.life / p.maxLife).clamp(0, 1).toDouble();
      _particlePaint.color = p.color.withValues(alpha: a);
      canvas.drawCircle(Offset(p.x, p.y), p.size * (0.4 + (0.6 * a)), _particlePaint);
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
  double maxLife;
  Color color;
  double size;

  void reset({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required Color color,
    required double maxLife,
    required double size,
  }) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.color = color;
    this.maxLife = maxLife;
    life = maxLife;
    this.size = size;
  }
}
