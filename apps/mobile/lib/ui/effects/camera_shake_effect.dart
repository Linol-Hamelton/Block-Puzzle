import 'dart:math' as math;
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'easing_presets.dart';

/// Damped harmonic camera shake effect for the Flame [Viewfinder].
///
/// Ensures the camera returns to its exact original position upon completion
/// or premature disposal, eliminating drift across rapid shake chains.
class CameraShakeEffect extends Component {
  CameraShakeEffect({
    required this.viewfinder,
    this.amplitude = 3.5,
    this.duration = 0.16,
    this.frequency = 36.0,
    this.onComplete,
  }) {
    priority = 1000;
  }

  final Viewfinder viewfinder;
  final double amplitude;
  final double duration;
  final double frequency;
  final void Function()? onComplete;

  double _elapsed = 0;
  late final Vector2 _initialPosition;
  bool _initialized = false;

  @override
  void onMount() {
    super.onMount();
    _initialPosition = viewfinder.position.clone();
    _initialized = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_initialized) {
      _initialPosition = viewfinder.position.clone();
      _initialized = true;
    }

    _elapsed += dt;
    if (_elapsed >= duration) {
      viewfinder.position = _initialPosition.clone();
      removeFromParent();
      onComplete?.call();
      return;
    }

    final double t = (_elapsed / duration).clamp(0.0, 1.0);
    // Damped exponential decay: exp(-3.2 * t) * (1 - t)
    final double decay = math.exp(-3.2 * t) * (1.0 - t);
    final double currentAmp = amplitude * decay;
    final double angle = _elapsed * frequency * 2 * math.pi;

    viewfinder.position = Vector2(
      _initialPosition.x + (math.sin(angle) * currentAmp),
      _initialPosition.y + (math.cos(angle * 1.35) * currentAmp * 0.7),
    );
  }

  @override
  void onRemove() {
    if (_initialized) {
      viewfinder.position = _initialPosition.clone();
    }
    super.onRemove();
  }
}

/// Instantaneous micro-zoom punch for big combo impacts and All Clear.
///
/// Zooms in by [maxZoomDelta] and smoothly springs back to 1.0 using [Curves.easeOutQuad].
class ZoomPunchEffect extends Component {
  ZoomPunchEffect({
    required this.viewfinder,
    this.maxZoomDelta = 0.025,
    this.duration = 0.28,
    this.onComplete,
  }) {
    priority = 1001;
  }

  final Viewfinder viewfinder;
  final double maxZoomDelta;
  final double duration;
  final void Function()? onComplete;

  double _elapsed = 0;
  late final double _initialZoom;
  bool _initialized = false;

  @override
  void onMount() {
    super.onMount();
    _initialZoom = viewfinder.zoom;
    _initialized = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_initialized) {
      _initialZoom = viewfinder.zoom;
      _initialized = true;
    }

    _elapsed += dt;
    if (_elapsed >= duration) {
      viewfinder.zoom = _initialZoom;
      removeFromParent();
      onComplete?.call();
      return;
    }

    final double t = (_elapsed / duration).clamp(0.0, 1.0);
    final double progress;
    if (t < 0.18) {
      progress = t / 0.18;
    } else {
      final double decayT = (t - 0.18) / 0.82;
      progress = 1.0 - EasingPresets.evaluateProgress(decayT, Curves.easeOutQuad);
    }

    viewfinder.zoom = _initialZoom + (maxZoomDelta * progress);
  }

  @override
  void onRemove() {
    if (_initialized) {
      viewfinder.zoom = _initialZoom;
    }
    super.onRemove();
  }
}
