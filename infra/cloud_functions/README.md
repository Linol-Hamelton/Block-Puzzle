# infra/cloud_functions

Firebase Cloud Functions for Lumina Blocks. Created in Phase 1 to back real
billing (P0). See [docs/adr/003-billing-receipt-validation.md](../../docs/adr/003-billing-receipt-validation.md).

## Functions

### `verifyPurchase` (callable)
Server-side Google Play purchase validation. Called by the client
`CloudFunctionsReceiptValidator` after a Play purchase/restore. It:
1. requires an authenticated caller (Firebase Anonymous Auth UID),
2. rejects a `purchaseToken` already bound to another account (replay/fraud),
3. verifies the token via the Google Play Developer API
   (`purchases.products.get`),
4. grants the entitlement under Firestore `entitlements/{uid}` (idempotent),
5. returns `{ valid, entitlements, errorCode?, message? }`.

Acknowledgement is left to the client (`completePurchase`), so this function
never double-acknowledges.

## Prerequisites (must be done before this works end-to-end)
1. **Anonymous Auth** must be enabled and the client must sign in anonymously at
   bootstrap so `request.auth.uid` is present. (Tracked separately — see audit.)
2. **Service account / Play linkage:** the Functions runtime service account
   must have the `androidpublisher` scope and be linked in Google Play Console
   (Setup → API access) with permission to view financial/order data.
3. Set the package name if it differs from the default:
   `firebase functions:config` / environment `ANDROID_PACKAGE_NAME`.
4. **Firestore rules:** `entitlements/{uid}` and `purchaseTokens/{token}` are
   written only by this function (Admin SDK, bypasses rules). Client read of
   own entitlements may be allowed; client writes must be denied.

## Deploy
```bash
cd infra/cloud_functions/functions
npm install
firebase deploy --only functions:verifyPurchase
```

## Status
Deployable scaffold. Not yet deployed or tested against a real Play purchase in
this repo. Validate with a Play sandbox account (purchase + restore + reinstall)
before relying on it — this is the Phase 1 billing acceptance gate.
