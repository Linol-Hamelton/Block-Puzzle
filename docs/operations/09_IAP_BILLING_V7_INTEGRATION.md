# IAP Billing v7 Integration Plan (Ad-Free Monetization)

Last updated: 2026-04-12. Supersedes the earlier IAP sandbox scaffold document. Aligned with [../roadmap/01_ROADMAP_AND_SPRINTS.md](../roadmap/01_ROADMAP_AND_SPRINTS.md) Phase 1 Week 3 and [08_AD_FREE_MODE_STRATEGY.md](08_AD_FREE_MODE_STRATEGY.md).

## 1. Scope
Replace the in-memory `LocalCatalogIapStoreService` with a real Google Play Billing v7 integration for production flavors, wired behind the existing `IapStoreService` contract. Receipt validation is server-side via Firebase Cloud Functions. The RuStore adapter is out of scope for Phase 1 and tracked for Phase 2.

## 2. Current State (Phase 0)
- `IapStoreService` contract in `apps/mobile/lib/features/store/` with catalog loading, ownership state, debug purchase flow, restore flow.
- `LocalCatalogIapStoreService` is the only implementation; it returns a hard-coded catalog and fakes purchase success.
- Analytics hooks already emit `store_open`, `iap_purchase_attempt`, `iap_purchase`, `iap_restore`, `offer_targeting_exposure`.
- No real money can be charged. No receipt validation. No cross-device entitlement.

## 3. Target State (Phase 1 W3, Day 14-15)

### 3.1 Client
- Add `in_app_purchase` (Billing v7 compatible stable) to [../../apps/mobile/pubspec.yaml](../../apps/mobile/pubspec.yaml).
- New `lib/infra/billing/google_play_billing_service.dart` implementing `IapStoreService`:
  - `loadCatalog()` — query `ProductDetails` for active SKUs.
  - `launchPurchase(skuId)` — `InAppPurchase.instance.buyNonConsumable` for cosmetics/pass, `buyConsumable` for currency packs.
  - `listenPurchaseStream()` — on `PurchaseStatus.purchased`, POST receipt to `verifyPurchase` Cloud Function; on success, grant entitlement locally and `completePurchase`.
  - `restorePurchases()` — `InAppPurchase.instance.restorePurchases()` + entitlement sync from Firestore.
  - Acknowledge and consume correctly (Billing v7 requires ack within 3 days).
- `LocalCatalogIapStoreService` is retained under `APP_FLAVOR=debug` only.
- DI: [../../apps/mobile/lib/core/di/di_container.dart](../../apps/mobile/lib/core/di/di_container.dart) selects the implementation by flavor.

### 3.2 Server (Cloud Functions)
- `infra/cloud_functions/verify_purchase.ts`:
  - HTTPS callable, auth required (Firebase Anonymous Auth UID).
  - Verifies receipt via Google Play Developer API (`purchases.products.get` / `purchases.subscriptions.get`).
  - On success, writes `entitlements/{uid}` document with SKU id, purchase token, order id, verified timestamp.
  - Rejects replayed purchase tokens, unknown SKUs, and mismatched UIDs.
- Secret management via Secret Manager for the Google Play service account key.

### 3.3 Firestore
- `entitlements/{uid}` — owned SKUs, schema version, last-verified timestamp.
- Security rules: read-only for the owning UID, write-only from Cloud Functions.

### 3.4 Anonymous Auth
- `lib/infra/firebase/firebase_auth_service.dart` — `FirebaseAuth.instance.signInAnonymously()` during bootstrap. UID is the entitlement key.

## 4. Initial SKU Catalog (Phase 1 W3)
| SKU | Type | Price (USD reference) | Purpose |
|---|---|---|---|
| `pass_premium` | non-consumable (seasonal) | $4.99 | Season Pass premium lane |
| `pack_shards_small` | consumable | $0.99 | 500 Shards |
| `pack_shards_medium` | consumable | $4.99 | 3,000 Shards + 10% bonus |
| `pack_shards_large` | consumable | $9.99 | 7,000 Shards + 20% bonus |
| `skin_aurora` | non-consumable | $2.99 | Block skin |
| `skin_sunset` | non-consumable | $2.99 | Block skin |
| `theme_zen` | non-consumable | $1.99 | Board background |

Regional pricing is managed in Play Console. The Play Store catalog is the source of truth; the client calls `queryProductDetails(skuIds)` and never hard-codes prices.

## 5. Restore + Entitlement Sync
- On cold start after Anonymous Auth: `inAppPurchase.restorePurchases()` + read Firestore `entitlements/{uid}` → reconcile local state.
- Settings screen exposes a manual "Restore purchases" button with loading state and success/failure toast.
- Reinstall scenario: the anonymous UID is not preserved across reinstalls, so sync relies on the purchase token — the restore stream re-surfaces owned SKUs from Google Play, which are then re-verified and re-written to Firestore under the new UID.

## 6. Analytics Events (Firebase Analytics)
- `iap_catalog_loaded` — count, latency_ms.
- `iap_purchase_attempt` — sku_id, source screen.
- `iap_purchase_success` — sku_id, price_usd_micros, currency, order_id.
- `iap_purchase_failure` — sku_id, error_code, error_message.
- `iap_verify_success` — sku_id, verify_latency_ms.
- `iap_verify_failure` — sku_id, reason.
- `iap_restore_attempt` / `iap_restore_success` / `iap_restore_failure`.
- `offer_targeting_exposure` — segment, variant, recommended_sku.

Names are Firebase Analytics snake_case; parameter count ≤ 25; string length ≤ 100.

## 7. Quality Gates
1. `flutter test` unit tests for `GooglePlayBillingService` using a mock `InAppPurchase` stream.
2. Sandbox purchase end-to-end: test account → `skin_aurora` purchase → Cloud Function verify → Firestore write → cosmetic unlocked.
3. Restore after reinstall: purchase → uninstall → reinstall → sign in anonymously → restore → cosmetic still unlocked.
4. Replay attack: the same purchase token is rejected on a second verify call.
5. Crashlytics breadcrumbs for every purchase phase.
6. Phase 1 exit gate: zero open P0/P1 bugs in the billing path.

## 8. Deferred
- RuStore billing adapter (`lib/infra/billing/rustore_billing_service.dart`) — Phase 2, after Google Play integration is stable.
- Subscription SKUs — Phase 3+, only if the product decision changes.
- Anti-fraud beyond Google Play Developer API verification (velocity checks, device fingerprinting) — Phase 5, as needed.

## 9. Out of Scope
- Ad-based monetization (permanently out of scope — see [08_AD_FREE_MODE_STRATEGY.md](08_AD_FREE_MODE_STRATEGY.md)).
- iOS StoreKit (Android-only product).
- Web / desktop storefronts.
