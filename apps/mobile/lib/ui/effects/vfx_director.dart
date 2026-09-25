import 'dart:ui';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import '../../domain/gameplay/board_state.dart';
import '../../features/diagnostics/step6_benchmark.dart';
import 'burst_field.dart';
import 'camera_shake_effect.dart';
import 'combo_pulse_component.dart';
import 'landing_squash_component.dart';
import 'line_clear_flash_component.dart';
import 'score_pop_component.dart';
import 'shockwave_ring_component.dart';
import 'vfx_events.dart';

/// Central coordinator for all Flame visual game juice and particle flourishes.
///
/// Encapsulates particle systems, shockwaves, floating text popups, flashes, and
/// screen shakes. Decouples game state controllers and game loops from Flame scene
/// tree mutations.
class VfxDirector extends Component {
  VfxDirector({
    BurstField? burstField,
    this.viewfinder,
    this.vfxLevel = VfxLevel.standard,
    this.isReducedMotion,
    this.onScreenShake,
  }) : burst = burstField ?? BurstField() {
    priority = 205;
  }

  /// Shared pooled particle field.
  final BurstField burst;

  /// Optional Flame camera viewfinder to attach camera shake and zoom punch effects directly.
  final Viewfinder? viewfinder;

  /// Active visual effects density tier.
  VfxLevel vfxLevel;

  /// Accessibility motion preference resolver. Defaults to [Step6Benchmark.reducedMotion.value].
  final bool Function()? isReducedMotion;

  /// Callback to shake the game camera/viewfinder when direct [viewfinder] is not bound.
  final void Function(double amplitude)? onScreenShake;

  bool get _reducedMotion =>
      isReducedMotion?.call() ?? Step6Benchmark.reducedMotion.value;

  late final _BurstRendererComponent _burstRenderer;

  double _hitStopTimer = 0;

  /// Whether simulation / VFX are temporarily frozen for high-impact hit-stop.
  bool get isHitStopActive => _hitStopTimer > 0;

  /// Triggers a brief micro-pause (40-60ms) to heighten explosion punch.
  void triggerHitStop(double durationSeconds) {
    if (_reducedMotion || vfxLevel.isOff) {
      return;
    }
    _hitStopTimer = durationSeconds.clamp(0.02, 0.08);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _burstRenderer = _BurstRendererComponent(burst);
    add(_burstRenderer);
  }

  @override
  void update(double dt) {
    if (_hitStopTimer > 0) {
      _hitStopTimer -= dt;
      return;
    }
    super.update(dt);
  }

  /// Dispatches a typed [VfxEvent] to trigger the appropriate effect pipeline.
  void handleEvent(VfxEvent event) {
    if (vfxLevel == VfxLevel.off) {
      return;
    }

    switch (event) {
      case PiecePlacedVfxEvent():
        _handlePiecePlaced(event);
      case LineClearedVfxEvent():
        _handleLineCleared(event);
      case ScorePoppedVfxEvent():
        _handleScorePopped(event);
      case ShockwaveVfxEvent():
        _handleShockwave(event);
      case ComboPulseVfxEvent():
        _handleComboPulse(event);
      case ScreenShakeVfxEvent():
        _handleScreenShake(event);
      case AllClearVfxEvent():
        _handleAllClear(event);
    }
  }

  void _handlePiecePlaced(PiecePlacedVfxEvent event) {
    if (_reducedMotion) {
      return;
    }

    // 1. Tactile landing squash & stretch on placed cells
    if (event.cellRects != null && event.cellRects!.isNotEmpty) {
      add(
        LandingSquashComponent(
          cellRects: event.cellRects!,
          color: event.color,
        ),
      );
    }

    // 2. Micro particle burst at cell centers
    final int particleCount = vfxLevel == VfxLevel.full ? 4 : 2;
    if (event.cellCenters != null && event.cellCenters!.isNotEmpty) {
      for (final Vector2 center in event.cellCenters!) {
        burst.spawnBurst(
          x: center.x,
          y: center.y,
          color: event.color,
          count: particleCount,
          sizeBase: event.cellSize * 0.08,
          sizeJitter: event.cellSize * 0.06,
          speedMin: 20,
          speedJitter: 40,
        );
      }
    } else {
      burst.spawnBurst(
        x: event.position.x,
        y: event.position.y,
        color: event.color,
        count: particleCount * 2,
        sizeBase: event.cellSize * 0.1,
        sizeJitter: event.cellSize * 0.08,
        speedMin: 25,
        speedJitter: 50,
      );
    }
  }

  void _handleLineCleared(LineClearedVfxEvent event) {
    final bool reduced = _reducedMotion;
    final double cellSize = event.cellSize;
    final Color color = event.color;

    // 1. Screen Shake & Zoom punch
    if (!reduced) {
      final double shake = (2.0 + (event.strength - 1) * 0.6).clamp(2.0, 4.5);
      final bool zoomPunch = event.strength >= 3;
      _handleScreenShake(ScreenShakeVfxEvent(amplitude: shake, zoomPunch: zoomPunch));
    }

    // 2. Full-board flash
    add(
      LineClearFlashComponent(
        boardOrigin: event.boardOrigin,
        boardSize: Vector2.all(cellSize * 8),
        strength: event.strength,
        customMotionFactor: reduced ? 0.25 : 1.0,
      ),
    );

    // 3. Shockwave ring expanding from centroid
    add(
      ShockwaveRingComponent(
        center: event.centroid,
        boardRect: Rect.fromLTWH(
          event.boardOrigin.x,
          event.boardOrigin.y,
          cellSize * 8,
          cellSize * 8,
        ),
        color: color,
      ),
    );

    // 4. Particle bursts
    final int perCellCount = reduced
        ? 2
        : (vfxLevel == VfxLevel.full ? 8 : 6);

    for (final BoardCell cell in event.cells) {
      burst.spawnBurst(
        x: event.boardOrigin.x + (cell.x * cellSize) + (cellSize / 2),
        y: event.boardOrigin.y + (cell.y * cellSize) + (cellSize / 2),
        color: color,
        count: perCellCount,
        sizeBase: cellSize * 0.12,
        sizeJitter: cellSize * 0.1,
      );
    }
  }

  void _handleScorePopped(ScorePoppedVfxEvent event) {
    add(
      ScorePopComponent(
        text: event.text,
        startPosition: event.position,
        duration: event.duration,
        color: event.color,
      ),
    );
  }

  void _handleShockwave(ShockwaveVfxEvent event) {
    // Remove existing shockwaves to avoid screen clutter
    final existing = children.whereType<ShockwaveRingComponent>().toList(growable: false);
    for (final s in existing) {
      s.removeFromParent();
    }
    add(
      ShockwaveRingComponent(
        center: event.center,
        boardRect: event.boardRect,
        color: event.color,
        maxRadius: event.maxRadius,
        duration: event.duration,
      ),
    );
  }

  void _handleComboPulse(ComboPulseVfxEvent event) {
    final existing = children.whereType<ComboPulseComponent>().toList(growable: false);
    for (final c in existing) {
      c.removeFromParent();
    }
    add(
      ComboPulseComponent(
        text: event.text,
        startPosition: event.position,
      ),
    );
  }

  void _handleScreenShake(ScreenShakeVfxEvent event) {
    if (_reducedMotion) {
      return;
    }

    if (viewfinder != null) {
      final existingShakes = children.whereType<CameraShakeEffect>().toList(growable: false);
      for (final s in existingShakes) {
        s.removeFromParent();
      }
      add(
        CameraShakeEffect(
          viewfinder: viewfinder!,
          amplitude: event.amplitude,
        ),
      );

      if (event.zoomPunch) {
        final existingZoom = children.whereType<ZoomPunchEffect>().toList(growable: false);
        for (final z in existingZoom) {
          z.removeFromParent();
        }
        add(
          ZoomPunchEffect(
            viewfinder: viewfinder!,
          ),
        );
      }
    } else {
      onScreenShake?.call(event.amplitude);
    }
  }

  void _handleAllClear(AllClearVfxEvent event) {
    final bool reduced = _reducedMotion;
    final Vector2 center = Vector2(
      event.boardOrigin.x + (event.boardSize.x / 2),
      event.boardOrigin.y + (event.boardSize.y / 2),
    );

    if (!reduced) {
      triggerHitStop(0.06);
      _handleScreenShake(const ScreenShakeVfxEvent(amplitude: 4.5, zoomPunch: true));
    }

    add(
      LineClearFlashComponent(
        boardOrigin: event.boardOrigin,
        boardSize: event.boardSize,
        strength: 5,
        customMotionFactor: reduced ? 0.25 : 1.0,
      ),
    );

    add(
      ShockwaveRingComponent(
        center: center,
        boardRect: Rect.fromLTWH(
          event.boardOrigin.x,
          event.boardOrigin.y,
          event.boardSize.x,
          event.boardSize.y,
        ),
        color: event.color ?? const Color(0xFFFFD700),
      ),
    );

    add(
      ComboPulseComponent(
        text: 'ALL CLEAR!',
        startPosition: Vector2(
          center.x,
          event.boardOrigin.y + (event.boardSize.y * 0.44),
        ),
      ),
    );

    // Firework celebrations across the board
    final int burstCount = reduced ? 8 : (vfxLevel == VfxLevel.full ? 32 : 18);
    final Color gold = event.color ?? const Color(0xFFFFD700);
    const Color white = Color(0xFFFFFFFF);

    burst.spawnBurst(
      x: center.x,
      y: center.y,
      color: gold,
      count: burstCount,
      sizeBase: 6.0,
      sizeJitter: 4.0,
      speedMin: 60.0,
      speedJitter: 120.0,
    );
    burst.spawnBurst(
      x: center.x,
      y: center.y,
      color: white,
      count: burstCount ~/ 2,
      sizeBase: 4.0,
      sizeJitter: 3.0,
      speedMin: 40.0,
      speedJitter: 80.0,
    );
  }

  /// Clears all active effects and pooled particles.
  void clearAll() {
    removeAll(children.whereType<ShockwaveRingComponent>().toList(growable: false));
    removeAll(children.whereType<ScorePopComponent>().toList(growable: false));
    removeAll(children.whereType<ComboPulseComponent>().toList(growable: false));
    removeAll(children.whereType<LineClearFlashComponent>().toList(growable: false));
    removeAll(children.whereType<LandingSquashComponent>().toList(growable: false));
    removeAll(children.whereType<CameraShakeEffect>().toList(growable: false));
    removeAll(children.whereType<ZoomPunchEffect>().toList(growable: false));
  }
}

/// Thin Flame position component that advances and renders the shared [BurstField].
class _BurstRendererComponent extends PositionComponent {
  _BurstRendererComponent(this._field) {
    priority = 220;
  }

  final BurstField _field;

  @override
  void update(double dt) {
    super.update(dt);
    _field.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _field.render(canvas);
  }
}
