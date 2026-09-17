import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../ui/effects/glass_board.dart';
import '../../ui/widgets/nebula_background.dart';

/// The exact layers for DEC-0024 Step 1g and 1h bisection.
enum BenchmarkLayer {
  /// 1. control (solid color + single small animating rectangle)
  control,

  /// 2. + NebulaBackground
  withNebula,

  /// 3. + empty GameWidget (FlameGame with no components)
  withGameWidget,

  /// 4. + board well (paintBoardWell)
  withBoardWell,

  /// 5. + stones (paintGlassFacet on 64 cells)
  withStones,
}

/// A dedicated benchmark scene for Step 1g (control floor) and Step 1h
/// (layer-by-layer decomposition).
///
/// Available only behind [kDiagnosticsEnabled].
class BenchmarkSceneScreen extends StatefulWidget {
  const BenchmarkSceneScreen({
    super.key,
    this.initialLayer = BenchmarkLayer.control,
  });

  final BenchmarkLayer initialLayer;

  @override
  State<BenchmarkSceneScreen> createState() => _BenchmarkSceneScreenState();
}

class _BenchmarkSceneScreenState extends State<BenchmarkSceneScreen>
    with SingleTickerProviderStateMixin {
  late BenchmarkLayer _layer;
  late final AnimationController _animController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _layer = widget.initialLayer;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1222),
      appBar: AppBar(
        title: Text('Benchmark: ${_layerTitle(_layer)}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: <Widget>[
          // Layer 2+: NebulaBackground
          if (_layer != BenchmarkLayer.control)
            const Positioned.fill(child: NebulaBackground()),

          // Layer 3+: Empty GameWidget
          if (_layer == BenchmarkLayer.withGameWidget)
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 360,
                  height: 360,
                  child: GameWidget(game: _EmptyBenchmarkGame()),
                ),
              ),
            ),

          // Layer 4+: GameWidget with Board Well
          if (_layer == BenchmarkLayer.withBoardWell)
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 360,
                  height: 360,
                  child: GameWidget(game: _WellBenchmarkGame()),
                ),
              ),
            ),

          // Layer 5+: GameWidget with Board Well + 64 Stones
          if (_layer == BenchmarkLayer.withStones)
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 360,
                  height: 360,
                  child: GameWidget(game: _StonesBenchmarkGame()),
                ),
              ),
            ),

          // Layer 1 (Control Base): Small animating rectangle to continuously drive frame production
          AnimatedBuilder(
            animation: _animation,
            builder: (BuildContext context, Widget? child) {
              return Transform.translate(
                offset: Offset(
                  40 + (200 * _animation.value),
                  80 + (120 * _animation.value),
                ),
                child: child,
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _layerTitle(BenchmarkLayer layer) {
    switch (layer) {
      case BenchmarkLayer.control:
        return '1g Control';
      case BenchmarkLayer.withNebula:
        return '1h.2 +Nebula';
      case BenchmarkLayer.withGameWidget:
        return '1h.3 +GameWidget';
      case BenchmarkLayer.withBoardWell:
        return '1h.4 +Well';
      case BenchmarkLayer.withStones:
        return '1h.5 +Stones';
    }
  }
}

class _EmptyBenchmarkGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0x00000000);
}

class _WellBenchmarkGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_WellComponent());
  }
}

class _WellComponent extends PositionComponent {
  ui.Image? _wellImage;
  double _ratio = 0;
  Vector2 _lastSize = Vector2.zero();

  @override
  void onMount() {
    super.onMount();
    size = Vector2(360, 360);
  }

  @override
  void onRemove() {
    _wellImage?.dispose();
    _wellImage = null;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double ratio = boardWellPixelRatio();
    if (_wellImage == null || _lastSize != size || _ratio != ratio) {
      _wellImage?.dispose();
      final double cellSize = size.x / 8;
      _wellImage = rasterizeBoardWell(
        width: size.x,
        height: size.y,
        cell: cellSize,
        cols: 8,
        rows: 8,
        devicePixelRatio: ratio,
        cornerRadius: 18,
        socketStrength: 0.5,
        tint: const Color(0xFF0C1B36),
        accent: const Color(0xFF55CEFF),
      );
      _lastSize = size.clone();
      _ratio = ratio;
    }
    drawBoardWellImage(canvas, _wellImage!, width: size.x, height: size.y);
  }
}

class _StonesBenchmarkGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_StonesComponent());
  }
}

class _StonesComponent extends PositionComponent {
  ui.Image? _wellImage;
  double _ratio = 0;
  Vector2 _lastSize = Vector2.zero();

  @override
  void onMount() {
    super.onMount();
    size = Vector2(360, 360);
  }

  @override
  void onRemove() {
    _wellImage?.dispose();
    _wellImage = null;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double ratio = boardWellPixelRatio();
    if (_wellImage == null || _lastSize != size || _ratio != ratio) {
      _wellImage?.dispose();
      final double cellSize = size.x / 8;
      _wellImage = rasterizeBoardWell(
        width: size.x,
        height: size.y,
        cell: cellSize,
        cols: 8,
        rows: 8,
        devicePixelRatio: ratio,
        cornerRadius: 18,
        socketStrength: 0.5,
        tint: const Color(0xFF0C1B36),
        accent: const Color(0xFF55CEFF),
      );
      _lastSize = size.clone();
      _ratio = ratio;
    }
    drawBoardWellImage(canvas, _wellImage!, width: size.x, height: size.y);

    final double cellSize = size.x / 8;
    // 64 glass stones
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final Rect bounds = Rect.fromLTWH(
          (x * cellSize) + 2,
          (y * cellSize) + 2,
          cellSize - 4,
          cellSize - 4,
        );
        final Path path = roundedSquarePath(bounds, 8);
        paintGlassFacet(
          canvas,
          path: path,
          bounds: bounds,
          tint: const Color(0xFF55CEFF),
          unit: cellSize,
        );
      }
    }
  }
}
