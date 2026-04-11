# infra/billing

Phase 1 Week 3.

Real store billing implementations:
- `GooglePlayBillingService` — `in_app_purchase` + Google Play Billing v7, acknowledge + pending transaction poll + past-purchase query
- `RuStoreBillingService` — Phase 2 add-on after Google Play bring-up
- Server-side receipt validation via Cloud Function `verifyPurchase` → Firestore `entitlements/{uid}`
- `LocalCatalogIapStoreService` (existing) is kept under `APP_FLAVOR=debug` only as a dev fallback

Catalog v1: `pass_premium`, `pack_shards_small`, `pack_shards_medium`, `pack_shards_large`, `skin_aurora`, `skin_sunset`, `theme_zen`.

Empty in Phase 0.
