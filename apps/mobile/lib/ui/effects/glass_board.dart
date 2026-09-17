/// The shared material the three games are made of.
///
/// Before this existed, Classic, Tetris and Match-3 each painted a block their
/// own way - three unrelated looks in one product, and the weakest of them set
/// the impression. Both halves of the look live here instead: [paintBoardWell]
/// builds the recessed field a game is played on, and [paintGlassFacet] cuts one
/// piece of coloured glass to any silhouette.
///
/// Two rules hold the whole thing together, and breaking either is what makes
/// this kind of art look cheap:
///
/// * **Light comes from the top-left.** Every pass here assumes it. A piece is
///   lit as a bulge - bright top-left, shadowed bottom-right - and a socket is
///   lit as a hole, which is the same lighting inverted.
/// * **The field is the darkest thing on screen.** The pieces carry the light;
///   the board and the background recede behind them. When the background is
///   brighter than the playfield, the board reads as a hole cut in the page.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Draws the recessed field a game is played on: a dark well, one socket per
/// cell, a bevelled groove on every boundary, and a rim.
///
/// Returns nothing and draws at the canvas origin - callers record it into a
/// [ui.Picture] (see [recordBoardWell]) because none of it moves.
void paintBoardWell(
  Canvas canvas, {
  required double width,
  required double height,
  required double cell,
  required int cols,
  required int rows,
  Color accent = const Color(0xFF9FD8F5),
  double cornerRadius = 16,
  double socketStrength = 1,
  Color? tint,
}) {
  final Rect rect = Rect.fromLTWH(0, 0, width, height);
  final RRect rr = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

  // [tint] lets a skin colour the field without lightening it. Classic ships
  // six skins whose whole difference is the tone of the board, so the well
  // bends halfway toward the skin rather than ignoring it - but it stays dark,
  // because the pieces are what the player is meant to be looking at.
  const Color wellBase = Color(0xFF0B1226);
  final Color base =
      tint == null ? wellBase : (Color.lerp(wellBase, tint, 0.5) ?? wellBase);
  final Color deep =
      Color.lerp(base, const Color(0xFF04070F), 0.55) ?? const Color(0xFF060A16);

  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[base, deep],
      ).createShader(rect),
  );
  // A cool wash from above, so the field is not a flat block of navy.
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.35),
        radius: 1.1,
        colors: <Color>[accent.withValues(alpha: 0.16), Colors.transparent],
      ).createShader(rect),
  );

  canvas.save();
  canvas.clipRRect(rr);

  // One socket per cell. Darker than the field and darker still at the top,
  // which is what makes it read as a hole rather than as a lighter tile.
  //
  // [socketStrength] exists because the same texture does opposite things in
  // two games. On Match-3 every cell holds a gem, so the socket frames it. On
  // Tetris most of a 10x20 board is empty, and at full strength two hundred
  // sockets became the loudest thing on screen - the field shouted while the
  // pieces whispered. An empty board should be calm.
  final double socket0 = socketStrength.clamp(0, 1).toDouble();
  final double pad = cell * 0.055;
  final Radius socketRadius = Radius.circular(cell * 0.22);
  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < cols; x++) {
      final Rect socket = Rect.fromLTWH(
        (x * cell) + pad,
        (y * cell) + pad,
        cell - (pad * 2),
        cell - (pad * 2),
      );
      final RRect socketRR = RRect.fromRectAndRadius(socket, socketRadius);
      canvas.drawRRect(
        socketRR,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.black.withValues(alpha: 0.4 * socket0),
              Colors.white.withValues(
                alpha: ((x + y).isEven ? 0.102 : 0.059) * socket0,
              ),
            ],
            stops: const <double>[0, 0.75],
          ).createShader(socket),
      );
      // The lit bottom lip of the hole.
      canvas.drawRRect(
        socketRR.deflate(0.6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, cell * 0.022)
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              const Color(0x00FFFFFF),
              accent.withValues(alpha: 0.25 * socket0),
            ],
            stops: const <double>[0.45, 1],
          ).createShader(socket),
      );
    }
  }

  // Grooves: a wide blurred channel with a crisp lip that catches the light.
  // A one-pixel hairline reads as nothing on a phone.
  final Paint groove = Paint()
    ..strokeWidth = math.max(2.5, cell * 0.085)
    ..color = const Color(0x59040711)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1, cell * 0.03));
  final Paint lip = Paint()
    ..strokeWidth = math.max(1.2, cell * 0.022)
    ..color = accent.withValues(alpha: 0.3);
  final double lipShift = math.max(0.8, cell * 0.018);
  for (int x = 1; x < cols; x++) {
    final double px = x * cell;
    canvas.drawLine(Offset(px, 0), Offset(px, height), groove);
    canvas.drawLine(
      Offset(px + lipShift, 0),
      Offset(px + lipShift, height),
      lip,
    );
  }
  for (int y = 1; y < rows; y++) {
    final double py = y * cell;
    canvas.drawLine(Offset(0, py), Offset(width, py), groove);
    canvas.drawLine(Offset(0, py + lipShift), Offset(width, py + lipShift), lip);
  }

  canvas.restore();

  canvas.drawRRect(
    rr.inflate(0.5),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = accent.withValues(alpha: 0.69),
  );
}

/// [paintBoardWell] recorded into a picture. Nothing in the well moves, and
/// re-running its gradients and blurs every frame would spend the budget the
/// pieces need.
ui.Picture recordBoardWell({
  required double width,
  required double height,
  required double cell,
  required int cols,
  required int rows,
  Color accent = const Color(0xFF9FD8F5),
  double cornerRadius = 16,
  double socketStrength = 1,
  Color? tint,
}) {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  paintBoardWell(
    Canvas(recorder),
    width: width,
    height: height,
    cell: cell,
    cols: cols,
    rows: rows,
    accent: accent,
    cornerRadius: cornerRadius,
    socketStrength: socketStrength,
    tint: tint,
  );
  return recorder.endRecording();
}

/// [recordBoardWell] rasterised once into a texture.
///
/// Recording into a [ui.Picture] removes the cost of *recording* the well and
/// nothing else. A picture is a command list, and the GPU re-executes the whole
/// list on every frame: the well is roughly 130 gradient shaders - two per
/// socket, fill and lip - plus the two blurs on the grooves and the rim. Step
/// 1h of DEC-0024 bisected a benchmark scene layer by layer and priced that
/// replay at +11.35 ms of a 19.25 ms frame, 81% of everything the scene added,
/// while the 64 glass gems on top of it cost -0.01 ms. An image is a texture,
/// and blitting a texture is close to free.
///
/// [devicePixelRatio] is what keeps the board sharp, and getting it wrong is
/// the one way this function makes the game look worse: the image is sized in
/// physical pixels and drawn back at logical size, so rasterising at 1.0 on a
/// 2.75x screen yields a board upscaled 2.75x - a soapy one. Pass
/// [boardWellPixelRatio], or the ratio of the view being drawn into.
///
/// The caller owns the result. Dispose it when the geometry changes and in
/// `onRemove`, or every rotation of the screen leaks a texture.
ui.Image rasterizeBoardWell({
  required double width,
  required double height,
  required double cell,
  required int cols,
  required int rows,
  required double devicePixelRatio,
  Color accent = const Color(0xFF9FD8F5),
  double cornerRadius = 16,
  double socketStrength = 1,
  Color? tint,
}) {
  final double ratio = devicePixelRatio > 0 ? devicePixelRatio : 1;
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  // Paint in logical units onto a canvas scaled to physical ones, so every
  // gradient and blur inside the well is resolved at the screen's resolution
  // rather than stretched up to it afterwards.
  canvas.scale(ratio);
  paintBoardWell(
    canvas,
    width: width,
    height: height,
    cell: cell,
    cols: cols,
    rows: rows,
    accent: accent,
    cornerRadius: cornerRadius,
    socketStrength: socketStrength,
    tint: tint,
  );
  final ui.Picture picture = recorder.endRecording();
  // toImageSync, not toImage: toImage is a future, and a board that arrives one
  // frame late is a board that is missing on the first frame the player sees.
  final ui.Image image = picture.toImageSync(
    math.max(1, (width * ratio).ceil()),
    math.max(1, (height * ratio).ceil()),
  );
  picture.dispose();
  return image;
}

/// Draws an image from [rasterizeBoardWell] back at its logical size.
///
/// The image is larger than [width] x [height] by the device pixel ratio it was
/// rasterised at, so this maps it down to exactly the rectangle the well used
/// to paint into - one texture blit in place of the command list.
void drawBoardWellImage(
  Canvas canvas,
  ui.Image image, {
  required double width,
  required double height,
}) {
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromLTWH(0, 0, width, height),
    _wellBlitPaint,
  );
}

/// Bilinear, because the destination rectangle is the source divided by the
/// pixel ratio and the `ceil` above leaves it a fraction of a pixel off exact.
final Paint _wellBlitPaint = Paint()..filterQuality = FilterQuality.low;

/// The ratio to rasterise the well at.
///
/// Read from the platform view rather than from a [BuildContext]: this is
/// wanted inside `render`, where taking an inherited-widget dependency on
/// [MediaQuery] would be the wrong thing to do during paint. The game runs in
/// the implicit view, and 1 is a defensive floor rather than an expected value.
double boardWellPixelRatio() {
  final double ratio =
      ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1;
  return ratio > 0 ? ratio : 1;
}

/// Cuts one piece of coloured glass to [path].
///
/// Nine passes, in this order: halo, body, crossed prism, core glow, sheen,
/// bevel, facet, spark, rim. The colour stays dominant throughout - the white
/// passes are deliberately restrained, because stacking sheen on core glow on
/// bevel leaves every piece a pastel version of itself.
///
/// [unit] is the cell size, and every offset and radius scales off it so the
/// same material works at any board size. [glow] adds an outward bloom for a
/// piece that is meant to look charged - a bonus gem, a row about to clear.
void paintGlassFacet(
  Canvas canvas, {
  required Path path,
  required Rect bounds,
  required Color tint,
  required double unit,
  double opacity = 1,
  double glow = 0,
  bool halo = true,
}) {
  final Offset centre = bounds.center;
  final double a = opacity.clamp(0, 1).toDouble();

  if (halo) {
    canvas.drawPath(
      path.shift(Offset(0, unit * 0.03)),
      Paint()
        ..color = tint.withValues(alpha: 0.62 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.07),
    );
  }
  if (glow > 0) {
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.lerp(tint, Colors.white, 0.5)!
            .withValues(alpha: (0.7 * glow * a).clamp(0, 1).toDouble())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.22 * glow),
    );
  }

  final Color light = Color.lerp(tint, Colors.white, 0.34) ?? tint;
  final Color dark = Color.lerp(tint, const Color(0xFF07040F), 0.56) ?? tint;
  canvas.drawPath(
    path,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          light.withValues(alpha: a),
          tint.withValues(alpha: a),
          dark.withValues(alpha: a),
        ],
        stops: const <double>[0, 0.42, 1],
      ).createShader(bounds),
  );

  // Crossed against the body, so the surface looks faceted and not just shaded.
  canvas.drawPath(
    path,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: <Color>[
          Colors.white.withValues(alpha: 0.15 * a),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.35 * a),
        ],
        stops: const <double>[0, 0.52, 1],
      ).createShader(bounds),
  );

  // The light a stone carries inside it. Mostly its own colour, so this
  // deepens the hue instead of bleaching it.
  canvas.drawPath(
    path,
    Paint()
      ..shader = RadialGradient(
        radius: 0.72,
        colors: <Color>[
          Color.lerp(tint, Colors.white, 0.6)!.withValues(alpha: 0.4 * a),
          tint.withValues(alpha: 0.3 * a),
          Colors.transparent,
        ],
        stops: const <double>[0, 0.5, 1],
      ).createShader(bounds),
  );

  // The wet highlight: small and off-centre toward the light, not a wash.
  canvas.drawPath(
    path,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.42, -0.5),
        radius: 0.72,
        colors: <Color>[
          Colors.white.withValues(alpha: 0.6 * a),
          Colors.white.withValues(alpha: 0.06 * a),
          Colors.transparent,
        ],
        stops: const <double>[0, 0.55, 1],
      ).createShader(bounds),
  );

  canvas.save();
  canvas.clipPath(path);

  // Thickness: a stroke on the outline clipped to the inside is an inner bevel
  // for any silhouette, with no per-shape inset maths.
  final double bevel = math.max(1.8, unit * 0.085);
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bevel
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Colors.white.withValues(alpha: 0.7 * a),
          Colors.white.withValues(alpha: 0.06 * a),
          Colors.black.withValues(alpha: 0.45 * a),
        ],
        stops: const <double>[0, 0.5, 1],
      ).createShader(bounds),
  );

  // The cut across the face: the silhouette scaled in, so every shape gets an
  // echo of itself rather than one generic diamond.
  canvas.drawPath(
    path.transform(
      (Matrix4.identity()
            ..translateByDouble(centre.dx, centre.dy, 0, 1)
            ..scaleByDouble(0.52, 0.52, 1, 1)
            ..translateByDouble(-centre.dx, -centre.dy, 0, 1))
          .storage,
    ),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.9, unit * 0.016)
      ..color = Colors.white.withValues(alpha: 0.3 * a),
  );
  canvas.restore();

  // One bright point, in the same place on every piece.
  canvas.drawCircle(
    Offset(
      bounds.left + (bounds.width * 0.28),
      bounds.top + (bounds.height * 0.26),
    ),
    math.max(1.2, unit * 0.05),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.8 * a)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.03),
  );

  // Rim, to hold the silhouette against a neighbour of a similar colour.
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, unit * 0.028)
      ..color = (Color.lerp(tint, Colors.white, 0.5) ?? tint)
          .withValues(alpha: 0.85 * a),
  );
}

/// A rounded-square silhouette inscribed in [bounds] - the default piece shape
/// for games whose pieces are not told apart by colour.
Path roundedSquarePath(Rect bounds, double radius) => Path()
  ..addRRect(RRect.fromRectAndRadius(bounds, Radius.circular(radius)));
