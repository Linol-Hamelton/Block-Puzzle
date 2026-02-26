# Ad-Free Mode Strategy

## 1. Current Product Decision
The app runs in **ad-free mode** for current rollout waves.

Enabled behavior:
1. Banner disabled
2. Interstitial disabled
3. Rewarded ad revive disabled

## 2. Config Priority
Remote config keys:
1. `ads.ad_free_mode = true`
2. `ads.banner_enabled = false`
3. `ads.interstitial_enabled = false`
4. `ads.rewarded_revive_enabled = false`

`ads.ad_free_mode = true` has priority over other ad toggles.

## 3. Monetization Direction (Current)
1. Cosmetic IAP packs
2. Utility entitlement (`utility_tools_pass`)
3. Bundles and targeting strategy via remote config

## 4. Product Owner Inputs Needed
1. Confirm ad-free mode for all environments (`dev/stage/prod`).
2. Confirm primary strategy variant (currently `cosmetics-first`).
3. Confirm offer frequency and economy boundaries.
