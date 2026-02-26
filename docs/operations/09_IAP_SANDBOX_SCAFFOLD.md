# IAP Sandbox Scaffold (Ad-Free Monetization)

## 1. Implemented
1. Store module with catalog loading and ownership state.
2. Debug/sandbox purchase flow (no real charge).
3. Restore purchases flow.
4. Segmentation and offer targeting v1.
5. Analytics hooks:
- `store_open`
- `iap_purchase_attempt`
- `iap_purchase`
- `iap_restore`
- `offer_targeting_exposure`

## 2. Initial SKU Draft
1. `skin_pack_neon` - `$1.99`
2. `skin_pack_mono` - `$2.99`
3. `premium_starter_bundle` - `$4.99`
4. `utility_tools_pass` - `$3.99`

## 3. Current Product Choice
- First focus: `cosmetics-first`.
- Bundles remain second-wave optimization track.

## 4. Still Needed for Real Launch
1. Final SKU catalog and localized descriptions.
2. Regional pricing matrix.
3. Real billing integration (`in_app_purchase` + store setup).
4. Purchase validation backend and anti-fraud checks.
