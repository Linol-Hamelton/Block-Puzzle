import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/di/di_container.dart';
import '../audio/game_sfx_player.dart';
import '../application/game_loop_controller.dart';
import '../application/game_loop_view_state.dart';
import 'block_puzzle_game.dart';

class GameLoopScreen extends StatefulWidget {
  const GameLoopScreen({super.key});

  @override
  State<GameLoopScreen> createState() => _GameLoopScreenState();
}

class _GameLoopScreenState extends State<GameLoopScreen> {
  static const double _surfaceMaxWidth = 920;

  late final GameLoopController _controller;
  late final GameSfxPlayer _sfxPlayer;
  late final BlockPuzzleGame _game;
  final List<_ComboToastData> _comboToasts = <_ComboToastData>[];
  int _comboToastSeq = 0;
  GameLoopViewState? _lastObservedState;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = sl<GameLoopController>();
    _sfxPlayer = sl<GameSfxPlayer>();
    _game = BlockPuzzleGame(
      controller: _controller,
      sfxPlayer: _sfxPlayer,
    );
    _controller.stateListenable.addListener(_onControllerStateChanged);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.stateListenable.removeListener(_onControllerStateChanged);
    super.dispose();
  }

  void _onControllerStateChanged() {
    final GameLoopViewState current = _controller.state;
    final GameLoopViewState? previous = _lastObservedState;
    _lastObservedState = current;

    if (previous == null) {
      return;
    }

    if (current.movesPlayed != previous.movesPlayed &&
        current.scoreState.comboStreak > 1 &&
        current.scoreState.comboStreak >= previous.scoreState.comboStreak) {
      _enqueueComboToast('Combo x${current.scoreState.comboStreak}');
    }

    if (current.level > previous.level) {
      _enqueueComboToast('Level ${current.level}');
    }

    if (current.isGameOver && !previous.isGameOver && _comboToasts.isNotEmpty) {
      setState(() {
        _comboToasts.clear();
      });
    }
  }

  void _enqueueComboToast(String text) {
    final int id = ++_comboToastSeq;
    final _ComboToastData entry = _ComboToastData(
      id: id,
      text: text,
      visible: false,
    );

    setState(() {
      _comboToasts.insert(0, entry);
      if (_comboToasts.length > 4) {
        _comboToasts.removeLast();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateToastVisibility(id: id, visible: true);
    });

    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      _updateToastVisibility(id: id, visible: false);
    });

    Future<void>.delayed(const Duration(milliseconds: 1350), () {
      if (_isDisposed) {
        return;
      }
      setState(() {
        _comboToasts.removeWhere((item) => item.id == id);
      });
    });
  }

  void _updateToastVisibility({
    required int id,
    required bool visible,
  }) {
    if (_isDisposed) {
      return;
    }

    final int index = _comboToasts.indexWhere((item) => item.id == id);
    if (index < 0) {
      return;
    }

    setState(() {
      final _ComboToastData current = _comboToasts[index];
      _comboToasts[index] = current.copyWith(visible: visible);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classic Mode')),
      body: ValueListenableBuilder<GameLoopViewState>(
        valueListenable: _controller.stateListenable,
        builder:
            (BuildContext context, GameLoopViewState state, Widget? child) {
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0xFFF6FBFF),
                        Color(0xFFE9F2FA),
                        Color(0xFFDDEAF6),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _surfaceMaxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: GameWidget(
                        game: _game,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _surfaceMaxWidth,
                      ),
                      child: _HudPanel(state: state),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 66,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _surfaceMaxWidth,
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: _ComboStackOverlay(
                          entries: _comboToasts,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (state.isOnboardingVisible)
                Positioned(
                  top: 122,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _surfaceMaxWidth,
                        ),
                        child: _OnboardingOverlayCard(
                          title:
                              state.onboardingTitle ?? 'Classic Mode Tutorial',
                          description: state.onboardingDescription ??
                              'Place pieces to fill lines and build combos.',
                          onDismiss: () {
                            unawaited(
                              _controller.dismissOnboarding(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              if (state.isGameOver)
                Positioned.fill(
                  child: Container(
                    color: const Color(0x66000000),
                    child: Center(
                      child: Card(
                        margin: const EdgeInsets.all(24),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text(
                                'Game Over',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Score: ${state.scoreState.totalScore}'),
                              Text('Best: ${state.bestScore}'),
                              const SizedBox(height: 16),
                              if (state.canUseRewardedRevive)
                                FilledButton.tonalIcon(
                                  onPressed: _onRevivePressed,
                                  icon: const Icon(Icons.favorite),
                                  label: const Text('Revive (Rewarded)'),
                                ),
                              if (state.canUseRewardedRevive)
                                const SizedBox(height: 10),
                              FilledButton(
                                onPressed: _controller.startNewGame,
                                child: const Text('Restart'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (state.isBannerVisible)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _surfaceMaxWidth,
                        ),
                        child: const _BannerAdPlaceholder(),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onRevivePressed() async {
    final RewardedReviveResult result = await _controller.useRewardedRevive();
    if (!mounted) {
      return;
    }
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Revive failed: ${result.failureReason ?? 'unknown'}',
          ),
        ),
      );
    }
  }
}

class _OnboardingOverlayCard extends StatelessWidget {
  const _OnboardingOverlayCard({
    required this.title,
    required this.description,
    required this.onDismiss,
  });

  final String title;
  final String description;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF5243348),
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.tips_and_updates_outlined,
              color: Color(0xFFFDE68A),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFFDCE7F2),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFBAE6FD),
              ),
              child: const Text('Hide'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComboStackOverlay extends StatelessWidget {
  const _ComboStackOverlay({
    required this.entries,
  });

  final List<_ComboToastData> entries;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            entries.map((entry) => _ComboToastChip(entry: entry)).toList(),
      ),
    );
  }
}

class _ComboToastChip extends StatelessWidget {
  const _ComboToastChip({
    required this.entry,
  });

  final _ComboToastData entry;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 180),
      offset: entry.visible ? Offset.zero : const Offset(0.2, -0.2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: entry.visible ? 1 : 0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFE86A33),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x553A1F1A),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            entry.text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _HudPanel extends StatelessWidget {
  const _HudPanel({
    required this.state,
  });

  final GameLoopViewState state;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      color: const Color.fromRGBO(255, 255, 255, 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _HudMetric(
                label: 'Score',
                value: '${state.scoreState.totalScore}',
              ),
            ),
            Expanded(
              child: _HudMetric(
                label: 'Level',
                value: '${state.level}',
              ),
            ),
            Expanded(
              child: _HudMetric(
                label: 'Combo',
                value: '${state.scoreState.comboStreak}',
              ),
            ),
            Expanded(
              child: _HudMetric(
                label: 'Best',
                value: '${state.bestScore}',
              ),
            ),
            Expanded(
              child: _HudMetric(
                label: 'Moves',
                value: '${state.movesPlayed}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF44657A),
          ),
        ),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Text(
            value,
            key: ValueKey<String>('${label}_$value'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerAdPlaceholder extends StatelessWidget {
  const _BannerAdPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F6FA),
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: <Widget>[
            Icon(
              Icons.campaign_outlined,
              color: Color(0xFF5B7281),
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Banner Ad Slot (Debug)',
              style: TextStyle(
                color: Color(0xFF49606F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComboToastData {
  const _ComboToastData({
    required this.id,
    required this.text,
    required this.visible,
  });

  final int id;
  final String text;
  final bool visible;

  _ComboToastData copyWith({
    int? id,
    String? text,
    bool? visible,
  }) {
    return _ComboToastData(
      id: id ?? this.id,
      text: text ?? this.text,
      visible: visible ?? this.visible,
    );
  }
}
