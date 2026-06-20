# infra/billing

> **STATUS: IMPLEMENTED IN CODE (2026-06-19), NOT YET SHIPPABLE.** `GooglePlayBillingService`, `PurchaseReceiptValidator` (+ `CloudFunctionsReceiptValidator`), and the `verifyPurchase` Cloud Function now exist and are wired in DI for production. Before it transacts real money it still needs: `flutter pub get`, Anonymous Auth sign-in at bootstrap, Play Console SKUs + service-account API linkage, function deploy, and a Play sandbox purchase+restore+reinstall test. See [docs/adr/003-billing-receipt-validation.md](../../../../../docs/adr/003-billing-receipt-validation.md).

Phase 1 Week 3.

Real store billing implementations:
- `GooglePlayBillingService` — `in_app_purchase` + Google Play Billing v7, acknowledge + pending transaction poll + past-purchase query
- `RuStoreBillingService` — Phase 2 add-on after Google Play bring-up
- Server-side receipt validation via Cloud Function `verifyPurchase` → Firestore `entitlements/{uid}`
- `LocalCatalogIapStoreService` (existing) is kept under `APP_FLAVOR=debug` only as a dev fallback

Catalog v1: `pass_premium`, `pack_shards_small`, `pack_shards_medium`, `pack_shards_large`, `skin_aurora`, `skin_sunset`, `theme_zen`.

Empty in Phase 0.
