# Ad-Free Mode Strategy

## 1. Decision
Current product mode: **no in-app ads**.

This means:
1. Banner disabled
2. Interstitial disabled
3. Rewarded disabled

## 2. Config Keys
In remote config:
1. `ads.ad_free_mode = true`
2. `ads.banner_enabled = false`
3. `ads.interstitial_enabled = false`
4. `ads.rewarded_revive_enabled = false`

Even if other ad keys are accidentally enabled, `ads.ad_free_mode = true` has priority.

## 3. Monetization Direction (without ads)
Recommended next monetization tracks:
1. `IAP ad-free` is not needed anymore (already ad-free by default)
2. Cosmetic packs (themes, board skins, VFX packs)
3. Premium progression bundles (quality-of-life boosts)
4. Battle pass / seasonal progression (later stage)

## 4. What is required from product owner now
1. Confirm ad-free mode for all environments (`dev/stage/prod`)
2. Choose first IAP strategy: `cosmetics-first` or `premium-bundle-first`
3. Define economy constraints (max spend per day/week, offer frequency)
