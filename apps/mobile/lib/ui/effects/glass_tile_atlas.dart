import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/match3/tile.dart';
import '../../domain/tetris/tetromino.dart';
import 'glass_board.dart';

/// Mino colors (neon palette consistent with the Lumina look).
const Map<TetrominoType, Color> defaultTetrominoColors = <TetrominoType, Color>{
  TetrominoType.i: Color(0xFF44E0EA),
  TetrominoType.o: Color(0xFFF2D24E),
  TetrominoType.t: Color(0xFFB672EC),
  TetrominoType.s: Color(0xFF5FE08A),
  TetrominoType.z: Color(0xFFF06A86),
  TetrominoType.j: Color(0xFF5A8CEC),
  TetrominoType.l: Color(0xFFF0A44E),
};

/// Gem colors (neon palette consistent with the Lumina look).
const Map<TileColor, Color> defaultGemColors = <TileColor, Color>{
  TileColor.ruby: Color(0xFFF0566E),
  TileColor.amber: Color(0xFFEF7A21),
  TileColor.citrine: Color(0xFFFFE94A),
  TileColor.emerald: Color(0xFF5FE08A),
  TileColor.sapphire: Color(0xFF4DA6F0),
  TileColor.amethyst: Color(0xFFB672EC),
};

/// Generates the geometric silhouette path for a Match-3 gem of [color] inscribed in [rect].
Path match3GemPath(TileColor color, Rect rect) {
  final Offset c = rect.center;
  final double rx = rect.width / 2;
  final double ry = rect.height / 2;

  switch (color) {
    case TileColor.ruby:
      return roundedSquarePath(rect, rect.width * 0.26);
    case TileColor.citrine:
      return Path()..addOval(rect);
    case TileColor.amber:
      return _polygon(c, rx, ry, 6, math.pi / 6);
    case TileColor.emerald:
      return _polygon(c, rx, ry, 4, 0);
    case TileColor.sapphire:
      return _polygon(c, rx, ry, 5, 0);
    case TileColor.amethyst:
      return _star(c, rx, ry, 6, 0.62);
  }
}

Path _polygon(Offset c, double rx, double ry, int sides, double phase) {
  final Path path = Path();
  for (int i = 0; i < sides; i++) {
    final double a = ((math.pi * 2) / sides) * i - (math.pi / 2) + phase;
    final double x = c.dx + (math.cos(a) * rx);
    final double y = c.dy + (math.sin(a) * ry);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  return path..close();
}

Path _star(Offset c, double rx, double ry, int points, double inner) {
  final Path path = Path();
  final int steps = points * 2;
  for (int i = 0; i < steps; i++) {
    final double a = ((math.pi * 2) / steps) * i - (math.pi / 2);
    final double scale = i.isEven ? 1.0 : inner;
    final double x = c.dx + (math.cos(a) * rx * scale);
    final double y = c.dy + (math.sin(a) * ry * scale);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  return path..close();
}

/// Specification of a single glass tile entry to be pre-baked into a [GlassTileAtlas].
class GlassTileSpec<K> {
  const GlassTileSpec({
    required this.key,
    required this.pathBuilder,
    required this.tint,
    this.insetRatio = 0.0,
  });

  /// Key identifying this tile.
  final K key;

  /// Builds the silhouette path for this tile given its inner bounds and cell unit.
  final Path Function(Rect bounds, double unit) pathBuilder;

  /// Base tint color for the glass facet.
  final Color tint;

  /// Ratio of [unit] to inset the tile bounds from the cell edges (e.g. 0.075 for Tetris, 0.115 for Match-3).
  final double insetRatio;
}

/// A GPU-resident texture atlas containing pre-rendered [paintGlassFacet] tiles.
///
/// Pre-baking procedural glass facets eliminates per-frame evaluation of up to 10
/// gradient shaders, blur filters, clip paths, and matrix operations per cell.
///
/// Supports individual blitting via [drawTile] using [Canvas.drawImageRect], or
/// whole-board rendering in a single GPU draw call via [drawBatch] using [Canvas.drawRawAtlas].
class GlassTileAtlas<K> {
  GlassTileAtlas._({
    required this.image,
    required this.unit,
    required this.devicePixelRatio,
    required Map<K, Rect> sourceRects,
  }) : _sourceRects = sourceRects;

  /// The baked GPU texture atlas.
  final ui.Image image;

  /// The logical cell size each tile was baked for.
  final double unit;

  /// The device pixel ratio used during rasterization.
  final double devicePixelRatio;

  /// Mapping from tile key to its physical pixel bounds inside [image].
  final Map<K, Rect> _sourceRects;

  static final Paint _defaultBlitPaint = Paint()
    ..filterQuality = FilterQuality.low;

  /// Returns whether this atlas matches the requested [unit] and [devicePixelRatio].
  bool isValidFor({required double unit, required double devicePixelRatio}) {
    final double ratio = devicePixelRatio <= 0 ? 1.0 : devicePixelRatio;
    return (this.unit - unit).abs() < 0.01 && (this.devicePixelRatio - ratio).abs() < 0.01;
  }

  /// Returns the physical source rect inside [image] for [key], or null if not found.
  Rect? sourceRectFor(K key) => _sourceRects[key];

  /// Creates and bakes a [GlassTileAtlas] containing the specified [specs].
  static GlassTileAtlas<K> bake<K>({
    required List<GlassTileSpec<K>> specs,
    required double unit,
    double devicePixelRatio = 1.0,
  }) {
    if (unit <= 0) {
      throw ArgumentError.value(unit, 'unit', 'Cell unit must be positive');
    }
    if (specs.isEmpty) {
      throw ArgumentError.value(specs, 'specs', 'Must contain at least one tile spec');
    }

    final double ratio = devicePixelRatio <= 0 ? 1.0 : devicePixelRatio;
    final int count = specs.length;
    final int physicalSlot = math.max(1, (unit * ratio).ceil());
    final int physicalWidth = physicalSlot * count;
    final int physicalHeight = physicalSlot;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.scale(ratio);

    final Map<K, Rect> sourceRects = <K, Rect>{};

    for (int i = 0; i < count; i++) {
      final GlassTileSpec<K> spec = specs[i];
      final double logicalLeft = i * unit;
      final double inset = unit * spec.insetRatio;
      final Rect tileBounds = Rect.fromLTWH(
        logicalLeft + inset,
        inset,
        unit - (inset * 2),
        unit - (inset * 2),
      );

      final Path path = spec.pathBuilder(tileBounds, unit);

      paintGlassFacet(
        canvas,
        path: path,
        bounds: tileBounds,
        tint: spec.tint,
        unit: unit,
        opacity: 1.0,
        glow: 0.0,
        halo: true,
      );

      sourceRects[spec.key] = Rect.fromLTWH(
        i * physicalSlot.toDouble(),
        0,
        physicalSlot.toDouble(),
        physicalSlot.toDouble(),
      );
    }

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = picture.toImageSync(physicalWidth, physicalHeight);
    picture.dispose();

    return GlassTileAtlas<K>._(
      image: image,
      unit: unit,
      devicePixelRatio: ratio,
      sourceRects: sourceRects,
    );
  }

  /// Convenience factory for Tetris minos.
  static GlassTileAtlas<TetrominoType> bakeTetris({
    required double cell,
    double devicePixelRatio = 1.0,
    Map<TetrominoType, Color>? palette,
  }) {
    final Map<TetrominoType, Color> colors = palette ?? defaultTetrominoColors;
    final List<GlassTileSpec<TetrominoType>> specs = <GlassTileSpec<TetrominoType>>[];

    for (final TetrominoType type in TetrominoType.values) {
      final Color color = colors[type] ?? const Color(0xFFFFFFFF);
      specs.add(
        GlassTileSpec<TetrominoType>(
          key: type,
          tint: color,
          insetRatio: 0.075,
          pathBuilder: (Rect bounds, double unit) =>
              roundedSquarePath(bounds, unit * 0.2),
        ),
      );
    }

    return GlassTileAtlas.bake<TetrominoType>(
      specs: specs,
      unit: cell,
      devicePixelRatio: devicePixelRatio,
    );
  }

  /// Convenience factory for Match-3 gems.
  static GlassTileAtlas<TileColor> bakeMatch3({
    required double cell,
    double devicePixelRatio = 1.0,
    Map<TileColor, Color>? palette,
  }) {
    final Map<TileColor, Color> colors = palette ?? defaultGemColors;
    final List<GlassTileSpec<TileColor>> specs = <GlassTileSpec<TileColor>>[];

    for (final TileColor color in TileColor.values) {
      final Color tint = colors[color] ?? const Color(0xFFFFFFFF);
      specs.add(
        GlassTileSpec<TileColor>(
          key: color,
          tint: tint,
          insetRatio: 0.115,
          pathBuilder: (Rect bounds, double unit) =>
              match3GemPath(color, bounds),
        ),
      );
    }

    return GlassTileAtlas.bake<TileColor>(
      specs: specs,
      unit: cell,
      devicePixelRatio: devicePixelRatio,
    );
  }

  /// Draws a single tile to [canvas] filling the logical [dstCellRect] (e.g. `Rect.fromLTWH(ox + x * cell, oy + y * cell, cell, cell)`).
  void drawTile(
    Canvas canvas, {
    required K key,
    required Rect dstCellRect,
    Paint? paint,
  }) {
    final Rect? src = _sourceRects[key];
    if (src == null) {
      return;
    }
    canvas.drawImageRect(
      image,
      src,
      dstCellRect,
      paint ?? _defaultBlitPaint,
    );
  }

  /// Batch renders multiple tiles in a single GPU draw call via [Canvas.drawRawAtlas].
  ///
  /// [keys] are the tile keys, and [positions] are the top-left logical coordinates for each tile cell.
  void drawBatch(
    Canvas canvas, {
    required List<K> keys,
    required List<Offset> positions,
    Paint? paint,
  }) {
    final int count = math.min(keys.length, positions.length);
    if (count == 0) {
      return;
    }

    final Float32List rstTransforms = Float32List(count * 4);
    final Float32List rects = Float32List(count * 4);

    final double scale = 1.0 / devicePixelRatio;
    int validCount = 0;

    for (int i = 0; i < count; i++) {
      final Rect? src = _sourceRects[keys[i]];
      if (src == null) {
        continue;
      }

      final int rIdx = validCount * 4;
      rects[rIdx] = src.left;
      rects[rIdx + 1] = src.top;
      rects[rIdx + 2] = src.right;
      rects[rIdx + 3] = src.bottom;

      final Offset pos = positions[i];
      final int tIdx = validCount * 4;
      rstTransforms[tIdx] = scale;
      rstTransforms[tIdx + 1] = 0.0;
      rstTransforms[tIdx + 2] = pos.dx;
      rstTransforms[tIdx + 3] = pos.dy;

      validCount++;
    }

    if (validCount == 0) {
      return;
    }

    canvas.drawRawAtlas(
      image,
      validCount == count ? rstTransforms : rstTransforms.sublist(0, validCount * 4),
      validCount == count ? rects : rects.sublist(0, validCount * 4),
      null,
      null,
      null,
      paint ?? _defaultBlitPaint,
    );
  }

  /// Releases the GPU-resident texture. Call in `dropCachedSurfaces()` or `onRemove()`.
  void dispose() {
    image.dispose();
  }
}
