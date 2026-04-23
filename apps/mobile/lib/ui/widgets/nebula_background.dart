import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-screen nebula gradient background used behind the game board.
///
/// Renders a multi-layer gradient with nebula clouds and static star
/// particles via a [CustomPainter]. The painting is static and never
/// repaints, so performance cost is a single frame.
class NebulaBackground extends StatelessWidget {
  const NebulaBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF060C2A),
            Color(0xFF101F51),
            Color(0xFF1B235C),
            Color(0xFF0B1645),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _NebulaBackgroundPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _NebulaBackgroundPainter extends CustomPainter {
  const _NebulaBackgroundPainter();

  static const List<Offset> _stars = <Offset>[
    Offset(0.08, 0.08),
    Offset(0.14, 0.16),
    Offset(0.23, 0.11),
    Offset(0.31, 0.2),
    Offset(0.42, 0.12),
    Offset(0.56, 0.17),
    Offset(0.63, 0.1),
    Offset(0.74, 0.2),
    Offset(0.86, 0.14),
    Offset(0.92, 0.24),
    Offset(0.12, 0.39),
    Offset(0.24, 0.33),
    Offset(0.39, 0.46),
    Offset(0.51, 0.38),
    Offset(0.67, 0.42),
    Offset(0.8, 0.35),
    Offset(0.89, 0.49),
    Offset(0.06, 0.6),
    Offset(0.19, 0.55),
    Offset(0.34, 0.66),
    Offset(0.46, 0.59),
    Offset(0.62, 0.67),
    Offset(0.76, 0.61),
    Offset(0.87, 0.71),
    Offset(0.11, 0.82),
    Offset(0.28, 0.78),
    Offset(0.43, 0.88),
    Offset(0.58, 0.8),
    Offset(0.71, 0.9),
    Offset(0.9, 0.86),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final Paint baseMist = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0x1C113064),
          Color(0x181D3A73),
          Color(0x151A376B),
          Color(0x10142E5C),
        ],
      ).createShader(rect);
    final Paint cyanNebula = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.16, -0.34),
        radius: 1.04,
        colors: <Color>[
          _withAlpha(const Color(0xFF56D4FF), 0.3),
          _withAlpha(const Color(0xFF56D4FF), 0.13),
          Colors.transparent,
        ],
      ).createShader(rect);
    final Paint violetNebula = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.58, 0.1),
        radius: 1.1,
        colors: <Color>[
          _withAlpha(const Color(0xFFA286FF), 0.27),
          _withAlpha(const Color(0xFFA286FF), 0.13),
          Colors.transparent,
        ],
      ).createShader(rect);
    final Paint lowerNebula = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.06, 0.84),
        radius: 1.0,
        colors: <Color>[
          _withAlpha(const Color(0xFF4FA8FF), 0.18),
          Colors.transparent,
        ],
      ).createShader(rect);
    final Paint rightNebula = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.88, -0.02),
        radius: 1.08,
        colors: <Color>[
          _withAlpha(const Color(0xFF6CB8FF), 0.14),
          Colors.transparent,
        ],
      ).createShader(rect);
    final Paint midNebula = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.58, 0.34),
        radius: 0.82,
        colors: <Color>[
          _withAlpha(const Color(0xFF8B7FFF), 0.18),
          _withAlpha(const Color(0xFF57D4FF), 0.13),
          Colors.transparent,
        ],
      ).createShader(rect);
    final Paint boardHalo = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.1, 0.08),
        radius: 0.82,
        colors: <Color>[
          _withAlpha(const Color(0xFF7DDCFF), 0.15),
          _withAlpha(const Color(0xFF9E86FF), 0.13),
          Colors.transparent,
        ],
      ).createShader(rect);
    final Paint bottomMist = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 1.04),
        radius: 0.95,
        colors: <Color>[
          _withAlpha(const Color(0xFF846FFF), 0.12),
          _withAlpha(const Color(0xFF59CAFF), 0.1),
          Colors.transparent,
        ],
      ).createShader(rect);
    final Paint starAura = Paint()
      ..color = const Color(0x2BBFEAFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.1);
    final Paint starCore = Paint()..color = const Color(0x88DDF6FF);

    canvas.drawRect(rect, baseMist);
    canvas.drawRect(rect, cyanNebula);
    canvas.drawRect(rect, violetNebula);
    canvas.drawRect(rect, lowerNebula);
    canvas.drawRect(rect, rightNebula);
    canvas.drawRect(rect, midNebula);
    canvas.drawRect(rect, boardHalo);
    canvas.drawRect(rect, bottomMist);

    for (int i = 0; i < _stars.length; i++) {
      if (i.isOdd) {
        continue;
      }
      final Offset star = _stars[i];
      final Offset point = Offset(size.width * star.dx, size.height * star.dy);
      final double auraRadius = (i % 6 == 0) ? 3.0 : 2.0;
      final double coreRadius = (i % 5 == 0) ? 1.1 : 0.8;
      canvas.drawCircle(point, auraRadius, starAura);
      canvas.drawCircle(point, coreRadius, starCore);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

Color _withAlpha(Color color, double alpha) {
  final int a =
      (alpha.clamp(0, 1).toDouble() * 255).round().clamp(0, 255).toInt();
  final int rgb = _colorToArgb32(color) & 0x00FFFFFF;
  return Color((a << 24) | rgb);
}

int _colorToArgb32(Color color) {
  final dynamic dynamicColor = color;
  try {
    return dynamicColor.toARGB32() as int;
  } catch (_) {
    return dynamicColor.value as int;
  }
}
