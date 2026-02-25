# IAP Sandbox Scaffold (Ad-Free Monetization)

## 1. Implemented
1. Store module with catalog loading and ownership state.
2. Debug purchase flow (sandbox-like, no real billing charge).
3. Restore purchases flow.
4. Analytics hooks:
- `store_open`
- `iap_purchase_attempt`
- `iap_purchase`
- `iap_restore`

## 2. Initial SKU Draft
1. `skin_pack_neon` - `$1.99`
2. `skin_pack_mono` - `$2.99`
3. `premium_starter_bundle` - `$4.99`

## 3. What is still needed for real launch
1. Final SKU list and product descriptions.
2. Regional pricing matrix.
3. Real billing provider integration (`in_app_purchase` + store setup).
4. Purchase validation backend and fraud checks.

## 4. Product Decision Required
Choose first production focus:
1. Cosmetics-first.
2. Starter-bundle-first.
3. Hybrid rollout (A/B).
