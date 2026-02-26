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

class _GameLoopScreenState extends State<GameLoopScreen> {
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
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            LuminaPalette.midnight,
                            LuminaPalette.deepNavy,
                            Color(0xFF18345A),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.25),
                          radius: 0.95,
                          colors: <Color>[
                            LuminaPalette.cyan.withOpacity(0.14),
                            LuminaPalette.violet.withOpacity(0.09),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
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
                              border: Border.all(
                                color: const Color(0x664C75A4),
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
          borderRadius: BorderRadius.circular(12),
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
            return const Color(0xFF24374F);
          }
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xFF335983);
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFF2F4F77);
          }
          return const Color(0xFF29466D);
        },
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return const Color(0xFF8CA7C1);
          }
          return LuminaPalette.textPrimary;
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
      color: const Color(0xE81B2C49),
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shadowColor: const Color(0x55050A14),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: LuminaPalette.panelBorder,
          ),
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
                          color: LuminaPalette.textPrimary,
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
                          color: LuminaPalette.textPrimary,
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
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      color: const Color(0xEAF3F8FF),
      shadowColor: const Color(0x33050A14),
      surfaceTintColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x442D4E78)),
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
        color: const Color(0xFFE7F1FC),
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
                color: const Color(0xFF2D4E66),
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
              color: const Color(0xFF214A65),
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
        color: const Color(0xFFE7F1FC),
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
                  color: const Color(0xFF264960),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Streak ${state.streak.currentDays}d / ${state.streak.bestDays}d',
                style: TextStyle(
                  fontSize: (11 * uiScale).clamp(10, 13).toDouble(),
                  color: const Color(0xFF214A65),
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
        color: completed ? const Color(0xFFD8F1E1) : const Color(0xFFF2F7FF),
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
                  completed ? const Color(0xFF2E6E4A) : const Color(0xFF33536A),
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
              color: const Color(0xFF203E53),
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
            color: const Color(0xFF446986),
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
