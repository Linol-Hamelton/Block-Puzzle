import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/di/di_container.dart';
import '../../../ui/theme/app_theme.dart';
import '../audio/game_sfx_player.dart';
import '../application/game_loop_controller.dart';
import '../application/game_loop_view_state.dart';
import 'block_puzzle_game.dart';

class GameLoopScreen extends StatefulWidget {
  const GameLoopScreen({super.key});

  @override
  State<GameLoopScreen> createState() => _GameLoopScreenState();
}

class _GameLoopScreenState extends State<GameLoopScreen>
    with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _controller.stateListenable.removeListener(_onControllerStateChanged);
    _game.shutdown();
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
        unawaited(_sfxPlayer.preload());
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _game.pauseEngine();
        return;
    }
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
      appBar: AppBar(
        title: const Text(
          'Classic Mode',
          style: TextStyle(
            color: Color(0xFFC9EDFF),
            fontWeight: FontWeight.w500,
            fontSize: 24,
            letterSpacing: 0.35,
            shadows: <Shadow>[
              Shadow(
                color: Color(0x6634C8FF),
                blurRadius: 18,
              ),
            ],
          ),
        ),
      ),
      body: ValueListenableBuilder<GameLoopViewState>(
        valueListenable: _controller.stateListenable,
        builder:
            (BuildContext context, GameLoopViewState state, Widget? child) {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final _LayoutProfile layout = _LayoutProfile.resolve(
                constraints: constraints,
                mediaQuery: MediaQuery.of(context),
                isBannerVisible: state.isBannerVisible,
                isOnboardingVisible: state.isOnboardingVisible,
              );

              _game.configureViewportInsets(
                topInset: layout.gameTopInset,
                bottomInset: layout.gameBottomInset,
                horizontalPadding: layout.surfaceHorizontalPadding,
                boardMaxPixels: layout.boardMaxPixels,
                boardMinPixels: layout.boardMinPixels,
                rackCellSize: layout.rackCellSize,
                boardToRackGap: layout.boardToRackGap,
                rackMinTouchTargetSize: layout.touchTargetMinSize,
                dragActivationDistance: layout.dragActivationDistance,
              );

              return Stack(
                children: <Widget>[
                  const Positioned.fill(child: _NebulaBackground()),
                  Positioned.fill(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: layout.surfaceMaxWidth,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: layout.surfaceHorizontalPadding,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: const Color(0x2C88CFFF),
                              ),
                            ),
                            child: GameWidget(
                              game: _game,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: layout.hudTop,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.surfaceHorizontalPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: layout.surfaceMaxWidth,
                          ),
                          child: _HudPanel(
                            state: state,
                            uiScale: layout.uiScale,
                            compact: layout.compactHud,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: layout.comboTop,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.surfaceHorizontalPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: layout.surfaceMaxWidth,
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
                      top: layout.onboardingTop,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: layout.surfaceHorizontalPadding,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: layout.surfaceMaxWidth,
                            ),
                            child: _OnboardingOverlayCard(
                              title: state.onboardingTitle ??
                                  'Classic Mode Tutorial',
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
                  Positioned(
                    bottom: layout.assistBarBottom,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.surfaceHorizontalPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: layout.surfaceMaxWidth,
                          ),
                          child: _AssistActionsBar(
                            canUseHint: state.canUseRewardedHint,
                            canUseUndo: state.canUseRewardedUndo,
                            hasUnlimitedTools: state.hasUnlimitedRewardedTools,
                            credits: state.rewardedToolsCredits,
                            onHintPressed: _onHintPressed,
                            onUndoPressed: _onUndoPressed,
                            compact: layout.compactActions,
                            uiScale: layout.uiScale,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (state.isGameOver)
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xB20A1222),
                        child: Center(
                          child: _GameOverOverlayCard(
                            state: state,
                            onRestartPressed: _controller.startNewGame,
                            onRevivePressed: state.canUseRewardedRevive
                                ? _onRevivePressed
                                : null,
                            onSharePressed: state.isShareFlowEnabled
                                ? _onSharePressed
                                : null,
                          ),
                        ),
                      ),
                    ),
                  if (state.isBannerVisible)
                    Positioned(
                      bottom: layout.bannerBottom,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: layout.surfaceHorizontalPadding,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: layout.surfaceMaxWidth,
                            ),
                            child: _BannerAdPlaceholder(
                              height: layout.bannerHeight,
                              compact: layout.compactActions,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
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

  Future<void> _onHintPressed() async {
    final RewardedHintResult result = await _controller.useRewardedHint();
    if (!mounted) {
      return;
    }
    if (result.isSuccess) {
      final HintSuggestion hint = result.hintSuggestion!;
      final String details = hint.estimatedClearedLines > 0
          ? 'Hint: try ${hint.piece.id} at (${hint.anchorX}, ${hint.anchorY}) for ${hint.estimatedClearedLines} line clear.'
          : 'Hint: try ${hint.piece.id} at (${hint.anchorX}, ${hint.anchorY}).';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(details)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hint unavailable: ${result.failureReason ?? 'unknown'}'),
      ),
    );
  }

  Future<void> _onUndoPressed() async {
    final RewardedUndoResult result = await _controller.useRewardedUndo();
    if (!mounted) {
      return;
    }
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Undo applied')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Undo unavailable: ${result.failureReason ?? 'unknown'}'),
      ),
    );
  }

  Future<void> _onSharePressed() async {
    const String channel = 'clipboard';
    final String shareText = _controller.buildShareScoreText();
    await _controller.trackShareScoreTapped(channel: channel);

    if (!mounted) {
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: shareText));
      await _controller.trackShareScoreResult(
        channel: channel,
        success: true,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Result copied to clipboard. Share it anywhere.'),
        ),
      );
    } catch (error) {
      await _controller.trackShareScoreResult(
        channel: channel,
        success: false,
        failureReason: 'clipboard_error',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: $error'),
        ),
      );
    }
  }
}

class _AssistActionsBar extends StatelessWidget {
  const _AssistActionsBar({
    required this.canUseHint,
    required this.canUseUndo,
    required this.hasUnlimitedTools,
    required this.credits,
    required this.onHintPressed,
    required this.onUndoPressed,
    required this.compact,
    required this.uiScale,
  });

  final bool canUseHint;
  final bool canUseUndo;
  final bool hasUnlimitedTools;
  final int credits;
  final VoidCallback onHintPressed;
  final VoidCallback onUndoPressed;
  final bool compact;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final String balanceLabel =
        hasUnlimitedTools ? 'Tools: Unlimited' : 'Tools credits: $credits';
    final double verticalPadding = (8 * uiScale).clamp(6, 12).toDouble();
    final double horizontalPadding = (10 * uiScale).clamp(8, 16).toDouble();
    final double fontSize = (12 * uiScale).clamp(11, 15).toDouble();
    final ButtonStyle actionButtonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size>(
        Size(0, (46 * uiScale).clamp(48, 58).toDouble()),
      ),
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(
          horizontal: (10 * uiScale).clamp(8, 16).toDouble(),
        ),
      ),
      elevation: const WidgetStatePropertyAll<double>(0),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x4F88C8FF)),
        ),
      ),
      textStyle: WidgetStatePropertyAll<TextStyle>(
        TextStyle(
          fontSize: (14 * uiScale).clamp(13, 16).toDouble(),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return const Color(0x1D8CB6E0);
          }
          if (states.contains(WidgetState.pressed)) {
            return const Color(0x355EA9DE);
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0x2D5A9FD3);
          }
          return const Color(0x285B9FD5);
        },
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return const Color(0xFF83A0BE);
          }
          return const Color(0xFFDDF2FF);
        },
      ),
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0x20FFFFFF);
          }
          if (states.contains(WidgetState.focused)) {
            return const Color(0x14FFFFFF);
          }
          return null;
        },
      ),
    );

    Widget actionsRow() {
      return Row(
        children: <Widget>[
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: canUseHint ? onHintPressed : null,
              style: actionButtonStyle,
              icon: Icon(
                Icons.lightbulb_outline,
                size: (18 * uiScale).clamp(16, 22).toDouble(),
              ),
              label: const Text('Hint'),
            ),
          ),
          SizedBox(width: (8 * uiScale).clamp(6, 12).toDouble()),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: canUseUndo ? onUndoPressed : null,
              style: actionButtonStyle,
              icon: Icon(
                Icons.undo_rounded,
                size: (18 * uiScale).clamp(16, 22).toDouble(),
              ),
              label: const Text('Undo'),
            ),
          ),
        ],
      );
    }

    return Material(
      color: const Color(0x5A253D67),
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shadowColor: const Color(0x55050A14),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0x71334D7E), Color(0x5A1F335C)],
          ),
          border: Border.all(
            color: const Color(0x6581B1DF),
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x221389C9),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        balanceLabel,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: const Color(0xCDE3F8FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: (8 * uiScale).clamp(6, 12).toDouble()),
                    actionsRow(),
                  ],
                )
              : Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        balanceLabel,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: const Color(0xCDE3F8FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: (8 * uiScale).clamp(6, 12).toDouble()),
                    Expanded(
                      flex: 2,
                      child: actionsRow(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LayoutProfile {
  const _LayoutProfile({
    required this.surfaceMaxWidth,
    required this.surfaceHorizontalPadding,
    required this.hudTop,
    required this.hudHeightEstimate,
    required this.comboTop,
    required this.onboardingTop,
    required this.assistBarBottom,
    required this.bannerBottom,
    required this.bannerHeight,
    required this.gameTopInset,
    required this.gameBottomInset,
    required this.boardMaxPixels,
    required this.boardMinPixels,
    required this.rackCellSize,
    required this.boardToRackGap,
    required this.touchTargetMinSize,
    required this.dragActivationDistance,
    required this.uiScale,
    required this.compactHud,
    required this.compactActions,
  });

  final double surfaceMaxWidth;
  final double surfaceHorizontalPadding;
  final double hudTop;
  final double hudHeightEstimate;
  final double comboTop;
  final double onboardingTop;
  final double assistBarBottom;
  final double bannerBottom;
  final double bannerHeight;
  final double gameTopInset;
  final double gameBottomInset;
  final double boardMaxPixels;
  final double boardMinPixels;
  final double rackCellSize;
  final double boardToRackGap;
  final double touchTargetMinSize;
  final double dragActivationDistance;
  final double uiScale;
  final bool compactHud;
  final bool compactActions;

  static _LayoutProfile resolve({
    required BoxConstraints constraints,
    required MediaQueryData mediaQuery,
    required bool isBannerVisible,
    required bool isOnboardingVisible,
  }) {
    final double width = constraints.maxWidth;
    final double height = constraints.maxHeight;
    final double shortestSide = math.min(width, height);
    final bool isTablet = shortestSide >= 600;
    final bool isCompactPhone = shortestSide < 370;
    final bool isLargePhone = shortestSide >= 410 && !isTablet;

    final double uiScale = isTablet
        ? (shortestSide / 700).clamp(1.08, 1.26).toDouble()
        : (shortestSide / 390).clamp(0.9, 1.06).toDouble();

    final double surfaceMaxWidth = isTablet ? 1100 : 920;
    final double surfaceHorizontalPadding = isTablet
        ? 20
        : (isCompactPhone ? 10 : (isLargePhone ? 14 : 12)).toDouble();
    const double hudTop = 8;
    final double hudHeightEstimate =
        isTablet ? 142 : (isCompactPhone ? 122 : 132).toDouble();
    final double comboTop = hudTop + (isTablet ? 56 : 60);
    final double onboardingTop = hudTop + hudHeightEstimate + 8;
    final double assistBarHeight =
        isTablet ? 86 : (isCompactPhone ? 78 : 80).toDouble();
    final double bannerHeight = isTablet ? 60 : 54;
    final double safeBottomInset = mediaQuery.padding.bottom;
    final double assistBarBottom =
        (isBannerVisible ? (bannerHeight + 14) : 12) + safeBottomInset;
    final double bannerBottom = safeBottomInset + 8;
    final double onboardingExtra =
        isOnboardingVisible ? (isTablet ? 84 : 72) : 0;
    final double gameTopInset =
        hudTop + hudHeightEstimate + 10 + onboardingExtra;
    final double gameBottomInset = assistBarHeight +
        (isBannerVisible ? (bannerHeight + 18) : 14) +
        safeBottomInset;

    final double boardMaxPixels = isTablet
        ? (width * 0.68).clamp(480, 620).toDouble()
        : (width * (isCompactPhone ? 0.94 : 0.92)).clamp(330, 430).toDouble();
    final double boardMinPixels =
        isTablet ? 260 : (isCompactPhone ? 190 : 210).toDouble();
    final double rackCellSize =
        isTablet ? 30 : (isCompactPhone ? 22 : 24).toDouble();
    final double boardToRackGap =
        isTablet ? 24 : (isCompactPhone ? 16 : 18).toDouble();
    final double touchTargetMinSize =
        isTablet ? 56 : (isCompactPhone ? 48 : 52).toDouble();
    final double dragActivationDistance =
        isTablet ? 12 : (isCompactPhone ? 7 : 9).toDouble();

    return _LayoutProfile(
      surfaceMaxWidth: surfaceMaxWidth,
      surfaceHorizontalPadding: surfaceHorizontalPadding,
      hudTop: hudTop,
      hudHeightEstimate: hudHeightEstimate,
      comboTop: comboTop,
      onboardingTop: onboardingTop,
      assistBarBottom: assistBarBottom,
      bannerBottom: bannerBottom,
      bannerHeight: bannerHeight,
      gameTopInset: gameTopInset,
      gameBottomInset: gameBottomInset,
      boardMaxPixels: boardMaxPixels,
      boardMinPixels: boardMinPixels,
      rackCellSize: rackCellSize,
      boardToRackGap: boardToRackGap,
      touchTargetMinSize: touchTargetMinSize,
      dragActivationDistance: dragActivationDistance,
      uiScale: uiScale,
      compactHud: isCompactPhone,
      compactActions: isCompactPhone,
    );
  }
}

class _GameOverOverlayCard extends StatelessWidget {
  const _GameOverOverlayCard({
    required this.state,
    required this.onRestartPressed,
    this.onRevivePressed,
    this.onSharePressed,
  });

  final GameLoopViewState state;
  final VoidCallback onRestartPressed;
  final VoidCallback? onRevivePressed;
  final VoidCallback? onSharePressed;

  @override
  Widget build(BuildContext context) {
    final bool isNewBest = state.scoreState.totalScore >= state.bestScore &&
        state.scoreState.totalScore > 0;
    final ButtonStyle actionButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size(112, 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w700,
      ),
    );

    return Card(
      margin: const EdgeInsets.all(20),
      color: const Color(0xFFF0F6FF),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0x442B4E7A)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.flag_circle_outlined,
                    color: Color(0xFF1E5B82),
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Round Complete',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isNewBest)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDF3E7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'New Best',
                        style: TextStyle(
                          color: Color(0xFF276642),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _RoundStatTile(
                      label: 'Score',
                      value: '${state.scoreState.totalScore}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RoundStatTile(
                      label: 'Best',
                      value: '${state.bestScore}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RoundStatTile(
                      label: 'Level',
                      value: '${state.level}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RoundStatTile(
                      label: 'Moves',
                      value: '${state.movesPlayed}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Daily goals: ${state.dailyGoals.completedCount}/${state.dailyGoals.totalCount}',
                        style: const TextStyle(
                          color: Color(0xFF244A66),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      'Streak ${state.streak.currentDays}d',
                      style: const TextStyle(
                        color: Color(0xFF244A66),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  if (onSharePressed != null)
                    FilledButton.tonalIcon(
                      onPressed: onSharePressed,
                      style: actionButtonStyle,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                  if (onRevivePressed != null)
                    FilledButton.tonalIcon(
                      onPressed: onRevivePressed,
                      style: actionButtonStyle,
                      icon: const Icon(Icons.favorite),
                      label: const Text('Revive'),
                    ),
                  FilledButton.icon(
                    onPressed: onRestartPressed,
                    style: actionButtonStyle,
                    icon: const Icon(Icons.replay),
                    label: const Text('Restart'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundStatTile extends StatelessWidget {
  const _RoundStatTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF3F617C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF14293D),
            ),
          ),
        ],
      ),
    );
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
      color: const Color(0xEE172840),
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.tips_and_updates_outlined,
              color: LuminaPalette.amber,
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
                      color: Color(0xFFCFE0F2),
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
                foregroundColor: LuminaPalette.cyan,
                minimumSize: const Size(64, 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            color: const Color(0xFFF58F56),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0x55FFFFFF),
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x552A1B16),
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
              letterSpacing: 0.2,
              shadows: <Shadow>[
                Shadow(
                  color: Color(0x44000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
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
    required this.uiScale,
    required this.compact,
  });

  final GameLoopViewState state;
  final double uiScale;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double metricLabelSize =
        ((compact ? 10.5 : 11.0) * uiScale).clamp(10, 13).toDouble();
    final double metricValueSize =
        ((compact ? 15.0 : 16.0) * uiScale).clamp(14, 21).toDouble();
    final double outerHorizontalPadding =
        (12 * uiScale).clamp(10, 18).toDouble();
    final double outerVerticalPadding = (10 * uiScale).clamp(8, 14).toDouble();
    final double rowGap = (8 * uiScale).clamp(6, 11).toDouble();

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      color: const Color(0x62344E79),
      shadowColor: const Color(0x3C091126),
      surfaceTintColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0x77415E8E), Color(0x5A2D436E)],
          ),
          border: Border.all(color: const Color(0x77A3CEFF)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x2A42C2FF),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: outerHorizontalPadding,
            vertical: outerVerticalPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (compact) ...<Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _HudMetric(
                        label: 'Score',
                        value: '${state.scoreState.totalScore}',
                        labelFontSize: metricLabelSize,
                        valueFontSize: metricValueSize,
                      ),
                    ),
                    Expanded(
                      child: _HudMetric(
                        label: 'Level',
                        value: '${state.level}',
                        labelFontSize: metricLabelSize,
                        valueFontSize: metricValueSize,
                      ),
                    ),
                    Expanded(
                      child: _HudMetric(
                        label: 'Combo',
                        value: '${state.scoreState.comboStreak}',
                        labelFontSize: metricLabelSize,
                        valueFontSize: metricValueSize,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: (4 * uiScale).clamp(3, 7).toDouble()),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _HudMetric(
                        label: 'Best',
                        value: '${state.bestScore}',
                        labelFontSize: metricLabelSize,
                        valueFontSize: metricValueSize,
                      ),
                    ),
                    Expanded(
                      child: _HudMetric(
                        label: 'Moves',
                        value: '${state.movesPlayed}',
                        labelFontSize: metricLabelSize,
                        valueFontSize: metricValueSize,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ] else
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _HudMetric(
                        label: 'Score',
                        value: '${state.scoreState.totalScore}',
                        labelFontSize: metricLabelSize,
                        valueFontSize: metricValueSize,
                      ),
                    ),
                    Expanded(
                      child: _HudMetric(
                        label: 'Level',
                        value: '${state.level}',
                        labelFontSize: metricLabelSize,
                        valueFontSize: metricValueSize,
                      ),
                    ),
                    Expanded(
                      child: _HudMetric(
                        label: 'Combo',
                        value: '${state.scoreState.comboStreak}',
                        labelFontSize: metricLabelSize,
                        valueFontSize: metricValueSize,
                      ),
                    ),
                    Expanded(
                      child: _HudMetric(
                        label: 'Best',
                        value: '${state.bestScore}',
                        labelFontSize: metricLabelSize,
                        valueFontSize: metricValueSize,
                      ),
                    ),
                    Expanded(
                      child: _HudMetric(
                        label: 'Moves',
                        value: '${state.movesPlayed}',
                        labelFontSize: metricLabelSize,
                        valueFontSize: metricValueSize,
                      ),
                    ),
                  ],
                ),
              SizedBox(height: rowGap),
              _ProgressSummaryBar(
                state: state,
                uiScale: uiScale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressSummaryBar extends StatelessWidget {
  const _ProgressSummaryBar({
    required this.state,
    required this.uiScale,
  });

  final GameLoopViewState state;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    if (state.uxVariant == 'hud_focus_v1') {
      return _FocusProgressSummary(
        state: state,
        uiScale: uiScale,
      );
    }

    final String goalsLine =
        'Goals ${state.dailyGoals.completedCount}/${state.dailyGoals.totalCount}'
        '  M ${state.dailyGoals.movesProgress}/${state.dailyGoals.movesTarget}'
        '  L ${state.dailyGoals.linesProgress}/${state.dailyGoals.linesTarget}'
        '  S ${state.dailyGoals.scoreProgress}/${state.dailyGoals.scoreTarget}';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: (10 * uiScale).clamp(8, 14).toDouble(),
        vertical: (6 * uiScale).clamp(5, 10).toDouble(),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0x2E9CBFEC),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              goalsLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: (11 * uiScale).clamp(10, 13).toDouble(),
                color: const Color(0xFFC8E6FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: (10 * uiScale).clamp(8, 14).toDouble()),
          Text(
            'Streak ${state.streak.currentDays}d'
            '  Best ${state.streak.bestDays}d',
            style: TextStyle(
              fontSize: (11 * uiScale).clamp(10, 13).toDouble(),
              color: const Color(0xFFD2ECFF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusProgressSummary extends StatelessWidget {
  const _FocusProgressSummary({
    required this.state,
    required this.uiScale,
  });

  final GameLoopViewState state;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: (10 * uiScale).clamp(8, 14).toDouble(),
        vertical: (8 * uiScale).clamp(6, 12).toDouble(),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0x2E9CBFEC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Goals ${state.dailyGoals.completedCount}/${state.dailyGoals.totalCount}',
                style: TextStyle(
                  fontSize: (11 * uiScale).clamp(10, 13).toDouble(),
                  color: const Color(0xFFC8E6FF),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Streak ${state.streak.currentDays}d / ${state.streak.bestDays}d',
                style: TextStyle(
                  fontSize: (11 * uiScale).clamp(10, 13).toDouble(),
                  color: const Color(0xFFD2ECFF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: (7 * uiScale).clamp(6, 10).toDouble()),
          Row(
            children: <Widget>[
              Expanded(
                child: _GoalProgressPill(
                  label: 'Moves',
                  progress: state.dailyGoals.movesProgress,
                  target: state.dailyGoals.movesTarget,
                  completed: state.dailyGoals.movesCompleted,
                  uiScale: uiScale,
                ),
              ),
              SizedBox(width: (6 * uiScale).clamp(4, 10).toDouble()),
              Expanded(
                child: _GoalProgressPill(
                  label: 'Lines',
                  progress: state.dailyGoals.linesProgress,
                  target: state.dailyGoals.linesTarget,
                  completed: state.dailyGoals.linesCompleted,
                  uiScale: uiScale,
                ),
              ),
              SizedBox(width: (6 * uiScale).clamp(4, 10).toDouble()),
              Expanded(
                child: _GoalProgressPill(
                  label: 'Score',
                  progress: state.dailyGoals.scoreProgress,
                  target: state.dailyGoals.scoreTarget,
                  completed: state.dailyGoals.scoreCompleted,
                  uiScale: uiScale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalProgressPill extends StatelessWidget {
  const _GoalProgressPill({
    required this.label,
    required this.progress,
    required this.target,
    required this.completed,
    required this.uiScale,
  });

  final String label;
  final int progress;
  final int target;
  final bool completed;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (8 * uiScale).clamp(6, 12).toDouble(),
        vertical: (6 * uiScale).clamp(5, 9).toDouble(),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: completed ? const Color(0x3B78DFAF) : const Color(0x254D7CB0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: (10 * uiScale).clamp(9, 12).toDouble(),
              color:
                  completed ? const Color(0xFFD9FFEC) : const Color(0xC9CBE4FF),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$progress/$target',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: (11 * uiScale).clamp(10, 13).toDouble(),
              color: const Color(0xFFE8F7FF),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
    required this.label,
    required this.value,
    required this.labelFontSize,
    required this.valueFontSize,
  });

  final String label;
  final String value;
  final double labelFontSize;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: labelFontSize,
            color: const Color(0xB6C4E4FF),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
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
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
              color: const Color(0xFFE8FAFF),
              shadows: const <Shadow>[
                Shadow(
                  color: Color(0x9929B6FF),
                  blurRadius: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerAdPlaceholder extends StatelessWidget {
  const _BannerAdPlaceholder({
    required this.height,
    required this.compact,
  });

  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE81B2C49),
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      shadowColor: const Color(0x44050A14),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: LuminaPalette.panelBorder,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
        alignment: Alignment.centerLeft,
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.campaign_outlined,
              color: LuminaPalette.textSecondary,
              size: 18,
            ),
            SizedBox(width: compact ? 6 : 8),
            const Text(
              'Banner Ad Slot (Debug)',
              style: TextStyle(
                color: LuminaPalette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NebulaBackground extends StatelessWidget {
  const _NebulaBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF070E2A),
            Color(0xFF121D4B),
            Color(0xFF141B4B),
            Color(0xFF0A153D),
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

    final Paint cyanNebula = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 0.95,
        colors: <Color>[
          _withAlpha(const Color(0xFF56D4FF), 0.2),
          _withAlpha(const Color(0xFF56D4FF), 0.06),
          Colors.transparent,
        ],
      ).createShader(rect);
    final Paint violetNebula = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.55, 0.08),
        radius: 1.05,
        colors: <Color>[
          _withAlpha(const Color(0xFF9B7CFF), 0.16),
          _withAlpha(const Color(0xFF9B7CFF), 0.05),
          Colors.transparent,
        ],
      ).createShader(rect);
    final Paint lowerNebula = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.85),
        radius: 1.0,
        colors: <Color>[
          _withAlpha(const Color(0xFF46A2FF), 0.1),
          Colors.transparent,
        ],
      ).createShader(rect);
    final Paint starAura = Paint()
      ..color = const Color(0x44C6EEFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.7);
    final Paint starCore = Paint()..color = const Color(0xA5DFF7FF);

    canvas.drawRect(rect, cyanNebula);
    canvas.drawRect(rect, violetNebula);
    canvas.drawRect(rect, lowerNebula);

    for (final Offset star in _stars) {
      final Offset point = Offset(size.width * star.dx, size.height * star.dy);
      canvas.drawCircle(point, 2.5, starAura);
      canvas.drawCircle(point, 0.95, starCore);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

Color _withAlpha(
  Color color,
  double alpha,
) {
  final int a =
      (alpha.clamp(0, 1).toDouble() * 255).round().clamp(0, 255).toInt();
  return Color.fromARGB(a, color.red, color.green, color.blue);
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
