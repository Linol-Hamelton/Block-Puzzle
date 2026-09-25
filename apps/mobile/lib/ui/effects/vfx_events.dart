import 'package:flame/extensions.dart';
import '../../domain/gameplay/board_state.dart';
import 'effect_timing.dart';

/// Performance tier for visual effects.
///
/// Can be dynamically driven by Firebase Remote Config (`vfx_level`),
/// device battery state, or accessibility settings.
enum VfxLevel {
  off,
  standard,
  full;

  static VfxLevel fromString(String? raw) {
    if (raw == null) {
      return VfxLevel.standard;
    }
    switch (raw.trim().toLowerCase()) {
      case 'off':
      case 'none':
        return VfxLevel.off;
      case 'full':
      case 'high':
      case 'max':
        return VfxLevel.full;
      case 'standard':
      case 'normal':
      case 'med':
      case 'medium':
      default:
        return VfxLevel.standard;
    }
  }

  bool get isOff => this == VfxLevel.off;
  bool get isStandard => this == VfxLevel.standard;
  bool get isFull => this == VfxLevel.full;
}

/// Abstract root for all visual game juice events emitted by game loop logic.
///
/// Decouples gameplay rules and state controllers from Flame rendering components.
sealed class VfxEvent {
  const VfxEvent();

  const factory VfxEvent.piecePlaced({
    required Vector2 position,
    required Color color,
    List<Vector2>? cellCenters,
    List<Rect>? cellRects,
    double cellSize,
  }) = PiecePlacedVfxEvent;

  const factory VfxEvent.lineCleared({
    required Set<BoardCell> cells,
    required Vector2 centroid,
    required int strength,
    required Color color,
    required Vector2 boardOrigin,
    required double cellSize,
  }) = LineClearedVfxEvent;

  const factory VfxEvent.scorePopped({
    required String text,
    required Vector2 position,
    Color? color,
    double duration,
  }) = ScorePoppedVfxEvent;

  const factory VfxEvent.shockwave({
    required Vector2 center,
    required Rect boardRect,
    Color? color,
    double maxRadius,
    double duration,
  }) = ShockwaveVfxEvent;

  const factory VfxEvent.comboPulse({
    required String text,
    required Vector2 position,
    int comboStreak,
  }) = ComboPulseVfxEvent;

  const factory VfxEvent.screenShake({
    required double amplitude,
    bool zoomPunch,
  }) = ScreenShakeVfxEvent;

  const factory VfxEvent.allClear({
    required Vector2 boardOrigin,
    required Vector2 boardSize,
    Color? color,
  }) = AllClearVfxEvent;
}

/// Dispatched when a puzzle piece snaps into the board.
class PiecePlacedVfxEvent extends VfxEvent {
  const PiecePlacedVfxEvent({
    required this.position,
    required this.color,
    this.cellCenters,
    this.cellRects,
    this.cellSize = 36.0,
  });

  final Vector2 position;
  final Color color;
  final List<Vector2>? cellCenters;
  final List<Rect>? cellRects;
  final double cellSize;
}

/// Dispatched when one or more rows/columns/gems are cleared.
class LineClearedVfxEvent extends VfxEvent {
  const LineClearedVfxEvent({
    required this.cells,
    required this.centroid,
    required this.strength,
    required this.color,
    required this.boardOrigin,
    required this.cellSize,
  });

  final Set<BoardCell> cells;
  final Vector2 centroid;
  final int strength;
  final Color color;
  final Vector2 boardOrigin;
  final double cellSize;
}

/// Dispatched when bonus points or combo points pop up floating over the board.
class ScorePoppedVfxEvent extends VfxEvent {
  const ScorePoppedVfxEvent({
    required this.text,
    required this.position,
    this.color,
    this.duration = 0.85,
  });

  final String text;
  final Vector2 position;
  final Color? color;
  final double duration;
}

/// Dispatched when an expanding circular energy shockwave sweeps the board.
class ShockwaveVfxEvent extends VfxEvent {
  const ShockwaveVfxEvent({
    required this.center,
    required this.boardRect,
    this.color,
    this.maxRadius = 140.0,
    this.duration = 0.8 * kEffectTimeScale,
  });

  final Vector2 center;
  final Rect boardRect;
  final Color? color;
  final double maxRadius;
  final double duration;
}

/// Dispatched when combo praise text pulses and rises in the HUD header.
class ComboPulseVfxEvent extends VfxEvent {
  const ComboPulseVfxEvent({
    required this.text,
    required this.position,
    this.comboStreak = 1,
  });

  final String text;
  final Vector2 position;
  final int comboStreak;
}

/// Dispatched to shake the game camera.
class ScreenShakeVfxEvent extends VfxEvent {
  const ScreenShakeVfxEvent({
    required this.amplitude,
    this.zoomPunch = false,
  });

  final double amplitude;
  final bool zoomPunch;
}

/// Dispatched during an All Clear (board cleared of all blocks).
class AllClearVfxEvent extends VfxEvent {
  const AllClearVfxEvent({
    required this.boardOrigin,
    required this.boardSize,
    this.color,
  });

  final Vector2 boardOrigin;
  final Vector2 boardSize;
  final Color? color;
}
