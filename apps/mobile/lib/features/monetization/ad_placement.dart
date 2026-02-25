enum AdPlacement {
  gameHudBanner,
  gameOverInterstitial,
  gameOverRewardedRevive,
}

extension AdPlacementWire on AdPlacement {
  String get wireName {
    switch (this) {
      case AdPlacement.gameHudBanner:
        return 'game_hud_banner';
      case AdPlacement.gameOverInterstitial:
        return 'game_over_interstitial';
      case AdPlacement.gameOverRewardedRevive:
        return 'game_over_rewarded_revive';
    }
  }
}
