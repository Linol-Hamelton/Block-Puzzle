# Segmentation & Offer Targeting v1

## 1. Goal
Provide first production-ready rules for ad-free store personalization:
1. User segmentation.
2. Segment-aware offer prioritization.
3. Analytics exposure for strategy evaluation.

## 2. User Segments (v1)
1. `new_user`
- no utility entitlement
- low recent activity

2. `engaged_user`
- daily activity/streak reaches configured threshold

3. `collector`
- owned IAP count reaches configured threshold

4. `utility_owner`
- owns `utility_tools_pass`

## 3. Remote Config Keys
1. Segmentation thresholds:
- `iap.segment_collector_owned_threshold`
- `iap.segment_engaged_streak_threshold`
- `iap.segment_engaged_daily_moves_threshold`
- `iap.segment_engaged_daily_score_threshold`

2. Offer mapping keys:
- `iap.targeting.new_user_primary_sku`
- `iap.targeting.engaged_primary_sku`
- `iap.targeting.collector_primary_sku`
- `iap.targeting.utility_owner_primary_sku`

3. Catalog ordering context:
- `ab.offer_strategy_variant`
- `iap.targeting_bundle_sku`
- `iap.targeting_cosmetic_primary_sku`
- `iap.targeting_cosmetic_secondary_sku`

## 4. Offer Targeting Rules
1. Resolve segment from ownership + progression snapshot.
2. Resolve base strategy from `ab.offer_strategy_variant`.
3. Build priority list:
- segment primary SKU first
- then strategy base order (bundle-first / cosmetics-first / utility-first)
4. Reorder store catalog:
- unowned offers first
- targeted rank
- lower price tie-breaker
5. Mark first unowned targeted SKU as `recommended`.

## 5. Analytics Events
1. `store_open`:
- `user_segment`
- `offer_strategy_variant`
- `recommended_sku`

2. `offer_targeting_exposure`:
- `segment`
- `strategy_variant`
- `recommended_sku`
- `targeted_skus`

3. `iap_purchase_attempt` and `iap_purchase`:
- `user_segment`
- `offer_strategy_variant`
- `is_recommended_offer`
- `position_index`

## 6. Guardrails for v1
1. Do not hide purchased SKUs, only de-prioritize.
2. Keep deterministic ordering for same inputs.
3. Use remote config defaults when keys are missing.
4. Rollback to `cosmetics_first_v1` if conversion drops in AB readout.
