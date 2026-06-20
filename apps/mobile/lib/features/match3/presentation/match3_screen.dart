import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/audio/music_controller.dart';
import '../../../core/device/haptics_controller.dart';
import '../../../core/di/di_container.dart';
import '../../../data/analytics/analytics_tracker.dart';
import '../../../domain/match3/tile.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/nebula_background.dart';
import '../../game_loop/audio/game_sfx_player.dart';
import '../application/match3_controller.dart';
import '../application/match3_session_store.dart';
import 'match3_game.dart';

class Match3Screen extends StatefulWidget {
  const Match3Screen({super.key});

  @override
  State<Match3Screen> createState() => _Match3ScreenState();
}

class _Match3ScreenState extends State<Match3Screen>
    with WidgetsBindingObserver {
  late final GameSfxPlayer _sfx;
  late final HapticsController _haptics;
  late final MusicController _music;
  late final Match3Controller _controller;
  late final Match3FlameGame _game;
  bool _isDisposed = false;

  // Swipe tracking (in GameWidget-local pixels).
  GridPos? _panStartCell;
  Offset? _panStartOffset;
  Offset? _panLastOffset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sfx = sl<GameSfxPlayer>();
    _haptics = sl<HapticsController>();
    _music = sl<MusicController>();
    _controller = Match3Controller(
      sfx: _sfx,
      haptics: _haptics,
      analyticsTracker: sl<AnalyticsTracker>(),
      store: sl<Match3SessionStore>(),
    );
    _game = Match3FlameGame(controller: _controller);
    unawaited(_sfx.preload());
    unawaited(_controller.initialize());
    unawaited(_initMusic());
  }

  Future<void> _initMusic() async {
    await _music.loadPreference();
    if (!mounted) {
      return;
    }
    await _music.play();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _game.pauseEngine();
    unawaited(_music.stop());
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
        _game.resumeEngine();
        unawaited(_sfx.onAppResumed());
        unawaited(_music.resume());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _controller.saveActiveGame();
        _game.pauseEngine();
        unawaited(_music.pause());
        break;
    }
  }

  void _onTapUp(TapUpDetails details) {
    final GridPos? cell = _game.cellAt(details.localPosition);
    if (cell != null) {
      _game.onCellTapped(cell);
    }
  }

  void _onPanStart(DragStartDetails details) {
    _panStartOffset = details.localPosition;
    _panLastOffset = details.localPosition;
    _panStartCell = _game.cellAt(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _panLastOffset = details.localPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    final GridPos? start = _panStartCell;
    final Offset? from = _panStartOffset;
    final Offset? to = _panLastOffset;
    _panStartCell = null;
    _panStartOffset = null;
    _panLastOffset = null;
    if (start == null || from == null || to == null) {
      return;
    }
    final double dx = to.dx - from.dx;
    final double dy = to.dy - from.dy;
    // Require a deliberate drag before treating it as a swipe.
    if (dx.abs() < 12 && dy.abs() < 12) {
      return;
    }
    if (dx.abs() >= dy.abs()) {
      _game.onSwipe(start, dx > 0 ? 1 : -1, 0);
    } else {
      _game.onSwipe(start, 0, dy > 0 ? 1 : -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Match 3',
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
                      return _Match3Hud(controller: _controller);
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: GestureDetector(
                            onTapUp: _onTapUp,
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: GameWidget<Match3FlameGame>(game: _game),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _SwipeHint(),
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
                      moves: _controller.movesUsed,
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

class _Match3Hud extends StatelessWidget {
  const _Match3Hud({required this.controller});

  final Match3Controller controller;

  @override
  Widget build(BuildContext context) {
    final int? movesLeft = controller.movesLeft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: LuminaPalette.panel,
        border: Border.all(color: LuminaPalette.panelBorder),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: _Metric(label: 'Score', value: '${controller.score}')),
          Expanded(child: _Metric(label: 'Best', value: '${controller.bestScore}')),
          Expanded(
            child: _Metric(
              label: 'Moves',
              value: movesLeft == null ? '∞' : '$movesLeft',
            ),
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

class _SwipeHint extends StatelessWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Tap two adjacent gems — or swipe one — to match 3+ in a row.',
      textAlign: TextAlign.center,
      style: TextStyle(color: LuminaPalette.textSecondary, fontSize: 12),
    );
  }
}

class _GameOverCard extends StatelessWidget {
  const _GameOverCard({
    required this.score,
    required this.best,
    required this.moves,
    required this.onRestart,
  });

  final int score;
  final int best;
  final int moves;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Out of Moves',
            style: TextStyle(
              color: Color(0xFFFFC56B),
              fontSize: 26,
              fontWeight: FontWeight.w800,
              shadows: <Shadow>[Shadow(color: Color(0x66FFC56B), blurRadius: 18)],
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
            'Moves played $moves',
            style: const TextStyle(color: LuminaPalette.textSecondary),
          ),
          const SizedBox(height: 20),
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
