# ADR-003 — Billing + server-side receipt validation architecture

Status: Accepted (2026-06-19) — implemented in code; pending `pub get`, deploy, and Play sandbox verification
Related: [audit §4](../audit/01_FULL_PROJECT_AUDIT_2026-06-19.md), [operations/09_IAP_BILLING_V7_INTEGRATION.md](../operations/09_IAP_BILLING_V7_INTEGRATION.md)

## Context
The product is ad-free, IAP-only. Billing currently does not exist: no `in_app_purchase` dependency, no billing `.dart`, no `verifyPurchase` Cloud Function. There is no revenue path at all, and this is the top release blocker for a monetization-driven game.

## Decision (to ratify)
Implement Google Play Billing v7 via `in_app_purchase`: `GooglePlayBillingService` (acknowledge + pending-transaction poll + restore/past-purchase query), with **server-side receipt validation** in a Cloud Function `verifyPurchase` writing to Firestore `entitlements/{uid}` bound to the Anonymous Auth UID. Keep `LocalCatalogIapStoreService` as a `APP_FLAVOR=debug`-only dev fallback. RuStore billing adapter follows in Phase 2.

## Implemented
- `apps/mobile/pubspec.yaml`: added `in_app_purchase: ^3.2.0` and `cloud_functions: ^5.0.0`.
- `lib/infra/billing/google_play_billing_service.dart`: `IapStoreService` impl over `in_app_purchase` (Billing v7). Bridges the async `purchaseStream` to the `Future<IapPurchaseResult> purchase(...)` contract via a per-product completer; validates every purchased/restored item before granting; acknowledges (`completePurchase`) only after a valid grant; caches entitlements in `PlayerProgressState.ownedProductIds`; restore + product-detail (localized price) loading.
- `lib/infra/billing/purchase_receipt_validator.dart` + `cloud_functions_receipt_validator.dart`: validator interface + `verifyPurchase` callable client.
- `infra/cloud_functions/functions/`: `verifyPurchase` callable (Functions v2) — auth-gated, replay-protected, verifies via Google Play Developer API, writes `entitlements/{uid}`.
- DI: production (`environment.isProduction`) → `GooglePlayBillingService`; stage/QA release → `LocalCatalogIapStoreService`; dev/debug → `DebugIapStoreService`.

## Consequences
- Entitlements become server-authoritative and survive reinstall; required for the acceptance gate "purchase + restore + reinstall passes for one cosmetic SKU".
- Adds Cloud Functions + Firestore to the must-deploy surface; receipt validation rejects replayed/forged tokens (token bound to one UID).
- **Still required before this transacts real money:** (1) `flutter pub get` to fetch the new plugins; (2) Anonymous Auth sign-in at bootstrap so `verifyPurchase` has a UID; (3) Play Console SKUs + service-account API linkage; (4) deploy `verifyPurchase`; (5) Play sandbox test of purchase + restore + reinstall. None of these are runnable in the authoring environment.
