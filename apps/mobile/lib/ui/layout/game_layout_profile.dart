import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Responsive layout profile for the game loop screen.
///
/// Resolves all dimension tokens (board size, HUD insets, UI scale,
/// compact flags) from the current [BoxConstraints] and [MediaQueryData].
/// This keeps the layout math out of the widget tree and makes it
/// independently testable.
class GameLayoutProfile {
  const GameLayoutProfile({
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

  /// Resolve a [GameLayoutProfile] from the current constraints.
  static GameLayoutProfile resolve({
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
        ? 22
        : (isCompactPhone ? 11 : (isLargePhone ? 16 : 14)).toDouble();
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
        hudTop + hudHeightEstimate + 26 + onboardingExtra;
    final double gameBottomInset = assistBarHeight +
        (isBannerVisible ? (bannerHeight + 18) : 14) +
        safeBottomInset;

    final double boardMaxPixels = isTablet
        ? (width * 0.67).clamp(468, 614).toDouble()
        : (width * (isCompactPhone ? 0.91 : 0.875)).clamp(318, 416).toDouble();
    final double boardMinPixels =
        isTablet ? 260 : (isCompactPhone ? 190 : 210).toDouble();
    final double rackCellSize =
        isTablet ? 30 : (isCompactPhone ? 22 : 24).toDouble();
    final double boardToRackGap =
        isTablet ? 30 : (isCompactPhone ? 26 : 28).toDouble();
    final double touchTargetMinSize =
        isTablet ? 56 : (isCompactPhone ? 48 : 52).toDouble();
    final double dragActivationDistance =
        isTablet ? 12 : (isCompactPhone ? 7 : 9).toDouble();

    return GameLayoutProfile(
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
