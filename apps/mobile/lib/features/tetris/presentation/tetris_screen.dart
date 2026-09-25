import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/device/haptics_controller.dart';
import '../../../core/di/di_container.dart';
import '../../../data/analytics/analytics_tracker.dart';
import '../../../domain/tetris/tetris_engine.dart';
import '../../../domain/tetris/tetromino.dart';
import '../../../ui/effects/celebration_director.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/nebula_background.dart';
import '../../game_loop/audio/game_sfx_player.dart';
import '../application/tetris_controller.dart';
import '../application/tetris_session_store.dart';
import 'tetris_game.dart';

class TetrisScreen extends StatefulWidget {
  const TetrisScreen({super.key});

  @override
  State<TetrisScreen> createState() => _TetrisScreenState();
}

class _TetrisScreenState extends State<TetrisScreen>
    with WidgetsBindingObserver {
  late final GameSfxPlayer _sfx;
  late final HapticsController _haptics;
  late final TetrisController _controller;
  late final TetrisFlameGame _game;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sfx = sl<GameSfxPlayer>();
    _haptics = sl<HapticsController>();
    _controller = TetrisController(
      sfx: _sfx,
      haptics: _haptics,
      analyticsTracker: sl<AnalyticsTracker>(),
      store: sl<TetrisSessionStore>(),
    );
    _game = TetrisFlameGame(controller: _controller);
    unawaited(_sfx.preload());
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _game.pauseEngine();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        // See the twin in Match-3: a cached GPU image is not guaranteed to
        // survive the render surface being rebuilt while the app was away.
        _game.dropCachedSurfaces();
        _game.resumeEngine();
        unawaited(_sfx.onAppResumed());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _controller.saveActiveGame();
        _game.pauseEngine();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tetris',
          style: TextStyle(
            color: Color(0xFFC5F2FF),
            fontWeight: FontWeight.w500,
            fontSize: 24,
            letterSpacing: 0.3,
            shadows: <Shadow>[
              Shadow(color: Color(0x7A53D5FF), blurRadius: 16),
              Shadow(color: Color(0x6640B9FF), blurRadius: 30),
            ],
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: NebulaBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: <Widget>[
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (BuildContext context, Widget? child) {
                      return _TetrisHud(controller: _controller);
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 10 / 20,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: GameWidget<TetrisFlameGame>(game: _game),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TetrisControls(onInput: _controller.input),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              if (!_controller.isGameOver) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xB20A1222),
                  child: Center(
                    child: _GameOverCard(
                      score: _controller.score,
                      best: _controller.bestScore,
                      isNewRecord: _controller.isNewRecord,
                      lines: _controller.lines,
                      level: _controller.level,
                      canRevive: _controller.canRevive,
                      onRevive: _controller.revive,
                      onRestart: _controller.restart,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TetrisHud extends StatelessWidget {
  const _TetrisHud({required this.controller});

  final TetrisController controller;

  @override
  Widget build(BuildContext context) {
    final List<TetrominoType> next = controller.nextQueue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: LuminaPalette.panel,
        border: Border.all(color: LuminaPalette.panelBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _Metric(label: 'Score', value: '${controller.score}'),
              ),
              Expanded(
                child: _Metric(label: 'Best', value: '${controller.bestScore}'),
              ),
              Expanded(
                child: _Metric(label: 'Lines', value: '${controller.lines}'),
              ),
              Expanded(
                child: _Metric(label: 'Level', value: '${controller.level}'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _PieceSlot(
                label: 'Hold',
                type: controller.hold,
                dim: !controller.canHold,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  const Text(
                    'Next',
                    style: TextStyle(
                      color: LuminaPalette.textSecondary,
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int i = 0; i < next.length && i < 5; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _PiecePreview(type: next[i], size: 24),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: LuminaPalette.textSecondary,
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFD5F4FF),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            shadows: <Shadow>[Shadow(color: Color(0x9252CBFF), blurRadius: 10)],
          ),
        ),
      ],
    );
  }
}

class _PieceSlot extends StatelessWidget {
  const _PieceSlot({required this.label, required this.type, this.dim = false});

  final String label;
  final TetrominoType? type;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: LuminaPalette.textSecondary,
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        _PiecePreview(type: type, size: 30, dim: dim),
      ],
    );
  }
}

class _PiecePreview extends StatelessWidget {
  const _PiecePreview({
    required this.type,
    required this.size,
    this.dim = false,
  });

  final TetrominoType? type;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dim ? 0.35 : 1,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: const Color(0x22132A4A),
          border: Border.all(color: const Color(0x3378B5DE)),
        ),
        child: CustomPaint(painter: _MiniPiecePainter(type)),
      ),
    );
  }
}

class _MiniPiecePainter extends CustomPainter {
  const _MiniPiecePainter(this.type);

  final TetrominoType? type;

  @override
  void paint(Canvas canvas, Size size) {
    final TetrominoType? t = type;
    if (t == null) {
      return;
    }
    final Tetromino tetromino = Tetromino.of(t);
    final List<TCell> cells = tetromino.cellsAt(0);

    int minX = 1 << 30;
    int minY = 1 << 30;
    int maxX = -(1 << 30);
    int maxY = -(1 << 30);
    for (final TCell c in cells) {
      minX = c.x < minX ? c.x : minX;
      minY = c.y < minY ? c.y : minY;
      maxX = c.x > maxX ? c.x : maxX;
      maxY = c.y > maxY ? c.y : maxY;
    }
    final int spanX = (maxX - minX) + 1;
    final int spanY = (maxY - minY) + 1;
    final double span = (spanX > spanY ? spanX : spanY).toDouble();
    final double pad = size.shortestSide * 0.12;
    final double cell = (size.shortestSide - (pad * 2)) / span;
    final double offX = (size.width - (spanX * cell)) / 2;
    final double offY = (size.height - (spanY * cell)) / 2;
    final Color color = tetrominoColors[t]!;
    final Paint paint = Paint()..color = color;

    for (final TCell c in cells) {
      final Rect rect = Rect.fromLTWH(
        offX + ((c.x - minX) * cell) + 1,
        offY + ((c.y - minY) * cell) + 1,
        cell - 2,
        cell - 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.22)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPiecePainter oldDelegate) =>
      oldDelegate.type != type;
}

class _TetrisControls extends StatelessWidget {
  const _TetrisControls({required this.onInput});

  final void Function(TetrisInput intent) onInput;

  @override
  Widget build(BuildContext context) {
    // Laid out from what the hands actually do, after play-testing on a phone.
    //
    // The bottom edge of the screen is where a thumb rests and where a stray
    // tap lands, so the bottom row holds only the two things pressed
    // constantly and safely: rotation on the left, movement on the right. Both
    // drops moved up. Hard drop is the single irreversible input in the game,
    // and having it along the bottom edge meant an accidental brush locked the
    // piece - the worst mistake in Tetris, caused by the cheapest slip.
    //
    // Everything is the same height. The earlier version made the drops
    // shorter because they are pressed less, which only made them harder to
    // hit on purpose while doing nothing about hitting them by accident.
    //
    // Hold sits in the middle, the hardest place to reach, because it is used
    // about once a round.
    const double buttonHeight = 62;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Top: the two drops, each spanning its whole cluster, so they are
        // twice the width of a single arrow and unmistakable.
        //
        // Hard drop on the left, soft drop on the right, which is how it felt
        // right in the hand. Soft drop is the one held down repeatedly, so it
        // sits above the movement arrows the same thumb is already working;
        // hard drop is a deliberate single press and belongs on the other side.
        Row(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: _PadButton(
                icon: Icons.vertical_align_bottom_rounded,
                height: buttonHeight,
                accent: true,
                onPressed: () => onInput(TetrisInput.hardDrop),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _PadButton(
                icon: Icons.layers_rounded,
                label: 'Hold',
                height: buttonHeight,
                onPressed: () => onInput(TetrisInput.hold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: _PadButton(
                icon: Icons.keyboard_arrow_down_rounded,
                height: buttonHeight,
                repeating: true,
                onPressed: () => onInput(TetrisInput.softDrop),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Bottom: rotation under the left thumb, movement under the right.
        Row(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _PadButton(
                      icon: Icons.rotate_left_rounded,
                      height: buttonHeight,
                      onPressed: () => onInput(TetrisInput.rotateCcw),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PadButton(
                      icon: Icons.rotate_right_rounded,
                      height: buttonHeight,
                      onPressed: () => onInput(TetrisInput.rotateCw),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Spacer(flex: 2),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _PadButton(
                      icon: Icons.chevron_left_rounded,
                      height: buttonHeight,
                      repeating: true,
                      onPressed: () => onInput(TetrisInput.moveLeft),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PadButton(
                      icon: Icons.chevron_right_rounded,
                      height: buttonHeight,
                      repeating: true,
                      onPressed: () => onInput(TetrisInput.moveRight),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PadButton extends StatefulWidget {
  const _PadButton({
    required this.icon,
    required this.onPressed,
    this.label,
    this.repeating = false,
    this.accent = false,
    this.height = 56,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final bool repeating;
  final bool accent;

  /// Frequently used inputs get taller targets than rare ones.
  final double height;

  @override
  State<_PadButton> createState() => _PadButtonState();
}

class _PadButtonState extends State<_PadButton> {
  Timer? _delay;
  Timer? _repeat;
  bool _pressed = false;

  void _start() {
    widget.onPressed();
    setState(() => _pressed = true);
    if (!widget.repeating) {
      return;
    }
    _delay = Timer(const Duration(milliseconds: 130), () {
      _repeat = Timer.periodic(
        const Duration(milliseconds: 45),
        (_) => widget.onPressed(),
      );
    });
  }

  void _stop() {
    _delay?.cancel();
    _repeat?.cancel();
    _delay = null;
    _repeat = null;
    if (mounted) {
      setState(() => _pressed = false);
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _repeat?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color base = widget.accent
        ? const Color(0x3A6FE0C9)
        : const Color(0x2D4B739F);
    final Color border =
        widget.accent ? const Color(0x886FE0C9) : const Color(0x588EB9D8);
    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _stop(),
      onTapCancel: _stop,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _pressed ? const Color(0x3D628FC0) : base,
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(widget.icon, color: const Color(0xFFD7EBFF), size: 24),
            if (widget.label != null)
              Text(
                widget.label!,
                style: const TextStyle(
                  color: Color(0xFFD7EBFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

typedef _GameOverCard = TetrisGameOverCard;

class TetrisGameOverCard extends StatelessWidget {
  const TetrisGameOverCard({
    super.key,
    required this.score,
    required this.best,
    required this.lines,
    required this.level,
    required this.canRevive,
    required this.onRevive,
    required this.onRestart,
    this.isNewRecord,
  });

  final int score;
  final int best;
  final int lines;
  final int level;
  final bool canRevive;
  final VoidCallback onRevive;
  final VoidCallback onRestart;
  final bool? isNewRecord;

  @override
  Widget build(BuildContext context) {
    final bool isNewBest = (isNewRecord ?? (score > best)) && score > 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: LuminaPalette.panel,
        border: Border.all(color: LuminaPalette.panelBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isNewBest) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: CelebrationDirector.instance.activeProvider.buildCelebrationWidget(
                context: context,
                type: CelebrationType.newRecord,
                score: score,
                size: 80.0,
              ),
            ),
          ],
          Text(
            isNewBest ? 'New Record!' : 'Game Over',
            style: TextStyle(
              color: isNewBest ? const Color(0xFFFFD54F) : const Color(0xFFFF7E97),
              fontSize: 26,
              fontWeight: FontWeight.w800,
              shadows: <Shadow>[
                Shadow(
                  color: isNewBest ? const Color(0x66FFD54F) : const Color(0x66FF7E97),
                  blurRadius: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Score $score   ·   Best $best',
            style: const TextStyle(
              color: Color(0xFFD5F4FF),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lines $lines   ·   Level $level',
            style: const TextStyle(color: LuminaPalette.textSecondary),
          ),
          const SizedBox(height: 20),
          if (canRevive) ...<Widget>[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E9E6B),
                  foregroundColor: Colors.white,
                ),
                onPressed: onRevive,
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('Continue'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Play Again'),
            ),
          ),
        ],
      ),
    );
  }
}
