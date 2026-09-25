import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'vfx_events.dart';

/// Manages the GLSL fragment program for organic chromatic piece & gem auras.
///
/// Gated strictly by [VfxLevel.full] and reduced motion settings.
/// Falls back to a procedural radial gradient paint in test environments or on GPUs
/// where runtime shader compilation is unsupported.
class PieceAuraShader {
  PieceAuraShader({
    ui.FragmentProgram? program,
    this.vfxLevel = VfxLevel.full,
    bool Function()? isReducedMotion,
  })  : _program = program,
        _isReducedMotion = isReducedMotion ?? (() => false);

  ui.FragmentProgram? _program;
  ui.FragmentShader? _cachedShader;
  VfxLevel vfxLevel;
  final bool Function() _isReducedMotion;

  /// Whether the native fragment program is loaded and available.
  bool get hasCompiledProgram => _program != null;

  /// Whether aura effects are currently enabled based on settings and motion preferences.
  bool get isEnabled =>
      (vfxLevel == VfxLevel.full || vfxLevel == VfxLevel.standard) &&
      !_isReducedMotion();

  /// Loads the fragment shader asset asynchronously.
  ///
  /// Safe against asset load or shader compilation failures (e.g. headless tests).
  Future<void> loadShader() async {
    try {
      _program = await ui.FragmentProgram.fromAsset('shaders/piece_aura.frag');
      _cachedShader?.dispose();
      _cachedShader = _program?.fragmentShader();
    } catch (_) {
      // Graceful fallback to procedural gradient
      _program = null;
      _cachedShader = null;
    }
  }

  /// Disposes the cached GPU fragment shader instance.
  void dispose() {
    _cachedShader?.dispose();
    _cachedShader = null;
  }

  /// Creates a [Paint] configured with either the GPU fragment shader or a procedural fallback.
  Paint createPaint({
    required Rect bounds,
    required Color color,
    required double time,
    double intensity = 1.0,
  }) {
    final ui.FragmentShader? shader = _cachedShader;
    if (_program != null && shader != null) {
      shader.setFloat(0, bounds.width);
      shader.setFloat(1, bounds.height);
      shader.setFloat(2, time);
      shader.setFloat(3, color.r);
      shader.setFloat(4, color.g);
      shader.setFloat(5, color.b);
      shader.setFloat(6, color.a);
      shader.setFloat(7, intensity.clamp(0.0, 1.0));

      return Paint()
        ..shader = shader
        ..blendMode = BlendMode.screen;
    }

    // Procedural radial fallback
    return Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: (0.45 * intensity).clamp(0.0, 1.0)),
          color.withValues(alpha: (0.15 * intensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const <double>[0.1, 0.45, 1.0],
      ).createShader(bounds);
  }

  /// Renders a pulsing aura behind [targetBounds] onto [canvas].
  ///
  /// If [vfxLevel] is not [VfxLevel.full] or reduced motion is active, this is a no-op.
  void drawAura(
    Canvas canvas, {
    required Rect targetBounds,
    required Color color,
    required double time,
    double intensity = 1.0,
    double inflationFactor = 0.35,
  }) {
    if (!isEnabled || intensity <= 0.0) {
      return;
    }

    final double pad = targetBounds.width * inflationFactor;
    final Rect auraRect = targetBounds.inflate(pad);

    canvas.save();
    canvas.translate(auraRect.left, auraRect.top);
    final Rect localRect = Rect.fromLTWH(0, 0, auraRect.width, auraRect.height);

    final Paint paint = createPaint(
      bounds: localRect,
      color: color,
      time: time,
      intensity: intensity,
    );

    canvas.drawOval(localRect, paint);
    canvas.restore();
  }
}
